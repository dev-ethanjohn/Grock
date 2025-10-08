////
////  CartViewModel.swift
////  Grock
////
////  Created by Ethan John Paguntalan on 10/6/25.
////
//
//import Foundation
//import SwiftData
//import Observation
//
//@Observable
//class CartViewModel {
//    var cartName: String = ""
//    var budget: Double = 0.0
//    
//    // Track items that are currently in the cart (active items)
//    var activeCartItems: [String: Double] = [:] // [itemId: quantity]
//    
//    // Add this method to update active items
//    func updateActiveItem(itemId: String, quantity: Double) {
//        if quantity > 0 {
//            activeCartItems[itemId] = quantity
//        } else {
//            activeCartItems.removeValue(forKey: itemId)
//        }
//    }
//    
//    
//    
//    func createCart(
//        context: ModelContext,
//        itemsWithQuantities: [String: Double],
//        vault: Vault
//    ) -> Cart? {
//        // Filter out items with quantity 0
//        let selectedItems = itemsWithQuantities.filter { $0.value > 0 }
//        
//        guard !selectedItems.isEmpty else { return nil }
//        
//        // Create cart items
//        var cartItems: [CartItem] = []
//        var totalSpent: Double = 0.0
//        
//        for (itemId, quantity) in selectedItems {
//            // Find the item in the vault
//            guard let item = findItemInVault(itemId: itemId, vault: vault),
//                  let priceOption = item.priceOptions.first else { continue }
//            
//            let totalPrice = priceOption.pricePerUnit.priceValue * quantity
//            totalSpent += totalPrice
//            
//            let cartItem = CartItem(
//                itemId: itemId,
//                priceOptionStore: priceOption.store,
//                quantity: quantity,
//                totalPrice: totalPrice
//            )
//            cartItems.append(cartItem)
//        }
//        
//        // Create the cart
//        let cart = Cart(
//            name: cartName.isEmpty ? "New Cart" : cartName,
//            budget: budget,
//            totalSpent: totalSpent,
//            fulfillmentStatus: 0.0
//        )
//        cart.cartItems = cartItems
//        
//        // Add cart to vault
//        vault.carts.append(cart)
//        
//        // Save context
//        try? context.save()
//        
//        return cart
//    }
//    
//    private func findItemInVault(itemId: String, vault: Vault) -> Item? {
//        for category in vault.categories {
//            if let item = category.items.first(where: { $0.id == itemId }) {
//                return item
//            }
//        }
//        return nil
//    }
//}

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
    var activeCartItems: [String: Double] = [:] // [itemId: quantity]
    
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
        // Implementation to load carts from vaultService
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
