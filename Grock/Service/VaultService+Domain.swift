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

        if currentCategory?.name != targetCategory.name {
            currentCategory?.items.removeAll { $0.id == item.id }

            if !vault.categories.contains(where: { $0.name == targetCategory.name }) {
                vault.categories.append(targetCategory)
            }
            targetCategory.items.append(item)
        }

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

    /// Removes an item from the vault by ID (moves it to Trash).
    ///
    /// Behavior:
    /// - Moves item out of its Category into `vault.deletedItems`.
    /// - Removes item from all ACTIVE carts (Planning/Shopping).
    /// - Keeps item data available for historical (Completed) carts.
    func deleteItem(itemId: String) {
        guard let vault = vault else { return }
        guard let item = findVaultItemById(itemId) else { return }
        
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
    /// Adds a store to the vault store list (deduped case-insensitively).
    func addStore(_ storeName: String) {
        guard let vault = vault else { return }

        let trimmedStore = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStore.isEmpty else { return }

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

    /// Renames a store and updates every item’s price options that reference it.
    ///
    /// Implications:
    /// - This is a bulk update across the vault; call sites should expect UI refresh.
    func renameStore(oldName: String, newName: String) {
        guard let vault = vault else { return }
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNewName.isEmpty else { return }

        if let store = vault.stores.first(where: { $0.name == oldName }) {
            store.name = trimmedNewName
        }

        for category in vault.categories {
            for item in category.items {
                for priceOption in item.priceOptions {
                    if priceOption.store == oldName {
                        priceOption.store = trimmedNewName
                    }
                }
            }
        }

        saveContext()
        print("✏️ Store renamed from '\(oldName)' to '\(trimmedNewName)'")
    }

    /// Deletes a store entry from the vault store list.
    ///
    /// Note:
    /// - Items that still reference this store keep the raw store string; it becomes “legacy”.
    func deleteStore(_ storeName: String) {
        guard let vault = vault else { return }

        if let index = vault.stores.firstIndex(where: { $0.name == storeName }) {
            vault.stores.remove(at: index)
            saveContext()
            print("🗑️ Store deleted: \(storeName)")
        }
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
