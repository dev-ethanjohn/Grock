import SwiftUI
import SwiftData

struct CartDetailScreen: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    // modes
    @State private var showingDeleteAlert = false
    @State private var editingItem: CartItem?
    @State private var showingCompleteAlert = false
    @State private var showingStartShoppingAlert = false
    
    // filter
    @State private var selectedFilter: FilterOption = .all
    @State private var showingFilterSheet = false
    
    @State private var headerHeight: CGFloat = 0
    
    @State private var animatedFulfilledAmount: Double = 0
    @State private var animatedFulfilledPercentage: Double = 0
    
    // ✅ SIMPLIFIED: Use only item binding for sheet
    @State private var itemToEdit: Item? = nil
    
    // ✅ NEW: State for showing VaultView
    @State private var showingVaultView = false
    
    private var cartInsights: CartInsights {
        vaultService.getCartInsights(cart: cart)
    }
    
    // group items by store with stable sorting
    private var itemsByStore: [String: [(cartItem: CartItem, item: Item?)]] {
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
    
    private var totalItemCount: Int {
        cart.cartItems.count
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack (alignment: .bottom){
                ZStack(alignment: .top) {
                    VStack(spacing: 12) {
                        modeToggleView
                        
                        itemsListView
                        
                        Spacer(minLength: 0)
                        
                    }
                    .padding(.vertical, 40)
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity, alignment: .top)
                    
                    headerView
                }
                
                footerView
                    .padding(.leading)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                
                Button(action: {
                    // ✅ UPDATED: Open VaultView to add items
                    showingVaultView = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.black)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                
            }
        }
        .navigationBarBackButtonHidden(true)
        // ✅ SIMPLIFIED: Use item binding for sheet
        .sheet(item: $itemToEdit) { item in
            EditItemSheet(
                item: item,
                onSave: { updatedItem in
                    vaultService.updateCartTotals(cart: cart)
                },
                context: .cart
            )
            .environment(vaultService)
            .presentationDetents([.medium, .fraction(0.75)])
            .presentationCornerRadius(24)
        }
        // ✅ NEW: Sheet for VaultView - USE EXISTING CartViewModel
        .sheet(isPresented: $showingVaultView) {
            NavigationView {
                VaultView(
                    // ✅ Pass the current cart so we can add items directly to it
                    existingCart: cart,
                    onAddItemsToCart: { selectedItems in
                        // Handle adding selected items to the current cart
                        for (itemId, quantity) in selectedItems {
                            if let item = vaultService.findItemById(itemId) {
                                vaultService.addItemToCart(item: item, cart: cart, quantity: quantity)
                            }
                        }
                        vaultService.updateCartTotals(cart: cart)
                        showingVaultView = false
                        // ✅ DON'T clear activeCartItems - they persist for next use
                    }
                )
                .environment(vaultService)
                // ✅ USE EXISTING CartViewModel from environment (not creating new one)
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
                    .onChange(of: geometry.size.height) {_, newValue in
                        headerHeight = newValue
                    }
            }
        )
    }
    
    private var modeToggleView: some View {
        HStack(spacing: 0) {
            ZStack {
                Color(hex: "EEEEEE")
                    .frame(width: 176, height: 26)
                    .cornerRadius(16)
                
                HStack {
                    if cart.isShopping {
                        Spacer()
                    }
                    Color.white
                        .frame(width: 88, height: 30)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0.5, y: 1)
                    if cart.isPlanning {
                        Spacer()
                    }
                }
                .frame(width: 176)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cart.status)
                
                
                HStack(spacing: 0) {
                    Button(action: {
                        if cart.status == .shopping {
                            cart.status = .planning
                            vaultService.updateCartTotals(cart: cart)
                        }
                    }) {
                        Text("Planning")
                            .lexendFont(12, weight: cart.isPlanning ? .bold : .medium)
                            .foregroundColor(cart.isPlanning ? .black : Color(hex: "999999"))
                            .frame(width: 88, height: 26)
                            .animation(.easeInOut(duration: 0.2), value: cart.isPlanning)
                    }
                    .disabled(cart.isCompleted)
                    
                    Button(action: {
                        if cart.status == .planning {
                            cart.status = .shopping
                            vaultService.updateCartTotals(cart: cart)
                        }
                    }) {
                        Text("Shopping")
                            .lexendFont(12, weight: cart.isShopping ? .bold : .medium)
                            .foregroundColor(cart.isShopping ? .black : Color(hex: "999999"))
                            .frame(width: 88, height: 26)
                            .animation(.easeInOut(duration: 0.2), value: cart.isShopping)
                    }
                    .disabled(cart.isCompleted)
                }
            }
            .frame(width: 176, height: 30)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: {
                    showingFilterSheet = true
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .fontWeight(.light)
                        .foregroundColor(.black)
                    
                }
                .padding(1.5)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 0.5)
                
                
                Text("|")
                    .lexendFont(16, weight: .thin)
                
                Button(action: {
                    // Future filter functionality
                }) {
                    Image(systemName: "circle")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .fontWeight(.light)
                        .foregroundColor(.black)
                    
                }
                .padding(1.5)
                .background(.white)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 0.5)
            }
        }
        .padding(.top, headerHeight)
        .background(Color.white)
    }
    
    private var itemsListView: some View {
        Group {
            if totalItemCount <= 7 {
                VStack(spacing: 0) {
                    ForEach(sortedStores.indices, id: \.self) { index in
                        let store = sortedStores[index]
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
                                    if let found = vaultService.findItemById(cartItem.itemId) {
                                        print("🟢 Setting item to edit: \(found.name)")
                                        itemToEdit = found
                                    }
                                },
                                onDeleteItem: { cartItem in
                                    handleDeleteItem(cartItem)
                                },
                                isLastStore: store == sortedStores.last,
                                isInScrollableView: false
                            )
                            .padding(.top, index == 0 ? 0 : 20)
                        }
                    }
                }
                .padding(.vertical, 12)
            } else {
                VerticalScrollViewWithCustomIndicator(maxHeight: 500, indicatorVerticalPadding: 12) {
                    VStack(spacing: 0) {
                        ForEach(sortedStores.indices, id: \.self) { index in
                            let store = sortedStores[index]
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
                                        if let item = vaultService.findItemById(cartItem.itemId) {
                                            print("🟢 Setting item to edit: \(item.name)")
                                            itemToEdit = item
                                        }
                                    },
                                    onDeleteItem: { cartItem in
                                        handleDeleteItem(cartItem)
                                    },
                                    isLastStore: store == sortedStores.last,
                                    isInScrollableView: true
                                )
                                .padding(.top, index == 0 ? 0 : 20)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(hex: "FAFAFA").darker(by: 0.03))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var footerView: some View {
        if cart.isShopping {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(cart.fulfilledItemsCount)/\(cart.totalItemsCount) items for ₱\(animatedFulfilledAmount, specifier: "%.2f")")
                    .fuzzyBubblesFont(15, weight: .bold)
                    .foregroundColor(.gray)
                    .contentTransition(.numericText(value: animatedFulfilledAmount))
                
                Text("\(Int(animatedFulfilledPercentage))% fulfilled")
                    .fuzzyBubblesFont(15, weight: .bold)
                    .foregroundColor(.gray)
                    .contentTransition(.numericText(value: animatedFulfilledPercentage))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                updateAnimatedValues()
            }
            .onChange(of: cart.fulfilledItemsCount) { oldValue, newValue in
                updateAnimatedValues()
            }
            .onChange(of: vaultService.getTotalFulfilledAmount(for: cart)) { oldValue, newValue in
                updateAnimatedValues()
            }
        }
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
    
    private func updateAnimatedValues() {
        withAnimation(.smooth(duration: 0.5)) {
            animatedFulfilledAmount = vaultService.getTotalFulfilledAmount(for: cart)
            animatedFulfilledPercentage = vaultService.getCurrentFulfillmentPercentage(for: cart)
        }
    }
    
    private func handleDeleteItem(_ cartItem: CartItem) {
        withTransaction(Transaction(animation: nil)) {
            vaultService.removeItemFromCart(cart: cart, itemId: cartItem.itemId)
            vaultService.updateCartTotals(cart: cart)
        }
    }
}
