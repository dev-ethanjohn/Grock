import Foundation
import SwiftData
import SwiftUI

@Observable
class InsightsViewModel {
    // Input data
    var completedCarts: [Cart] = []
    
    // MARK: - Section 1: Spending Overview
    var totalSpentAllTime: Double = 0
    var totalSpentLast30Days: Double = 0
    var avgSpendPerTrip: Double = 0
    var avgItemsPerTrip: Double = 0
    
    // MARK: - Section 2: Store & Price Patterns
    struct StoreStat: Identifiable {
        let id = UUID()
        let name: String
        let totalSpend: Double
        let visitCount: Int
        var avgSpend: Double { totalSpend / Double(max(1, visitCount)) }
    }
    var storeStats: [StoreStat] = []
    
    // MARK: - Section 3: Budget-Aware Insights
    var hasBudgetData: Bool = false
    var budgetedTripsCount: Int = 0
    var avgBudgetVariance: Double = 0 // Positive = over budget, Negative = under
    var budgetAccuracy: Double = 0 // Percentage difference
    
    // MARK: - Section 4: Behavior Comparison
    var avgSpendBudgeted: Double = 0
    var avgSpendUnbudgeted: Double = 0
    var spendDifferencePercentage: Double = 0 // (Unbudgeted - Budgeted) / Budgeted
    
    // MARK: - Section 5: Item-Level Memory
    struct ItemStat: Identifiable {
        let id: String
        let name: String
        let frequency: Int
        let avgPrice: Double
        let lastPrice: Double
        let priceVolatility: Double // (Max - Min) / Min
    }
    var frequentItems: [ItemStat] = []
    
    init(carts: [Cart] = []) {
        self.completedCarts = carts
        calculateInsights()
    }
    
    func update(carts: [Cart]) {
        self.completedCarts = carts.filter { $0.isCompleted }
        calculateInsights()
    }
    
    private func calculateInsights() {
        guard !completedCarts.isEmpty else {
            resetStats()
            return
        }
        
        // 1. Spending Overview
        totalSpentAllTime = completedCarts.reduce(0) { $0 + $1.totalSpent }
        avgSpendPerTrip = totalSpentAllTime / Double(completedCarts.count)
        
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentCarts = completedCarts.filter { $0.completedAt ?? Date() >= thirtyDaysAgo }
        totalSpentLast30Days = recentCarts.reduce(0) { $0 + $1.totalSpent }
        
        let totalItems = completedCarts.reduce(0) { $0 + $1.totalItemsCount }
        avgItemsPerTrip = Double(totalItems) / Double(completedCarts.count)
        
        // 2. Store Stats
        var storeSpend: [String: Double] = [:]
        var storeVisits: [String: Int] = [:]
        
        for cart in completedCarts {
            // Determine primary store for the cart?
            // Or aggregate items by store?
            // "Average spend by store" implies we track how much we spend at "Trader Joe's" vs "Whole Foods".
            // Since a cart can have multiple stores, we should aggregate item totals by store.
            
            var currentCartStoreTotals: [String: Double] = [:]
            
            for item in cart.cartItems {
                let store = item.actualStore ?? item.plannedStore
                let price = item.actualPrice ?? item.plannedPrice ?? 0
                let qty = item.actualQuantity ?? item.quantity
                // Only count fulfilled items? Or all? Completed cart items are usually fulfilled or have final data.
                // Vault.swift: totalSpent uses actualPrice/Quantity for completed status.
                // Let's stick to totalSpent logic:
                let lineTotal = price * qty
                currentCartStoreTotals[store, default: 0] += lineTotal
            }
            
            for (store, total) in currentCartStoreTotals {
                storeSpend[store, default: 0] += total
                storeVisits[store, default: 0] += 1 // Count this cart as a visit to this store
            }
        }
        
        storeStats = storeSpend.map { (store, total) in
            StoreStat(name: store, totalSpend: total, visitCount: storeVisits[store] ?? 0)
        }.sorted { $0.totalSpend > $1.totalSpend }
        
        // 3. Budget Insights
        let budgetedCarts = completedCarts.filter { $0.budget > 0 }
        budgetedTripsCount = budgetedCarts.count
        hasBudgetData = budgetedTripsCount > 0
        
        if hasBudgetData {
            let totalVariance = budgetedCarts.reduce(0) { $0 + ($1.totalSpent - $1.budget) }
            avgBudgetVariance = totalVariance / Double(budgetedTripsCount)
            
            // Accuracy: How close to budget?
            // Let's use simple variance percentage relative to budget
            // Or maybe avg absolute error?
            // Prompt says: "Average over/under budget" (calculated above) and "Typical variance".
        }
        
        // 4. Behavior Comparison
        let unbudgetedCarts = completedCarts.filter { $0.budget <= 0 }
        
        if !budgetedCarts.isEmpty {
            avgSpendBudgeted = budgetedCarts.reduce(0) { $0 + $1.totalSpent } / Double(budgetedCarts.count)
        }
        
        if !unbudgetedCarts.isEmpty {
            avgSpendUnbudgeted = unbudgetedCarts.reduce(0) { $0 + $1.totalSpent } / Double(unbudgetedCarts.count)
        }
        
        if avgSpendBudgeted > 0 {
            spendDifferencePercentage = (avgSpendUnbudgeted - avgSpendBudgeted) / avgSpendBudgeted
        } else {
            spendDifferencePercentage = 0
        }
        
        // 5. Item Memory
        // Count fulfilled items
        var itemCounts: [String: Int] = [:]
        var itemNames: [String: String] = [:]
        var itemPrices: [String: [Double]] = [:]
        var itemLastPrices: [String: Double] = [:] // Store last seen price
        
        // Sort carts by date ascending to track price history correctly
        let sortedCarts = completedCarts.sorted { ($0.completedAt ?? Date()) < ($1.completedAt ?? Date()) }
        
        for cart in sortedCarts {
            for cartItem in cart.cartItems where cartItem.isFulfilled {
                let id = cartItem.itemId
                itemCounts[id, default: 0] += 1
                
                // Get name (either from vault item or shopping only name)
                if itemNames[id] == nil {
                     if cartItem.isShoppingOnlyItem {
                         itemNames[id] = cartItem.shoppingOnlyName ?? "Unknown Item"
                     }
                }
                
                let price = cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
                if price > 0 {
                    itemPrices[id, default: []].append(price)
                    itemLastPrices[id] = price // Update last price (carts are sorted)
                }
            }
        }
        
        frequentItems = itemCounts.map { (id, count) in
            let prices = itemPrices[id] ?? []
            let avgPrice = prices.reduce(0, +) / Double(max(1, prices.count))
            let lastPrice = itemLastPrices[id] ?? avgPrice
            
            var volatility: Double = 0
            if let minPrice = prices.min(), let maxPrice = prices.max(), minPrice > 0 {
                volatility = (maxPrice - minPrice) / minPrice
            }
            
            // Name will be resolved in View or we assume we can get it later
            return ItemStat(
                id: id,
                name: itemNames[id] ?? "",
                frequency: count,
                avgPrice: avgPrice,
                lastPrice: lastPrice,
                priceVolatility: volatility
            )
        }.sorted { $0.frequency > $1.frequency }.prefix(5).map { $0 }
    }
    
    private func resetStats() {
        totalSpentAllTime = 0
        totalSpentLast30Days = 0
        avgSpendPerTrip = 0
        avgItemsPerTrip = 0
        storeStats = []
        hasBudgetData = false
        budgetedTripsCount = 0
        avgBudgetVariance = 0
        avgSpendBudgeted = 0
        avgSpendUnbudgeted = 0
        spendDifferencePercentage = 0
        frequentItems = []
    }
}
