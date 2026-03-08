import Foundation
import SwiftData

/// The “core data rules” for the app (Vault, Categories, Items, Stores).
///
/// If you’re browsing as a non-dev:
/// - This is where the app creates/updates your saved grocery data.
///
/// If you’re browsing as a dev:
/// - Shopping-trip workflow is in `VaultService+Carts.swift`.
/// - Name/duplicate checks are in `VaultService+Validation.swift`.
extension VaultService {
    /// Loads the current user and vault from SwiftData.
    ///
    /// What it does:
    /// - If this is the first run, it creates a default user + default categories.
    /// - If the user already exists, it makes sure the default categories are present.
    ///
    /// Side effects:
    /// - Reads and writes to the database.
    /// - Updates `currentUser` / `vault`.
    func loadUserAndVault() {
        isLoading = true
        defer { isLoading = false }

        do {
            let userDescriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(userDescriptor)

            if let existingUser = users.first {
                self.currentUser = existingUser
                ensureAllCategoriesExist(in: existingUser.userVault)
            } else {
                let newUser = User(name: "Default User")
                modelContext.insert(newUser)
                prePopulateCategories(in: newUser.userVault)
                try modelContext.save()
                self.currentUser = newUser
            }

            let isPro = UserDefaults.standard.isPro
            reconcilePlanEntitlementState(isPro: isPro)
            reconcileCartPlanningEntitlementState(isPro: isPro)
            reconcileCartBackgroundEntitlementState(isPro: isPro)
            reconcileStoreEntitlementState(isPro: isPro)
        } catch {
            self.error = error
            print("❌ Failed to load user and vault: \(error)")
        }
    }

    func updateUserName(_ newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        currentUser?.name = trimmedName
        saveContext()
    }
}

extension VaultService {
    static let removedEmojiSentinel = "__removed__"
    private static let planSuppressionReasonCustomCategory = "custom_category_requires_pro"

    private func isAllowedLockedCategoryName(_ categoryName: String, allowedLockedCategoryNames: [String]) -> Bool {
        let normalizedCategory = normalizedCategoryName(categoryName)
        guard !normalizedCategory.isEmpty else { return false }

        return allowedLockedCategoryNames.contains {
            normalizedCategoryName($0) == normalizedCategory
        }
    }

    func isCategoryLockedByPlan(named categoryName: String) -> Bool {
        if let category = getCategory(named: categoryName) {
            return category.isPlanSuppressed
        }
        return shouldSuppressCategory(named: categoryName, isPro: UserDefaults.standard.isPro)
    }

    /// Reconciles persisted entitlement-lock state without mutating user-delete flags.
    func reconcilePlanEntitlementState(isPro: Bool) {
        guard let vault = vault else { return }

        var didChange = false

        for category in vault.categories {
            let shouldSuppressCategory = shouldSuppressCategory(named: category.name, isPro: isPro)
            let reason = shouldSuppressCategory ? Self.planSuppressionReasonCustomCategory : nil

            if applyPlanSuppression(
                to: category,
                isSuppressed: shouldSuppressCategory,
                reason: reason
            ) {
                didChange = true
            }

            for item in category.items {
                if applyPlanSuppression(
                    to: item,
                    isSuppressed: shouldSuppressCategory,
                    reason: reason
                ) {
                    didChange = true
                }
            }
        }

        for item in vault.deletedItems {
            let categoryName = item.deletedFromCategoryName ?? item.category?.name ?? ""
            let shouldSuppressItem = shouldSuppressCategory(named: categoryName, isPro: isPro)
            let reason = shouldSuppressItem ? Self.planSuppressionReasonCustomCategory : nil
            if applyPlanSuppression(
                to: item,
                isSuppressed: shouldSuppressItem,
                reason: reason
            ) {
                didChange = true
            }
        }

        guard didChange else { return }

        itemCache.removeAll()
        invalidateCategoryCache()
        saveContext()

        NotificationCenter.default.post(
            name: NSNotification.Name("DataUpdated"),
            object: nil
        )
    }

    /// Triggers UI refresh for plan-based store lock state.
    ///
    /// Store locks are computed dynamically from current entitlement, so no data mutation is required.
    func reconcileStoreEntitlementState(isPro: Bool) {
        NotificationCenter.default.post(
            name: NSNotification.Name("DataUpdated"),
            object: nil,
            userInfo: ["isPro": isPro]
        )
    }

    private func shouldSuppressCategory(named categoryName: String, isPro: Bool) -> Bool {
        guard !isPro else { return false }
        return !isSystemCategory(named: categoryName)
    }

    private func isSystemCategory(named categoryName: String) -> Bool {
        GroceryCategory.allCases.contains {
            normalizedCategoryName($0.title) == normalizedCategoryName(categoryName)
        }
    }

    @discardableResult
    private func applyPlanSuppression(to category: Category, isSuppressed: Bool, reason: String?) -> Bool {
        var changed = false

        if category.isPlanSuppressed != isSuppressed {
            category.isPlanSuppressed = isSuppressed
            changed = true
        }

        if isSuppressed {
            if category.planSuppressedAt == nil {
                category.planSuppressedAt = Date()
                changed = true
            }
            if category.planSuppressedReason != reason {
                category.planSuppressedReason = reason
                changed = true
            }
        } else {
            if category.planSuppressedAt != nil {
                category.planSuppressedAt = nil
                changed = true
            }
            if category.planSuppressedReason != nil {
                category.planSuppressedReason = nil
                changed = true
            }
        }

        return changed
    }

    @discardableResult
    private func applyPlanSuppression(to item: Item, isSuppressed: Bool, reason: String?) -> Bool {
        var changed = false

        if item.isPlanSuppressed != isSuppressed {
            item.isPlanSuppressed = isSuppressed
            changed = true
        }

        if isSuppressed {
            if item.planSuppressedAt == nil {
                item.planSuppressedAt = Date()
                changed = true
            }
            if item.planSuppressedReason != reason {
                item.planSuppressedReason = reason
                changed = true
            }
        } else {
            if item.planSuppressedAt != nil {
                item.planSuppressedAt = nil
                changed = true
            }
            if item.planSuppressedReason != nil {
                item.planSuppressedReason = nil
                changed = true
            }
        }

        return changed
    }

    /// Ensures the default grocery categories exist (without deleting user-created categories).
    ///
    /// Side effects:
    /// - Keeps default categories in the correct order.
    /// - Leaves any custom categories intact (they stay after defaults).
    private func ensureAllCategoriesExist(in vault: Vault) {
        func key(_ name: String) -> String {
            name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        let existingCategoriesDict = Dictionary(uniqueKeysWithValues: vault.categories.map { (key($0.name), $0) })
        let defaultCategoryTitles = GroceryCategory.allCases.map { $0.title }
        let defaultCategoryKeys = Set(defaultCategoryTitles.map(key))

        var orderedCategories: [Category] = []
        var needsSave = false

        for (index, groceryCategory) in GroceryCategory.allCases.enumerated() {
            let categoryName = groceryCategory.title
            let categoryKey = key(categoryName)

            if let existingCategory = existingCategoriesDict[categoryKey] {
                if existingCategory.name != categoryName {
                    existingCategory.name = categoryName
                    needsSave = true
                }
                if existingCategory.sortOrder != index {
                    existingCategory.sortOrder = index
                    needsSave = true
                }
                orderedCategories.append(existingCategory)
            } else {
                let newCategory = Category(name: categoryName)
                newCategory.sortOrder = index
                orderedCategories.append(newCategory)
                needsSave = true
            }
        }

        let extraCategories = vault.categories
            .filter { !defaultCategoryKeys.contains(key($0.name)) }
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

        var nextSortOrder = GroceryCategory.allCases.count
        for category in extraCategories {
            if category.sortOrder < nextSortOrder {
                category.sortOrder = nextSortOrder
                needsSave = true
            }
            nextSortOrder += 1
        }

        vault.categories = (orderedCategories + extraCategories).sorted { $0.sortOrder < $1.sortOrder }

        if needsSave {
            saveContext()
        }
    }

    private func prePopulateCategories(in vault: Vault) {
        vault.categories.removeAll()

        for (index, groceryCategory) in GroceryCategory.allCases.enumerated() {
            let category = Category(name: groceryCategory.title, emoji: groceryCategory.emoji)
            category.sortOrder = index
            vault.categories.append(category)
        }

        saveContext()
    }

    func addCategory(_ category: GroceryCategory) {
        guard let vault = vault else { return }

        let newCategory = Category(name: category.title, emoji: category.emoji)
        vault.categories.append(newCategory)
        saveContext()
    }
    
    func createCustomCategory(named name: String, emoji: String? = nil, colorHex: String? = nil) -> Category? {
        guard UserDefaults.standard.isPro else { return nil }
        guard let vault = vault else { return nil }
        
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let existing = vault.categories.first(where: { normalizedCategoryName($0.name) == normalizedCategoryName(trimmed) }) {
            // Update color/emoji if provided and different? 
            // For now, let's assume we just return existing, or maybe update if fields are provided?
            // The user wants to CREATE, but if it exists, maybe they want to EDIT?
            // Existing logic just returns existing. I'll stick to that to avoid side effects.
            return existing
        }
        
        let cleanedEmoji = emoji?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmoji: String? = {
            guard let cleanedEmoji, !cleanedEmoji.isEmpty else { return nil }
            return String(cleanedEmoji.prefix(1))
        }()
        
        // Updated to include colorHex
        let newCategory = Category(name: trimmed, emoji: normalizedEmoji, colorHex: colorHex)
        let nextSortOrder = (vault.categories.map(\.sortOrder).max() ?? (GroceryCategory.allCases.count - 1)) + 1
        newCategory.sortOrder = nextSortOrder
        
        modelContext.insert(newCategory)
        vault.categories.append(newCategory)
        saveContext()
        
        return newCategory
    }

    func updateCustomCategory(originalName: String, newName: String, emoji: String? = nil, colorHex: String? = nil) -> Category? {
        guard UserDefaults.standard.isPro else { return nil }
        guard let vault = vault else { return nil }

        let normalizedOriginal = normalizedCategoryName(originalName)
        guard let category = vault.categories.first(where: { normalizedCategoryName($0.name) == normalizedOriginal }) else {
            return nil
        }

        let isSystemCategory = GroceryCategory.allCases.contains {
            normalizedCategoryName($0.title) == normalizedCategoryName(category.name)
        }
        guard !isSystemCategory else { return nil }

        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let normalizedNew = normalizedCategoryName(trimmed)
        if normalizedNew != normalizedOriginal {
            if vault.categories.contains(where: { normalizedCategoryName($0.name) == normalizedNew }) {
                return nil
            }
        }

        let cleanedEmoji = emoji?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmoji: String? = {
            guard let cleanedEmoji, !cleanedEmoji.isEmpty else { return nil }
            return String(cleanedEmoji.prefix(1))
        }()

        let cleanedColor = colorHex?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedColor: String? = {
            guard let cleanedColor, !cleanedColor.isEmpty else { return nil }
            return cleanedColor
        }()

        category.name = trimmed
        category.emoji = normalizedEmoji
        category.colorHex = normalizedColor

        invalidateCategoryCache()
        saveContext()

        return category
    }

    func deleteCustomCategory(named name: String) -> Bool {
        guard UserDefaults.standard.isPro else { return false }
        guard let vault = vault else { return false }
        let normalized = normalizedCategoryName(name)
        guard let category = vault.categories.first(where: { normalizedCategoryName($0.name) == normalized }) else {
            return false
        }

        let isSystemCategory = GroceryCategory.allCases.contains {
            normalizedCategoryName($0.title) == normalizedCategoryName(category.name)
        }
        guard !isSystemCategory else { return false }

        let itemIds = category.items.map(\.id)
        for itemId in itemIds {
            deleteItem(itemId: itemId)
        }

        if let index = vault.categories.firstIndex(where: { $0.uid == category.uid }) {
            vault.categories.remove(at: index)
        }
        modelContext.delete(category)

        invalidateCategoryCache()
        saveContext()

        return true
    }

    func getCategory(_ groceryCategory: GroceryCategory) -> Category? {
        vault?.categories.first { $0.name == groceryCategory.title }
    }

    func getCategory(named name: String) -> Category? {
        guard let vault = vault else { return nil }
        let normalized = normalizedCategoryName(name)
        return vault.categories.first { normalizedCategoryName($0.name) == normalized }
    }

    func displayEmoji(forCategoryName name: String) -> String {
        if let category = getCategory(named: name) {
            let emoji = category.emoji?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if emoji == Self.removedEmojiSentinel {
                let trimmed = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? "📦" : String(trimmed.prefix(1)).uppercased()
            }
            if !emoji.isEmpty {
                return String(emoji.prefix(1))
            }

            if let groceryCategory = GroceryCategory.allCases.first(
                where: { normalizedCategoryName($0.title) == normalizedCategoryName(category.name) }
            ) {
                return groceryCategory.emoji
            }

            let trimmed = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "📦" : String(trimmed.prefix(1)).uppercased()
        }

        if let groceryCategory = GroceryCategory.allCases.first(
            where: { normalizedCategoryName($0.title) == normalizedCategoryName(name) }
        ) {
            return groceryCategory.emoji
        }

        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "📦" : String(trimmed.prefix(1)).uppercased()
    }

    /// Finds the category that currently contains `itemId`.
    func getCategory(for itemId: String) -> Category? {
        guard let vault = vault else { return nil }

        for category in vault.categories {
            if category.items.contains(where: { $0.id == itemId }) {
                return category
            }
        }
        return nil
    }
}

private func normalizedCategoryName(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
}

extension VaultService {
    /// Creates a new vault `Item` in a category and assigns a single initial `PriceOption`.
    ///
    /// Important:
    /// - This validates duplicates by (name + store).
    /// - This writes to SwiftData.
    func addItem(
        name: String,
        to category: GroceryCategory,
        store: String,
        price: Double,
        unit: String
    ) -> Item? {
        guard let vault = vault else { return nil }

        let validation = validateItemName(name, store: store)
        guard validation.isValid else {
            print("❌ Cannot add item: \(validation.errorMessage ?? "Unknown error")")
            return nil
        }

        let targetCategory: Category
        if let existingCategory = getCategory(category) {
            targetCategory = existingCategory
        } else {
            targetCategory = Category(name: category.title)
            modelContext.insert(targetCategory)
            vault.categories.append(targetCategory)
        }

        guard UserDefaults.standard.isPro || !targetCategory.isPlanSuppressed else {
            return nil
        }

        let pricePerUnit = PricePerUnit(priceValue: price, unit: unit)
        let priceOption = PriceOption(store: store, pricePerUnit: pricePerUnit)
        let newItem = Item(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        newItem.priceOptions = [priceOption]

        modelContext.insert(newItem)
        targetCategory.items.append(newItem)
        saveContext()
        return newItem
    }

    /// Creates a new vault `Item` in a category by name (supports custom categories).
    func addItem(
        name: String,
        toCategoryName categoryName: String,
        store: String,
        price: Double,
        unit: String
    ) -> Item? {
        guard let vault = vault else { return nil }

        let validation = validateItemName(name, store: store)
        guard validation.isValid else {
            print("❌ Cannot add item: \(validation.errorMessage ?? "Unknown error")")
            return nil
        }

        let trimmedCategory = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetCategory: Category
        if let existingCategory = getCategory(named: trimmedCategory) {
            guard UserDefaults.standard.isPro || !existingCategory.isPlanSuppressed else {
                return nil
            }
            targetCategory = existingCategory
        } else {
            guard UserDefaults.standard.isPro || isSystemCategory(named: trimmedCategory) else {
                return nil
            }
            targetCategory = Category(name: trimmedCategory)
            modelContext.insert(targetCategory)
            vault.categories.append(targetCategory)
        }

        let pricePerUnit = PricePerUnit(priceValue: price, unit: unit)
        let priceOption = PriceOption(store: store, pricePerUnit: pricePerUnit)
        let newItem = Item(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        newItem.priceOptions = [priceOption]

        modelContext.insert(newItem)
        targetCategory.items.append(newItem)
        saveContext()
        return newItem
    }

    /// Updates an item’s name/category and replaces the first price option with the new store/price/unit.
    ///
    /// Implications:
    /// - May move the item between categories.
    /// - Triggers active shopping carts containing the item to recompute totals.
    func updateItem(
        item: Item,
        newName: String,
        newCategory: GroceryCategory,
        newStore: String,
        newPrice: Double,
        newUnit: String
    ) -> Bool {
        guard let vault = vault else { return false }

        let validation = validateItemName(newName, store: newStore, excluding: item.id)
        guard validation.isValid else {
            print("❌ Cannot update item: \(validation.errorMessage ?? "Unknown error")")
            return false
        }

        guard UserDefaults.standard.isPro || !item.isPlanSuppressed else {
            return false
        }

        item.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingPriceOption = item.priceOptions.first {
            existingPriceOption.store = newStore
            existingPriceOption.pricePerUnit = PricePerUnit(priceValue: newPrice, unit: newUnit)
        } else {
            let newPriceOption = PriceOption(
                store: newStore,
                pricePerUnit: PricePerUnit(priceValue: newPrice, unit: newUnit)
            )
            item.priceOptions = [newPriceOption]
        }

        let currentCategory = vault.categories.first { $0.items.contains(where: { $0.id == item.id }) }
        let targetCategory = getCategory(newCategory) ?? Category(name: newCategory.title)

        guard UserDefaults.standard.isPro || !targetCategory.isPlanSuppressed else {
            return false
        }

        if currentCategory?.name != targetCategory.name {
            currentCategory?.items.removeAll { $0.id == item.id }

            if !vault.categories.contains(where: { $0.name == targetCategory.name }) {
                vault.categories.append(targetCategory)
            }
            targetCategory.items.append(item)
        }

        applyPlanSuppression(
            to: item,
            isSuppressed: targetCategory.isPlanSuppressed,
            reason: targetCategory.isPlanSuppressed ? Self.planSuppressionReasonCustomCategory : nil
        )

        saveContext()
        updateActiveCartsContainingItem(itemId: item.id)
        return true
    }

    /// Updates an item’s name/category using a category name (supports custom categories).
    func updateItem(
        item: Item,
        newName: String,
        newCategoryName: String,
        newStore: String,
        newPrice: Double,
        newUnit: String,
        allowedLockedCategoryNames: [String] = [],
        allowedLockedStoreNames: [String] = []
    ) -> Bool {
        guard let vault = vault else { return false }

        let validation = validateItemName(
            newName,
            store: newStore,
            excluding: item.id,
            allowedLockedStoreNames: allowedLockedStoreNames
        )
        guard validation.isValid else {
            print("❌ Cannot update item: \(validation.errorMessage ?? "Unknown error")")
            return false
        }

        let currentCategory = vault.categories.first { $0.items.contains(where: { $0.id == item.id }) }

        guard UserDefaults.standard.isPro
            || !item.isPlanSuppressed
            || isAllowedLockedCategoryName(
                currentCategory?.name ?? item.deletedFromCategoryName ?? "",
                allowedLockedCategoryNames: allowedLockedCategoryNames
            ) else {
            return false
        }

        item.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingPriceOption = item.priceOptions.first {
            existingPriceOption.store = newStore
            existingPriceOption.pricePerUnit = PricePerUnit(priceValue: newPrice, unit: newUnit)
        } else {
            let newPriceOption = PriceOption(
                store: newStore,
                pricePerUnit: PricePerUnit(priceValue: newPrice, unit: newUnit)
            )
            item.priceOptions = [newPriceOption]
        }

        let trimmedCategory = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingTargetCategory = getCategory(named: trimmedCategory)
        guard UserDefaults.standard.isPro || existingTargetCategory != nil || isSystemCategory(named: trimmedCategory) else {
            return false
        }
        let targetCategory = existingTargetCategory ?? Category(name: trimmedCategory)

        guard UserDefaults.standard.isPro
            || !targetCategory.isPlanSuppressed
            || isAllowedLockedCategoryName(
                targetCategory.name,
                allowedLockedCategoryNames: allowedLockedCategoryNames
            ) else {
            return false
        }

        if currentCategory?.name != targetCategory.name {
            currentCategory?.items.removeAll { $0.id == item.id }

            if !vault.categories.contains(where: { $0.name == targetCategory.name }) {
                vault.categories.append(targetCategory)
            }
            targetCategory.items.append(item)
        }

        applyPlanSuppression(
            to: item,
            isSuppressed: targetCategory.isPlanSuppressed,
            reason: targetCategory.isPlanSuppressed ? Self.planSuppressionReasonCustomCategory : nil
        )

        saveContext()
        updateActiveCartsContainingItem(itemId: item.id)
        return true
    }

    /// Updates an item depending on cart status:
    /// - Planning: updates the vault item and syncs planning carts.
    /// - Shopping: updates only the cart item’s actuals (must be fulfilled).
    /// - Completed: disallowed.
    func updateItemFromCart(
        itemId: String,
        cart: Cart,
        newName: String? = nil,
        newCategory: GroceryCategory? = nil,
        newStore: String? = nil,
        newPrice: Double? = nil,
        newUnit: String? = nil
    ) -> Bool {
        guard let item = findItemById(itemId) else { return false }

        switch cart.status {
        case .planning:
            guard !isCartPlanningLockedByPlan(cart) else {
                print("🔒 Planning edits are locked for cart: \(cart.name)")
                return false
            }

            var currentGroceryCategory: GroceryCategory = GroceryCategory.allCases.first!
            if let currentCategory = getCategory(for: itemId),
               let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == currentCategory.name }) {
                currentGroceryCategory = groceryCategory
            }

            let targetStore = newStore ?? item.priceOptions.first?.store ?? "Unknown Store"
            let targetPrice = newPrice ?? item.priceOptions.first(where: { $0.store == targetStore })?.pricePerUnit.priceValue ?? 0.0
            let targetUnit = newUnit ?? item.priceOptions.first(where: { $0.store == targetStore })?.pricePerUnit.unit ?? "piece"

            let success = updateItem(
                item: item,
                newName: newName ?? item.name,
                newCategory: newCategory ?? currentGroceryCategory,
                newStore: targetStore,
                newPrice: targetPrice,
                newUnit: targetUnit
            )

            if success {
                updateAllPlanningCartsWithItem(itemId: itemId, price: targetPrice, unit: targetUnit, store: targetStore)
            }
            return success

        case .shopping:
            guard let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }),
                  cartItem.isFulfilled else {
                print("⚠️ Cannot edit unfulfilled item while shopping")
                return false
            }

            cartItem.updateActualData(
                price: newPrice,
                quantity: nil,
                unit: newUnit,
                store: newStore
            )
            updateCartTotals(cart: cart)
            saveContext()
            return true

        case .completed:
            print("⚠️ Cannot edit items in completed cart")
            return false
        }
    }

    private func updateAllPlanningCartsWithItem(itemId: String, price: Double, unit: String, store: String) {
        guard let vault = vault else { return }

        for cart in vault.carts where cart.status == .planning {
            for cartItem in cart.cartItems where cartItem.itemId == itemId {
                cartItem.plannedPrice = price
                cartItem.plannedUnit = unit
                cartItem.plannedStore = store
            }
        }
        saveContext()
    }

    func deleteItem(itemId: String) {
        deleteItem(itemId: itemId, bypassPlanSuppression: false)
    }

    /// Removes an item from the vault by ID (moves it to Trash).
    ///
    /// Behavior:
    /// - Moves item out of its Category into `vault.deletedItems`.
    /// - Removes item from all ACTIVE carts (Planning/Shopping).
    /// - Keeps item data available for historical (Completed) carts.
    private func deleteItem(itemId: String, bypassPlanSuppression: Bool) {
        guard let vault = vault else { return }
        guard let item = findVaultItemById(itemId) else { return }

        guard bypassPlanSuppression || UserDefaults.standard.isPro || !item.isPlanSuppressed else {
            return
        }
        
        if item.isDeleted {
            return
        }
        
        print("🗑️ Soft deleting item: \(item.name)")
        
        if let category = getCategory(for: itemId),
           let index = category.items.firstIndex(where: { $0.id == itemId }) {
            category.items.remove(at: index)
            item.deletedFromCategoryName = category.name
        }
        
        item.category = nil
        item.isDeleted = true
        item.deletedAt = Date()
        
        if !vault.deletedItems.contains(where: { $0.id == itemId }) {
            vault.deletedItems.append(item)
        }
        
        for cart in vault.carts where cart.isActive {
            if let index = cart.cartItems.firstIndex(where: { $0.itemId == itemId }) {
                let cartItem = cart.cartItems[index]
                
                let snapshot = DeletedCartItemSnapshot(
                    cartId: cart.id,
                    quantity: cartItem.quantity,
                    plannedStore: cartItem.plannedStore,
                    plannedPrice: cartItem.plannedPrice,
                    plannedUnit: cartItem.plannedUnit,
                    actualStore: cartItem.actualStore,
                    actualPrice: cartItem.actualPrice,
                    actualQuantity: cartItem.actualQuantity,
                    actualUnit: cartItem.actualUnit,
                    wasEditedDuringShopping: cartItem.wasEditedDuringShopping,
                    wasFulfilled: cartItem.isFulfilled
                )
                snapshot.item = item
                modelContext.insert(snapshot)
                item.deletedCartItemSnapshots.append(snapshot)
                
                cart.cartItems.remove(at: index)
                updateCartTotals(cart: cart)
            }
        }
        
        itemCache.removeValue(forKey: itemId)
        invalidateCategoryCache()
        saveContext()
        
        NotificationCenter.default.post(
            name: NSNotification.Name("DataUpdated"),
            object: nil
        )
    }
    
    /// Removes an item from the vault (soft delete).
    func deleteItem(_ item: Item) {
        deleteItem(itemId: item.id)
    }
    
    func restoreDeletedItem(itemId: String, restoreToActiveCarts: Bool = false) {
        guard let vault = vault else { return }
        guard let item = vault.deletedItems.first(where: { $0.id == itemId }) else { return }
        
        let categoryName = item.deletedFromCategoryName

        if let categoryName, UserDefaults.standard.isPro == false, shouldSuppressCategory(named: categoryName, isPro: false) {
            return
        }
        
        let targetCategory: Category = {
            if let categoryName, let existing = vault.categories.first(where: { $0.name == categoryName }) {
                return existing
            }
            if let categoryName {
                let newCategory = Category(name: categoryName)
                newCategory.sortOrder = vault.categories.count
                modelContext.insert(newCategory)
                vault.categories.append(newCategory)
                return newCategory
            }
            let fallbackName = GroceryCategory.allCases.first?.title ?? "Other"
            if let existing = vault.categories.first(where: { $0.name == fallbackName }) {
                return existing
            }
            let newCategory = Category(name: fallbackName)
            newCategory.sortOrder = vault.categories.count
            modelContext.insert(newCategory)
            vault.categories.append(newCategory)
            return newCategory
        }()
        
        if !targetCategory.items.contains(where: { $0.id == itemId }) {
            targetCategory.items.append(item)
        }
        item.category = targetCategory
        item.isDeleted = false
        item.deletedAt = nil
        item.deletedFromCategoryName = nil
        applyPlanSuppression(
            to: item,
            isSuppressed: targetCategory.isPlanSuppressed,
            reason: targetCategory.isPlanSuppressed ? Self.planSuppressionReasonCustomCategory : nil
        )
        
        if let index = vault.deletedItems.firstIndex(where: { $0.id == itemId }) {
            vault.deletedItems.remove(at: index)
        }
        
        if restoreToActiveCarts {
            for snapshot in item.deletedCartItemSnapshots {
                guard let cart = vault.carts.first(where: { $0.id == snapshot.cartId && $0.isActive }) else { continue }
                guard !cart.cartItems.contains(where: { $0.itemId == itemId }) else { continue }
                
                let cartItem = CartItem(
                    itemId: itemId,
                    quantity: snapshot.quantity,
                    plannedStore: snapshot.plannedStore,
                    isFulfilled: snapshot.wasFulfilled,
                    plannedPrice: snapshot.plannedPrice,
                    plannedUnit: snapshot.plannedUnit,
                    actualStore: snapshot.actualStore,
                    actualPrice: snapshot.actualPrice,
                    actualQuantity: snapshot.actualQuantity,
                    actualUnit: snapshot.actualUnit,
                    isShoppingOnlyItem: false,
                    shoppingOnlyName: nil,
                    shoppingOnlyStore: nil,
                    shoppingOnlyPrice: nil,
                    shoppingOnlyUnit: nil,
                    shoppingOnlyCategory: nil,
                    vaultItemNameSnapshot: item.name,
                    vaultItemCategorySnapshot: targetCategory.name,
                    originalPlanningQuantity: nil,
                    addedDuringShopping: cart.isShopping
                )
                cartItem.wasEditedDuringShopping = snapshot.wasEditedDuringShopping
                cart.cartItems.append(cartItem)
                updateCartTotals(cart: cart)
            }
        }
        
        let snapshotsToDelete = item.deletedCartItemSnapshots
        item.deletedCartItemSnapshots.removeAll()
        for snapshot in snapshotsToDelete {
            modelContext.delete(snapshot)
        }
        
        itemCache.removeValue(forKey: itemId)
        invalidateCategoryCache()
        saveContext()
        
        NotificationCenter.default.post(
            name: NSNotification.Name("DataUpdated"),
            object: nil
        )
    }
    
    func permanentlyDeleteItemFromTrash(itemId: String) {
        guard let vault = vault else { return }
        guard let index = vault.deletedItems.firstIndex(where: { $0.id == itemId }) else { return }
        let item = vault.deletedItems.remove(at: index)
        modelContext.delete(item)
        itemCache.removeValue(forKey: itemId)
        invalidateCategoryCache()
        saveContext()
        
        NotificationCenter.default.post(
            name: NSNotification.Name("DataUpdated"),
            object: nil
        )
    }
    
    private func findVaultItemById(_ itemId: String) -> Item? {
        guard let vault = vault else { return nil }
        
        for category in vault.categories {
            if let item = category.items.first(where: { $0.id == itemId }) {
                return item
            }
        }
        
        if let item = vault.deletedItems.first(where: { $0.id == itemId }) {
            return item
        }
        
        return nil
    }

    /// Returns every vault item across all categories (not including shopping-only cart items).
    func getAllItems() -> [Item] {
        guard let vault = vault else { return [] }
        return vault.categories.flatMap { $0.items }.filter { !$0.isDeleted }
    }

    /// Finds an item by ID.
    ///
    /// Behavior:
    /// - First checks `itemCache`.
    /// - If the ID belongs to a shopping-only `CartItem`, returns a temporary `Item` wrapper.
    /// - Otherwise scans vault categories and caches the result.
    func findItemById(_ itemId: String) -> Item? {
        guard let vault = vault else { return nil }

        if let cachedItem = itemCache[itemId] {
            return cachedItem
        }

        for cart in vault.carts {
            if let cartItem = cart.cartItems.first(where: { $0.itemId == itemId && $0.isShoppingOnlyItem }) {
                return Item(
                    id: itemId,
                    name: cartItem.shoppingOnlyName ?? "Unknown",
                    priceOptions: cartItem.shoppingOnlyPrice.map { price in
                        [PriceOption(
                            store: cartItem.shoppingOnlyStore ?? "Unknown Store",
                            pricePerUnit: PricePerUnit(
                                priceValue: price,
                                unit: cartItem.shoppingOnlyUnit ?? ""
                            )
                        )]
                    } ?? [],
                    isTemporaryShoppingItem: true,
                    shoppingPrice: cartItem.shoppingOnlyPrice,
                    shoppingUnit: cartItem.shoppingOnlyUnit
                )
            }
        }

        for category in vault.categories {
            if let item = category.items.first(where: { $0.id == itemId }) {
                itemCache[itemId] = item
                return item
            }
        }
        
        if let deletedItem = vault.deletedItems.first(where: { $0.id == itemId }) {
            return deletedItem
        }
        return nil
    }

    func findItemsByName(_ name: String) -> [Item] {
        guard let vault = vault else { return [] }

        let searchTerm = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var foundItems: [Item] = []

        for category in vault.categories {
            for item in category.items {
                // Skip deleted items
                if item.isDeleted { continue }
                
                let itemName = item.name.lowercased()
                if itemName.contains(searchTerm) {
                    foundItems.append(item)
                }
            }
        }

        return foundItems
    }
}

extension VaultService {
    private static let freeStoreLimit = 1

    private func normalizedStoreKey(_ storeName: String) -> String {
        storeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func orderedStoreNamesForEntitlementEvaluation() -> [String] {
        getAllStores()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func orderedUniqueStoreEntriesForEntitlementEvaluation() -> [(name: String, key: String)] {
        var seenKeys = Set<String>()
        var orderedEntries: [(name: String, key: String)] = []

        for name in orderedStoreNamesForEntitlementEvaluation() {
            let key = normalizedStoreKey(name)
            guard !key.isEmpty else { continue }
            guard !seenKeys.contains(key) else { continue }

            orderedEntries.append((name: name, key: key))
            seenKeys.insert(key)
        }

        return orderedEntries
    }

    private func orderedUniqueStoreKeysForEntitlementEvaluation() -> [String] {
        orderedUniqueStoreEntriesForEntitlementEvaluation().map { $0.key }
    }

    private func persistedFreeEditableStoreKeys() -> [String] {
        var seen = Set<String>()
        return UserDefaults.standard.freeEditableStoreKeys
            .map { normalizedStoreKey($0) }
            .filter { key in
                guard !key.isEmpty else { return false }
                if seen.contains(key) { return false }
                seen.insert(key)
                return true
            }
    }

    private func validPersistedFreeEditableStoreKeys(isPro: Bool = UserDefaults.standard.isPro) -> [String] {
        let orderedKeys = orderedUniqueStoreKeysForEntitlementEvaluation()
        guard !isPro else { return orderedKeys }

        let validKeys = Set(orderedKeys)
        return persistedFreeEditableStoreKeys().filter { validKeys.contains($0) }
    }

    private func freeEditableStoreKeysForCurrentData(isPro: Bool = UserDefaults.standard.isPro) -> [String] {
        let orderedKeys = orderedUniqueStoreKeysForEntitlementEvaluation()
        guard !isPro else { return orderedKeys }

        if orderedKeys.count <= Self.freeStoreLimit {
            return orderedKeys
        }

        let validPersistedKeys = validPersistedFreeEditableStoreKeys(isPro: isPro)
        if validPersistedKeys.count >= Self.freeStoreLimit {
            return Array(validPersistedKeys.prefix(Self.freeStoreLimit))
        }

        // No implicit defaults: require explicit user selection when over the Free limit.
        return validPersistedKeys
    }

    private func replacePersistedFreeEditableStoreKey(oldKey: String, newKey: String) {
        var keys = persistedFreeEditableStoreKeys()
        guard !keys.isEmpty else { return }

        var didChange = false
        for index in keys.indices where keys[index] == oldKey {
            keys[index] = newKey
            didChange = true
        }

        guard didChange else { return }

        var deduped: [String] = []
        var seen = Set<String>()
        for key in keys where !key.isEmpty && !seen.contains(key) {
            deduped.append(key)
            seen.insert(key)
        }
        UserDefaults.standard.freeEditableStoreKeys = deduped
    }

    private func removePersistedFreeEditableStoreKey(_ key: String) {
        let keys = persistedFreeEditableStoreKeys().filter { $0 != key }
        UserDefaults.standard.freeEditableStoreKeys = keys
    }

    private func uniqueStoreKeys() -> Set<String> {
        Set(orderedUniqueStoreKeysForEntitlementEvaluation())
    }

    private func unlockedStoreKeys(isPro: Bool = UserDefaults.standard.isPro) -> Set<String> {
        Set(freeEditableStoreKeysForCurrentData(isPro: isPro))
    }

    var storeLimitForCurrentPlan: Int? {
        UserDefaults.standard.isPro ? nil : Self.freeStoreLimit
    }

    func storesForFreeSelection() -> [String] {
        orderedUniqueStoreEntriesForEntitlementEvaluation().map { $0.name }
    }

    func isFreeStoreSelectionRequired(isPro: Bool = UserDefaults.standard.isPro) -> Bool {
        guard !isPro else { return false }

        let orderedUniqueKeys = orderedUniqueStoreKeysForEntitlementEvaluation()
        guard orderedUniqueKeys.count > Self.freeStoreLimit else { return false }

        return validPersistedFreeEditableStoreKeys(isPro: isPro).count < Self.freeStoreLimit
    }

    func preselectedStoresForFreeSelection(isPro: Bool = UserDefaults.standard.isPro) -> [String] {
        let entries = orderedUniqueStoreEntriesForEntitlementEvaluation()
        guard !entries.isEmpty else { return [] }

        let requiredCount = min(Self.freeStoreLimit, entries.count)
        let selectedKeys = Array(validPersistedFreeEditableStoreKeys(isPro: isPro).prefix(requiredCount))

        let displayNameByKey = Dictionary(uniqueKeysWithValues: entries.map { ($0.key, $0.name) })
        return selectedKeys.compactMap { displayNameByKey[$0] }
    }

    @discardableResult
    func applyFreeStoreSelection(_ selectedStoreNames: [String], isPro: Bool = UserDefaults.standard.isPro) -> Bool {
        guard !isPro else { return true }

        let entries = orderedUniqueStoreEntriesForEntitlementEvaluation()
        let requiredCount = min(Self.freeStoreLimit, entries.count)
        if requiredCount == 0 {
            UserDefaults.standard.freeEditableStoreKeys = []
            reconcileStoreEntitlementState(isPro: false)
            return true
        }

        let availableKeys = Set(entries.map { $0.key })
        var selectedKeys: [String] = []

        for storeName in selectedStoreNames {
            let key = normalizedStoreKey(storeName)
            guard availableKeys.contains(key) else { continue }
            guard !selectedKeys.contains(key) else { continue }
            selectedKeys.append(key)
        }

        guard selectedKeys.count == requiredCount else { return false }

        UserDefaults.standard.freeEditableStoreKeys = selectedKeys
        reconcileStoreEntitlementState(isPro: false)
        return true
    }

    func unlockedStoreNamesForCurrentPlan(isPro: Bool = UserDefaults.standard.isPro) -> [String] {
        let orderedStores = orderedStoreNamesForEntitlementEvaluation()
        guard !isPro else { return orderedStores }

        let unlockedKeys = unlockedStoreKeys(isPro: isPro)
        return orderedStores.filter { unlockedKeys.contains(normalizedStoreKey($0)) }
    }

    func isStoreLimitReached(isPro: Bool = UserDefaults.standard.isPro) -> Bool {
        guard !isPro else { return false }
        return uniqueStoreKeys().count >= Self.freeStoreLimit
    }

    func isStoreLockedByPlan(named storeName: String, isPro: Bool = UserDefaults.standard.isPro) -> Bool {
        let normalized = normalizedStoreKey(storeName)
        guard !normalized.isEmpty else { return false }
        guard !isPro else { return false }
        return !unlockedStoreKeys(isPro: isPro).contains(normalized)
    }

    /// Returns whether a store can be used under the current plan.
    ///
    /// Pro:
    /// - Any store is allowed.
    ///
    /// Free:
    /// - Only unlocked stores (selected in Free Store Selection) are editable.
    /// - A brand-new store is allowed only while under the Free store limit.
    func canUseStoreName(_ storeName: String, isPro: Bool = UserDefaults.standard.isPro) -> Bool {
        let normalized = normalizedStoreKey(storeName)
        guard !normalized.isEmpty else { return false }

        guard !isPro else { return true }

        let existingKeys = uniqueStoreKeys()
        if existingKeys.contains(normalized) {
            return unlockedStoreKeys(isPro: isPro).contains(normalized)
        }

        return existingKeys.count < Self.freeStoreLimit
    }

    func storeLimitErrorMessage() -> String {
        let noun = Self.freeStoreLimit == 1 ? "store" : "stores"
        return "Free supports up to \(Self.freeStoreLimit) \(noun). Upgrade to Pro to add more."
    }

    /// Adds a store to the vault store list (deduped case-insensitively).
    func addStore(_ storeName: String) {
        guard let vault = vault else { return }

        let trimmedStore = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStore.isEmpty else { return }

        guard canUseStoreName(trimmedStore) else {
            print("🔒 Store limit reached on Free (\(Self.freeStoreLimit))")
            return
        }

        if !vault.stores.contains(where: { $0.name.lowercased() == trimmedStore.lowercased() }) {
            let newStore = Store(name: trimmedStore)
            vault.stores.insert(newStore, at: 0)
            saveContext()
            print("➕ Store added to vault: \(trimmedStore)")
        } else {
            print("⚠️ Store already exists: \(trimmedStore)")
        }
    }

    /// Returns store names ordered by recency, then any legacy item-only stores alphabetically.
    func getAllStores() -> [String] {
        guard let vault = vault else { return [] }

        let sortedVaultStores = vault.stores.sorted { $0.createdAt > $1.createdAt }
        let vaultStoreNames = sortedVaultStores.map { $0.name }

        let itemStores = vault.categories.flatMap { category in
            category.items.flatMap { item in
                item.priceOptions.map { $0.store }
            }
        }

        var orderedStores: [String] = []
        var seenStores = Set<String>()

        for storeName in vaultStoreNames {
            let lowercased = storeName.lowercased()
            if !seenStores.contains(lowercased) {
                orderedStores.append(storeName)
                seenStores.insert(lowercased)
            }
        }

        let uniqueItemStores = Array(Set(itemStores))
            .filter { !seenStores.contains($0.lowercased()) }
            .sorted()

        orderedStores.append(contentsOf: uniqueItemStores)

        return orderedStores
    }

    /// Returns the most recently created store entry, if any.
    func getMostRecentStore() -> String? {
        guard let vault = vault else { return nil }

        let sortedStores = vault.stores.sorted { $0.createdAt > $1.createdAt }
        return sortedStores.first?.name
    }

    /// Convenience wrapper to ensure a store is present in the store list.
    func ensureStoreExists(_ storeName: String) {
        addStore(storeName)
    }

    /// Renames a store and updates every vault/cart reference that points to it.
    ///
    /// Implications:
    /// - This is a bulk update across the vault; call sites should expect UI refresh.
    func renameStore(oldName: String, newName: String) {
        guard let vault = vault else { return }
        let trimmedOldName = oldName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedOldName.isEmpty, !trimmedNewName.isEmpty else { return }

        let normalizedOldName = normalizedStoreKey(trimmedOldName)
        let normalizedNewName = normalizedStoreKey(trimmedNewName)
        guard !normalizedOldName.isEmpty, !normalizedNewName.isEmpty else { return }

        if !UserDefaults.standard.isPro {
            guard !isStoreLockedByPlan(named: trimmedOldName, isPro: false) else { return }
        }

        for store in vault.stores where normalizedStoreKey(store.name) == normalizedOldName {
            store.name = trimmedNewName
        }

        for category in vault.categories {
            for item in category.items {
                for priceOption in item.priceOptions {
                    if normalizedStoreKey(priceOption.store) == normalizedOldName {
                        priceOption.store = trimmedNewName
                    }
                }
            }
        }

        for cart in vault.carts {
            var cartNeedsTotalsRefresh = false

            for cartItem in cart.cartItems {
                if normalizedStoreKey(cartItem.plannedStore) == normalizedOldName {
                    cartItem.plannedStore = trimmedNewName
                    cartNeedsTotalsRefresh = true
                }

                if let actualStore = cartItem.actualStore,
                   normalizedStoreKey(actualStore) == normalizedOldName {
                    cartItem.actualStore = trimmedNewName
                    cartNeedsTotalsRefresh = true
                }

                if let shoppingOnlyStore = cartItem.shoppingOnlyStore,
                   normalizedStoreKey(shoppingOnlyStore) == normalizedOldName {
                    cartItem.shoppingOnlyStore = trimmedNewName
                    cartNeedsTotalsRefresh = true
                }
            }

            if cartNeedsTotalsRefresh && cart.isActive {
                updateCartTotals(cart: cart)
            }
        }

        replacePersistedFreeEditableStoreKey(
            oldKey: normalizedOldName,
            newKey: normalizedNewName
        )

        itemCache.removeAll()
        invalidateCategoryCache()
        saveContext()

        NotificationCenter.default.post(
            name: NSNotification.Name("DataUpdated"),
            object: nil
        )

        print("✏️ Store renamed from '\(oldName)' to '\(trimmedNewName)'")
    }

    /// Deletes a store and cleans up all active data tied to it.
    ///
    /// Behavior:
    /// - Removes the store entry from vault stores (if present).
    /// - Removes matching store price options from vault items.
    /// - Soft-deletes items that no longer have any price options left.
    /// - Removes matching store rows from active carts.
    func deleteStore(_ storeName: String) {
        guard let vault = vault else { return }
        let normalizedKey = normalizedStoreKey(storeName)
        guard !normalizedKey.isEmpty else { return }

        // Remove explicit store entries (covers case-insensitive duplicates too).
        vault.stores.removeAll { normalizedStoreKey($0.name) == normalizedKey }

        var orphanedItemIDs = Set<String>()

        // Remove store price options from active vault items.
        for category in vault.categories {
            for item in category.items {
                let matchingOptions = item.priceOptions.filter {
                    normalizedStoreKey($0.store) == normalizedKey
                }
                guard !matchingOptions.isEmpty else { continue }

                let hasAlternateStore = item.priceOptions.contains {
                    normalizedStoreKey($0.store) != normalizedKey
                }

                if hasAlternateStore {
                    item.priceOptions.removeAll { normalizedStoreKey($0.store) == normalizedKey }
                    for option in matchingOptions {
                        modelContext.delete(option)
                    }
                } else {
                    // No alternate store remains; remove the entire item from active vault/cart surfaces.
                    orphanedItemIDs.insert(item.id)
                }
            }
        }

        // Remove matching rows from active carts so Manage Cart / Cart Detail stay in sync.
        for cart in vault.carts where cart.isActive {
            let originalCount = cart.cartItems.count
            cart.cartItems.removeAll { cartItem in
                if cartItem.isShoppingOnlyItem {
                    let shoppingStoreKey = normalizedStoreKey(cartItem.shoppingOnlyStore ?? cartItem.plannedStore)
                    return shoppingStoreKey == normalizedKey
                }

                let plannedStoreKey = normalizedStoreKey(cartItem.plannedStore)
                let actualStoreKey = normalizedStoreKey(cartItem.actualStore ?? "")
                return plannedStoreKey == normalizedKey || actualStoreKey == normalizedKey
            }

            if cart.cartItems.count != originalCount {
                updateCartTotals(cart: cart)
            }
        }

        // Soft-delete items that lost their only store.
        for itemId in orphanedItemIDs {
            deleteItem(itemId: itemId, bypassPlanSuppression: true)
        }

        // Keep free editable keys in sync with current data.
        if !uniqueStoreKeys().contains(normalizedKey) {
            removePersistedFreeEditableStoreKey(normalizedKey)
        }

        itemCache.removeAll()
        invalidateCategoryCache()
        saveContext()

        NotificationCenter.default.post(
            name: NSNotification.Name("DataUpdated"),
            object: nil
        )

        print("🗑️ Store deleted with data cleanup: \(storeName)")
    }
}

extension VaultService {
    /// Cache of itemId -> categoryName mappings, scoped by vault identity.
    private static var categoryLookupCache: [String: [String: String]] = [:]

    /// Returns the category name that currently contains `itemId`, using an internal cache.
    func getCategoryName(for itemId: String) -> String? {
        guard let vault = vault else { return nil }

        let vaultId = vault.id.hashValue.description

        if let cached = Self.categoryLookupCache[vaultId]?[itemId] {
            return cached
        }

        if let category = vault.categories.first(where: { $0.items.contains(where: { $0.id == itemId }) }) {
            if Self.categoryLookupCache[vaultId] == nil {
                Self.categoryLookupCache[vaultId] = [:]
            }
            Self.categoryLookupCache[vaultId]?[itemId] = category.name
            return category.name
        }

        if let deletedItem = vault.deletedItems.first(where: { $0.id == itemId }),
           let categoryName = deletedItem.deletedFromCategoryName {
            if Self.categoryLookupCache[vaultId] == nil {
                Self.categoryLookupCache[vaultId] = [:]
            }
            Self.categoryLookupCache[vaultId]?[itemId] = categoryName
            return categoryName
        }

        return nil
    }

    /// Clears the category lookup cache. Call when categories/items move between categories.
    func invalidateCategoryCache() {
        Self.categoryLookupCache.removeAll()
    }
}
