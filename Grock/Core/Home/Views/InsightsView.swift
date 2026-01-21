import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    
    private var recentCompletedCarts: [Cart] {
        let carts = vaultService.vault?.carts ?? []
        return carts
            .filter { $0.status == .completed }
            .sorted { ($0.completedAt ?? $0.updatedAt) > ($1.completedAt ?? $1.updatedAt) }
    }
    
    private var monthCompletedCarts: [Cart] {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: comps) else { return [] }
        return recentCompletedCarts.filter { ( $0.completedAt ?? $0.updatedAt ) >= startOfMonth }
    }
    
    private var monthPlannedTotal: Double {
        monthCompletedCarts.reduce(0) { acc, cart in
            let vault = vaultService.vault
            let planned = cart.cartItems.reduce(0) { sum, ci in
                let price = ci.plannedPrice ?? (vault != nil ? ci.getCurrentPrice(from: vault!, store: ci.plannedStore) ?? 0 : 0)
                let qty = ci.quantity
                return sum + price * qty
            }
            return acc + planned
        }
    }
    
    private var monthActualTotal: Double {
        monthCompletedCarts.reduce(0) { acc, cart in
            acc + cart.totalSpent
        }
    }
    
    private var monthDifference: Double {
        monthActualTotal - monthPlannedTotal
    }
    
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("This Month")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(monthActualTotal.formattedCurrency)
                                    .font(.title3.weight(.semibold))
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Trips")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(monthCompletedCarts.count)")
                                    .font(.title3.weight(.semibold))
                            }
                        }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Planned")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(monthPlannedTotal.formattedCurrency)
                                    .font(.headline)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Difference")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(monthDifference.formattedCurrency)
                                    .font(.headline)
                                    .foregroundColor(monthDifference >= 0 ? .red : .green)
                            }
                        }
                        NavigationLink(destination: InsightsDetailView()
                            .environment(vaultService)
                            .environment(cartViewModel)
                        ) {
                            Text("Open Insights")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.black)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .frame(height: geo.size.height * 0.5)
                    .background(Color(.systemGray6))
                    
                    VStack(spacing: 0) {
                        if recentCompletedCarts.isEmpty {
                            VStack(spacing: 12) {
                                Spacer()
                                Text("No completed trips yet")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(hex: "#F9F9F9"))
                        } else {
                            List {
                                Section {
                                    ForEach(recentCompletedCarts, id: \.id) { cart in
                                        NavigationLink {
                                            CompletedCartDetailView(cart: cart)
                                                .environment(vaultService)
                                                .environment(cartViewModel)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(cart.name)
                                                        .font(.headline)
                                                    Text(cart.completedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Completed")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                                Spacer()
                                                Text(cart.totalSpent.formattedCurrency)
                                                    .font(.headline)
                                            }
                                        }
                                    }
                                } header: {
                                    Text("Recent Trips")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                    .frame(height: geo.size.height * 0.5)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CompletedCartDetailView: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    
    private var plannedTotal: Double {
        let vault = vaultService.vault
        return cart.cartItems.reduce(0) { sum, ci in
            let price = ci.plannedPrice ?? (vault != nil ? ci.getCurrentPrice(from: vault!, store: ci.plannedStore) ?? 0 : 0)
            let qty = ci.quantity
            return sum + price * qty
        }
    }
    
    private var actualTotal: Double {
        cart.totalSpent
    }
    
    private var difference: Double {
        actualTotal - plannedTotal
    }
    
    private var completedItems: [CartItem] {
        cart.cartItems.filter { $0.isFulfilled }
    }
    
    private var skippedItems: [CartItem] {
        cart.cartItems.filter { $0.isSkippedDuringShopping }
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Planned Total")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(plannedTotal.formattedCurrency)
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Actual Total")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(actualTotal.formattedCurrency)
                            .font(.headline)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Difference")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(difference.formattedCurrency)
                            .font(.headline)
                            .foregroundColor(difference >= 0 ? .red : .green)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Trip Summary")
            }
            
            if !completedItems.isEmpty {
                Section {
                    ForEach(completedItems, id: \.itemId) { ci in
                        CompletedItemRow(ci: ci, cart: cart)
                            .environment(vaultService)
                    }
                } header: {
                    Text("Completed Items")
                }
            }
            
            if !skippedItems.isEmpty {
                Section {
                    ForEach(skippedItems, id: \.itemId) { ci in
                        SkippedItemRow(ci: ci)
                            .environment(vaultService)
                    }
                } header: {
                    Text("Skipped Items")
                }
            }
        }
        .navigationTitle(cart.name)
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
    }
}

private struct CompletedItemRow: View {
    let ci: CartItem
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    
    private var itemName: String {
        vaultService.findItemById(ci.itemId)?.name ?? ci.shoppingOnlyName ?? "Unknown Item"
    }
    
    private var store: String {
        ci.getStore(cart: cart)
    }
    
    private var unit: String {
        ci.getUnit(from: vaultService.vault ?? Vault(), cart: cart)
    }
    
    private var qty: Double {
        ci.actualQuantity ?? ci.quantity
    }
    
    private var price: Double {
        ci.actualPrice ?? ci.plannedPrice ?? 0
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(itemName)
                    .font(.subheadline)
                Text("\(store) • \(unit)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(price.formattedCurrency) × \(qty.formattedQuantity)")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text((price * qty).formattedCurrency)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SkippedItemRow: View {
    let ci: CartItem
    @Environment(VaultService.self) private var vaultService
    
    private var itemName: String {
        vaultService.findItemById(ci.itemId)?.name ?? ci.shoppingOnlyName ?? "Unknown Item"
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(itemName)
                    .font(.subheadline)
                Text("Skipped")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct InsightsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "chart.bar.xaxis")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color.black.opacity(0.2))
                Text("Insights Preview")
                    .font(.title3.weight(.semibold))
                Text("Detailed insights will arrive in a future update.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline.bold())
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                Spacer().frame(height: 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#F9F9F9"))
            .navigationTitle("Insights Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
