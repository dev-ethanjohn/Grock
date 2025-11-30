import Foundation
import SwiftData
import Observation

extension Category {
    var sortedItems: [Item] {
        items.sorted { $0.createdAt > $1.createdAt } // ✅ Newest first
    }
}

// MARK: - Vault Service
/// Main service class for managing user vault, categories, items, stores, and shopping carts
@MainActor
@Observable
class VaultService {
   
    // MARK: - Properties
    private let modelContext: ModelContext
   
    // Current state
    var currentUser: User?
    var vault: Vault? { currentUser?.userVault }
    var isLoading = false
    var error: Error?
   
    // MARK: - Computed Properties
    var sortedCategories: [Category] {
        vault?.categories.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }
   
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserAndVault()
    }
}

// MARK: - User & Vault Management
extension VaultService {
   
    /// Loads or creates user and vault with default categories
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
   
    /// Updates the current user's name
    func updateUserName(_ newName: String) {
        currentUser?.name = newName
        saveContext()
    }
}

// MARK: - Category Operations
extension VaultService {
   
    /// Ensures all predefined grocery categories exist in the vault
    private func ensureAllCategoriesExist(in vault: Vault) {
        let existingCategoriesDict = Dictionary(uniqueKeysWithValues: vault.categories.map { ($0.name, $0) })
        var orderedCategories: [Category] = []
        var needsSave = false
       
        for (index, groceryCategory) in GroceryCategory.allCases.enumerated() {
            let categoryName = groceryCategory.title
           
            if let existingCategory = existingCategoriesDict[categoryName] {
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
       
        vault.categories = orderedCategories.sorted { $0.sortOrder < $1.sortOrder }
       
        if needsSave {
            saveContext()
        }
    }
   
    /// Pre-populates vault with default categories
    private func prePopulateCategories(in vault: Vault) {
        vault.categories.removeAll()
       
        for (index, groceryCategory) in GroceryCategory.allCases.enumerated() {
            let category = Category(name: groceryCategory.title)
            category.sortOrder = index
            vault.categories.append(category)
        }
       
        saveContext()
    }
   
    /// Adds a new category to the vault
    func addCategory(_ category: GroceryCategory) {
        guard let vault = vault else { return }
       
        let newCategory = Category(name: category.title)
        vault.categories.append(newCategory)
        saveContext()
    }
   
    /// Retrieves a category by grocery category type
    func getCategory(_ groceryCategory: GroceryCategory) -> Category? {
        vault?.categories.first { $0.name == groceryCategory.title }
    }
   
    /// Finds the category containing a specific item
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

// MARK: - Duplicate Validation
extension VaultService {
   
    /// Checks if an item name already exists in the vault (case insensitive, trimmed)
    func isItemNameDuplicate(_ name: String, store: String, excluding itemId: String? = nil) -> Bool {
         guard let vault = vault else { return false }
        
         let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
         let trimmedStore = store.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
         for category in vault.categories {
             for item in category.items {
                 // If we're excluding an item (during edit), skip it
                 if let excludedId = itemId, item.id == excludedId {
                     continue
                 }
                
                 let existingName = item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                 // Check if this item has a price option for the same store
                 let hasSameStore = item.priceOptions.contains { priceOption in
                     priceOption.store.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedStore
                 }
                
                 if existingName == trimmedName && hasSameStore {
                     return true
                 }
             }
         }
        
         return false
     }
   
    /// Validates if an item name is available (not empty and not duplicate)
    func validateItemName(_ name: String, store: String, excluding itemId: String? = nil) -> (isValid: Bool, errorMessage: String?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
       
        if trimmedName.isEmpty {
            return (false, "Item name cannot be empty")
        }
       
        if isItemNameDuplicate(trimmedName, store: store, excluding: itemId) {
            return (false, "An item with this name already exists at \(store)")
        }
       
        return (true, nil)
    }
}

// MARK: - Item Operations
extension VaultService {
   
    /// Adds a new item to the specified category
    func addItem(
        name: String,
        to category: GroceryCategory,
        store: String,
        price: Double,
        unit: String
    ) -> Bool {
        guard let vault = vault else { return false }
       
        let validation = validateItemName(name, store: store)
        guard validation.isValid else {
            print("❌ Cannot add item: \(validation.errorMessage ?? "Unknown error")")
            return false
        }
       
        let targetCategory: Category
        if let existingCategory = getCategory(category) {
            targetCategory = existingCategory
        } else {
            targetCategory = Category(name: category.title)
            vault.categories.append(targetCategory)
        }
       
        let pricePerUnit = PricePerUnit(priceValue: price, unit: unit)
        let priceOption = PriceOption(store: store, pricePerUnit: pricePerUnit)
        let newItem = Item(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        newItem.priceOptions = [priceOption]
        // createdAt is automatically set to Date() in init
       
        targetCategory.items.append(newItem) // ✅ Just append, sorting handles order
        saveContext()
        return true
    }

   
    /// Updates an existing item with new properties
    func updateItem(
         item: Item,
         newName: String,
         newCategory: GroceryCategory,
         newStore: String,
         newPrice: Double,
         newUnit: String
     ) -> Bool {
         guard let vault = vault else { return false }
        
         // Validate the new item name
         let validation = validateItemName(newName, store: newStore, excluding: item.id)
         guard validation.isValid else {
             print("❌ Cannot update item: \(validation.errorMessage ?? "Unknown error")")
             return false
         }
        
         // 1. Update item properties
         item.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
         // 2. UPDATE SPECIFIC PRICE OPTION (not replace all)
         if let existingPriceOption = item.priceOptions.first {
             // Update the existing price option with new store, price, and unit
             existingPriceOption.store = newStore
             existingPriceOption.pricePerUnit = PricePerUnit(priceValue: newPrice, unit: newUnit)
         } else {
             // If no price options exist, create a new one
             let newPriceOption = PriceOption(
                 store: newStore,
                 pricePerUnit: PricePerUnit(priceValue: newPrice, unit: newUnit)
             )
             item.priceOptions = [newPriceOption]
         }
        
         // 3. Update category if needed
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
   
    /// Updates item properties from cart context
    func updateItemFromCart(
        itemId: String,
        newName: String? = nil,
        newCategory: GroceryCategory? = nil,
        newStore: String? = nil,
        newPrice: Double? = nil,
        newUnit: String? = nil
    ) -> Bool { // Return Bool to indicate success
        guard let item = findItemById(itemId) else { return false }
       
        // Change 'let' to 'var' to make it mutable
        var currentGroceryCategory: GroceryCategory = GroceryCategory.allCases.first!
        if let currentCategory = getCategory(for: itemId),
           let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == currentCategory.name }) {
            currentGroceryCategory = groceryCategory
        }
       
        let targetStore = newStore ?? item.priceOptions.first?.store ?? "Unknown Store"
        let targetPrice = newPrice ?? item.priceOptions.first(where: { $0.store == targetStore })?.pricePerUnit.priceValue ?? 0.0
        let targetUnit = newUnit ?? item.priceOptions.first(where: { $0.store == targetStore })?.pricePerUnit.unit ?? "piece"
       
        return updateItem(
            item: item,
            newName: newName ?? item.name,
            newCategory: newCategory ?? currentGroceryCategory,
            newStore: targetStore,
            newPrice: targetPrice,
            newUnit: targetUnit
        )
    }
   
    /// Deletes an item from the vault
    func deleteItem(_ item: Item) {
        guard let vault = vault else { return }
       
        for category in vault.categories {
            if let index = category.items.firstIndex(where: { $0.id == item.id }) {
                category.items.remove(at: index)
                saveContext()
                break
            }
        }
    }
   
    /// Retrieves all items from all categories
    func getAllItems() -> [Item] {
        guard let vault = vault else { return [] }
        return vault.categories.flatMap { $0.items }
    }
   
    /// Finds an item by its ID
    func findItemById(_ itemId: String) -> Item? {
        guard let vault = vault else { return nil }
       
        for category in vault.categories {
            if let item = category.items.first(where: { $0.id == itemId }) {
                return item
            }
        }
        return nil
    }
   
    /// Finds items by name (case insensitive, partial match)
    func findItemsByName(_ name: String) -> [Item] {
        guard let vault = vault else { return [] }
       
        let searchTerm = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var foundItems: [Item] = []
       
        for category in vault.categories {
            for item in category.items {
                let itemName = item.name.lowercased()
                if itemName.contains(searchTerm) {
                    foundItems.append(item)
                }
            }
        }
       
        return foundItems
    }
}

// MARK: - Store Operations
extension VaultService {
   
    /// Adds a new store to the vault
    func addStore(_ storeName: String) {
        guard let vault = vault else { return }
       
        let trimmedStore = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStore.isEmpty else { return }
       
        // Check if store already exists (case-insensitive)
        if !vault.stores.contains(where: { $0.name.lowercased() == trimmedStore.lowercased() }) {
            let newStore = Store(name: trimmedStore)
            // ✅ Insert at beginning for most recent first ordering
            vault.stores.insert(newStore, at: 0)
            saveContext()
            print("➕ Store added to vault: \(trimmedStore)")
        } else {
            print("⚠️ Store already exists: \(trimmedStore)")
        }
    }
   
    /// Retrieves all unique store names, sorted by most recent first
    func getAllStores() -> [String] {
        guard let vault = vault else { return [] }
       
        // Get stores from vault (persisted stores) - sorted by createdAt descending
        let sortedVaultStores = vault.stores.sorted { $0.createdAt > $1.createdAt }
        let vaultStoreNames = sortedVaultStores.map { $0.name }
       
        // Also include stores from current items (for backward compatibility)
        let itemStores = vault.categories.flatMap { category in
            category.items.flatMap { item in
                item.priceOptions.map { $0.store }
            }
        }
       
        // Create ordered set: vault stores first (by recency), then unique item stores alphabetically
        var orderedStores: [String] = []
        var seenStores = Set<String>()
       
        // Add vault stores in order (most recent first)
        for storeName in vaultStoreNames {
            let lowercased = storeName.lowercased()
            if !seenStores.contains(lowercased) {
                orderedStores.append(storeName)
                seenStores.insert(lowercased)
            }
        }
       
        // Add any stores from items that aren't in vault (alphabetically)
        let uniqueItemStores = Array(Set(itemStores))
            .filter { !seenStores.contains($0.lowercased()) }
            .sorted()
       
        orderedStores.append(contentsOf: uniqueItemStores)
       
        return orderedStores
    }
   
    /// Gets the most recently added store
    func getMostRecentStore() -> String? {
        guard let vault = vault else { return nil }
       
        // Sort by creation date and get the most recent
        let sortedStores = vault.stores.sorted { $0.createdAt > $1.createdAt }
        return sortedStores.first?.name
    }
   
    /// Ensures a store exists in the vault (used when editing items)
    func ensureStoreExists(_ storeName: String) {
        addStore(storeName)
    }
}

// MARK: - Cart Management
extension VaultService {
   
    /// Creates a new shopping cart
    func createCart(name: String, budget: Double) -> Cart {
        let newCart = Cart(name: name, budget: budget, status: .planning)
        vault?.carts.append(newCart)
        saveContext()
        return newCart
    }
   
    /// Creates a cart with pre-selected items
    func createCartWithActiveItems(name: String, budget: Double, activeItems: [String: Double]) -> Cart {
        let newCart = createCart(name: name, budget: budget)
       
        for (itemId, quantity) in activeItems {
            if let item = findItemById(itemId) {
                addItemToCart(item: item, cart: newCart, quantity: quantity)
            }
        }
       
        updateCartTotals(cart: newCart)
        saveContext()
       
        return newCart
    }
   
    /// Deletes a shopping cart
    func deleteCart(_ cart: Cart) {
        vault?.carts.removeAll { $0.id == cart.id }
        saveContext()
        print("🗑️ Deleted cart: \(cart.name)")
    }
}

// MARK: - Cart Mode Management
extension VaultService {
   
    /// Starts shopping session for a cart
    func startShopping(cart: Cart) {
        guard cart.status == .planning else { return }
       
        for cartItem in cart.cartItems {
            cartItem.capturePlannedData(from: vault!)
        }
       
        cart.status = .shopping
        updateCartTotals(cart: cart)
        saveContext()
        print("🛒 Started shopping for: \(cart.name)")
    }
   
    /// Completes shopping session for a cart
    func completeShopping(cart: Cart) {
        guard cart.status == .shopping else { return }
       
        for cartItem in cart.cartItems {
            cartItem.captureActualData()
        }
       
        cart.status = .completed
        updateCartTotals(cart: cart)
        saveContext()
        print("✅ Completed shopping for: \(cart.name)")
    }
   
    /// Reopens a completed cart for modifications
    func reopenCart(cart: Cart) {
        guard cart.status == .completed else { return }
       
        cart.status = .shopping
       
        for cartItem in cart.cartItems {
            cartItem.actualPrice = nil
            cartItem.actualQuantity = nil
            cartItem.actualUnit = nil
            cartItem.actualStore = nil
            cartItem.isFulfilled = false
        }
       
        updateCartTotals(cart: cart)
        saveContext()
        print("🔄 Reopened cart: \(cart.name) - Now using current prices")
    }
}

// MARK: - Cart Item Operations
extension VaultService {
   
    /// Adds an item to a shopping cart
    func addItemToCart(item: Item, cart: Cart, quantity: Double, selectedStore: String? = nil) {
        let store = selectedStore ?? item.priceOptions.first?.store ?? "Unknown Store"
       
        let cartItem = CartItem(
            itemId: item.id,
            quantity: quantity,
            plannedStore: store
        )
       
        if cart.status == .shopping {
            cartItem.capturePlannedData(from: vault!)
        }
       
        cart.cartItems.append(cartItem)
        updateCartTotals(cart: cart)
        saveContext()
        print("➕ Added item to cart: \(item.name) ×\(quantity)")
    }
   
    /// Removes an item from a shopping cart
    func removeItemFromCart(cart: Cart, itemId: String) {
        guard let index = cart.cartItems.firstIndex(where: { $0.itemId == itemId }) else {
            print("⚠️ Item not found in cart")
            return
        }
       
        let itemName = findItemById(itemId)?.name ?? "Unknown Item"
        cart.cartItems.remove(at: index)
        updateCartTotals(cart: cart)
        saveContext()
        print("🗑️ Removed \(itemName) from cart: \(cart.name)")
    }
   
    /// Updates actual shopping data for a cart item
    func updateCartItemActualData(
        cart: Cart,
        itemId: String,
        actualPrice: Double? = nil,
        actualQuantity: Double? = nil,
        actualUnit: String? = nil,
        actualStore: String? = nil
    ) {
        guard let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }),
              cart.status == .shopping else { return }
       
        if let actualPrice = actualPrice {
            cartItem.actualPrice = actualPrice
        }
        if let actualQuantity = actualQuantity {
            cartItem.actualQuantity = actualQuantity
        }
        if let actualUnit = actualUnit {
            cartItem.actualUnit = actualUnit
        }
        if let actualStore = actualStore {
            cartItem.actualStore = actualStore
        }
       
        updateCartTotals(cart: cart)
        saveContext()
        print("💰 Updated cart item actual data")
    }
   
    /// Updates price and quantity for a cart item
    func updateCartItemPrice(
        cart: Cart,
        itemId: String,
        newPrice: Double?,
        newQuantity: Double?,
        newUnit: String? = nil
    ) {
        updateCartItemActualData(
            cart: cart,
            itemId: itemId,
            actualPrice: newPrice,
            actualQuantity: newQuantity,
            actualUnit: newUnit
        )
    }
   
    /// Changes the store for a cart item
    func changeCartItemStore(cart: Cart, itemId: String, newStore: String) {
        guard let vault = vault else { return }
       
        if let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }) {
            switch cart.status {
            case .planning:
                cartItem.plannedStore = newStore
                if let newPrice = cartItem.getCurrentPrice(from: vault, store: newStore) {
                    cartItem.plannedPrice = newPrice
                }
                if let newUnit = cartItem.getCurrentUnit(from: vault, store: newStore) {
                    cartItem.plannedUnit = newUnit
                }
               
            case .shopping:
                cartItem.actualStore = newStore
                if let newPrice = cartItem.getCurrentPrice(from: vault, store: newStore) {
                    cartItem.actualPrice = newPrice
                }
                if let newUnit = cartItem.getCurrentUnit(from: vault, store: newStore) {
                    cartItem.actualUnit = newUnit
                }
               
            case .completed:
                return // Don't allow store changes in completed carts
            }
           
            updateCartTotals(cart: cart)
            saveContext()
            print("🏪 Updated cart item store to: \(newStore)")
        }
    }
   
    /// Toggles fulfillment status of a cart item
    func toggleItemFulfillment(cart: Cart, itemId: String) {
        guard let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }),
              cart.status == .shopping else { return }
       
        cartItem.isFulfilled.toggle()
        updateCartTotals(cart: cart)
        saveContext()
        print(cartItem.isFulfilled ? "✅ Fulfilled item" : "❌ Unfulfilled item")
    }
}

// MARK: - Cart Calculations & Insights
extension VaultService {
   
    /// Updates total calculations for a cart
    func updateCartTotals(cart: Cart) {
        guard let vault = vault else { return }
       
        var totalSpent: Double = 0.0
       
        for cartItem in cart.cartItems {
            totalSpent += cartItem.getTotalPrice(from: vault, cart: cart)
        }
       
        cart.totalSpent = totalSpent
       
        switch cart.status {
        case .planning:
            if cart.budget > 0 {
                cart.fulfillmentStatus = min(totalSpent / cart.budget, 1.0)
            }
        case .shopping:
            let fulfilledCount = cart.cartItems.filter { $0.isFulfilled }.count
            let totalCount = cart.cartItems.count
            cart.fulfillmentStatus = totalCount > 0 ? Double(fulfilledCount) / Double(totalCount) : 0.0
        case .completed:
            cart.fulfillmentStatus = 1.0
        }
       
        saveContext()
    }
   
    /// Generates insights for a shopping cart
    func getCartInsights(cart: Cart) -> CartInsights {
        guard let vault = vault else { return CartInsights() }
       
        var insights = CartInsights()
       
        for cartItem in cart.cartItems {
            let plannedPrice = cartItem.plannedPrice ?? 0.0
            let actualPrice = cartItem.actualPrice ?? plannedPrice
            let plannedQty = cartItem.quantity
            let actualQty = cartItem.actualQuantity ?? plannedQty
           
            let plannedTotal = plannedPrice * plannedQty
            let actualTotal = actualPrice * actualQty
            let difference = actualTotal - plannedTotal
           
            insights.plannedTotal += plannedTotal
            insights.actualTotal += actualTotal
            insights.totalDifference += difference
           
            if difference != 0 {
                insights.priceChanges.append(PriceChange(
                    itemName: cartItem.getItem(from: vault)?.name ?? "Unknown",
                    plannedPrice: plannedPrice,
                    actualPrice: actualPrice,
                    difference: difference
                ))
            }
        }
       
        return insights
    }
   
    /// Calculates total fulfilled amount in a cart
    func getTotalFulfilledAmount(for cart: Cart) -> Double {
        guard let vault = vault else { return 0.0 }
        return cart.cartItems
            .filter { $0.isFulfilled }
            .reduce(0.0) { result, cartItem in
                result + cartItem.getTotalPrice(from: vault, cart: cart)
            }
    }
   
    /// Calculates total value of all items in a cart
    func getTotalCartValue(for cart: Cart) -> Double {
        guard let vault = vault else { return 0.0 }
        return cart.cartItems.reduce(0.0) { result, cartItem in
            result + cartItem.getTotalPrice(from: vault, cart: cart)
        }
    }
   
    /// Calculates current fulfillment percentage for a cart
    func getCurrentFulfillmentPercentage(for cart: Cart) -> Double {
        let totalValue = getTotalCartValue(for: cart)
        guard totalValue > 0 else { return 0 }
        return (getTotalFulfilledAmount(for: cart) / totalValue) * 100
    }
}

// MARK: - Private Helper Methods
private extension VaultService {
   
    /// Saves changes to the model context
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            self.error = error
            print("❌ Failed to save: \(error)")
        }
    }
   
    /// Updates all active carts containing a specific item
    func updateActiveCartsContainingItem(itemId: String) {
        guard let vault = vault else { return }
       
        for cart in vault.carts where cart.isShopping {
            if cart.cartItems.contains(where: { $0.itemId == itemId }) {
                updateCartTotals(cart: cart)
            }
        }
        saveContext()
        print("🔄 Updated active carts with new item prices")
    }
}


// MARK: - Cart Duplicate Validation
extension VaultService {
    
    /// Checks if a cart name already exists in the vault (case insensitive, trimmed)
    func isCartNameDuplicate(_ name: String, excluding cartId: String? = nil) -> Bool {
        guard let vault = vault else { return false }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        for cart in vault.carts {
            // If we're excluding a cart (during edit), skip it
            if let excludedId = cartId, cart.id == excludedId {
                continue
            }
            
            let existingName = cart.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            if existingName == trimmedName {
                return true
            }
        }
        
        return false
    }
    
    /// Validates if a cart name is available (not empty and not duplicate)
    func validateCartName(_ name: String, excluding cartId: String? = nil) -> (isValid: Bool, errorMessage: String?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
       
        if trimmedName.isEmpty {
            return (false, "Cart name cannot be empty")
        }
       
        if isCartNameDuplicate(trimmedName, excluding: cartId) {
            return (false, "A cart with this name already exists")
        }
       
        return (true, nil)
    }
}
