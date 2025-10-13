//
//  VaultService.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/8/25.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
class VaultService {
    private let modelContext: ModelContext
    
    // Current state - now using User
    var currentUser: User?
    var vault: Vault? { currentUser?.userVault } // This stays the same
    
    var isLoading = false
    var error: Error?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserAndVault()
    }
    
    var sortedCategories: [Category] {
        vault?.categories.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }
    
    // In VaultService.swift - update loadUserAndVault method
    func loadUserAndVault() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // First try to load existing user
            let userDescriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(userDescriptor)
            
            if let existingUser = users.first {
                self.currentUser = existingUser
                print("✅ Loaded existing user: \(existingUser.name)")
                // Ensure all categories exist in existing vault
                ensureAllCategoriesExist(in: existingUser.userVault)
            } else {
                // Create new user with vault
                let newUser = User(name: "Default User")
                modelContext.insert(newUser)
                
                // Pre-populate with all categories
                prePopulateCategories(in: newUser.userVault)
                
                try modelContext.save()
                self.currentUser = newUser
                print("✅ Created new user with vault: \(newUser.name)")
            }
        } catch {
            self.error = error
            print("❌ Failed to load user and vault: \(error)")
        }
    }

    private func ensureAllCategoriesExist(in vault: Vault) {
        // Create a dictionary of existing categories for quick lookup
        let existingCategoriesDict = Dictionary(uniqueKeysWithValues: vault.categories.map { ($0.name, $0) })
        
        // Create new array in the correct order WITH SORT ORDER
        var orderedCategories: [Category] = []
        var needsSave = false
        
        for (index, groceryCategory) in GroceryCategory.allCases.enumerated() {
            let categoryName = groceryCategory.title
            
            if let existingCategory = existingCategoriesDict[categoryName] {
                // Update sort order if needed
                if existingCategory.sortOrder != index {
                    existingCategory.sortOrder = index
                    needsSave = true
                }
                orderedCategories.append(existingCategory)
            } else {
                // Create new category with correct sort order
                let newCategory = Category(name: categoryName)
                newCategory.sortOrder = index
                orderedCategories.append(newCategory)
                needsSave = true
                print("➕ Created missing category: \(categoryName) with order \(index)")
            }
        }
        
        // Sort by sortOrder to ensure correct order
        vault.categories = orderedCategories.sorted { $0.sortOrder < $1.sortOrder }
        
        if needsSave {
            saveContext()
            print("✅ Categories ordered with sort indexes")
        }
    }

    private func prePopulateCategories(in vault: Vault) {
        // Clear any existing categories
        vault.categories.removeAll()
        
        // Add categories with proper sort order
        for (index, groceryCategory) in GroceryCategory.allCases.enumerated() {
            let category = Category(name: groceryCategory.title)
            category.sortOrder = index
            vault.categories.append(category)
        }
        
    //MARK: FOR LATER if needed
//        // Add default stores
//        let defaultStores = ["SM Supermarket", "Puregold", "Robinsons", "Metro Market"]
//        for storeName in defaultStores {
//            if !vault.stores.contains(where: { $0.name == storeName }) {
//                let store = Store(name: storeName)
//                vault.stores.append(store)
//            }
//        }
        
        vault.stores.sort { $0.name < $1.name }
    }
    
    // MARK: - User Operations
    func updateUserName(_ newName: String) {
        currentUser?.name = newName
        saveContext()
    }
    
    // MARK: - Category Operations
    func addCategory(_ category: GroceryCategory) {
        guard let vault = vault else { return }
        
        let newCategory = Category(name: category.title)
        vault.categories.append(newCategory)
        
        saveContext()
    }
    
    func getCategory(_ groceryCategory: GroceryCategory) -> Category? {
        vault?.categories.first { $0.name == groceryCategory.title }
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
        
        // Find or create category
        let targetCategory: Category
        if let existingCategory = getCategory(category) {
            targetCategory = existingCategory
        } else {
            targetCategory = Category(name: category.title)
            vault.categories.append(targetCategory)
        }
        
        // Create item with price option
        let pricePerUnit = PricePerUnit(priceValue: price, unit: unit)
        let priceOption = PriceOption(store: store, pricePerUnit: pricePerUnit)
        let newItem = Item(name: name)
        newItem.priceOptions = [priceOption]
        
        targetCategory.items.append(newItem)
        saveContext()
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
    
    // MARK: - Store Operations
    func addStore(_ storeName: String) {
        guard let vault = vault else { return }
        
        let trimmedStore = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStore.isEmpty else { return }
        
        // Check if store already exists
        if !vault.stores.contains(where: { $0.name == trimmedStore }) {
            let newStore = Store(name: trimmedStore)
            vault.stores.append(newStore)
            
            // Sort stores by name
            vault.stores.sort { $0.name < $1.name }
            saveContext()
            print("➕ Added new store to vault: \(trimmedStore)")
        }
    }
    
    func getAllStores() -> [String] {
        guard let vault = vault else { return [] }
        
        // Get stores from Store objects
        let vaultStores = vault.stores.map { $0.name }
        
        // Combine with stores from existing items
        let itemStores = vault.categories.flatMap { category in
            category.items.flatMap { item in
                item.priceOptions.map { $0.store }
            }
        }
        
        let allStores = Array(Set(itemStores + vaultStores)).sorted()
        return allStores
    }
    
    // MARK: - Cart Operations
    func createCart(name: String, budget: Double) -> Cart {
        let newCart = Cart(name: name, budget: budget)
        vault?.carts.append(newCart)
        saveContext()
        return newCart
    }
    
    // MARK: - Helper
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            self.error = error
            print("❌ Failed to save: \(error)")
        }
    }
    
    // In VaultService - make sure your updateItem method does this:
    func updateItem(
        item: Item,
        newName: String,
        newCategory: GroceryCategory,
        newStore: String,
        newPrice: Double,
        newUnit: String
    ) {
        guard let vault = vault else { return }
        
        // 1. Update the item properties (your existing code)
        item.name = newName
        
        // Update price options...
        if let existingPriceOption = item.priceOptions.first(where: { $0.store == newStore }) {
            existingPriceOption.pricePerUnit = PricePerUnit(priceValue: newPrice, unit: newUnit)
        } else {
            let newPriceOption = PriceOption(store: newStore, pricePerUnit: PricePerUnit(priceValue: newPrice, unit: newUnit))
            item.priceOptions.append(newPriceOption)
        }
        
        // Update category if needed...
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
        
        // 2. CRITICAL: Update all ACTIVE carts that contain this item
        updateActiveCartsContainingItem(itemId: item.id)
    }
    
    // MARK: - Cart Status Management
    func completeCart(_ cart: Cart) {
        guard cart.isActive else { return }
        
        // Capture historical prices for all items
        for cartItem in cart.cartItems {
            cartItem.captureHistoricalPrice(from: vault!)
        }
        
        cart.status = .completed
        cart.fulfillmentStatus = 1.0 // 100% fulfilled
        
        saveContext()
        print("✅ Completed cart: \(cart.name) - Prices preserved historically")
    }

    // REMOVED: archiveCart method
    // REMOVED: reactivateCart method

    // NEW: Simple reactivation for completed carts
    func reactivateCart(_ cart: Cart) {
        guard cart.isCompleted else { return }
        
        cart.status = .active
        
        // Clear historical prices since we're active again
        for cartItem in cart.cartItems {
            cartItem.historicalPrice = nil
            cartItem.historicalUnit = nil
        }
        
        // Update totals with current prices
        updateCartTotals(cart: cart)
        
        saveContext()
        print("🔄 Reactivated cart: \(cart.name) - Now using current prices")
    }

    // UPDATED: Update cart totals - respect cart status
    func updateCartTotals(cart: Cart) {
        guard let vault = vault else { return }
        
        var totalSpent: Double = 0.0
        
        for cartItem in cart.cartItems {
            totalSpent += cartItem.getTotalPrice(from: vault, cart: cart)
        }
        
        cart.totalSpent = totalSpent
        
        // Update fulfillment status for active carts only
        if cart.isActive && cart.budget > 0 {
            cart.fulfillmentStatus = min(totalSpent / cart.budget, 1.0)
        }
        
        saveContext()
    }

    // UPDATED: Update item from cart - only affect active carts
    func updateItemFromCart(
        itemId: String,
        newName: String? = nil,
        newCategory: GroceryCategory? = nil,
        newStore: String? = nil,
        newPrice: Double? = nil,
        newUnit: String? = nil
    ) {
        guard let vault = vault,
              let item = findItemById(itemId) else { return }
        
        var needsSave = false
        
        // Update item name if provided
        if let newName = newName, !newName.isEmpty, item.name != newName {
            item.name = newName
            needsSave = true
            print("✏️ Updated item name to: \(newName)")
        }
        
        // Update category if provided
        if let newCategory = newCategory {
            let currentCategory = vault.categories.first { $0.items.contains(where: { $0.id == itemId }) }
            let targetCategory = getCategory(newCategory) ?? Category(name: newCategory.title)
            
            if currentCategory?.name != targetCategory.name {
                currentCategory?.items.removeAll { $0.id == itemId }
                
                if !vault.categories.contains(where: { $0.name == targetCategory.name }) {
                    vault.categories.append(targetCategory)
                }
                targetCategory.items.append(item)
                needsSave = true
                print("🔄 Moved item to category: \(newCategory.title)")
            }
        }
        
        // Update price options if provided
        if let newStore = newStore, let newPrice = newPrice, let newUnit = newUnit {
            if let existingPriceOption = item.priceOptions.first(where: { $0.store == newStore }) {
                // Update existing store's price
                existingPriceOption.pricePerUnit = PricePerUnit(priceValue: newPrice, unit: newUnit)
                needsSave = true
                print("💰 Updated price for \(newStore): ₱\(newPrice) per \(newUnit)")
            } else {
                // Create new price option
                let newPriceOption = PriceOption(
                    store: newStore,
                    pricePerUnit: PricePerUnit(priceValue: newPrice, unit: newUnit)
                )
                item.priceOptions.append(newPriceOption)
                needsSave = true
                print("➕ Added new price option: \(newStore) @ ₱\(newPrice) per \(newUnit)")
            }
        }
        
        if needsSave {
            saveContext()
            
            // Update ONLY ACTIVE carts that contain this item
            updateActiveCartsContainingItem(itemId: itemId)
        }
    }

    // UPDATED: Only update active carts
    private func updateActiveCartsContainingItem(itemId: String) {
        guard let vault = vault else { return }
        
        for cart in vault.carts where cart.isActive {
            if cart.cartItems.contains(where: { $0.itemId == itemId }) {
                updateCartTotals(cart: cart)
            }
        }
        saveContext()
        print("🔄 Updated active carts with new item prices")
    }
    
    // MARK: - Cart Item Operations
    func createCartWithActiveItems(name: String, budget: Double, activeItems: [String: Double]) -> Cart {
        let newCart = createCart(name: name, budget: budget)
        
        // Add all active items to the cart
        for (itemId, quantity) in activeItems {
            if let item = findItemById(itemId) {
                addItemToCart(item: item, cart: newCart, quantity: quantity)
            }
        }
        
        updateCartTotals(cart: newCart)
        saveContext()
        
        print("🛒 Created cart '\(name)' with \(newCart.cartItems.count) items")
        return newCart
    }

    func addItemToCart(item: Item, cart: Cart, quantity: Double, selectedStore: String? = nil) {
        // Use the first store if none specified
        let store = selectedStore ?? item.priceOptions.first?.store ?? "Unknown Store"
        
        let cartItem = CartItem(
            itemId: item.id,
            quantity: quantity,
            selectedStore: store
        )
        
        cart.cartItems.append(cartItem)
        updateCartTotals(cart: cart)
        
        saveContext()
        print("➕ Added item to cart: \(item.name) ×\(quantity)")
    }

    func deleteCart(_ cart: Cart) {
        vault?.carts.removeAll { $0.id == cart.id }
        saveContext()
        print("🗑️ Deleted cart: \(cart.name)")
    }

    func updateCartItemStore(cart: Cart, itemId: String, newStore: String) {
        if let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }) {
            cartItem.selectedStore = newStore
            updateCartTotals(cart: cart)
            saveContext()
            print("🏪 Updated cart item store to: \(newStore)")
        }
    }

    // MARK: - Helper Methods
    func findItemById(_ itemId: String) -> Item? {
        guard let vault = vault else { return nil }
        
        for category in vault.categories {
            if let item = category.items.first(where: { $0.id == itemId }) {
                return item
            }
        }
        return nil
    }

    // MARK: - Item Search and Management
    func getCategory(for itemId: String) -> Category? {
        guard let vault = vault else { return nil }
        
        for category in vault.categories {
            if category.items.contains(where: { $0.id == itemId }) {
                return category
            }
        }
        return nil
    }

    func getAllItems() -> [Item] {
        guard let vault = vault else { return [] }
        
        return vault.categories.flatMap { $0.items }
    }
}
