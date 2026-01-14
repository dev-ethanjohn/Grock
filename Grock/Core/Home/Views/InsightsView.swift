import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = InsightsViewModel()
    @State private var subscriptionManager = SubscriptionManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    if viewModel.completedCarts.isEmpty {
                        emptyStateView
                    } else {
                        // Section 1: Spending Overview (Free)
                        SpendingOverviewSection(viewModel: viewModel)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Section 2: Store & Price Patterns (Free)
                        StorePatternsSection(viewModel: viewModel)
                        
                        // Section 3: Budget-Aware Insights (Pro)
                        if viewModel.hasBudgetData {
                            Divider()
                                .padding(.horizontal)
                            
                            ProGatedSection(
                                title: "Budget Reflections",
                                description: "Understand your budgeting habits and accuracy.",
                                isPro: subscriptionManager.isPro,
                                onUnlock: { print("Show RevenueCat Paywall") }
                            ) {
                                VStack(spacing: 32) {
                                    BudgetInsightsSection(viewModel: viewModel)
                                    BehaviorComparisonSection(viewModel: viewModel)
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Section 5: Item-Level Memory (Pro)
                        ProGatedSection(
                            title: "Item Memory",
                            description: "See your purchasing history and price trends.",
                            isPro: subscriptionManager.isPro,
                            onUnlock: { print("Show RevenueCat Paywall") }
                        ) {
                            ItemMemorySection(viewModel: viewModel, vaultService: vaultService)
                        }
                    }
                }
                .padding(.vertical, 24)
            }
            .background(Color(hex: "#F9F9F9"))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .lexendFont(16, weight: .semibold)
                }
            }
            .onAppear {
                viewModel.update(carts: cartViewModel.carts)
            }
            .onChange(of: cartViewModel.carts) { _, newCarts in
                viewModel.update(carts: newCarts)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            Text("No completed trips yet")
                .lexendFont(18, weight: .medium)
                .foregroundColor(.gray)
            Text("Finish a shopping trip to see insights.")
                .lexendFont(14)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(height: 400)
    }
}

// MARK: - Pro Gated Section Component
struct ProGatedSection<Content: View>: View {
    let title: String
    let description: String
    let isPro: Bool
    let onUnlock: () -> Void
    let content: Content
    
    init(
        title: String,
        description: String,
        isPro: Bool,
        onUnlock: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.isPro = isPro
        self.onUnlock = onUnlock
        self.content = content()
    }
    
    var body: some View {
        if isPro {
            content
        } else {
            VStack(alignment: .leading, spacing: 16) {
                // Header is always visible
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .lexendFont(18, weight: .semibold)
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    Text(description)
                        .lexendFont(14)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                ZStack {
                    // Blurred content
                    content
                        .blur(radius: 10)
                        .opacity(0.6)
                        .allowsHitTesting(false)
                        .overlay(Color.white.opacity(0.1))
                    
                    // Unlock overlay
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.black)
                        
                        Text("Unlock Pro Insights")
                            .lexendFont(18, weight: .bold)
                            .foregroundColor(.black)
                        
                        Button(action: onUnlock) {
                            Text("Unlock Pro")
                                .lexendFont(14, weight: .semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.black)
                                .cornerRadius(20)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}


// MARK: - Section 1: Spending Overview
private struct SpendingOverviewSection: View {
    let viewModel: InsightsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Overview")
                .lexendFont(18, weight: .semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    OverviewCard(
                        title: "Avg Spend / Trip",
                        value: viewModel.avgSpendPerTrip.formattedCurrency,
                        subtitle: "Based on all trips"
                    )
                    
                    OverviewCard(
                        title: "30-Day Total",
                        value: viewModel.totalSpentLast30Days.formattedCurrency,
                        subtitle: "Recent activity"
                    )
                    
                    OverviewCard(
                        title: "Avg Items",
                        value: String(format: "%.0f", viewModel.avgItemsPerTrip),
                        subtitle: "Per trip"
                    )
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct OverviewCard: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .lexendFont(12, weight: .medium)
                .foregroundColor(.gray)
            
            Text(value)
                .lexendFont(24, weight: .bold)
                .foregroundColor(.black)
            
            Text(subtitle)
                .lexendFont(10)
                .foregroundColor(.gray.opacity(0.8))
        }
        .padding(16)
        .frame(width: 160, height: 110, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Section 2: Store Patterns
private struct StorePatternsSection: View {
    let viewModel: InsightsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Store Patterns")
                    .lexendFont(18, weight: .semibold)
                Text("Where your money goes")
                    .lexendFont(14)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(viewModel.storeStats.prefix(5)) { store in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.name.isEmpty ? "Unknown Store" : store.name)
                                .lexendFont(16, weight: .medium)
                            Text("\(store.visitCount) visits")
                                .lexendFont(12)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(store.avgSpend.formattedCurrency)
                                .lexendFont(16, weight: .semibold)
                            Text("avg / trip")
                                .lexendFont(10)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(16)
                    
                    if store.id != viewModel.storeStats.prefix(5).last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Section 3: Budget Insights
private struct BudgetInsightsSection: View {
    let viewModel: InsightsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Budget Reflections")
                    .lexendFont(18, weight: .semibold)
                Text("Based on \(viewModel.budgetedTripsCount) budgeted trips")
                    .lexendFont(14)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                // Variance Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Typical Variance")
                        .lexendFont(12, weight: .medium)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Text(viewModel.avgBudgetVariance >= 0 ? "+" : "")
                            .lexendFont(24, weight: .bold)
                            .foregroundColor(.gray)
                        Text(abs(viewModel.avgBudgetVariance).formattedCurrency)
                            .lexendFont(24, weight: .bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text(viewModel.avgBudgetVariance >= 0 ? "Over budget avg" : "Under budget avg")
                        .lexendFont(12)
                        .foregroundColor(.gray.opacity(0.8))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Section 4: Behavior Comparison
private struct BehaviorComparisonSection: View {
    let viewModel: InsightsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Behavior")
                    .lexendFont(18, weight: .semibold)
                Text("With vs. Without Budget")
                    .lexendFont(14)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 20) {
                // Insight Text
                if viewModel.spendDifferencePercentage != 0 {
                    let percent = abs(Int(viewModel.spendDifferencePercentage * 100))
                    let direction = viewModel.spendDifferencePercentage > 0 ? "more" : "less"
                    Text("You spend about \(percent)% \(direction) on trips without a budget.")
                        .lexendFont(16, weight: .medium)
                        .foregroundColor(Color(hex: "231F30"))
                        .padding(.bottom, 8)
                }
                
                // Bar Chart
                VStack(spacing: 12) {
                    // Budgeted Bar
                    HStack {
                        Text("With Budget")
                            .lexendFont(12, weight: .medium)
                            .foregroundColor(.gray)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geo in
                            let maxSpend = max(viewModel.avgSpendBudgeted, viewModel.avgSpendUnbudgeted)
                            let width = maxSpend > 0 ? (viewModel.avgSpendBudgeted / maxSpend) * geo.size.width : 0
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black.opacity(0.8))
                                .frame(width: width, height: 24)
                        }
                        .frame(height: 24)
                        
                        Text(viewModel.avgSpendBudgeted.formattedCurrency)
                            .lexendFont(12, weight: .medium)
                            .frame(width: 60, alignment: .trailing)
                    }
                    
                    // Unbudgeted Bar
                    HStack {
                        Text("No Budget")
                            .lexendFont(12, weight: .medium)
                            .foregroundColor(.gray)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geo in
                            let maxSpend = max(viewModel.avgSpendBudgeted, viewModel.avgSpendUnbudgeted)
                            let width = maxSpend > 0 ? (viewModel.avgSpendUnbudgeted / maxSpend) * geo.size.width : 0
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: width, height: 24)
                        }
                        .frame(height: 24)
                        
                        Text(viewModel.avgSpendUnbudgeted.formattedCurrency)
                            .lexendFont(12, weight: .medium)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Section 5: Item Memory
private struct ItemMemorySection: View {
    let viewModel: InsightsViewModel
    let vaultService: VaultService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Item Memory")
                    .lexendFont(18, weight: .semibold)
                Text("Frequently bought items")
                    .lexendFont(14)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(viewModel.frequentItems) { itemStat in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(resolveItemName(id: itemStat.id, fallback: itemStat.name))
                                .lexendFont(16, weight: .medium)
                            Text("Bought \(itemStat.frequency) times")
                                .lexendFont(12)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(itemStat.lastPrice.formattedCurrency)
                                .lexendFont(16, weight: .semibold)
                            
                            HStack(spacing: 4) {
                                Text("avg")
                                    .foregroundColor(.gray)
                                Text(itemStat.avgPrice.formattedCurrency)
                                    .foregroundColor(.gray)
                            }
                            .lexendFont(10)
                            
                            if itemStat.priceVolatility > 0.1 {
                                Text("Variable price")
                                    .lexendFont(9)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(16)
                    
                    if itemStat.id != viewModel.frequentItems.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }
    
    private func resolveItemName(id: String, fallback: String) -> String {
        if !fallback.isEmpty && fallback != "Unknown Item" {
            return fallback
        }
        return vaultService.findItemById(id)?.name ?? "Unknown Item"
    }
}
