import SwiftUI
import SwiftData
import Charts

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
                        
                        // Section 2: Store Patterns (Free)
                        StorePatternsSection(viewModel: viewModel)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Section 3: Budget Reflections (Pro)
                        ProGatedSection(
                            title: "Budget Reflections",
                            subtitle: "Based on budgeted trips",
                            lockText: "See how your spending compares to what you planned.",
                            isPro: subscriptionManager.isPro,
                            onUnlock: { print("Show RevenueCat Paywall") }
                        ) {
                            BudgetInsightsSection(viewModel: viewModel)
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Section 4: Behavior Comparison (Pro)
                        ProGatedSection(
                            title: "Behavior",
                            subtitle: "With vs without a budget",
                            lockText: "Understand how planning changes your shopping.",
                            isPro: subscriptionManager.isPro,
                            onUnlock: { print("Show RevenueCat Paywall") }
                        ) {
                            BehaviorComparisonSection(viewModel: viewModel)
                        }
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Section 5: Item Memory (Pro)
                        ProGatedSection(
                            title: "Item Memory",
                            subtitle: "Frequently bought items",
                            lockText: "Build long-term price memory across trips.",
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
    let subtitle: String
    let lockText: String
    let isPro: Bool
    let onUnlock: () -> Void
    let content: Content
    
    init(
        title: String,
        subtitle: String,
        lockText: String,
        isPro: Bool,
        onUnlock: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.lockText = lockText
        self.isPro = isPro
        self.onUnlock = onUnlock
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header is always visible
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .lexendFont(18, weight: .semibold)
                    if !isPro {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                Text(subtitle)
                    .lexendFont(14)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            ZStack {
                // Content
                content
                    .blur(radius: isPro ? 0 : 8)
                    .disabled(!isPro)
                    .opacity(isPro ? 1 : 0.6)
                    .allowsHitTesting(isPro)
                
                if !isPro {
                    // Lock Overlay
                    VStack(spacing: 16) {
                        Text(lockText)
                            .lexendFont(16, weight: .medium)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black.opacity(0.8))
                            .padding(.horizontal)
                        
                        Button(action: onUnlock) {
                            Text("Unlock Pro")
                                .lexendFont(14, weight: .semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.black)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.9))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    )
                    .padding(24)
                }
            }
        }
    }
}


// MARK: - Section 1: Spending Overview
private struct SpendingOverviewSection: View {
    let viewModel: InsightsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Spending Overview")
                .lexendFont(18, weight: .semibold)
                .padding(.horizontal)
            
            // Subtle monthly line graph
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.recentTrips.isEmpty {
                    // Empty State Graph
                    Chart {
                        RuleMark(y: .value("Amount", 0))
                            .foregroundStyle(Color.gray.opacity(0.1))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 180)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 24))
                                .foregroundColor(.gray.opacity(0.4))
                            Text("No recent activity")
                                .lexendFont(14)
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                } else {
                    Chart(viewModel.recentTrips) { trip in
                        LineMark(
                            x: .value("Date", trip.date),
                            y: .value("Amount", trip.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .symbol {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { value in
                            AxisValueLabel(format: .dateTime.day().month())
                        }
                    }
                    .chartYAxis(.hidden)
                    .frame(height: 180)
                }
            }
            .padding(.horizontal)
            
            // Horizontal metric cards
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
                if viewModel.storeStats.isEmpty {
                     Text("Not enough data yet")
                        .lexendFont(14)
                        .foregroundColor(.gray)
                        .padding()
                } else {
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
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        }
    }
}

// MARK: - Section 3: Budget Reflections
private struct BudgetInsightsSection: View {
    let viewModel: InsightsViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Card 1: Budgeted Trips
                OverviewCard(
                    title: "Budgeted Trips",
                    value: "\(viewModel.budgetedTripsCount)",
                    subtitle: "Planned shopping"
                )
                
                // Card 2: Variance (Net)
                OverviewCard(
                    title: "Avg Variance",
                    value: viewModel.avgBudgetVariance.formattedCurrency,
                    subtitle: viewModel.avgBudgetVariance >= 0 ? "Over budget" : "Under budget"
                )
                
                // Card 3: Typical Deviation (Absolute)
                OverviewCard(
                    title: "Typical Deviation",
                    value: viewModel.avgAbsoluteBudgetDeviation.formattedCurrency,
                    subtitle: "Avg. difference"
                )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Section 4: Behavior Comparison
private struct BehaviorComparisonSection: View {
    let viewModel: InsightsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Comparison Bars
            VStack(spacing: 16) {
                // With Budget
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("With Budget")
                            .lexendFont(14, weight: .medium)
                        Spacer()
                        Text(viewModel.avgSpendBudgeted.formattedCurrency)
                            .lexendFont(14, weight: .semibold)
                    }
                    
                    GeometryReader { geo in
                        let maxSpend = max(viewModel.avgSpendBudgeted, viewModel.avgSpendUnbudgeted)
                        let width = maxSpend > 0 ? (viewModel.avgSpendBudgeted / maxSpend) * geo.size.width : 0
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black)
                            .frame(width: width, height: 12)
                    }
                    .frame(height: 12)
                }
                
                // Without Budget
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Without Budget")
                            .lexendFont(14, weight: .medium)
                        Spacer()
                        Text(viewModel.avgSpendUnbudgeted.formattedCurrency)
                            .lexendFont(14, weight: .semibold)
                    }
                    
                    GeometryReader { geo in
                        let maxSpend = max(viewModel.avgSpendBudgeted, viewModel.avgSpendUnbudgeted)
                        let width = maxSpend > 0 ? (viewModel.avgSpendUnbudgeted / maxSpend) * geo.size.width : 0
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: width, height: 12)
                    }
                    .frame(height: 12)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            
            // Insight Text
            if viewModel.spendDifferencePercentage != 0 {
                let percent = abs(Int(viewModel.spendDifferencePercentage * 100))
                let direction = viewModel.spendDifferencePercentage > 0 ? "more" : "less"
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.gray)
                    Text("You spend about \(percent)% \(direction) without a budget.")
                        .lexendFont(14)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Section 5: Item Memory
private struct ItemMemorySection: View {
    let viewModel: InsightsViewModel
    let vaultService: VaultService
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.frequentItems.isEmpty {
                Text("Keep shopping to build item history")
                   .lexendFont(14)
                   .foregroundColor(.gray)
                   .padding()
            } else {
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
        }
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
    
    private func resolveItemName(id: String, fallback: String) -> String {
        // Try to find the item in the vault to get the most up-to-date name
        if let vaultItem = vaultService.findItemById(id) {
            return vaultItem.name
        }
        return fallback
    }
}
