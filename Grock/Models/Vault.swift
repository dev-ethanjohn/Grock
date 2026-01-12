import Foundation
import SwiftData

enum FulfillmentAnimationState: Int, Codable {
    case none = 0
    case checkmarkAppearing = 1
    case checkmarkVisible = 2
    case strikethroughAnimating = 3
    case strikethroughComplete = 4
    case removalAnimating = 5
}

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
    var createdAt: Date
    
    // MARK: - New properties for shopping context
    var isTemporaryShoppingItem: Bool? = false
    var shoppingPrice: Double?
    var shoppingUnit: String?
    
    
    init(
        id: String = UUID().uuidString,
        name: String,
        priceOptions: [PriceOption] = [],
        createdAt: Date = Date(),
        isTemporaryShoppingItem: Bool = false,
        shoppingPrice: Double? = nil,
        shoppingUnit: String? = nil
    ) {
        self.id = id
        self.name = name
        self.priceOptions = priceOptions
        self.createdAt = createdAt
        self.isTemporaryShoppingItem = isTemporaryShoppingItem
        self.shoppingPrice = shoppingPrice
        self.shoppingUnit = shoppingUnit
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
    var updatedAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var status: CartStatus
    
    @Relationship(deleteRule: .cascade)
    var cartItems: [CartItem] = []
    
    init(
        id: String = UUID().uuidString,
        name: String,
        budget: Double,
        fulfillmentStatus: Double = 0.0,
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        status: CartStatus = .planning
    ) {
        self.id = id
        self.name = name
        self.budget = budget
        self.fulfillmentStatus = fulfillmentStatus
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
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
    @Attribute var addedAt: Date  // Remove default value
    var itemId: String
    var quantity: Double
    var isFulfilled: Bool
    
    var isSkippedDuringShopping: Bool = false
    var plannedStore: String
    var plannedPrice: Double?
    var plannedUnit: String?
    
    var actualStore: String?
    var actualPrice: Double?
    var actualQuantity: Double?
    var actualUnit: String?
    
    var wasEditedDuringShopping: Bool = false
    
    // MARK: - Shopping-only item properties
    var isShoppingOnlyItem: Bool = false
    var shoppingOnlyName: String?
    var shoppingOnlyStore: String?
    var shoppingOnlyPrice: Double?
    var shoppingOnlyUnit: String?
    var shoppingOnlyCategory: String?
    
    // MARK: - Original planning quantity for restoration
    var originalPlanningQuantity: Double?
    var addedDuringShopping: Bool = false
    
    // MARK: - Animation states for fulfillment
    var fulfillmentAnimationState: Int = 0  // Use Int instead of enum for @Model
    var fulfillmentStartTime: Date?
    var shouldShowCheckmark: Bool = false
    var shouldStrikethrough: Bool = false
    
    init(
        itemId: String,
        quantity: Double,
        plannedStore: String,
        isFulfilled: Bool = false,
        isSkippedDuringShopping: Bool = false,
        plannedPrice: Double? = nil,
        plannedUnit: String? = nil,
        actualStore: String? = nil,
        actualPrice: Double? = nil,
        actualQuantity: Double? = nil,
        actualUnit: String? = nil,
        isShoppingOnlyItem: Bool = false,
        shoppingOnlyName: String? = nil,
        shoppingOnlyStore: String? = nil,
        shoppingOnlyPrice: Double? = nil,
        shoppingOnlyUnit: String? = nil,
        shoppingOnlyCategory: String? = nil,
        originalPlanningQuantity: Double? = nil,
        addedDuringShopping: Bool = false,
        fulfillmentAnimationState: Int = 0,
        fulfillmentStartTime: Date? = nil,
        shouldShowCheckmark: Bool = false,
        shouldStrikethrough: Bool = false
    ) {
        self.addedAt = Date()  // Set default value in initializer
        self.itemId = itemId
        self.quantity = quantity
        self.plannedStore = plannedStore
        self.isFulfilled = isFulfilled
        self.isSkippedDuringShopping = isSkippedDuringShopping
        self.plannedPrice = plannedPrice
        self.plannedUnit = plannedUnit
        self.actualStore = actualStore
        self.actualPrice = actualPrice
        self.actualQuantity = actualQuantity
        self.actualUnit = actualUnit
        self.isShoppingOnlyItem = isShoppingOnlyItem
        self.shoppingOnlyName = shoppingOnlyName
        self.shoppingOnlyStore = shoppingOnlyStore
        self.shoppingOnlyPrice = shoppingOnlyPrice
        self.shoppingOnlyUnit = shoppingOnlyUnit
        self.shoppingOnlyCategory = shoppingOnlyCategory
        self.originalPlanningQuantity = originalPlanningQuantity
        self.addedDuringShopping = addedDuringShopping
        self.fulfillmentAnimationState = fulfillmentAnimationState
        self.fulfillmentStartTime = fulfillmentStartTime
        self.shouldShowCheckmark = shouldShowCheckmark
        self.shouldStrikethrough = shouldStrikethrough
    }
    
    // Helper for animation state
    var animationState: FulfillmentAnimationState {
        get {
            return FulfillmentAnimationState(rawValue: fulfillmentAnimationState) ?? .none
        }
        set {
            fulfillmentAnimationState = newValue.rawValue
        }
    }
    
    // MARK: - Static factory method for shopping-only items
    static func createShoppingOnlyItem(
        name: String,
        store: String,
        price: Double,
        unit: String,
        quantity: Double = 1,
        category: GroceryCategory? = nil
    ) -> CartItem {
        return CartItem(
            itemId: UUID().uuidString,
            quantity: quantity,
            plannedStore: store,
            isFulfilled: false,
            // Shopping-only flags
            actualStore: store,
            actualPrice: price,
            actualQuantity: quantity,
            actualUnit: unit,
            isShoppingOnlyItem: true,
            shoppingOnlyName: name,
            shoppingOnlyStore: store,
            shoppingOnlyPrice: price,
            shoppingOnlyUnit: unit,
            shoppingOnlyCategory: category?.rawValue,
            originalPlanningQuantity: nil,
            addedDuringShopping: true
        )
    }
    
    // MARK: - Helper Methods
    
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
        if isShoppingOnlyItem, let name = shoppingOnlyName {
            return Item(
                id: itemId,
                name: name,
                priceOptions: shoppingOnlyPrice.map { price in
                    [PriceOption(
                        store: shoppingOnlyStore ?? "Unknown Store",
                        pricePerUnit: PricePerUnit(
                            priceValue: price,
                            unit: shoppingOnlyUnit ?? ""
                        )
                    )]
                } ?? [],
                isTemporaryShoppingItem: true,
                shoppingPrice: shoppingOnlyPrice,
                shoppingUnit: shoppingOnlyUnit
            )
        }
        
        for category in vault.categories {
            if let item = category.items.first(where: { $0.id == itemId }) {
                return item
            }
        }
        return nil
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
    
    func getPrice(from vault: Vault, cart: Cart) -> Double {
        if isShoppingOnlyItem {
            return shoppingOnlyPrice ?? 0.0
        }
        
        switch cart.status {
        case .planning:
            return plannedPrice ?? getCurrentPrice(from: vault, store: plannedStore) ?? 0.0
        case .shopping:
            if let actualPrice = actualPrice {
                return actualPrice
            }
            return actualPrice ?? plannedPrice ?? getCurrentPrice(from: vault, store: actualStore ?? plannedStore) ?? 0.0
        case .completed:
            return actualPrice ?? plannedPrice ?? 0.0
        }
    }
    
    func getStore(cart: Cart) -> String {
        if isShoppingOnlyItem {
            return shoppingOnlyStore ?? "Unknown Store"
        }
        
        switch cart.status {
        case .planning:
            return plannedStore
        case .shopping, .completed:
            return actualStore ?? plannedStore
        }
    }
    
    func getUnit(from vault: Vault, cart: Cart) -> String {
        if isShoppingOnlyItem {
            return shoppingOnlyUnit ?? ""
        }
        
        switch cart.status {
        case .planning:
            return plannedUnit ?? getCurrentUnit(from: vault, store: plannedStore) ?? ""
        case .shopping:
            if let actualUnit = actualUnit {
                return actualUnit
            }
            return actualUnit ?? plannedUnit ?? getCurrentUnit(from: vault, store: actualStore ?? plannedStore) ?? ""
        case .completed:
            return actualUnit ?? plannedUnit ?? ""
        }
    }
    
    func getQuantity(cart: Cart) -> Double {
        switch cart.status {
        case .planning:
            print("🔍 getQuantity - Planning: quantity = \(quantity)")
            return quantity
        case .shopping, .completed:
            // CRITICAL FIX: Always return quantity, not actualQuantity
            // The quantity field should be the single source of truth
            print("🔍 getQuantity - Shopping/Completed: using quantity = \(quantity)")
            return quantity
        }
    }
    
    func syncQuantities(cart: Cart) {
        // Keep quantity and actualQuantity in sync
        switch cart.status {
        case .planning:
            // In planning, actualQuantity should match quantity
            if actualQuantity != quantity {
                actualQuantity = quantity
            }
        case .shopping, .completed:
            // In shopping/completed, quantity is the primary source
            // Only update actualQuantity if it's different
            if actualQuantity != quantity {
                actualQuantity = quantity
            }
        }
    }
    
    func getTotalPrice(from vault: Vault, cart: Cart) -> Double {
        return getPrice(from: vault, cart: cart) * getQuantity(cart: cart)
    }
    
    func updateActualData(price: Double? = nil, quantity: Double? = nil, unit: String? = nil, store: String? = nil) {
        if let price = price { actualPrice = price }
        if let quantity = quantity { actualQuantity = quantity }
        if let unit = unit { actualUnit = unit }
        if let store = store { actualStore = store }
    }
    
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
    
    func updateShoppingData(
        price: Double? = nil,
        quantity: Double? = nil,
        unit: String? = nil,
        store: String? = nil,
        isFulfilled: Bool = false
    ) {
        if isFulfilled {
            if let price = price { actualPrice = price }
            if let quantity = quantity { actualQuantity = quantity }
            if let unit = unit { actualUnit = unit }
            if let store = store { actualStore = store }
        } else {
            if let price = price { actualPrice = price }
            if let quantity = quantity { actualQuantity = quantity }
            if let unit = unit { actualUnit = unit }
            if let store = store { actualStore = store }
            wasEditedDuringShopping = true
        }
    }
    
    func getShoppingDisplayPrice(cart: Cart) -> Double {
        switch cart.status {
        case .planning:
            return plannedPrice ?? 0
        case .shopping:
            if isFulfilled {
                return actualPrice ?? plannedPrice ?? 0
            } else if wasEditedDuringShopping {
                return actualPrice ?? plannedPrice ?? 0
            } else {
                return plannedPrice ?? 0
            }
        case .completed:
            return actualPrice ?? plannedPrice ?? 0
        }
    }
    
    // MARK: - NEW: Save original planning quantity
    func saveOriginalPlanningQuantity() {
        // Only save if not already saved and this is a vault item
        if originalPlanningQuantity == nil && !isShoppingOnlyItem {
            originalPlanningQuantity = quantity
            print("📝 Saved original planning quantity: \(quantity)")
        }
    }
    
    // MARK: - NEW: Restore to original planning quantity
    func restoreToOriginalPlanningQuantity() -> Bool {
        guard let originalQty = originalPlanningQuantity else {
            print("⚠️ No original planning quantity saved")
            return false
        }
        
        print("↩️ Restoring to original planning quantity: \(quantity) → \(originalQty)")
        quantity = originalQty
        originalPlanningQuantity = nil  // Clear after restoring
        return true
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
