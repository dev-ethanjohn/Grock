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
    
        func updateActiveItem(itemId: String, quantity: Double) {
            if quantity > 0 {
                activeCartItems[itemId] = quantity
            } else {
                activeCartItems.removeValue(forKey: itemId)
            }
        }
    
    private let vaultService: VaultService
    
    init(vaultService: VaultService) {
        self.vaultService = vaultService
        loadCarts()
    }
    
    func loadCarts() {
        if let vault = vaultService.vault {
            self.carts = vault.carts
        }
    }
    
    func createCart(name: String, budget: Double) {
        let newCart = vaultService.createCart(name: name, budget: budget)
        self.carts.append(newCart)
        self.currentCart = newCart
    }
}
