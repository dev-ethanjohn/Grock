import Foundation
import SwiftUI
import Observation


@MainActor
@Observable
class CartViewModel {
    var carts: [Cart] = []
    var currentCart: Cart?
    var isLoading = false
    var error: Error?
    var activeCartItems: [String: Double] = [:]
    
    private let vaultService: VaultService
    
    init(vaultService: VaultService) {
        self.vaultService = vaultService
        loadCarts()
    }
    
    // MARK: - Active Cart Items Management
    func updateActiveItem(itemId: String, quantity: Double) {
        if quantity > 0 {
            activeCartItems[itemId] = quantity
        } else {
            activeCartItems.removeValue(forKey: itemId)
        }
    }
    
    // MARK: - Cart Loading
    func loadCarts() {
        if let vault = vaultService.vault {
            // Sort carts by creation date (newest first)
            self.carts = vault.carts.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    // MARK: - Cart Creation with Active Items
    func createCartWithActiveItems(name: String, budget: Double) -> Cart? {
        guard vaultService.vault != nil else { return nil }
        
        // Use the new method from VaultService that adds active items
        let newCart = vaultService.createCartWithActiveItems(
            name: name,
            budget: budget,
            activeItems: activeCartItems
        )
        
        // Update local state
        self.carts.append(newCart)
        self.currentCart = newCart
        self.activeCartItems.removeAll() // Clear active items after cart creation
        
        print("✅ Cart created with \(newCart.cartItems.count) items")
        return newCart
    }
    
    // MARK: - Cart Status Management
    func completeCart(_ cart: Cart) {
        vaultService.completeCart(cart)
        loadCarts() // Refresh the carts list
    }
    
    func reactivateCart(_ cart: Cart) {
        vaultService.reactivateCart(cart)
        loadCarts() // Refresh the carts list
    }
    
    func deleteCart(_ cart: Cart) {
        vaultService.deleteCart(cart)
        loadCarts() // Refresh the carts list
        
        // Clear current cart if it was deleted
        if currentCart?.id == cart.id {
            currentCart = nil
        }
    }
    
    // MARK: - Convenience Properties
    var activeCarts: [Cart] {
        carts.filter { $0.isActive }
    }
    
    var completedCarts: [Cart] {
        carts.filter { $0.isCompleted }
    }
    
    var recentCompletedCarts: [Cart] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return completedCarts.filter { $0.createdAt > thirtyDaysAgo }
    }
    
    var hasActiveItems: Bool {
        !activeCartItems.isEmpty
    }
    
    var activeItemsCount: Int {
        activeCartItems.count
    }
    
    // MARK: - Cart Item Updates
    func updateCartItemStore(cart: Cart, itemId: String, newStore: String) {
        vaultService.updateCartItemStore(cart: cart, itemId: itemId, newStore: newStore)
    }
    
    // MARK: - Item Editing (Updates both cart and vault)
    func updateItemFromCart(
        itemId: String,
        newName: String? = nil,
        newCategory: GroceryCategory? = nil,
        newStore: String? = nil,
        newPrice: Double? = nil,
        newUnit: String? = nil
    ) {
        vaultService.updateItemFromCart(
            itemId: itemId,
            newName: newName,
            newCategory: newCategory,
            newStore: newStore,
            newPrice: newPrice,
            newUnit: newUnit
        )
    }
}
