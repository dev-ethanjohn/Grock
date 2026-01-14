import Foundation
import SwiftData
import SwiftUI

/*
@Observable
class InsightsViewModel {
    var completedCarts: [Cart] = []
    
    enum TimeRange: String, CaseIterable {
        case sevenDays = "7 Days"
        case month = "Month"
    }
    
    var selectedTimeRange: TimeRange = .month {
        didSet { calculateTrendInsights() }
    }
    var selectedDate: Date = Date() {
        didSet { calculateTrendInsights() }
    }
    
    var currentPeriodTotalSpent: Double = 0
    var trendPercentage: Double = 0
    var graphData: [TripData] = []
    
    var totalSpentAllTime: Double = 0
    var totalSpentLast30Days: Double = 0
    var avgSpendPerTrip: Double = 0
    var avgItemsPerTrip: Double = 0
    
    struct TripData: Identifiable {
        let id: UUID
        let date: Date
        let amount: Double
        let index: Int
    }
    var recentTrips: [TripData] = []
    var allTrips: [TripData] = []
    
    struct StoreStat: Identifiable {
        let id = UUID()
        let name: String
        let totalSpend: Double
        let visitCount: Int
        var avgSpend: Double { totalSpend / Double(max(1, visitCount)) }
    }
    var storeStats: [StoreStat] = []
    
    var hasBudgetData: Bool = false
    var budgetedTripsCount: Int = 0
    var avgBudgetVariance: Double = 0
    var avgAbsoluteBudgetDeviation: Double = 0
    var budgetAccuracy: Double = 0
    
    var avgSpendBudgeted: Double = 0
    var avgSpendUnbudgeted: Double = 0
    var spendDifferencePercentage: Double = 0
    
    struct ItemStat: Identifiable {
        let id: String
        let name: String
        let frequency: Int
        let avgPrice: Double
        let lastPrice: Double
        let priceVolatility: Double
    }
    var frequentItems: [ItemStat] = []
    
    init(carts: [Cart] = []) {
        self.completedCarts = carts
        calculateInsights()
    }
    
    func update(carts: [Cart]) {
        self.completedCarts = carts.filter { $0.isCompleted }
        calculateInsights()
        calculateTrendInsights()
    }
    
    func navigateMonth(_ value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func calculateTrendInsights() {
        let calendar = Calendar.current
        var currentCarts: [Cart] = []
        var previousCarts: [Cart] = []
        
        switch selectedTimeRange {
        case .sevenDays:
            let today = Date()
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today)!
            let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: today)!
            
            currentCarts = completedCarts.filter {
                guard let date = $0.completedAt else { return false }
                return date >= sevenDaysAgo && date <= today
            }
            
            previousCarts = completedCarts.filter {
                guard let date = $0.completedAt else { return false }
                return date >= fourteenDaysAgo && date < sevenDaysAgo
            }
            
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            let startOfPrevMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth)!
            
            currentCarts = completedCarts.filter {
                guard let date = $0.completedAt else { return false }
                return date >= startOfMonth && date < endOfMonth
            }
            
            previousCarts = completedCarts.filter {
                guard let date = $0.completedAt else { return false }
                return date >= startOfPrevMonth && date < startOfMonth
            }
        }
        
        currentPeriodTotalSpent = currentCarts.reduce(0) { $0 + $1.totalSpent }
        let previousTotal = previousCarts.reduce(0) { $0 + $1.totalSpent }
        
        if previousTotal > 0 {
            trendPercentage = (currentPeriodTotalSpent - previousTotal) / previousTotal
        } else {
            trendPercentage = currentPeriodTotalSpent > 0 ? 1.0 : 0.0
        }
        
        var dailyTotals: [Date: Double] = [:]
        for cart in currentCarts {
            let date = calendar.startOfDay(for: cart.completedAt ?? Date())
            dailyTotals[date, default: 0] += cart.totalSpent
        }
        
        graphData = dailyTotals.sorted { $0.key < $1.key }.enumerated().map { (index, entry) in
            TripData(id: UUID(), date: entry.key, amount: entry.value, index: index)
        }
    }
    
    private func calculateInsights() {
        guard !completedCarts.isEmpty else {
            resetStats()
            return
        }
        
        totalSpentAllTime = completedCarts.reduce(0) { $0 + $1.totalSpent }
        
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentCarts = completedCarts.filter { $0.completedAt ?? Date() >= thirtyDaysAgo }
        totalSpentLast30Days = recentCarts.reduce(0) { $0 + $1.totalSpent }
        
        if !recentCarts.isEmpty {
            avgSpendPerTrip = totalSpentLast30Days / Double(recentCarts.count)
            let totalItems = recentCarts.reduce(0) { $0 + $1.totalItemsCount }
            avgItemsPerTrip = Double(totalItems) / Double(recentCarts.count)
        } else {
            avgSpendPerTrip = 0
            avgItemsPerTrip = 0
        }
        
        let sortedAllCarts = completedCarts.sorted { ($0.completedAt ?? Date()) < ($1.completedAt ?? Date()) }
        allTrips = sortedAllCarts.enumerated().map { (index, cart) in
            TripData(
                id: UUID(),
                date: cart.completedAt ?? Date(),
                amount: cart.totalSpent,
                index: index
            )
        }
        
        let recentCarts = completedCarts.filter { $0.completedAt ?? Date() >= thirtyDaysAgo }
        recentTrips = recentCarts.enumerated().map { (index, cart) in
            TripData(
                id: UUID(),
                date: cart.completedAt ?? Date(),
                amount: cart.totalSpent,
                index: index
            )
        }.sorted { $0.date < $1.date }
        
        var storeSpend: [String: Double] = [:]
        var storeVisits: [String: Int] = [:]
        
        for cart in completedCarts {
            var currentCartStoreTotals: [String: Double] = [:]
            
            for item in cart.cartItems {
                let store = item.actualStore ?? item.plannedStore
                let price = item.actualPrice ?? item.plannedPrice ?? 0
                let qty = item.actualQuantity ?? item.quantity
                let lineTotal = price * qty
                currentCartStoreTotals[store, default: 0] += lineTotal
            }
            
            for (store, total) in currentCartStoreTotals {
                storeSpend[store, default: 0] += total
                storeVisits[store, default: 0] += 1
            }
        }
        
        storeStats = storeSpend.map { (store, total) in
            StoreStat(name: store, totalSpend: total, visitCount: storeVisits[store] ?? 0)
        }.sorted { $0.totalSpend > $1.totalSpend }
        
        let budgetedCarts = completedCarts.filter { $0.budget > 0 }
        budgetedTripsCount = budgetedCarts.count
        hasBudgetData = budgetedTripsCount > 0
        
        if hasBudgetData {
            let totalVariance = budgetedCarts.reduce(0) { $0 + ($1.totalSpent - $1.budget) }
            avgBudgetVariance = totalVariance / Double(budgetedTripsCount)
            
            let totalAbsDeviation = budgetedCarts.reduce(0) { $0 + abs($1.totalSpent - $1.budget) }
            avgAbsoluteBudgetDeviation = totalAbsDeviation / Double(budgetedTripsCount)
        }
        
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
        
        var itemCounts: [String: Int] = [:]
        var itemNames: [String: String] = [:]
        var itemPrices: [String: [Double]] = [:]
        var itemLastPrices: [String: Double] = [:]
        
        let sortedCarts = completedCarts.sorted { ($0.completedAt ?? Date()) < ($1.completedAt ?? Date()) }
        
        for cart in sortedCarts {
            for cartItem in cart.cartItems where cartItem.isFulfilled {
                let id = cartItem.itemId
                itemCounts[id, default: 0] += 1
                
                if itemNames[id] == nil {
                    if cartItem.isShoppingOnlyItem {
                        itemNames[id] = cartItem.shoppingOnlyName ?? "Unknown Item"
                    }
                }
                
                let price = cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
                if price > 0 {
                    itemPrices[id, default: []].append(price)
                    itemLastPrices[id] = price
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
        avgAbsoluteBudgetDeviation = 0
        avgSpendBudgeted = 0
        avgSpendUnbudgeted = 0
        spendDifferencePercentage = 0
        frequentItems = []
    }
}
*/
