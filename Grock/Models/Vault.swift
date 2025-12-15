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
class Vault: Equatable {
    @Attribute(.unique) var uid: String
    var categories: [Category] = []
    var carts: [Cart] = []
    var stores: [Store] = []
    
    init(uid: String = UUID().uuidString) {
        self.uid = uid
    }
    
    //
    static func == (lhs: Vault, rhs: Vault) -> Bool {
           lhs.uid == rhs.uid
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
class Item: Identifiable {
    @Attribute(.unique) var id: String
    var name: String
    var priceOptions: [PriceOption] = []
    var createdAt: Date  // ✅ ADD THIS
    
    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
        self.createdAt = Date()  // ✅ ADD THIS
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

enum CartStatus: Int, Codable {
    case planning = 0
    case shopping = 1
    case completed = 2
}


@Model
class Cart {
    @Attribute(.unique) var id: String
    var name: String
    var budget: Double
    var fulfillmentStatus: Double
    var createdAt: Date
    var status: CartStatus
    
    @Relationship(deleteRule: .cascade)
    var cartItems: [CartItem] = []
    
    init(
        id: String = UUID().uuidString,
        name: String,
        budget: Double,
        fulfillmentStatus: Double = 0.0,
        createdAt: Date = Date(),
        status: CartStatus = .planning
    ) {
        self.id = id
        self.name = name
        self.budget = budget
        self.fulfillmentStatus = fulfillmentStatus
        self.createdAt = createdAt
        self.status = status
    }
    
    var isPlanning: Bool { status == .planning }
    var isShopping: Bool { status == .shopping }
    var isCompleted: Bool { status == .completed }
    var isActive: Bool { isPlanning || isShopping }
    
    var fulfilledItemsCount: Int {
        cartItems.filter { $0.isFulfilled }.count
    }

    var totalItemsCount: Int {
        cartItems.count
    }
    
    // Fixed totalSpent calculation based on cart status
    var totalSpent: Double {
        cartItems.reduce(0) { total, cartItem in
            let price: Double
            let quantity: Double
            
            switch status {
            case .planning:
                price = cartItem.plannedPrice ?? 0
                quantity = cartItem.quantity
                
            case .shopping:
                if cartItem.isFulfilled {
                    price = cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
                    quantity = cartItem.actualQuantity ?? cartItem.quantity
                } else if cartItem.wasEditedDuringShopping {
                    // Use edited shopping data for unfulfilled items
                    price = cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
                    quantity = cartItem.actualQuantity ?? cartItem.quantity
                } else {
                    price = cartItem.plannedPrice ?? 0
                    quantity = cartItem.quantity
                }
                
            case .completed:
                price = cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
                quantity = cartItem.actualQuantity ?? cartItem.quantity
            }
            
            return total + (price * quantity)
        }
    }
}

@Model
class CartItem {
    var itemId: String
    var quantity: Double
    var isFulfilled: Bool
    
    // PLANNED data (frozen when shopping starts)
    var plannedStore: String
    var plannedPrice: Double?
    var plannedUnit: String?
    
    // ACTUAL data (editable during shopping)
    var actualStore: String?
    var actualPrice: Double?
    var actualQuantity: Double?
    var actualUnit: String?
    
    // Add a property to track if item was edited during shopping
    var wasEditedDuringShopping: Bool = false
    
    init(
        itemId: String,
        quantity: Double,
        plannedStore: String,
        isFulfilled: Bool = false,
        plannedPrice: Double? = nil,
        plannedUnit: String? = nil,
        actualStore: String? = nil,
        actualPrice: Double? = nil,
        actualQuantity: Double? = nil,
        actualUnit: String? = nil
    ) {
        self.itemId = itemId
        self.quantity = quantity
        self.plannedStore = plannedStore
        self.isFulfilled = isFulfilled
        self.plannedPrice = plannedPrice
        self.plannedUnit = plannedUnit
        self.actualStore = actualStore
        self.actualPrice = actualPrice
        self.actualQuantity = actualQuantity
        self.actualUnit = actualUnit
    }
    
    func getPrice(from vault: Vault, cart: Cart) -> Double {
        switch cart.status {
        case .planning:
            return plannedPrice ?? getCurrentPrice(from: vault, store: plannedStore) ?? 0.0
        case .shopping:
            // CRITICAL: Use actualPrice if set (even if unfulfilled)
            if let actualPrice = actualPrice {
                return actualPrice
            }
            return actualPrice ?? plannedPrice ?? getCurrentPrice(from: vault, store: actualStore ?? plannedStore) ?? 0.0
        case .completed:
            return actualPrice ?? plannedPrice ?? 0.0
        }
    }

    
    func getQuantity(cart: Cart) -> Double {
        switch cart.status {
        case .planning:
            return quantity
        case .shopping, .completed:
            // CRITICAL: Use actualQuantity if set (even if unfulfilled)
            return actualQuantity ?? quantity
        }
    }
    
    func getUnit(from vault: Vault, cart: Cart) -> String {
        switch cart.status {
        case .planning:
            return plannedUnit ?? getCurrentUnit(from: vault, store: plannedStore) ?? ""
        case .shopping:
            // CRITICAL: Use actualUnit if set (even if unfulfilled)
            if let actualUnit = actualUnit {
                return actualUnit
            }
            return actualUnit ?? plannedUnit ?? getCurrentUnit(from: vault, store: actualStore ?? plannedStore) ?? ""
        case .completed:
            return actualUnit ?? plannedUnit ?? ""
        }
    }

    func getStore(cart: Cart) -> String {
        switch cart.status {
        case .planning:
            return plannedStore
        case .shopping, .completed:
            return actualStore ?? plannedStore
        }
    }
    
    func getTotalPrice(from vault: Vault, cart: Cart) -> Double {
        return getPrice(from: vault, cart: cart) * getQuantity(cart: cart)
    }
    
    func capturePlannedData(from vault: Vault) {
        if plannedPrice == nil {
            plannedPrice = getCurrentPrice(from: vault, store: plannedStore)
        }
        if plannedUnit == nil {
            plannedUnit = getCurrentUnit(from: vault, store: plannedStore)
        }
    }
    
    func captureActualData() {
        // If user didn't set actual data during shopping, use planned as actual
        if actualStore == nil {
            actualStore = plannedStore
        }
        if actualPrice == nil {
            actualPrice = plannedPrice
        }
        if actualQuantity == nil {
            actualQuantity = quantity
        }
        if actualUnit == nil {
            actualUnit = plannedUnit
        }
    }
    
    // Helper methods
    func getCurrentPrice(from vault: Vault, store: String) -> Double? {
        guard let item = getItem(from: vault),
              let priceOption = item.priceOptions.first(where: { $0.store == store })
        else { return nil }
        return priceOption.pricePerUnit.priceValue
    }
    
    func getCurrentUnit(from vault: Vault, store: String) -> String? {
        guard let item = getItem(from: vault),
              let priceOption = item.priceOptions.first(where: { $0.store == store })
        else { return nil }
        return priceOption.pricePerUnit.unit
    }
    
    func getItem(from vault: Vault) -> Item? {
        for category in vault.categories {
            if let item = category.items.first(where: { $0.id == itemId }) {
                return item
            }
        }
        return nil
    }
    
    // MARK: - Shopping Mode Updates
    func updateActualData(price: Double? = nil, quantity: Double? = nil, unit: String? = nil, store: String? = nil) {
        if let price = price { actualPrice = price }
        if let quantity = quantity { actualQuantity = quantity }
        if let unit = unit { actualUnit = unit }
        if let store = store { actualStore = store }
    }
    
    // Add validation method
    func canEditInMode(cartStatus: CartStatus) -> (canEdit: Bool, message: String) {
        switch cartStatus {
        case .planning:
            return (true, "Can edit planned data")
        case .shopping:
            if isFulfilled {
                return (true, "Can edit actual shopping data")
            } else {
                return (false, "Mark item as fulfilled to edit actual data")
            }
        case .completed:
            return (false, "Cart is completed")
        }
    }
    
    // Add a method for shopping mode edits
     func updateShoppingData(
         price: Double? = nil,
         quantity: Double? = nil,
         unit: String? = nil,
         store: String? = nil,
         isFulfilled: Bool = false
     ) {
         if isFulfilled {
             // Update actual data for fulfilled items
             if let price = price { actualPrice = price }
             if let quantity = quantity { actualQuantity = quantity }
             if let unit = unit { actualUnit = unit }
             if let store = store { actualStore = store }
         } else {
             // For unfulfilled items: store edits in actual fields
             // but don't mark as fulfilled yet
             if let price = price { actualPrice = price }
             if let quantity = quantity { actualQuantity = quantity }
             if let unit = unit { actualUnit = unit }
             if let store = store { actualStore = store }
             wasEditedDuringShopping = true
         }
     }
    
    // Helper to get display data during shopping
     func getShoppingDisplayPrice(cart: Cart) -> Double {
         switch cart.status {
         case .planning:
             return plannedPrice ?? 0
         case .shopping:
             // For shopping: show edited actual price if set, otherwise planned
             if isFulfilled {
                 return actualPrice ?? plannedPrice ?? 0
             } else if wasEditedDuringShopping {
                 // Show edited price even if not fulfilled
                 return actualPrice ?? plannedPrice ?? 0
             } else {
                 return plannedPrice ?? 0
             }
         case .completed:
             return actualPrice ?? plannedPrice ?? 0
         }
     }
}

// MARK: - Supporting Types for Insights
struct CartInsights {
    var plannedTotal: Double = 0.0
    var actualTotal: Double = 0.0
    var totalDifference: Double = 0.0
    var priceChanges: [PriceChange] = []
    
    var isOverBudget: Bool { totalDifference > 0 }
    var savings: Double { max(0, -totalDifference) }
    var overspend: Double { max(0, totalDifference) }
}

struct PriceChange {
    let itemName: String
    let plannedPrice: Double
    let actualPrice: Double
    let difference: Double
}
