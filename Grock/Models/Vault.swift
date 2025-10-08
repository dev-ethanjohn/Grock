//
//  Vault.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import Foundation
import SwiftData

@Model
class Vault {
    @Attribute(.unique) var uid: String
    var categories: [Category] = []
    var carts: [Cart] = []
    
    init(uid: String = UUID().uuidString) {
        self.uid = uid
    }
}
@Model
class Category {
    var uid: String
    var name: String
    var sortOrder: Int // ADD THIS
    
    @Relationship(deleteRule: .cascade)
    var items: [Item] = []
    
    init(name: String) {
        self.uid = UUID().uuidString
        self.name = name
        self.sortOrder = 0 // Will be set properly later
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

