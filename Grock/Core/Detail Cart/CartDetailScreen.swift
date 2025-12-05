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
    @State private var showingSwitchToPlanningAlert = false
    
    @State private var anticipationOffset: CGFloat = 0
    
    // filter
    @State private var selectedFilter: FilterOption = .all
    @State private var showingFilterSheet = false
    
    @State private var headerHeight: CGFloat = 0
    
    @State private var animatedFulfilledAmount: Double = 0
    @State private var animatedFulfilledPercentage: Double = 0
    
    @State private var itemToEdit: Item? = nil
    
    @State private var showingVaultView = false
    
    @State private var previousHasItems = false
    
    // Celebration state
    @State private var showCelebration = false
    
    @State private var manageCartButtonVisible = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var shouldBounceAfterCelebration = false
    
    // Loading state
    @State private var cartReady = false
    
    // Refresh trigger for synchronization
    @State private var refreshTrigger = UUID()
    
    private var cartInsights: CartInsights {
        vaultService.getCartInsights(cart: cart)
    }
    
    private var itemsByStore: [String: [(cartItem: CartItem, item: Item?)]] {
        let sortedCartItems = cart.cartItems.sorted { $0.itemId < $1.itemId }
        let cartItemsWithDetails = sortedCartItems.map { cartItem in
            (cartItem, vaultService.findItemById(cartItem.itemId))
        }
        let grouped = Dictionary(grouping: cartItemsWithDetails) { cartItem, item in
            cartItem.getStore(cart: cart)
        }
        return grouped.filter { !$0.key.isEmpty && !$0.value.isEmpty }
    }
    
    // Add refresh-aware computed property
    private var itemsByStoreWithRefresh: [String: [(cartItem: CartItem, item: Item?)]] {
        _ = refreshTrigger // Force recalculation when refreshTrigger changes
        
        let sortedCartItems = cart.cartItems.sorted { $0.itemId < $1.itemId }
        let cartItemsWithDetails = sortedCartItems.map { cartItem in
            (cartItem, vaultService.findItemById(cartItem.itemId))
        }
        let grouped = Dictionary(grouping: cartItemsWithDetails) { cartItem, item in
            cartItem.getStore(cart: cart)
        }
        return grouped.filter { !$0.key.isEmpty && !$0.value.isEmpty }
    }
    
    private var sortedStores: [String] {
        Array(itemsByStore.keys).sorted()
    }
    
    private var sortedStoresWithRefresh: [String] {
        Array(itemsByStoreWithRefresh.keys).sorted()
    }
    
    private var totalItemCount: Int {
        cart.cartItems.count
    }
    
    private var hasItems: Bool {
        totalItemCount > 0 && !sortedStores.isEmpty
    }
    
    private var shouldAnimateTransition: Bool {
        previousHasItems != hasItems
    }
    
    private func storeItems(for store: String) -> [(cartItem: CartItem, item: Item?)] {
        itemsByStore[store] ?? []
    }
    
    private func storeItemsWithRefresh(for store: String) -> [(cartItem: CartItem, item: Item?)] {
        itemsByStoreWithRefresh[store] ?? []
    }
    
    var body: some View {
        CartDetailContent(
            cart: cart,
            cartInsights: cartInsights,
            itemsByStore: itemsByStore,
            itemsByStoreWithRefresh: itemsByStoreWithRefresh,
            sortedStores: sortedStores,
            sortedStoresWithRefresh: sortedStoresWithRefresh,
            totalItemCount: totalItemCount,
            hasItems: hasItems,
            shouldAnimateTransition: shouldAnimateTransition,
            storeItems: storeItems(for:),
            storeItemsWithRefresh: storeItemsWithRefresh(for:),
            showingDeleteAlert: $showingDeleteAlert,
            editingItem: $editingItem,
            showingCompleteAlert: $showingCompleteAlert,
            showingStartShoppingAlert: $showingStartShoppingAlert,
            showingSwitchToPlanningAlert: $showingSwitchToPlanningAlert,
            anticipationOffset: $anticipationOffset,
            selectedFilter: $selectedFilter,
            showingFilterSheet: $showingFilterSheet,
            headerHeight: $headerHeight,
            animatedFulfilledAmount: $animatedFulfilledAmount,
            animatedFulfilledPercentage: $animatedFulfilledPercentage,
            itemToEdit: $itemToEdit,
            showingVaultView: $showingVaultView,
            previousHasItems: $previousHasItems,
            showCelebration: $showCelebration,
            manageCartButtonVisible: $manageCartButtonVisible,
            buttonScale: $buttonScale,
            shouldBounceAfterCelebration: $shouldBounceAfterCelebration,
            cartReady: $cartReady,
            refreshTrigger: $refreshTrigger
        )
        .onAppear {
            previousHasItems = hasItems
            checkAndShowCelebration()
        }
        .onChange(of: hasItems) { oldValue, newValue in
            if oldValue != newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    previousHasItems = newValue
                }
            }
        }
        .onChange(of: cartReady) { oldValue, newValue in
            if newValue && !showCelebration {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 3.0, dampingFraction: 0.6)) {
                        manageCartButtonVisible = true
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(item: $itemToEdit) { item in
            EditItemSheet(
                item: item,
                onSave: { updatedItem in
                    
                    vaultService.updateCartTotals(cart: cart)
                    refreshTrigger = UUID()
                },
                context: .cart
            )
            .environment(vaultService)
            .presentationDetents([.medium, .fraction(0.75)])
            .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showingVaultView) {
            // This closure runs when sheet is dismissed
            print("🔄 Manage cart sheet dismissed - refreshing cart data")
            vaultService.updateCartTotals(cart: cart)
            refreshTrigger = UUID() // Force refresh
        } content: {
            NavigationStack {
                ManageCartSheet(cart: cart)
                    .environment(vaultService)
                    .environment(cartViewModel)
            }
            .presentationCornerRadius(24)
        }
        .alert("Start Shopping", isPresented: $showingStartShoppingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Start Shopping") {
                vaultService.startShopping(cart: cart)
                refreshTrigger = UUID()
            }
        } message: {
            Text("This will freeze your planned prices. You'll be able to update actual prices during shopping.")
        }
        .alert("Switch to Planning", isPresented: $showingSwitchToPlanningAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Switch to Planning") {
                cart.status = .planning
                vaultService.updateCartTotals(cart: cart)
                refreshTrigger = UUID()
            }
        } message: {
            Text("Switching back to planning mode will unfreeze planned prices and allow you to modify your shopping list.")
        }
        .alert("Complete Shopping", isPresented: $showingCompleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                vaultService.completeShopping(cart: cart)
                refreshTrigger = UUID()
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
    
    private func checkAndShowCelebration() {
        let hasSeenCelebration = UserDefaults.standard.bool(forKey: "hasSeenFirstShoppingCartCelebration")
        
        print("🎉 Cart Celebration Debug:")
        print(" - hasSeenCelebration: \(hasSeenCelebration)")
        print(" - Total carts: \(cartViewModel.carts.count)")
        print(" - Current cart name: \(cart.name)")
        print(" - Current cart ID: \(cart.id)")
        
        guard !hasSeenCelebration else {
            print("⏭️ Skipping first cart celebration - already seen")
            manageCartButtonVisible = true
            return
        }
        
        let isFirstCart = cartViewModel.carts.count == 1 || cartViewModel.isFirstCart(cart)
        print(" - Is first cart: \(isFirstCart)")
        
        if isFirstCart {
            print("🎉 First cart celebration triggered!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showCelebration = true
            }
            UserDefaults.standard.set(true, forKey: "hasSeenFirstShoppingCartCelebration")
        } else {
            print("⏭️ Not the first cart - no celebration")
        }
    }
}


struct CartDetailContent: View {
    let cart: Cart
    let cartInsights: CartInsights
    let itemsByStore: [String: [(cartItem: CartItem, item: Item?)]]
    let itemsByStoreWithRefresh: [String: [(cartItem: CartItem, item: Item?)]]
    let sortedStores: [String]
    let sortedStoresWithRefresh: [String]
    let totalItemCount: Int
    let hasItems: Bool
    let shouldAnimateTransition: Bool
    let storeItems: (String) -> [(cartItem: CartItem, item: Item?)]
    let storeItemsWithRefresh: (String) -> [(cartItem: CartItem, item: Item?)]
    
    @Binding var showingDeleteAlert: Bool
    @Binding var editingItem: CartItem?
    @Binding var showingCompleteAlert: Bool
    
    @Binding var showingStartShoppingAlert: Bool
    @Binding var showingSwitchToPlanningAlert: Bool
    
    @Binding var anticipationOffset: CGFloat
    
    // filter
    @Binding var selectedFilter: FilterOption
    @Binding var showingFilterSheet: Bool
    
    @Binding var headerHeight: CGFloat
    
    @Binding var animatedFulfilledAmount: Double
    @Binding var animatedFulfilledPercentage: Double
    
    @Binding var itemToEdit: Item?
    
    @Binding var showingVaultView: Bool
    
    @Binding var previousHasItems: Bool
    
    // Celebration state
    @Binding var showCelebration: Bool
    
    @Binding var manageCartButtonVisible: Bool
    @Binding var buttonScale: CGFloat
    @Binding var shouldBounceAfterCelebration: Bool
    
    // Loading state
    @Binding var cartReady: Bool
    
    // Refresh trigger for synchronization
    @Binding var refreshTrigger: UUID
    
    // NEW: State for budget editing
    @State private var showEditBudget = false
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content area
                if cartReady {
                    ZStack(alignment: .top) {
                        VStack(spacing: 12) {
                            ModeToggleView(
                                cart: cart,
                                anticipationOffset: $anticipationOffset,
                                showingStartShoppingAlert: $showingStartShoppingAlert,
                                showingSwitchToPlanningAlert: $showingSwitchToPlanningAlert,
                                headerHeight: $headerHeight,
                                refreshTrigger: $refreshTrigger
                            )
                            
                            ZStack {
                                if hasItems {
                                    VStack(spacing: 24) {
                                        ItemsListView(
                                            cart: cart,
                                            totalItemCount: totalItemCount,
                                            sortedStoresWithRefresh: sortedStoresWithRefresh,
                                            storeItemsWithRefresh: storeItemsWithRefresh,
                                            onToggleFulfillment: { cartItem in
                                                if cart.isShopping {
                                                    vaultService.toggleItemFulfillment(cart: cart, itemId: cartItem.itemId)
                                                    refreshTrigger = UUID()
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
                                            }
                                        )
                                        .transition(.scale)
                                        
                                        FooterView(
                                            cart: cart,
                                            animatedFulfilledAmount: $animatedFulfilledAmount,
                                            animatedFulfilledPercentage: $animatedFulfilledPercentage,
                                            shouldAnimateTransition: shouldAnimateTransition,
                                            geometry: geometry
                                        )
                                    }
                                } else {
                                    EmptyStateView()
                                        .transition(.scale)
                                }
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: hasItems)
                            
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                        .frame(maxHeight: .infinity, alignment: .top)
                        
                        HeaderView(
                            cart: cart,
                            showingDeleteAlert: $showingDeleteAlert,
                            showingCompleteAlert: $showingCompleteAlert,
                            showingStartShoppingAlert: $showingStartShoppingAlert,
                            headerHeight: $headerHeight,
                            dismiss: dismiss,
                            onBudgetTap: {
                                showEditBudget = true
                            }
                        )
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                                cartReady = true
                            }
                        }
                }
                
                // Edit budget popover (will appear above main content)
                if showEditBudget {
                    EditBudgetPopover(
                        isPresented: $showEditBudget,
                        cart: cart,
                        onSave: { newBudget in
                            vaultService.updateCartTotals(cart: cart)
                            refreshTrigger = UUID()
                        },
                        onDismiss: nil
                    )
                    .environment(vaultService)
                    .zIndex(1000)
                }
                
                // Celebration overlay (on top of everything)
                if showCelebration {
                    CelebrationView(
                        isPresented: $showCelebration,
                        title: "WOW! Your First Shopping Cart! 🎉",
                        subtitle: nil
                    )
                    .transition(.scale)
                    .zIndex(1001)
                }
            }
            .overlay(alignment: .bottom) {
                if !showCelebration && manageCartButtonVisible {
                    Button(action: {
                        showingVaultView = true
                    }) {
                        Text("Manage Cart")
                            .fuzzyBubblesFont(16, weight: .bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .cornerRadius(25)
                    }
                    .transition(.scale)
                    .scaleEffect(showEditBudget ? 0 : buttonScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
                    .animation(.easeInOut(duration: 0.2), value: showEditBudget)
                    .ignoresSafeArea(.keyboard)
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private func handleDeleteItem(_ cartItem: CartItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            vaultService.removeItemFromCart(cart: cart, itemId: cartItem.itemId)
            vaultService.updateCartTotals(cart: cart)
            refreshTrigger = UUID()
        }
    }
}


struct HeaderView: View {
    let cart: Cart
    @Binding var showingDeleteAlert: Bool
    @Binding var showingCompleteAlert: Bool
    @Binding var showingStartShoppingAlert: Bool
    @Binding var headerHeight: CGFloat
    let dismiss: DismissAction
    
    var onBudgetTap: (() -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    
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
    
    var body: some View {
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
            .padding(.top)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(cart.name)
                    .lexendFont(22, weight: .bold)
                    .foregroundColor(.black)
                
                VStack(spacing: 8) {
                    HStack(alignment: .center, spacing: 8) {
                        BudgetProgressBar(cart: cart, budgetProgressColor: budgetProgressColor, progressWidth: progressWidth)
                        
                        Button(action: {
                            onBudgetTap?()
                        }) {
                            Text(cart.budget.formattedCurrency)
                                .lexendFont(14, weight: .bold)
                                .foregroundColor(Color(hex: "333"))
                        }
                        .buttonStyle(.plain)
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
}

struct ModeToggleView: View {
    let cart: Cart
    @Binding var anticipationOffset: CGFloat
    @Binding var showingStartShoppingAlert: Bool
    @Binding var showingSwitchToPlanningAlert: Bool
    @Binding var headerHeight: CGFloat
    @Binding var refreshTrigger: UUID
    
    @Environment(VaultService.self) private var vaultService
    //    @Environment(\.showingFilterSheet) private var showingFilterSheet
    
    var body: some View {
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
                        .offset(x: anticipationOffset)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: anticipationOffset)
                    if cart.isPlanning {
                        Spacer()
                    }
                }
                .frame(width: 176)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cart.status)
                
                HStack(spacing: 0) {
                    Button(action: {
                        if cart.status == .shopping {
                            // Anticipation animation for switching to planning
                            withAnimation(.easeInOut(duration: 0.1)) {
                                anticipationOffset = -16// Move left halfway
                            }
                            
                            // Show confirmation alert
                            showingSwitchToPlanningAlert = true
                        }
                    }) {
                        Text("Planning")
                            .lexendFont(12, weight: cart.isPlanning ? .bold : .medium)
                            .foregroundColor(cart.isPlanning ? .black : Color(hex: "999999"))
                            .frame(width: 88, height: 26)
                            .offset(x: cart.isPlanning ? anticipationOffset : 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: anticipationOffset)
                            .animation(.easeInOut(duration: 0.2), value: cart.isPlanning)
                    }
                    .disabled(cart.isCompleted)
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        if cart.status == .planning {
                            // Anticipation animation for switching to shopping
                            withAnimation(.easeInOut(duration: 0.1)) {
                                anticipationOffset = 16 // Move right halfway
                            }
                            
                            // Show confirmation alert
                            showingStartShoppingAlert = true
                        }
                    }) {
                        Text("Shopping")
                            .lexendFont(12, weight: cart.isShopping ? .bold : .medium)
                            .foregroundColor(cart.isShopping ? .black : Color(hex: "999999"))
                            .frame(width: 88, height: 26)
                            .offset(x: cart.isShopping ? anticipationOffset : 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: anticipationOffset)
                            .animation(.easeInOut(duration: 0.2), value: cart.isShopping)
                    }
                    .disabled(cart.isCompleted)
                }
            }
            .frame(width: 176, height: 30)
            
            Spacer()
            
            HStack(spacing: 8) {
                
                Button(action: {
                    //                    showingFilterSheet = true
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
        .onChange(of: cart.status) { oldValue, newValue in
            // Reset anticipation offset when status actually changes
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                anticipationOffset = 0
            }
        }
        .onChange(of: showingStartShoppingAlert) { oldValue, newValue in
            if !newValue && cart.status == .planning {
                // User cancelled the shopping alert, reset anticipation
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    anticipationOffset = 0
                }
            }
        }
        .onChange(of: showingSwitchToPlanningAlert) { oldValue, newValue in
            if !newValue && cart.status == .shopping {
                // User cancelled the planning alert, reset anticipation
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    anticipationOffset = 0
                }
            }
        }
    }
}

// MARK: - Items List View
struct ItemsListView: View {
    let cart: Cart
    let totalItemCount: Int
    let sortedStoresWithRefresh: [String]
    let storeItemsWithRefresh: (String) -> [(cartItem: CartItem, item: Item?)]
    let onToggleFulfillment: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    
    var body: some View {
        Group {
            if totalItemCount <= 7 {
                VStack(spacing: 0) {
                    ForEach(Array(sortedStoresWithRefresh.enumerated()), id: \.offset) { index, store in
                        let storeItems = storeItemsWithRefresh(store)
                        if !storeItems.isEmpty {
                            StoreSectionView(
                                store: store,
                                items: storeItems,
                                cart: cart,
                                onToggleFulfillment: onToggleFulfillment,
                                onEditItem: onEditItem,
                                onDeleteItem: onDeleteItem,
                                isLastStore: index == sortedStoresWithRefresh.count - 1,
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
                        ForEach(Array(sortedStoresWithRefresh.enumerated()), id: \.offset) { index, store in
                            let storeItems = storeItemsWithRefresh(store)
                            if !storeItems.isEmpty {
                                StoreSectionView(
                                    store: store,
                                    items: storeItems,
                                    cart: cart,
                                    onToggleFulfillment: onToggleFulfillment,
                                    onEditItem: onEditItem,
                                    onDeleteItem: onDeleteItem,
                                    isLastStore: index == sortedStoresWithRefresh.count - 1,
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
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("Add items from vault")
                .lexendFont(18, weight: .medium)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cornerRadius(16)
    }
}

// MARK: - Footer View
struct FooterView: View {
    let cart: Cart
    @Binding var animatedFulfilledAmount: Double
    @Binding var animatedFulfilledPercentage: Double
    let shouldAnimateTransition: Bool
    let geometry: GeometryProxy
    
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        if cart.isShopping {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    Text("\(cart.fulfilledItemsCount)")
                        .fuzzyBubblesFont(15, weight: .bold)
                        .foregroundColor(.gray)
                        .contentTransition(.numericText(value: animatedFulfilledAmount))
                    
                    Text("/")
                        .fuzzyBubblesFont(10, weight: .bold)
                        .foregroundColor(Color(.systemGray3))
                    
                    Text("\(cart.totalItemsCount) items for ₱\(animatedFulfilledAmount, specifier: "%.2f")")
                        .fuzzyBubblesFont(15, weight: .bold)
                        .foregroundColor(.gray)
                        .contentTransition(.numericText(value: animatedFulfilledAmount))
                }
                
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
            .scaleEffect(shouldAnimateTransition ? 0.8 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.05), value: shouldAnimateTransition)
            .padding(.leading)
            .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
        }
    }
    
    private func updateAnimatedValues() {
        withAnimation(.smooth(duration: 0.5)) {
            animatedFulfilledAmount = vaultService.getTotalFulfilledAmount(for: cart)
            animatedFulfilledPercentage = vaultService.getCurrentFulfillmentPercentage(for: cart)
        }
    }
}

// MARK: - Cart Stores List View (original provided)
struct CartStoresListView: View {
    let cart: Cart
    let sortedStores: [String]
    let storeItemsProvider: (String) -> [(cartItem: CartItem, item: Item?)]
    let onToggleFulfillment: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    let isScrollable: Bool
    
    var body: some View {
        Group {
            if isScrollable {
                VerticalScrollViewWithCustomIndicator(maxHeight: 500, indicatorVerticalPadding: 12) {
                    storesVStack
                        .padding(.vertical, 12)
                }
            } else {
                storesVStack
                    .padding(.vertical, 12)
            }
        }
    }
    
    private var storesVStack: some View {
        VStack(spacing: 0) {
            ForEach(Array(sortedStores.enumerated()), id: \.offset) { index, store in
                let storeItems = storeItemsProvider(store)
                if !storeItems.isEmpty {
                    StoreSectionView(
                        store: store,
                        items: storeItems,
                        cart: cart,
                        onToggleFulfillment: onToggleFulfillment,
                        onEditItem: onEditItem,
                        onDeleteItem: onDeleteItem,
                        isLastStore: index == sortedStores.count - 1,
                        isInScrollableView: isScrollable
                    )
                    .padding(.top, index == 0 ? 0 : 20)
                }
            }
        }
    }
}
