//
//  Vault.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import Foundation
import SwiftData

// MARK: - Vault
@Model
class Vault {
    @Attribute(.unique) var uid: String
    var categories: [Category] = []
    var carts: [Cart] = []
    
    init(uid: String = UUID().uuidString) {
        self.uid = uid
    }
}

// MARK: - Category
@Model
class Category {
    @Attribute(.unique) var uid: String
    var name: String
    var items: [Item] = []
    
    init(uid: String = UUID().uuidString, name: String) {
        self.uid = uid
        self.name = name
    }
}

// MARK: - Item
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

// MARK: - PriceOption
@Model
class PriceOption {
    var store: String
    var pricePerUnit: PricePerUnit
    
    init(store: String, pricePerUnit: PricePerUnit) {
        self.store = store
        self.pricePerUnit = pricePerUnit
    }
}

// MARK: - PricePerUnit
@Model
class PricePerUnit {
    var priceValue: Double
    var unit: String
    
    init(priceValue: Double, unit: String) {
        self.priceValue = priceValue
        self.unit = unit
    }
}

// MARK: - Cart
@Model
class Cart {
    @Attribute(.unique) var id: String
    var name: String
    var budget: Double
    var totalSpent: Double
    var fulfillmentStatus: Double
    var cartItems: [CartItem] = []
    
    init(
        id: String = UUID().uuidString,
        name: String,
        budget: Double,
        totalSpent: Double = 0.0,
        fulfillmentStatus: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.budget = budget
        self.totalSpent = totalSpent
        self.fulfillmentStatus = fulfillmentStatus
    }
}

// MARK: - CartItem
@Model
class CartItem {
    var itemId: String
    var priceOptionStore: String
    var quantity: Double
    var isFulfilled: Bool
    var totalPrice: Double
    
    init(
        itemId: String,
        priceOptionStore: String,
        quantity: Double,
        isFulfilled: Bool = false,
        totalPrice: Double
    ) {
        self.itemId = itemId
        self.priceOptionStore = priceOptionStore
        self.quantity = quantity
        self.isFulfilled = isFulfilled
        self.totalPrice = totalPrice
    }
}

// MARK: - Vault Helper
func ensureVault(context: ModelContext) -> Vault {
    if let vault = try? context.fetch(FetchDescriptor<Vault>()).first {
        return vault
    }

    let vault = Vault()

    let meats = Category(name: "Meats & Seafood")
    let fresh = Category(name: "Fresh Produce")
    let frozen = Category(name: "Frozen")

    vault.categories = [meats, fresh, frozen]

    context.insert(vault)
    try? context.save()

    return vault
}
