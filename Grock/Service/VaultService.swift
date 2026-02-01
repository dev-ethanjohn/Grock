import Foundation
import SwiftData
import Observation

extension Category {
    /// Returns items in descending creation order (newest first).
    var sortedItems: [Item] {
        items.sorted { $0.createdAt > $1.createdAt } // ✅ Newest first
    }
}

// MARK: - Vault Service
/// The app’s “data brain”.
///
/// If you’re new to the codebase: most screens talk to `VaultService` to read or update data.
///
/// Quick glossary:
/// - Vault: your saved grocery database (items, categories, stores, carts).
/// - Cart: a shopping trip (planning → shopping → completed).
/// - CartItem: an item inside a cart (planned vs actual price/quantity).
///
/// What this service does:
/// - Loads (or creates) the user + vault when the app starts.
/// - Saves changes to SwiftData.
/// - Provides a single, consistent API for the rest of the app.
///
/// Tech note:
/// - `@MainActor` because SwiftUI calls this directly via `@Environment`.
@MainActor
@Observable
class VaultService {
   
    // MARK: - Properties
    /// SwiftData context used for reads/writes.
    let modelContext: ModelContext
    
    /// Cache for fast item lookups (itemId → Item).
    var itemCache: [String: Item] = [:]
   
    // Current state
    /// The single app user (this app is currently single-user).
    var currentUser: User?
    /// Convenience accessor for the user’s vault (the main dataset).
    var vault: Vault? { currentUser?.userVault }
    /// Used by the UI to show loading while the vault is being prepared.
    var isLoading = false
    /// Stores the last persistence error, if any.
    var error: Error?
   
    // MARK: - Computed Properties
    /// Categories ordered the way the UI expects.
    var sortedCategories: [Category] {
        vault?.categories.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }
   
    // MARK: - Initialization
    /// Creates the service and loads (or creates) the user + vault.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserAndVault()
    }
    
    /// Clears internal caches used for faster lookups.
    func clearCaches() {
        itemCache.removeAll()
        invalidateCategoryCache()
    }
}

extension VaultService {
    /// Saves pending changes to SwiftData (writes to disk).
    ///
    /// If saving fails:
    /// - `error` is set
    /// - a debug message is printed
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            self.error = error
            print("❌ Failed to save: \(error)")
        }
    }

    /// Recomputes totals for any active shopping cart that contains this item.
    ///
    /// Why it matters:
    /// - If you change an item’s price/unit/store, the “shopping” UI needs updated totals.
    func updateActiveCartsContainingItem(itemId: String) {
        guard let vault = vault else { return }

        for cart in vault.carts where cart.isShopping {
            if cart.cartItems.contains(where: { $0.itemId == itemId }) {
                updateCartTotals(cart: cart)
            }
        }
        saveContext()
        print("🔄 Updated active carts with new item prices")
    }
}

@MainActor
/// User/vault initialization and user-level actions.
protocol VaultUserManaging {
    func loadUserAndVault()
    func updateUserName(_ newName: String)
}

@MainActor
/// Category operations: add/find categories and resolve an item’s category.
protocol VaultCategoryManaging {
    var sortedCategories: [Category] { get }
    func addCategory(_ category: GroceryCategory)
    func getCategory(_ groceryCategory: GroceryCategory) -> Category?
    func getCategory(for itemId: String) -> Category?
    func getCategoryName(for itemId: String) -> String?
    func clearCaches()
}

@MainActor
/// Item operations: create/update/delete items and look them up.
protocol VaultItemManaging {
    func addItem(name: String, to category: GroceryCategory, store: String, price: Double, unit: String) -> Bool
    func updateItem(item: Item, newName: String, newCategory: GroceryCategory, newStore: String, newPrice: Double, newUnit: String) -> Bool
    func deleteItem(_ item: Item)
    func getAllItems() -> [Item]
    func findItemById(_ itemId: String) -> Item?
    func findItemsByName(_ name: String) -> [Item]
}

@MainActor
/// Store operations: add/rename/delete stores and list known stores.
protocol VaultStoreManaging {
    func addStore(_ storeName: String)
    func getAllStores() -> [String]
    func getMostRecentStore() -> String?
    func ensureStoreExists(_ storeName: String)
    func renameStore(oldName: String, newName: String)
    func deleteStore(_ storeName: String)
}

@MainActor
/// Cart operations: create/delete carts and keep totals up to date.
protocol VaultCartManaging {
    func createCart(name: String, budget: Double) -> Cart
    func createCartWithActiveItems(name: String, budget: Double, activeItems: [String: Double]) -> Cart
    func deleteCart(_ cart: Cart)
    func updateCartName(cart: Cart, newName: String)
    func updateCartBudget(cart: Cart, newBudget: Double)
    func updateCartTotals(cart: Cart)
}

@MainActor
/// Shopping workflow: start/finish trips and update items while shopping.
protocol VaultShoppingManaging {
    func startShopping(cart: Cart)
    func completeShopping(cart: Cart)
    func reopenCart(cart: Cart)
    func returnToPlanning(cart: Cart)
    func addVaultItemToCart(item: Item, cart: Cart, quantity: Double, selectedStore: String?)
    func addVaultItemToCartDuringShopping(item: Item, store: String, price: Double, unit: String, cart: Cart, quantity: Double)
    func addShoppingItemToCart(name: String, store: String, price: Double, unit: String, cart: Cart, quantity: Double, category: GroceryCategory?)
    func removeItemFromCart(cart: Cart, itemId: String)
    func updateCartItemActualData(cart: Cart, itemId: String, actualPrice: Double?, actualQuantity: Double?, actualUnit: String?, actualStore: String?)
    func changeCartItemStore(cart: Cart, itemId: String, newStore: String)
    func toggleItemFulfillment(cart: Cart, itemId: String)
}

@MainActor
/// Insights helpers derived from carts and completed trips.
protocol VaultInsightsProviding {
    func getCartInsights(cart: Cart) -> CartInsights
    func getTotalFulfilledAmount(for cart: Cart) -> Double
    func getTotalCartValue(for cart: Cart) -> Double
    func getCurrentFulfillmentPercentage(for cart: Cart) -> Double
    func getItemPriceHistory(for itemId: String) -> [VaultService.PriceHistoryPoint]
}

extension VaultService: VaultUserManaging {}
extension VaultService: VaultCategoryManaging {}
extension VaultService: VaultItemManaging {}
extension VaultService: VaultStoreManaging {}
extension VaultService: VaultCartManaging {}
extension VaultService: VaultShoppingManaging {}
extension VaultService: VaultInsightsProviding {}
