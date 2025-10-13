//
//  Vault.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import Foundation
import SwiftData


@Model
class User {
    var id: String
    var name: String
    var userVault: Vault
    
    init(id: String = UUID().uuidString, name: String = "Default User") {
        self.id = id
        self.name = name
        self.userVault = Vault()
    }
}



@Model
class Vault {
    @Attribute(.unique) var uid: String
    var categories: [Category] = []
    var carts: [Cart] = []
    var stores: [Store] = []
    
    init(uid: String = UUID().uuidString) {
        self.uid = uid
    }
}

@Model
class Store {
    var name: String
    var createdAt: Date
    
    init(name: String) {
        self.name = name
        self.createdAt = Date()
    }
}


@Model
class Category {
    var uid: String
    var name: String
    var sortOrder: Int
    
    @Relationship(deleteRule: .cascade)
    var items: [Item] = []
    
    init(name: String) {
        self.uid = UUID().uuidString
        self.name = name
        self.sortOrder = 0
    }
}

@Model
class Item {
    @Attribute(.unique) var id: String
    var name: String
    var priceOptions: [PriceOption] = []
    
    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}

@Model
class PriceOption {
    var store: String
    var pricePerUnit: PricePerUnit
    
    init(store: String, pricePerUnit: PricePerUnit) {
        self.store = store
        self.pricePerUnit = pricePerUnit
    }
}

@Model
class PricePerUnit {
    var priceValue: Double
    var unit: String
    
    init(priceValue: Double, unit: String) {
        self.priceValue = priceValue
        self.unit = unit
    }
}

@Model
class Cart {
    @Attribute(.unique) var id: String
    var name: String
    var budget: Double
    var totalSpent: Double
    var fulfillmentStatus: Double
    var createdAt: Date
    var status: CartStatus // Make sure this exists
    
    @Relationship(deleteRule: .cascade)
    var cartItems: [CartItem] = []
    
    init(
        id: String = UUID().uuidString,
        name: String,
        budget: Double,
        totalSpent: Double = 0.0,
        fulfillmentStatus: Double = 0.0,
        createdAt: Date = Date(),
        status: CartStatus = .active
    ) {
        self.id = id
        self.name = name
        self.budget = budget
        self.totalSpent = totalSpent
        self.fulfillmentStatus = fulfillmentStatus
        self.createdAt = createdAt
        self.status = status
    }
    
    var isActive: Bool {
        status == .active
    }
    
    var isCompleted: Bool {
        status == .completed
    }
}

@Model
class CartItem {
    var itemId: String
    var quantity: Double
    var isFulfilled: Bool
    var selectedStore: String
    
    // Store historical price for completed carts
    var historicalPrice: Double?
    var historicalUnit: String?
    
    init(
        itemId: String,
        quantity: Double,
        selectedStore: String,
        isFulfilled: Bool = false,
        historicalPrice: Double? = nil,
        historicalUnit: String? = nil
    ) {
        self.itemId = itemId
        self.quantity = quantity
        self.selectedStore = selectedStore
        self.isFulfilled = isFulfilled
        self.historicalPrice = historicalPrice
        self.historicalUnit = historicalUnit
    }
    
    // Get price - use historical if available, otherwise current from vault
    func getPrice(from vault: Vault, cart: Cart) -> Double {
        // For completed carts, use historical price
        if cart.isCompleted, let historicalPrice = historicalPrice {
            return historicalPrice
        }
        
        // For active carts, use current price from vault
        guard let item = getItem(from: vault) else { return 0.0 }
        return item.priceOptions.first(where: { $0.store == selectedStore })?.pricePerUnit.priceValue ?? 0.0
    }
    
    // Get unit - use historical if available, otherwise current from vault
    func getUnit(from vault: Vault, cart: Cart) -> String {
        // For completed carts, use historical unit
        if cart.isCompleted, let historicalUnit = historicalUnit {
            return historicalUnit
        }
        
        // For active carts, use current unit from vault
        guard let item = getItem(from: vault) else { return "" }
        return item.priceOptions.first(where: { $0.store == selectedStore })?.pricePerUnit.unit ?? ""
    }
    
    // Get total price
    func getTotalPrice(from vault: Vault, cart: Cart) -> Double {
        return getPrice(from: vault, cart: cart) * quantity
    }
    
    func getItem(from vault: Vault) -> Item? {
        for category in vault.categories {
            if let item = category.items.first(where: { $0.id == itemId }) {
                return item
            }
        }
        return nil
    }
    
    // Capture historical prices when cart is completed
    func captureHistoricalPrice(from vault: Vault) {
        guard let item = getItem(from: vault),
              let priceOption = item.priceOptions.first(where: { $0.store == selectedStore })
        else { return }
        
        self.historicalPrice = priceOption.pricePerUnit.priceValue
        self.historicalUnit = priceOption.pricePerUnit.unit
    }
}

// Make sure CartStatus enum exists
enum CartStatus: Int, Codable {
    case active = 0      // Currently shopping, use current prices
    case completed = 1   // Finished shopping, preserve historical prices
}
