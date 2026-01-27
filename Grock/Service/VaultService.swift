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
            Logger.error("Failed to load user and vault: \(error)", category: .vault)
        }
    }
   
    /// Updates the current user's name
    func updateUserName(_ newName: String) {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        currentUser?.name = trimmedName
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
//    func isItemNameDuplicate(_ name: String, store: String, excluding itemId: String? = nil) -> Bool {
//         guard let vault = vault else { return false }
//        
//         let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
//         let trimmedStore = store.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
//        
//         for category in vault.categories {
//             for item in category.items {
//                 // If we're excluding an item (during edit), skip it
//                 if let excludedId = itemId, item.id == excludedId {
//                     continue
//                 }
//                
//                 let existingName = item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
//                
//                 // Check if this item has a price option for the same store
//                 let hasSameStore = item.priceOptions.contains { priceOption in
//                     priceOption.store.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedStore
//                 }
//                
//                 if existingName == trimmedName && hasSameStore {
//                     return true
//                 }
//             }
//         }
//        
//         return false
//     }
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
                
                // Check if this item has a price option for the EXACT SAME STORE (case-insensitive)
                let hasSameStore = item.priceOptions.contains { priceOption in
                    priceOption.store.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedStore
                }
                
                // Only duplicate if BOTH name AND store match (case-insensitive)
                if existingName == trimmedName && hasSameStore {
                    return true
                }
            }
        }
        
        return false
    }
   
    /// Validates if an item name is available (not empty and not duplicate)
//    func validateItemName(_ name: String, store: String, excluding itemId: String? = nil) -> (isValid: Bool, errorMessage: String?) {
//        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
//       
//        if trimmedName.isEmpty {
//            return (false, "Item name cannot be empty")
//        }
//       
//        if isItemNameDuplicate(trimmedName, store: store, excluding: itemId) {
//            return (false, "An item with this name already exists at \(store)")
//        }
//       
//        return (true, nil)
//    }
    func validateItemName(_ name: String, store: String, excluding itemId: String? = nil) -> (isValid: Bool, errorMessage: String?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            return (false, "Item name cannot be empty")
        }
        
        if isItemNameDuplicate(trimmedName, store: store, excluding: itemId) {
            // Make error message clearer
            return (false, "An item with name '\(trimmedName)' already exists at \(store)")
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
            Logger.warning("Cannot add item: \(validation.errorMessage ?? "Unknown error")", category: .vault)
            return false
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
        // createdAt is automatically set to Date() in init
       
        // Explicitly insert into model context to ensure relationships are established
        modelContext.insert(newItem)
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
             Logger.warning("Cannot update item: \(validation.errorMessage ?? "Unknown error")", category: .vault)
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
   
    func updateItemFromCart(
        itemId: String,
        cart: Cart,  // REQUIRED: Must know which cart
        newName: String? = nil,
        newCategory: GroceryCategory? = nil,
        newStore: String? = nil,
        newPrice: Double? = nil,
        newUnit: String? = nil
    ) -> Bool {
        guard let item = findItemById(itemId) else { return false }
        
        switch cart.status {
        case .planning:
            // Planning mode: Update Vault
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
                // Update all planning carts with this item
                updateAllPlanningCartsWithItem(itemId: itemId, price: targetPrice, unit: targetUnit, store: targetStore)
            }
            return success
            
        case .shopping:
            // Shopping mode: Only update cart item's actual data
            guard let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }),
                  cartItem.isFulfilled else {
                Logger.warning("Cannot edit unfulfilled item while shopping", category: .cart)
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
            Logger.warning("Cannot edit items in completed cart", category: .cart)
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
    
//    func returnToPlanning(cart: Cart) {
//        guard cart.status == .shopping else { return }
//        
//        print("🔄 Returning cart '\(cart.name)' to planning mode")
//        
//        cleanupShoppingOnlyItems(cart: cart)
//        
//        // First, count shopping-only items for debugging
//        let shoppingOnlyCountBefore = cart.cartItems.filter { $0.isShoppingOnlyItem }.count
//        print("   Shopping-only items before reset: \(shoppingOnlyCountBefore)")
//        
//        // Create a new array with ONLY non-shopping-only items (vault items)
//        let vaultItemsOnly = cart.cartItems.filter { !$0.isShoppingOnlyItem }
//        
//        // Remove ALL items from cart
//        cart.cartItems.removeAll()
//        
//        // Add back ONLY the vault items
//        cart.cartItems.append(contentsOf: vaultItemsOnly)
//        
//        print("   Kept \(cart.cartItems.count) vault items, removed \(shoppingOnlyCountBefore) shopping-only items")
//        
//        // Now reset all vault items to planning state
//        for cartItem in cart.cartItems {
//            // IMPORTANT: Reset ALL shopping-specific flags
//            cartItem.isFulfilled = false
//            cartItem.isSkippedDuringShopping = false
//            cartItem.wasEditedDuringShopping = false
//            
//            // Clear all shopping data
//            cartItem.actualPrice = nil
//            cartItem.actualQuantity = nil
//            cartItem.actualUnit = nil
//            cartItem.actualStore = nil
//            
//            // Reset planned data from current Vault
//            if let vault = vault {
//                // Get current price and unit from vault
//                cartItem.plannedPrice = cartItem.getCurrentPrice(from: vault, store: cartItem.plannedStore)
//                cartItem.plannedUnit = cartItem.getCurrentUnit(from: vault, store: cartItem.plannedStore)
//            }
//        }
//        
//        // Update cart status
//        cart.status = .planning
//        cart.startedAt = nil // Clear shopping start time
//        cart.updatedAt = Date()
//        
//        updateCartTotals(cart: cart)
//        saveContext()
//        
//        print("✅ Cart '\(cart.name)' reset to planning mode - only vault items retained")
//    }
    func returnToPlanning(cart: Cart) {
        guard cart.status == .shopping else { return }
        
        Logger.info("Returning cart '\(cart.name)' to planning mode", category: .cart)
        
        // STEP 1: Remove all items that were added during shopping
        cart.cartItems.removeAll { cartItem in
            cartItem.addedDuringShopping || cartItem.isShoppingOnlyItem
        }
        
        // STEP 2: Reset all remaining vault items to planning state
        // Optimize: Single pass
        if let vault = vault {
            for cartItem in cart.cartItems {
                // Reset shopping flags
                cartItem.isFulfilled = false
                cartItem.isSkippedDuringShopping = false
                cartItem.wasEditedDuringShopping = false
                cartItem.addedDuringShopping = false
                
                // Clear shopping data
                cartItem.actualPrice = nil
                cartItem.actualQuantity = nil
                cartItem.actualUnit = nil
                cartItem.actualStore = nil
                
                // Restore original planning quantity
                if let originalQty = cartItem.originalPlanningQuantity {
                    cartItem.quantity = originalQty
                    cartItem.originalPlanningQuantity = nil
                }
                
                // Refresh planned data from vault
                cartItem.plannedPrice = cartItem.getCurrentPrice(from: vault, store: cartItem.plannedStore)
                cartItem.plannedUnit = cartItem.getCurrentUnit(from: vault, store: cartItem.plannedStore)
            }
        }
        
        // STEP 3: Update cart status
        cart.status = .planning
        cart.startedAt = nil
        cart.updatedAt = Date()
        
        // Optimize: Update totals immediately for UI
        updateCartTotals(cart: cart)
        
        // Defer save to background
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.saveContext()
            }
        }
        
        Logger.info("Cart '\(cart.name)' reset to planning mode", category: .cart)
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
   
    /// Finds an item by its ID (now handles shopping-only items too)
    func findItemById(_ itemId: String) -> Item? {
        guard let vault = vault else { return nil }
        
        // First check if it's a shopping-only CartItem in any cart
        for cart in vault.carts {
            if let cartItem = cart.cartItems.first(where: { $0.itemId == itemId && $0.isShoppingOnlyItem }) {
                // Create a temporary Item for shopping-only items
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
        
        // Otherwise, search in vault
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
            Logger.info("Store added to vault: \(trimmedStore)", category: .vault)
        } else {
            Logger.debug("Store already exists: \(trimmedStore)", category: .vault)
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
    
    /// Renames a store and updates all items using it
    func renameStore(oldName: String, newName: String) {
        guard let vault = vault else { return }
        let trimmedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNewName.isEmpty else { return }
        
        // 1. Update the Store entity
        if let store = vault.stores.first(where: { $0.name == oldName }) {
            store.name = trimmedNewName
        }
        
        // 2. Update all items that use this store
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
        Logger.info("Store renamed from '\(oldName)' to '\(trimmedNewName)'", category: .vault)
    }
    
    /// Deletes a store from the vault
    /// Note: This only removes the Store entity. Items using this store will keep the store name
    /// but it will be treated as a "legacy" or "item-only" store until those items are updated.
    func deleteStore(_ storeName: String) {
        guard let vault = vault else { return }
        
        if let index = vault.stores.firstIndex(where: { $0.name == storeName }) {
            vault.stores.remove(at: index)
            saveContext()
            Logger.info("Store deleted: \(storeName)", category: .vault)
        }
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
                addVaultItemToCart(item: item, cart: newCart, quantity: quantity)
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
        Logger.info("Deleted cart: \(cart.name)", category: .cart)
    }
}

// MARK: - Cart Mode Management
extension VaultService {
   
    /// Starts shopping session for a cart
    func startShopping(cart: Cart) {
        guard cart.status == .planning else { return }
        
        cleanupShoppingOnlyItems(cart: cart)
        
        // CRITICAL: Save original planning quantities
        // Optimize: Batch updates
        var itemsToUpdate: [CartItem] = []
        for cartItem in cart.cartItems {
            if !cartItem.isShoppingOnlyItem {
                cartItem.originalPlanningQuantity = cartItem.quantity
                itemsToUpdate.append(cartItem)
            }
            // Capture planned data in the same pass
            cartItem.capturePlannedData(from: vault!)
        }
        
        cart.status = .shopping
        cart.startedAt = Date()
        cart.updatedAt = Date()
        
        // Optimize: Update totals first (memory), then save
        updateCartTotals(cart: cart)
        
        // Defer heavy save to background thread to keep UI responsive
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.saveContext()
            }
        }
        Logger.info("Started shopping for: \(cart.name)", category: .cart)
    }
   
    /// Completes shopping session for a cart
    func completeShopping(cart: Cart) {
         guard cart.status == .shopping else { return }
         
         Logger.info("Completing shopping for cart: \(cart.name)", category: .cart)
         
         for cartItem in cart.cartItems {
             cartItem.captureActualData()
             updateVaultWithActualData(cartItem: cartItem)
         }
         
         cart.status = .completed
         cart.completedAt = Date() // ✅ SET WHEN COMPLETED
         cart.updatedAt = Date()
         updateCartTotals(cart: cart)
         saveContext()
         
         Logger.info("Shopping completed! Vault prices updated.", category: .cart)
     }
     
  
     
    private func updateVaultWithActualData(cartItem: CartItem) {
        // Skip shopping-only items (they shouldn't be saved to vault)
        if cartItem.isShoppingOnlyItem {
            Logger.debug("Skipping vault update for shopping-only item: \(cartItem.shoppingOnlyName ?? "Unknown")", category: .vault)
            return
        }
        
        guard let item = findItemById(cartItem.itemId) else {
            Logger.error("Item not found for cartItem: \(cartItem.itemId)", category: .vault)
            return
        }
        
        // Only update if we have actual data
        guard let actualPrice = cartItem.actualPrice,
              let actualUnit = cartItem.actualUnit,
              let actualStore = cartItem.actualStore else {
            Logger.debug("No actual data to update vault for item: \(item.name)", category: .vault)
            return
        }
        
        Logger.debug("Updating vault for item: \(item.name) | Store: \(actualStore) | Price: \(actualPrice)", category: .vault)
        
        // Update or add price option in the item
        if let existingPriceOption = item.priceOptions.first(where: { $0.store == actualStore }) {
            // Update existing price option
            existingPriceOption.pricePerUnit = PricePerUnit(
                priceValue: actualPrice,
                unit: actualUnit
            )
            Logger.debug("Updated existing price option", category: .vault)
        } else {
            // Add new price option
            let newPriceOption = PriceOption(
                store: actualStore,
                pricePerUnit: PricePerUnit(
                    priceValue: actualPrice,
                    unit: actualUnit
                )
            )
            item.priceOptions.append(newPriceOption)
            Logger.debug("Added new price option", category: .vault)
        }
        
        // Also ensure the store exists in vault stores
        ensureStoreExists(actualStore)
    }

   
    /// Reopens a completed cart for modifications
    func reopenCart(cart: Cart) {
         guard cart.status == .completed else { return }
        
         cart.status = .shopping
         cart.completedAt = nil // ✅ CLEAR WHEN REOPENED
         cart.updatedAt = Date()
        
         for cartItem in cart.cartItems {
             cartItem.actualPrice = nil
             cartItem.actualQuantity = nil
             cartItem.actualUnit = nil
             cartItem.actualStore = nil
             cartItem.isFulfilled = false
         }
        
         updateCartTotals(cart: cart)
         saveContext()
         Logger.info("Reopened cart: \(cart.name) - Now using current prices", category: .cart)
     }
    
    /// Updates the cart name
     func updateCartName(cart: Cart, newName: String) {
         cart.name = newName
         cart.updatedAt = Date()  // ✅ Update timestamp when edited
         saveContext()
     }
     
     /// Updates the cart budget
     func updateCartBudget(cart: Cart, newBudget: Double) {
         cart.budget = newBudget
         cart.updatedAt = Date()  // ✅ Update timestamp when edited
         updateCartTotals(cart: cart)
         saveContext()
     }
}

// MARK: - Cart Item Operations
extension VaultService {
    
    // MARK: - Vault-Based Operations (Planning Mode)
    func addVaultItemToCart(item: Item, cart: Cart, quantity: Double, selectedStore: String? = nil) {
        let store = selectedStore ?? item.priceOptions.first?.store ?? "Unknown Store"
        let priceOption = item.priceOptions.first(where: { $0.store == store })
        
        // Check if item already exists in cart
        if let existingCartItem = cart.cartItems.first(where: {
            !$0.isShoppingOnlyItem && $0.itemId == item.id
        }) {
            // Update quantity and timestamp
            existingCartItem.quantity += quantity
            existingCartItem.addedAt = Date() // Update timestamp
            
            // DO NOT change addedDuringShopping flag - keep existing value
            Logger.debug("Updated existing vault item quantity: \(item.name)", category: .cart)
        } else {
            // Add new item
            let cartItem = CartItem(
                itemId: item.id,
                quantity: quantity,
                plannedStore: store,
                plannedPrice: priceOption?.pricePerUnit.priceValue,
                plannedUnit: priceOption?.pricePerUnit.unit,
                // During shopping mode, also set actual data
                actualStore: cart.isShopping ? store : nil,
                actualPrice: cart.isShopping ? priceOption?.pricePerUnit.priceValue : nil,
                actualQuantity: cart.isShopping ? quantity : nil,
                actualUnit: cart.isShopping ? priceOption?.pricePerUnit.unit : nil,
                // CRITICAL: This is a vault item, NOT shopping-only!
                isShoppingOnlyItem: false,
                shoppingOnlyName: nil,
                shoppingOnlyStore: nil,
                shoppingOnlyPrice: nil,
                shoppingOnlyUnit: nil,
                originalPlanningQuantity: nil,
                addedDuringShopping: cart.isShopping // Set to true if added during shopping mode
            )
            
            cart.cartItems.append(cartItem)
        }
        
        updateCartTotals(cart: cart)
        saveContext()
        Logger.info("Added Vault item to cart: \(item.name) ×\(quantity)", category: .cart)
    }
    
    // MARK: - Shopping-Only Operations (No Vault Shopping Mode)
    func addShoppingItemToCart(
        name: String,
        store: String,
        price: Double,
        unit: String,
        cart: Cart,
        quantity: Double = 1,
        category: GroceryCategory? = nil
    ) {
        Logger.info("Adding shopping-only item: \(name)", category: .cart)
        
        // Create a shopping-only CartItem (not linked to vault)
        let cartItem = CartItem.createShoppingOnlyItem(
            name: name,
            store: store,
            price: price,
            unit: unit,
            quantity: quantity,
            category: category
        )
        
        cart.cartItems.append(cartItem)
        updateCartTotals(cart: cart)
        
        saveContext()
        
        NotificationCenter.default.post(
            name: NSNotification.Name("ShoppingDataUpdated"),
            object: nil,
            userInfo: ["cartItemId": cart.id]
        )
        
        Logger.info("Added Shopping-only item to cart: \(name) ×\(quantity)", category: .cart)
    }
   
    /// Removes an item from a shopping cart
    func removeItemFromCart(cart: Cart, itemId: String) {
        guard let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }) else {
            Logger.warning("Item not found in cart", category: .cart)
            return
        }
        
        let itemName = findItemById(itemId)?.name ?? "Unknown Item"
        
        if cart.status == .shopping {
            // SHOPPING MODE: Handle differently based on item type
            if cartItem.isShoppingOnlyItem {
                // SHOPPING-ONLY ITEMS: Remove completely during shopping
                if let index = cart.cartItems.firstIndex(where: { $0.itemId == itemId }) {
                    cart.cartItems.remove(at: index)
                    Logger.info("Removed shopping-only item \(itemName) during shopping", category: .cart)
                }
            } else {
                // VAULT ITEMS: Mark as skipped instead of removing
                cartItem.isSkippedDuringShopping = true
                cartItem.isFulfilled = false
                Logger.info("Skipped vault item \(itemName) during shopping", category: .cart)
            }
        } else {
            // PLANNING MODE: Actually remove the item (both types)
            if let index = cart.cartItems.firstIndex(where: { $0.itemId == itemId }) {
                cart.cartItems.remove(at: index)
                Logger.info("Removed \(itemName) from cart: \(cart.name)", category: .cart)
            }
        }
        
        updateCartTotals(cart: cart)
        saveContext()
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
        Logger.debug("Updated cart item actual data", category: .cart)
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
            Logger.debug("Updated cart item store to: \(newStore)", category: .cart)
        }
    }
   
    /// Toggles fulfillment status of a cart item
    func toggleItemFulfillment(cart: Cart, itemId: String) {
        guard let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }),
              cart.status == .shopping else { return }
       
        cartItem.isFulfilled.toggle()
        updateCartTotals(cart: cart)
        saveContext()
        Logger.debug(cartItem.isFulfilled ? "Fulfilled item" : "Unfulfilled item", category: .cart)
        
        NotificationCenter.default.post(
            name: NSNotification.Name("CartItemFulfillmentToggled"),
            object: nil,
            userInfo: [
                "cartId": cart.id,
                "itemId": itemId,
                "isFulfilled": cartItem.isFulfilled
            ]
        )
        
        NotificationCenter.default.post(
            name: NSNotification.Name("ShoppingDataUpdated"),
            object: nil,
            userInfo: [
                "cartItemId": cart.id
            ]
        )
    }
}

// MARK: - Cart Calculations & Insights
extension VaultService {
   
    func updateCartTotals(cart: Cart) {
        guard let vault = vault else { return }
        
        // Update cartItems if needed
        for cartItem in cart.cartItems {
            // If we need to capture planned data when starting shopping
            if cart.status == .shopping && !cartItem.isFulfilled && cartItem.plannedPrice == nil {
                cartItem.capturePlannedData(from: vault)
            }
        }
        
        // Update fulfillmentStatus based on cart status
        switch cart.status {
        case .planning:
            if cart.budget > 0 {
                // Use the computed totalSpent
                cart.fulfillmentStatus = min(cart.totalSpent / cart.budget, 1.0)
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
            // Use originalPlanningQuantity if available (for items edited during shopping), otherwise fallback to current quantity
            let plannedQty = cartItem.originalPlanningQuantity ?? cartItem.quantity
            let actualQty = cartItem.actualQuantity ?? cartItem.quantity
           
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
            Logger.error("Failed to save: \(error)", category: .vault)
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
        Logger.debug("Updated active carts with new item prices", category: .vault)
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

// MARK: - Cart Cleanup Operations
extension VaultService {
    
    /// Cleans up shopping-only items from a cart
    func cleanupShoppingOnlyItems(cart: Cart) {
        let shoppingOnlyItems = cart.cartItems.filter { $0.isShoppingOnlyItem }
        
        if !shoppingOnlyItems.isEmpty {
            Logger.debug("Cleaning up \(shoppingOnlyItems.count) shopping-only items", category: .cart)
            
            // Remove shopping-only items
            cart.cartItems.removeAll { $0.isShoppingOnlyItem }
            
            updateCartTotals(cart: cart)
            saveContext()
            
            Logger.debug("Removed shopping-only items", category: .cart)
        }
    }
    
    /// Optional: Clean up completed carts
    func cleanupCompletedCart(cart: Cart) {
        guard cart.status == .completed else { return }
        
        // You could add other cleanup logic here
        Logger.debug("Cleaning up completed cart: \(cart.name)", category: .cart)
    }
    
    func addVaultItemToCartDuringShopping(
        item: Item,
        store: String,
        price: Double,
        unit: String,
        cart: Cart,
        quantity: Double = 1
    ) {
        Logger.info("Adding vault item during shopping: \(item.name)", category: .cart)
        
        // Check if this vault item is already in cart
        if let existingCartItem = cart.cartItems.first(where: {
            !$0.isShoppingOnlyItem && $0.itemId == item.id
        }) {
            // Already in cart as vault item
            existingCartItem.quantity += quantity
            existingCartItem.isSkippedDuringShopping = false
            
            // FIX: Update addedAt timestamp to mark as "recently added"
            existingCartItem.addedAt = Date()
            
            // If it was added during shopping, keep the flag; if not, set it
            existingCartItem.addedDuringShopping = true
            Logger.debug("Updated existing vault item during shopping: \(item.name)", category: .cart)
        } else {
            // Not in cart - add as vault item added DURING shopping
            let cartItem = CartItem(
                itemId: item.id,
                quantity: quantity,
                plannedStore: store,
                plannedPrice: price,
                plannedUnit: unit,
                // During shopping mode, also set actual data
                actualStore: store,
                actualPrice: price,
                actualQuantity: quantity,
                actualUnit: unit,
                // CRITICAL: This is NOT a shopping-only item!
                isShoppingOnlyItem: false,
                shoppingOnlyName: nil,
                shoppingOnlyStore: nil,
                shoppingOnlyPrice: nil,
                shoppingOnlyUnit: nil,
                originalPlanningQuantity: nil,
                addedDuringShopping: true // MARK AS ADDED DURING SHOPPING
            )
            cart.cartItems.append(cartItem)
        }
        
        updateCartTotals(cart: cart)
        saveContext()
        Logger.info("Added Vault item during shopping: \(item.name) ×\(quantity)", category: .cart)
    }
}


extension VaultService {
    // Add this property to cache item-to-category mappings
    private static var categoryLookupCache: [String: [String: String]] = [:] // [vaultId: [itemId: categoryName]]
    
    func getCategoryName(for itemId: String) -> String? {
        guard let vault = vault else { return nil }
        
        // Create cache key - convert PersistentIdentifier to String
        let vaultId = vault.id.hashValue.description
        
        // Check cache first
        if let cached = Self.categoryLookupCache[vaultId]?[itemId] {
            return cached
        }
        
        // Find category
        if let category = vault.categories.first(where: { $0.items.contains(where: { $0.id == itemId }) }) {
            // Update cache
            if Self.categoryLookupCache[vaultId] == nil {
                Self.categoryLookupCache[vaultId] = [:]
            }
            Self.categoryLookupCache[vaultId]?[itemId] = category.name
            return category.name
        }
        
        return nil
    }
    
    func invalidateCategoryCache() {
        Self.categoryLookupCache.removeAll()
    }
}

