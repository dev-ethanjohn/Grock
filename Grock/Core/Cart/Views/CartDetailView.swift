import SwiftUI
import SwiftData

struct CartDetailView: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    
    // Mode management
    @State private var showingDeleteAlert = false
    @State private var editingItem: CartItem?
    @State private var showingEditSheet = false
    @State private var showingCompleteAlert = false
    @State private var showingStartShoppingAlert = false
    
    // Filter state
    @State private var selectedFilter: FilterOption = .all
    
    private var cartInsights: CartInsights {
        vaultService.getCartInsights(cart: cart)
    }
    
    // Group items by store
    private var itemsByStore: [String: [(cartItem: CartItem, item: Item?)]] {
        let cartItemsWithDetails = cart.cartItems.map { cartItem in
            (cartItem, vaultService.findItemById(cartItem.itemId))
        }
        
        return Dictionary(grouping: cartItemsWithDetails) { cartItem, item in
            cartItem.getStore(cart: cart)
        }
    }
    
    private var sortedStores: [String] {
        itemsByStore.keys.sorted()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with cart name and totals
            headerView
            
            // Filter bar
            filterBarView
            
            // Items list grouped by store
            itemsListView
            
            // Footer with progress and actions
            footerView
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
//        .sheet(isPresented: $showingEditSheet) {
//            if let editingItem = editingItem,
//               let item = vaultService.findItemById(editingItem.itemId) {
//                EditItemSheet(
//                    item: item,
//                    cartItem: editingItem,
//                    cart: cart,
//                    isPresented: $showingEditSheet,
//                    onSave: { updatedItem in
//                        vaultService.updateCartTotals(cart: cart)
//                    },
//                    context: .cart
//                )
//                .environment(vaultService)
//            }
//        }
        .alert("Start Shopping", isPresented: $showingStartShoppingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Start Shopping") {
                vaultService.startShopping(cart: cart)
            }
        } message: {
            Text("This will freeze your planned prices. You'll be able to update actual prices during shopping.")
        }
        .alert("Complete Shopping", isPresented: $showingCompleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                vaultService.completeShopping(cart: cart)
            }
        } message: {
            Text("This will preserve your shopping data for review.")
        }
        .alert("Delete Cart", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                vaultService.deleteCart(cart)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this cart? This action cannot be undone.")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Back button and cart name
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(cart.name)
                        .font(.fuzzyBold_20)
                        .foregroundColor(.black)
                    
                    // Mode badge
                    Text(cart.status.displayName.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(cart.status.color)
                        .cornerRadius(6)
                }
                
                Spacer()
                
                Menu {
                    // Mode-specific actions
                    if cart.isPlanning {
                        Button("Start Shopping", systemImage: "cart") {
                            showingStartShoppingAlert = true
                        }
                    } else if cart.isShopping {
                        Button("Complete Shopping", systemImage: "checkmark.circle") {
                            showingCompleteAlert = true
                        }
                    } else if cart.isCompleted {
                        Button("Reactivate Cart", systemImage: "arrow.clockwise") {
                            vaultService.reopenCart(cart: cart)
                        }
                    }
                    
                    Divider()
                    
                    Button("Delete Cart", systemImage: "trash", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                }
            }
            
            // Total and budget
            VStack(spacing: 8) {
                HStack {
                    Text("\(formatCurrency(cart.totalSpent))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Text("\(formatCurrency(cart.budget))")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                // Budget progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)
                        
                        Rectangle()
                            .fill(budgetProgressColor)
                            .frame(width: min(progressWidth(for: geometry.size.width), geometry.size.width), height: 6)
                    }
                    .cornerRadius(3)
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - Filter Bar
    private var filterBarView: some View {
        HStack {
            Text("Filter:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            Picker("Filter", selection: $selectedFilter) {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Items count
            Text("\(cart.cartItems.count) items")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    // MARK: - Items List View
    private var itemsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sortedStores, id: \.self) { store in
                    if let storeItems = itemsByStore[store] {
                        StoreSectionView(
                            store: store,
                            items: storeItems,
                            cart: cart,
                            onToggleFulfillment: { cartItem in
                                if cart.isShopping {
                                    vaultService.toggleItemFulfillment(cart: cart, itemId: cartItem.itemId)
                                }
                            },
                            onEditItem: { cartItem in
                                editingItem = cartItem
                                showingEditSheet = true
                            }
                        )
                        .environment(vaultService)
                    }
                }
            }
        }
    }
    
    // MARK: - Footer View
    private var footerView: some View {
        VStack(spacing: 16) {
            // Progress summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(sortedStores.count) stores • \(cart.cartItems.filter { $0.isFulfilled }.count)/\(cart.cartItems.count) items")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                    
                    if cart.isShopping {
                        Text("\(Int(cart.fulfillmentStatus * 100))% fulfilled")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                
                Spacer()
                
                // Mode-specific action buttons
                if cart.isPlanning {
                    Button("Start Shopping") {
                        showingStartShoppingAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                } else if cart.isShopping {
                    Button("Complete Shopping") {
                        showingCompleteAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.white)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    
    private var budgetProgressColor: Color {
        let progress = cart.totalSpent / cart.budget
        if progress < 0.7 {
            return .green
        } else if progress < 0.9 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let progress = cart.totalSpent / cart.budget
        return CGFloat(progress) * totalWidth
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PHP"
        formatter.maximumFractionDigits = value == Double(Int(value)) ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "₱\(value)"
    }
}

// MARK: - Supporting Types

enum FilterOption: String, CaseIterable {
    case all = "All"
    case fulfilled = "Fulfilled"
    case unfulfilled = "Unfulfilled"
}

struct StoreSectionView: View {
    let store: String
    let items: [(cartItem: CartItem, item: Item?)]
    let cart: Cart
    let onToggleFulfillment: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        VStack(spacing: 0) {
            // Store header
            HStack {
                Text(store)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Store total
                Text(storeTotal)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            
            // Items in this store
            LazyVStack(spacing: 0) {
                ForEach(items, id: \.cartItem.itemId) { cartItem, item in
                    CartItemRowView(
                        cartItem: cartItem,
                        item: item,
                        cart: cart,
                        onToggleFulfillment: {
                            onToggleFulfillment(cartItem)
                        },
                        onEditItem: {
                            onEditItem(cartItem)
                        }
                    )
                    .environment(vaultService)
                    
                    if cartItem.itemId != items.last?.cartItem.itemId {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color.white)
        }
        .padding(.bottom, 16)
    }
    
    private var storeTotal: String {
        guard let vault = vaultService.vault else { return "" }
        
        let total = items.reduce(0.0) { sum, itemData in
            sum + itemData.cartItem.getTotalPrice(from: vault, cart: cart)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PHP"
        formatter.maximumFractionDigits = 2
        
        return formatter.string(from: NSNumber(value: total)) ?? ""
    }
}

struct CartItemRowView: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onToggleFulfillment: () -> Void
    let onEditItem: () -> Void
    
    @Environment(VaultService.self) private var vaultService
    
    private var itemName: String {
        item?.name ?? "Unknown Item"
    }
    
    private var price: Double {
        guard let vault = vaultService.vault else { return 0.0 }
        return cartItem.getPrice(from: vault, cart: cart)
    }
    
    private var unit: String {
        guard let vault = vaultService.vault else { return "" }
        return cartItem.getUnit(from: vault, cart: cart)
    }
    
    private var quantity: Double {
        cartItem.getQuantity(cart: cart)
    }
    
    private var totalPrice: Double {
        guard let vault = vaultService.vault else { return 0.0 }
        return cartItem.getTotalPrice(from: vault, cart: cart)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox (only in shopping mode)
            if cart.isShopping {
                Button(action: onToggleFulfillment) {
                    Image(systemName: cartItem.isFulfilled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundColor(cartItem.isFulfilled ? .green : .gray)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Item name and quantity
                HStack {
                    Text("\(quantityString) \(itemName)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(cartItem.isFulfilled && cart.isShopping ? .gray : .black)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formatCurrency(totalPrice))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(cartItem.isFulfilled && cart.isShopping ? .gray : .black)
                }
                
                // Price per unit and edit buttons
                HStack {
                    Text("\(formatCurrency(price)) / \(unit)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Single edit button
                    Button("Edit") {
                        onEditItem()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private var quantityString: String {
        let qty = cartItem.getQuantity(cart: cart)
        if qty == Double(Int(qty)) {
            return "\(Int(qty))"
        } else {
            return "\(qty)"
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PHP"
        formatter.maximumFractionDigits = value == Double(Int(value)) ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "₱\(value)"
    }
}
