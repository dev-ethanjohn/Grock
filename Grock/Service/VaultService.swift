import Foundation
import SwiftData
import Observation

@MainActor
@Observable
class VaultService {
    private let modelContext: ModelContext
    
    // Current state
    var currentUser: User?
    var vault: Vault? { currentUser?.userVault }
    
    var isLoading = false
    var error: Error?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserAndVault()
    }
    
    // MARK: - Computed Properties
    var sortedCategories: [Category] {
        vault?.categories.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }
    
    // MARK: - User & Vault Management
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
        currentUser?.name = newName
        saveContext()
    }
    
    // MARK: - Category Operations
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

    private func prePopulateCategories(in vault: Vault) {
        vault.categories.removeAll()
        
        for (index, groceryCategory) in GroceryCategory.allCases.enumerated() {
            let category = Category(name: groceryCategory.title)
            category.sortOrder = index
            vault.categories.append(category)
        }
        
        saveContext()
    }
    
    func addCategory(_ category: GroceryCategory) {
        guard let vault = vault else { return }
        
        let newCategory = Category(name: category.title)
        vault.categories.append(newCategory)
        saveContext()
    }
    
    func getCategory(_ groceryCategory: GroceryCategory) -> Category? {
        vault?.categories.first { $0.name == groceryCategory.title }
    }
    
    func getCategory(for itemId: String) -> Category? {
        guard let vault = vault else { return nil }
        
        for category in vault.categories {
            if category.items.contains(where: { $0.id == itemId }) {
                return category
            }
        }
        return nil
    }
    
    // MARK: - Item Operations
    func addItem(
        name: String,
        to category: GroceryCategory,
        store: String,
        price: Double,
        unit: String
    ) {
        guard let vault = vault else { return }
        
        let targetCategory: Category
        if let existingCategory = getCategory(category) {
            targetCategory = existingCategory
        } else {
            targetCategory = Category(name: category.title)
            vault.categories.append(targetCategory)
        }
        
        let pricePerUnit = PricePerUnit(priceValue: price, unit: unit)
        let priceOption = PriceOption(store: store, pricePerUnit: pricePerUnit)
        let newItem = Item(name: name)
        newItem.priceOptions = [priceOption]
        
        targetCategory.items.append(newItem)
        saveContext()
    }
    
    func updateItem(
        item: Item,
        newName: String,
        newCategory: GroceryCategory,
        newStore: String,
        newPrice: Double,
        newUnit: String
    ) {
        guard let vault = vault else { return }
        
        // 1. Update the item properties
        item.name = newName
        
        // 2. Update price options
        if let existingPriceOption = item.priceOptions.first(where: { $0.store == newStore }) {
            // Update existing store's price
            existingPriceOption.pricePerUnit = PricePerUnit(priceValue: newPrice, unit: newUnit)
        } else {
            // Create new price option
            let newPriceOption = PriceOption(
                store: newStore,
                pricePerUnit: PricePerUnit(priceValue: newPrice, unit: newUnit)
            )
            item.priceOptions.append(newPriceOption)
        }
        
        // 3. Update category if needed
        let currentCategory = vault.categories.first { $0.items.contains(where: { $0.id == item.id }) }
        let targetCategory = getCategory(newCategory) ?? Category(name: newCategory.title)
        
        if currentCategory?.name != targetCategory.name {
            // Remove from current category
            currentCategory?.items.removeAll { $0.id == item.id }
            
            // Add to target category (create if needed)
            if !vault.categories.contains(where: { $0.name == targetCategory.name }) {
                vault.categories.append(targetCategory)
            }
            targetCategory.items.append(item)
        }
        
        saveContext()
        
        // 4. Update all ACTIVE carts that contain this item
        updateActiveCartsContainingItem(itemId: item.id)
    }
    
    func updateItemFromCart(
        itemId: String,
        newName: String? = nil,
        newCategory: GroceryCategory? = nil,
        newStore: String? = nil,
        newPrice: Double? = nil,
        newUnit: String? = nil
    ) {
        guard let item = findItemById(itemId) else { return }
        
        // Get current category - use the first available GroceryCategory as default
        var currentGroceryCategory: GroceryCategory = GroceryCategory.allCases.first!
        if let currentCategory = getCategory(for: itemId),
           let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == currentCategory.name }) {
            currentGroceryCategory = groceryCategory
        }
        
        // Determine target store
        let targetStore = newStore ?? item.priceOptions.first?.store ?? "Unknown Store"
        
        // Determine target price and unit
        let targetPrice = newPrice ?? item.priceOptions.first(where: { $0.store == targetStore })?.pricePerUnit.priceValue ?? 0.0
        let targetUnit = newUnit ?? item.priceOptions.first(where: { $0.store == targetStore })?.pricePerUnit.unit ?? "piece"
        
        // Update the item
        updateItem(
            item: item,
            newName: newName ?? item.name,
            newCategory: newCategory ?? currentGroceryCategory,
            newStore: targetStore,
            newPrice: targetPrice,
            newUnit: targetUnit
        )
    }
    
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
    
    func getAllItems() -> [Item] {
        guard let vault = vault else { return [] }
        return vault.categories.flatMap { $0.items }
    }
    
    // MARK: - Store Operations
    func addStore(_ storeName: String) {
        guard let vault = vault else { return }
        
        let trimmedStore = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStore.isEmpty else { return }
        
        if !vault.stores.contains(where: { $0.name == trimmedStore }) {
            let newStore = Store(name: trimmedStore)
            vault.stores.append(newStore)
            vault.stores.sort { $0.name < $1.name }
            saveContext()
        }
    }
    
    func getAllStores() -> [String] {
        guard let vault = vault else { return [] }
        
        let vaultStores = vault.stores.map { $0.name }
        let itemStores = vault.categories.flatMap { category in
            category.items.flatMap { item in
                item.priceOptions.map { $0.store }
            }
        }
        
        let allStores = Array(Set(itemStores + vaultStores)).sorted()
        return allStores
    }
    
    // MARK: - Cart Management
    func createCart(name: String, budget: Double) -> Cart {
        let newCart = Cart(name: name, budget: budget, status: .planning)
        vault?.carts.append(newCart)
        saveContext()
        return newCart
    }
    
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
    
    func deleteCart(_ cart: Cart) {
        vault?.carts.removeAll { $0.id == cart.id }
        saveContext()
        print("🗑️ Deleted cart: \(cart.name)")
    }
    
    // MARK: - Cart Mode Management
    func startShopping(cart: Cart) {
        guard cart.status == .planning else { return }
        
        // Capture planned prices for all items (FREEZE planned data)
        for cartItem in cart.cartItems {
            cartItem.capturePlannedData(from: vault!)
        }
        
        cart.status = .shopping
        updateCartTotals(cart: cart)
        saveContext()
        print("🛒 Started shopping for: \(cart.name)")
    }
    
    func completeShopping(cart: Cart) {
        guard cart.status == .shopping else { return }
        
        // Capture actual data for all items
        for cartItem in cart.cartItems {
            cartItem.captureActualData()
        }
        
        cart.status = .completed
        updateCartTotals(cart: cart)
        saveContext()
        print("✅ Completed shopping for: \(cart.name)")
    }
    
    func reopenCart(cart: Cart) {
        guard cart.status == .completed else { return }
        
        cart.status = .shopping
        
        // Clear actual data since we're active again
        for cartItem in cart.cartItems {
            cartItem.actualPrice = nil
            cartItem.actualQuantity = nil
            cartItem.actualUnit = nil
            cartItem.actualStore = nil
            cartItem.isFulfilled = false
        }
        
        // Update totals with current prices
        updateCartTotals(cart: cart)
        
        saveContext()
        print("🔄 Reopened cart: \(cart.name) - Now using current prices")
    }
    
    // MARK: - Cart Item Operations
    func addItemToCart(item: Item, cart: Cart, quantity: Double, selectedStore: String? = nil) {
        let store = selectedStore ?? item.priceOptions.first?.store ?? "Unknown Store"
        
        let cartItem = CartItem(
            itemId: item.id,
            quantity: quantity,
            plannedStore: store
        )
        
        // If cart is already in shopping mode, capture planned data immediately
        if cart.status == .shopping {
            cartItem.capturePlannedData(from: vault!)
        }
        
        cart.cartItems.append(cartItem)
        updateCartTotals(cart: cart)
        saveContext()
        print("➕ Added item to cart: \(item.name) ×\(quantity)")
    }
    
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
        
        // Update the actual data
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
    
    func changeCartItemStore(cart: Cart, itemId: String, newStore: String) {
        guard let vault = vault else { return }
        
        if let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }) {
            switch cart.status {
            case .planning:
                cartItem.plannedStore = newStore
                // Update planned price/unit from vault for the new store
                if let newPrice = cartItem.getCurrentPrice(from: vault, store: newStore) {
                    cartItem.plannedPrice = newPrice
                }
                if let newUnit = cartItem.getCurrentUnit(from: vault, store: newStore) {
                    cartItem.plannedUnit = newUnit
                }
                
            case .shopping:
                cartItem.actualStore = newStore
                // Auto-update actual price/unit from vault for the new store
                if let newPrice = cartItem.getCurrentPrice(from: vault, store: newStore) {
                    cartItem.actualPrice = newPrice
                }
                if let newUnit = cartItem.getCurrentUnit(from: vault, store: newStore) {
                    cartItem.actualUnit = newUnit
                }
                
            case .completed:
                // Don't allow store changes in completed carts
                return
            }
            
            updateCartTotals(cart: cart)
            saveContext()
            print("🏪 Updated cart item store to: \(newStore)")
        }
    }
    
    func toggleItemFulfillment(cart: Cart, itemId: String) {
        guard let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }),
              cart.status == .shopping else { return }
        
        cartItem.isFulfilled.toggle()
        updateCartTotals(cart: cart)
        saveContext()
        print(cartItem.isFulfilled ? "✅ Fulfilled item" : "❌ Unfulfilled item")
    }
    
    // MARK: - Cart Calculations & Insights
    func updateCartTotals(cart: Cart) {
        guard let vault = vault else { return }
        
        var totalSpent: Double = 0.0
        
        for cartItem in cart.cartItems {
            totalSpent += cartItem.getTotalPrice(from: vault, cart: cart)
        }
        
        cart.totalSpent = totalSpent
        
        // Update fulfillment status based on mode
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
    
    // MARK: - Helper Methods
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            self.error = error
            print("❌ Failed to save: \(error)")
        }
    }
    
    func findItemById(_ itemId: String) -> Item? {
        guard let vault = vault else { return nil }
        
        for category in vault.categories {
            if let item = category.items.first(where: { $0.id == itemId }) {
                return item
            }
        }
        return nil
    }
    
    private func updateActiveCartsContainingItem(itemId: String) {
        guard let vault = vault else { return }
        
        for cart in vault.carts where cart.isShopping {
            if cart.cartItems.contains(where: { $0.itemId == itemId }) {
                updateCartTotals(cart: cart)
            }
        }
        saveContext()
        print("🔄 Updated active carts with new item prices")
    }
    
    
//    cart related
    func getTotalFulfilledAmount(for cart: Cart) -> Double {
        guard let vault = vault else { return 0.0 }
        return cart.cartItems
            .filter { $0.isFulfilled }
            .reduce(0.0) { result, cartItem in
                result + cartItem.getTotalPrice(from: vault, cart: cart)
            }
    }

    func getTotalCartValue(for cart: Cart) -> Double {
        guard let vault = vault else { return 0.0 }
        return cart.cartItems.reduce(0.0) { result, cartItem in
            result + cartItem.getTotalPrice(from: vault, cart: cart)
        }
    }

    func getCurrentFulfillmentPercentage(for cart: Cart) -> Double {
        let totalValue = getTotalCartValue(for: cart)
        guard totalValue > 0 else { return 0 }
        return (getTotalFulfilledAmount(for: cart) / totalValue) * 100
    }
    
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

}
