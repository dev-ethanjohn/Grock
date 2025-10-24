import SwiftUI
import SwiftData

struct CartDetailScreen: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    
    // modes
    @State private var showingDeleteAlert = false
    @State private var editingItem: CartItem?
    @State private var showingEditSheet = false
    @State private var showingCompleteAlert = false
    @State private var showingStartShoppingAlert = false
    
    // filter
    @State private var selectedFilter: FilterOption = .all
    @State private var showingFilterSheet = false
    
    @State private var headerHeight: CGFloat = 0
    
    private var cartInsights: CartInsights {
        vaultService.getCartInsights(cart: cart)
    }
    
    // group items by store with stable sorting
    private var itemsByStore: [String: [(cartItem: CartItem, item: Item?)]] {
        // Sort cartItems by itemId to ensure consistent order
        let sortedCartItems = cart.cartItems.sorted { $0.itemId < $1.itemId }
        let cartItemsWithDetails = sortedCartItems.map { cartItem in
            (cartItem, vaultService.findItemById(cartItem.itemId))
        }
        
        return Dictionary(grouping: cartItemsWithDetails) { cartItem, item in
            cartItem.getStore(cart: cart)
        }
    }
    
    private var sortedStores: [String] {
        itemsByStore.keys.sorted()
    }
    
    // Calculate total items across all stores
    private var totalItemCount: Int {
        cart.cartItems.count
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 12) {
                modeToggleView
                
                itemsListView
                
                Spacer(minLength: 0)
                
                footerView
            }
            .padding(.vertical, 40)
            .padding(.horizontal)
            .frame(maxHeight: .infinity, alignment: .top)
            
            headerView
        }
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
        VStack(alignment: .leading, spacing: 12) {
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
            
            VStack(alignment: .leading, spacing: 8) {
                Text(cart.name)
                    .lexendFont(22, weight: .bold)
                    .foregroundColor(.black)
                
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        BudgetProgressBar(cart: cart, budgetProgressColor: budgetProgressColor, progressWidth: progressWidth)
                        
                        Text(cart.budget.formattedCurrency)
                            .lexendFont(14, weight: .bold)
                            .foregroundColor(Color(hex: "333"))
                    }
                    .frame(height: 22)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .background(
            GeometryReader { geometry in
                Color.white
                    .ignoresSafeArea(edges: .top)
                    .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 1)
                    .onAppear {
                        headerHeight = geometry.size.height
                    }
                    .onChange(of: geometry.size.height) { oldValue, newValue in
                        headerHeight = newValue
                    }
            }
        )
    }
    
    private var modeToggleView: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                Button(action: {
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
            
            Button(action: {
                showingFilterSheet = true
            }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
            
            Button(action: {
            }) {
                Image(systemName: "circle")
                    .font(.system(size: 24))
                    .foregroundColor(.black)
            }
        }
        .padding(.top, headerHeight)
        .background(Color.white)
    }
    
    private var itemsListView: some View {
        Group {
            if totalItemCount <= 7 {
                VStack(spacing: 0) {
                    ForEach(sortedStores, id: \.self) { store in
                        if let storeItems = itemsByStore[store] {
                            StoreSectionView(
                                store: store,
                                items: storeItems,
                                cart: cart,
                                onToggleFulfillment: { cartItem in
                                    if cart.isShopping {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            vaultService.toggleItemFulfillment(cart: cart, itemId: cartItem.itemId)
                                        }
                                    }
                                },
                                onEditItem: { cartItem in
                                    editingItem = cartItem
                                    showingEditSheet = true
                                },
                                isLastStore: store == sortedStores.last,
                                isInScrollableView: false
                            )
                            .environment(vaultService)
                            .id(store)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.leading, 12)
            } else {
                VerticalScrollViewWithCustomIndicator(maxHeight: 500, indicatorVerticalPadding: 12) {
                    VStack(spacing: 0) {
                        ForEach(sortedStores, id: \.self) { store in
                            if let storeItems = itemsByStore[store] {
                                StoreSectionView(
                                    store: store,
                                    items: storeItems,
                                    cart: cart,
                                    onToggleFulfillment: { cartItem in
                                        if cart.isShopping {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                                vaultService.toggleItemFulfillment(cart: cart, itemId: cartItem.itemId)
                                            }
                                        }
                                    },
                                    onEditItem: { cartItem in
                                        editingItem = cartItem
                                        showingEditSheet = true
                                    },
                                    isLastStore: store == sortedStores.last,
                                    isInScrollableView: true
                                )
                                .environment(vaultService)
                                .id(store)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.leading, 12)
                }
            }
        }
        .background(Color(hex: "FAFAFA").darker(by: 0.03))
        .cornerRadius(16)
    }
    
    private var footerView: some View {
        VStack(spacing: 16) {
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
    
    private var budgetProgressColor: Color {
        let progress = cart.totalSpent / cart.budget
        if progress < 0.7 {
            return Color(hex: "98F476")
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
