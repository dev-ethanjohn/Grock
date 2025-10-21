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
    @State private var showingFilterSheet = false
    
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
            
            // Mode toggle and filter bar
            modeToggleView
            
            // Items list grouped by store
            itemsListView
            
            // Footer with progress and actions
            footerView
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showingEditSheet) {
            if let editingItem = editingItem,
               let item = vaultService.findItemById(editingItem.itemId) {
                EditItemSheet(
                    item: item,
                    isPresented: $showingEditSheet,
                    onSave: { updatedItem in
                        vaultService.updateCartTotals(cart: cart)
                    },
                    context: .cart
                )
                .environment(vaultService)
            }
        }
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
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(selectedFilter: $selectedFilter)
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            //MARK: toolbar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                Spacer()
                Menu {
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
                }
            }
   
                
            Text(cart.name)
                .lexendFont(22, weight: .bold)
                .foregroundColor(.black)
                .padding(.top, 4)
            
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
    
    // MARK: - Mode Toggle View
    private var modeToggleView: some View {
        HStack(spacing: 12) {
            // Planning/Shopping Toggle - Simple UI toggle only
            HStack(spacing: 0) {
                Button(action: {
                    // Just visual toggle - don't change actual cart status
                    if cart.status == .shopping {
                        cart.status = .planning
                        vaultService.updateCartTotals(cart: cart)
                    }
                }) {
                    Text("Planning")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(cart.isPlanning ? .white : .black)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(cart.isPlanning ? Color.black : Color.clear)
                        .cornerRadius(8)
                }
                .disabled(cart.isCompleted)
                
                Button(action: {
                    // Just visual toggle - don't change actual cart status
                    if cart.status == .planning {
                        cart.status = .shopping
                        vaultService.updateCartTotals(cart: cart)
                    }
                }) {
                    Text("Shopping")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(cart.isShopping ? .white : .black)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(cart.isShopping ? Color.black : Color.clear)
                        .cornerRadius(8)
                }
                .disabled(cart.isCompleted)
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            Spacer()
            
            // Filter icon (hamburger lines in circle)
            Button(action: {
                showingFilterSheet = true
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
            
            // Empty filter icon (circle outline)
            Button(action: {
                // Future filter functionality
            }) {
                Image(systemName: "circle")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
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
                            .padding(.leading, cart.isShopping ? 52 : 16)
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
            // Checkbox (only visible in shopping mode)
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

// MARK: - Filter Sheet
struct FilterSheet: View {
    @Binding var selectedFilter: FilterOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedFilter = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .foregroundColor(.black)
                            Spacer()
                            if selectedFilter == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
