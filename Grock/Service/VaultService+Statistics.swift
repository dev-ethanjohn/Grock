import Foundation
import SwiftData

// MARK: - Item Statistics
/// Small helpers used for charts/insights (like “price over time”).
///
/// In plain terms:
/// - Every completed trip can produce a “data point” for an item’s price graph.
extension VaultService {
    
    /// A single historical price point for an item, taken from a completed cart.
    struct PriceHistoryPoint: Identifiable {
        let id = UUID()
        let date: Date
        let price: Double
        let store: String
        let unit: String
    }
    
    /// Fetches price history for a specific item from completed carts.
    ///
    /// Included:
    /// - Only carts with `status == .completed`.
    /// - Only items that were fulfilled in that cart.
    /// - Uses `actualPrice` when present; falls back to `plannedPrice`.
    ///
    /// Not included:
    /// - Manual vault edits outside of a completed shopping trip (those aren’t “purchase events”).
    func getItemPriceHistory(for itemId: String) -> [PriceHistoryPoint] {
        guard let vault = vault else { return [] }
        
        var history: [PriceHistoryPoint] = []
        
        // Filter completed carts
        let completedCarts = vault.carts.filter { $0.status == .completed }
        
        for cart in completedCarts {
            // Find the item in this cart
            if let cartItem = cart.cartItems.first(where: { $0.itemId == itemId && $0.isFulfilled }) {
                // Use actual price if available, otherwise planned price
                if let price = cartItem.actualPrice ?? cartItem.plannedPrice, price > 0 {
                    let store = cartItem.actualStore ?? cartItem.plannedStore
                    let unit = cartItem.actualUnit ?? cartItem.plannedUnit ?? ""
                    
                    history.append(PriceHistoryPoint(
                        date: cart.completedAt ?? cart.updatedAt,
                        price: price,
                        store: store,
                        unit: unit
                    ))
                }
            }
        }
        
        // Sort by date ascending
        return history.sorted { $0.date < $1.date }
    }
}
