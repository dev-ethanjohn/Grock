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
    
    @State private var showFinishTripButton = false
    @Namespace private var buttonNamespace
    
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
        //        CartDetailContent(
        //            cart: cart,
        //            cartInsights: cartInsights,
        //            itemsByStore: itemsByStore,
        //            itemsByStoreWithRefresh: itemsByStoreWithRefresh,
        //            sortedStores: sortedStores,
        //            sortedStoresWithRefresh: sortedStoresWithRefresh,
        //            totalItemCount: totalItemCount,
        //            hasItems: hasItems,
        //            shouldAnimateTransition: shouldAnimateTransition,
        //            storeItems: storeItems(for:),
        //            storeItemsWithRefresh: storeItemsWithRefresh(for:),
        //            showingDeleteAlert: $showingDeleteAlert,
        //            editingItem: $editingItem,
        //            showingCompleteAlert: $showingCompleteAlert,
        //            showingStartShoppingAlert: $showingStartShoppingAlert,
        //            showingSwitchToPlanningAlert: $showingSwitchToPlanningAlert,
        //            anticipationOffset: $anticipationOffset,
        //            selectedFilter: $selectedFilter,
        //            showingFilterSheet: $showingFilterSheet,
        //            headerHeight: $headerHeight,
        //            animatedFulfilledAmount: $animatedFulfilledAmount,
        //            animatedFulfilledPercentage: $animatedFulfilledPercentage,
        //            itemToEdit: $itemToEdit,
        //            showingVaultView: $showingVaultView,
        //            previousHasItems: $previousHasItems,
        //            showCelebration: $showCelebration,
        //            manageCartButtonVisible: $manageCartButtonVisible,
        //            buttonScale: $buttonScale,
        //            shouldBounceAfterCelebration: $shouldBounceAfterCelebration,
        //            cartReady: $cartReady,
        //            refreshTrigger: $refreshTrigger
        //        )
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
            refreshTrigger: $refreshTrigger,
            // ADD THESE NEW BINDINGS:
            showFinishTripButton: $showFinishTripButton,
            buttonNamespace: buttonNamespace
        )
        //        .onAppear {
        //            previousHasItems = hasItems
        //            checkAndShowCelebration()
        //        }
        .onAppear {
            previousHasItems = hasItems
            checkAndShowCelebration()
            
            if cart.isShopping && hasItems {
                showFinishTripButton = true
            }
        }
        .onChange(of: cart.status) { oldValue, newValue in
            print("🛒 Cart status changed: \(oldValue) -> \(newValue)")
            
            // Only update if the status actually changed
            if oldValue != newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if newValue == .shopping && hasItems {
                        showFinishTripButton = true
                    } else if newValue == .planning {
                        showFinishTripButton = false
                    }
                }
            }
        }
        
        .onChange(of: hasItems) { oldValue, newValue in
            print("📦 Items changed: \(oldValue) -> \(newValue)")
            
            // Only update if items actually changed
            if oldValue != newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if cart.isShopping && newValue {
                        showFinishTripButton = true
                    } else if !newValue {
                        showFinishTripButton = false
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(item: $itemToEdit) { item in
            // FIXED: Find the cartItem for this item
            if let cartItem = cart.cartItems.first(where: { $0.itemId == item.id }) {
                EditItemSheet(
                    item: item,
                    cart: cart,
                    cartItem: cartItem,
                    onSave: { updatedItem in
                        print("✅ Updated cart item")
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger = UUID()
                    }
                )
                .environment(vaultService)
                .presentationDetents([.medium, .fraction(0.75)])
                .presentationCornerRadius(24)
            }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    manageCartButtonVisible = true
                    // REMOVE THIS LINE - DON'T RESET THE BUTTON STATE
                    // showFinishTripButton = false
                }
            }
        }
    }
    private func toggleButtonState() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showFinishTripButton.toggle()
        }
    }
    
    private func morphToFinishTrip() {
        guard cart.isShopping && hasItems else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showFinishTripButton = true
        }
    }
    
    private func morphToManageCart() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showFinishTripButton = false
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
    @State private var localBudget: Double = 0
    @State private var isSavingBudget = false
    @State private var animatedBudget: Double = 0
    @State private var showEditBudget = false
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    @Binding var showFinishTripButton: Bool
    var buttonNamespace: Namespace.ID
    
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
                                        
                                        //                                        FooterView(
                                        //                                            cart: cart,
                                        //                                            animatedFulfilledAmount: $animatedFulfilledAmount,
                                        //                                            animatedFulfilledPercentage: $animatedFulfilledPercentage,
                                        //                                            shouldAnimateTransition: shouldAnimateTransition,
                                        //                                            geometry: geometry
                                        //                                        )
                                    }
                                } else {
                                    EmptyCartView()
                                        .transition(.scale)
                                        .offset(y: 80)
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
                            animatedBudget: animatedBudget,
                            localBudget: localBudget,
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
                
                if showEditBudget {
                    EditBudgetPopover(
                        isPresented: $showEditBudget,
                        currentBudget: localBudget,
                        onSave: { newBudget in
                            isSavingBudget = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                localBudget = newBudget
                                
                                withAnimation(.spring(duration: 0.3)) {
                                    animatedBudget = newBudget
                                }
                                
                                isSavingBudget = false
                            }
                        },
                        onDismiss: {
                            if !isSavingBudget {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    animatedBudget = localBudget
                                }
                            }
                        }
                    )
                    .environment(vaultService)
                    .zIndex(1000)
                }
                
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
            //            .overlay(alignment: .bottom) {
            //                if !showCelebration && manageCartButtonVisible {
            //                    Button(action: {
            //                        showingVaultView = true
            //                    }) {
            //                        Text("Manage Cart")
            //                            .fuzzyBubblesFont(16, weight: .bold)
            //                            .foregroundColor(.white)
            //                            .padding(.horizontal, 24)
            //                            .padding(.vertical, 12)
            //                            .background(Color.black)
            //                            .cornerRadius(25)
            //                    }
            //                    .transition(.scale)
            //                    .scaleEffect(showEditBudget ? 0 : buttonScale)
            //                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
            //                    .animation(.easeInOut(duration: 0.2), value: showEditBudget)
            //                    .ignoresSafeArea(.keyboard)
            //                }
            //            }
            //            .overlay(alignment: .bottom) {
            //                if cartReady && !showCelebration && manageCartButtonVisible {
            //                    VStack(spacing: 0) {
            //                        Spacer()
            //
            //                        MorphingCartButtonWithGeometry(
            //                            isExpanded: showFinishTripButton,
            //                            onManageCart: {
            //                                showingVaultView = true
            //                            },
            //                            onFinishTrip: {
            //                                // Handle finish trip action
            //                                print("Finish trip tapped")
            //                                // You can trigger completion or navigation here
            //                                showingCompleteAlert = true
            //                            },
            //                            namespace: buttonNamespace
            //                        )
            //                        .padding(.bottom, 20)
            //                        .padding(.horizontal, 16)
            //                    }
            //                    .transition(.move(edge: .bottom).combined(with: .opacity))
            //                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: manageCartButtonVisible)
            //                    .ignoresSafeArea(.keyboard)
            //                }
            //            }
            //            .onAppear {
            //                // Initialize both with cart's budget
            //                animatedBudget = cart.budget
            //                localBudget = cart.budget
            //            }
            .onDisappear {
                // Save to actual cart ONLY when dismissing CartDetailScreen
                if localBudget != cart.budget {
                    cart.budget = localBudget
                    vaultService.updateCartTotals(cart: cart)
                    print("💾 Saved budget update: \(cart.name) = \(localBudget)")
                }
            }
            .onChange(of: cart.budget) { oldValue, newValue in
                if localBudget != newValue {
                    localBudget = newValue
                    withAnimation(.easeInOut(duration: 0.3)) {
                        animatedBudget = newValue
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if cartReady && !showCelebration && manageCartButtonVisible {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        CartDetailActionBar(
                            showFinishTrip: showFinishTripButton,
                            onManageCart: {
                                showingVaultView = true
                            },
                            onFinishTrip: {
                                print("Finish trip tapped")
                                showingCompleteAlert = true
                            },
                            namespace: buttonNamespace
                        )
                        .padding(.horizontal, 16)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: manageCartButtonVisible)
                    .ignoresSafeArea(.keyboard)
                }
            }
            .onAppear {
                // Initialize both with cart's budget
                animatedBudget = cart.budget
                localBudget = cart.budget
                
                // Set initial button state
                if cart.isShopping && hasItems {
                    showFinishTripButton = true
                }
            }
            .onChange(of: cart.status) { oldValue, newValue in
                print("🛒 Cart status changed: \(oldValue) -> \(newValue)")
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if newValue == .shopping && hasItems {
                        showFinishTripButton = true
                    } else {
                        showFinishTripButton = false
                    }
                }
            }
            
            .onChange(of: hasItems) { oldValue, newValue in
                print("📦 Items changed: \(oldValue) -> \(newValue)")
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    if cart.isShopping && newValue {
                        showFinishTripButton = true
                    } else if !newValue {
                        showFinishTripButton = false
                    }
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
    let animatedBudget: Double
    let localBudget: Double
    @Binding var showingDeleteAlert: Bool
    @Binding var showingCompleteAlert: Bool
    @Binding var showingStartShoppingAlert: Bool
    @Binding var headerHeight: CGFloat
    let dismiss: DismissAction
    
    var onBudgetTap: (() -> Void)?
    
    private var progress: Double {
        guard localBudget > 0 else { return 0 }
        return min(cart.totalSpent / localBudget, 1.0)
    }
    
    @Environment(VaultService.self) private var vaultService
    
    private var budgetProgressColor: Color {
        let progress = self.progress
        if progress < 0.7 {
            return Color(hex: "98F476")
        } else if progress < 0.9 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
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
                    HStack(alignment: .center, spacing: 16) {
                        BudgetProgressBar(cart: cart, animatedBudget: animatedBudget, budgetProgressColor: budgetProgressColor, progressWidth: progressWidth)
                        
                        Button(action: {
                            onBudgetTap?()
                        }) {
                            Text(animatedBudget.formattedCurrency)
                                .lexendFont(14, weight: .bold)
                                .foregroundColor(Color(hex: "333"))
                                .contentTransition(.numericText())
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
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
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
                            withAnimation(.easeInOut(duration: 0.1)) {
                                anticipationOffset = -14
                            }
                            
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
                            withAnimation(.easeInOut(duration: 0.1)) {
                                anticipationOffset = 14
                            }
                            
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
            
            Button(action: {
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

struct ItemsListView: View {
    let cart: Cart
    let totalItemCount: Int
    let sortedStoresWithRefresh: [String]
    let storeItemsWithRefresh: (String) -> [(cartItem: CartItem, item: Item?)]
    let onToggleFulfillment: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    
    // Calculate available width based on screen width minus total padding
    private var availableWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        // TOTAL HORIZONTAL PADDING BREAKDOWN:
        // 1. CartDetailContent: ~17pt (default system padding)
        // 2. CartItemRowListView:
        //    - Shopping: 12pt left + 8pt button spacing + 16pt right = 36pt
        //    - Planning: 12pt left + 16pt right = 28pt
        // 3. Additional 4pt internal HStack spacing in price details
        // 4. Small buffer for safety: ~3pt
        
        let cartDetailPadding: CGFloat = 17
        let itemRowPadding: CGFloat = cart.isShopping ? 36 : 28
        let internalSpacing: CGFloat = 4
        let safetyBuffer: CGFloat = 3
        
        let totalPadding = cartDetailPadding + itemRowPadding + internalSpacing + safetyBuffer
        
        // Shopping: 17 + 36 + 4 + 3 = 60pt
        // Planning: 17 + 28 + 4 + 3 = 52pt
        
        let calculatedWidth = screenWidth - totalPadding
        
        // Ensure reasonable bounds
        return max(min(calculatedWidth, 250), 150)
    }
    
    private func estimateRowHeight(for itemName: String, isFirstInSection: Bool = true) -> CGFloat {
        let averageCharWidth: CGFloat = 8.0
        
        let estimatedTextWidth = CGFloat(itemName.count) * averageCharWidth
        let numberOfLines = ceil(estimatedTextWidth / availableWidth)
        
        let singleLineTextHeight: CGFloat = 22
        let verticalPadding: CGFloat = 24
        let internalSpacing: CGFloat = 10
        
        // Base height = text + padding + spacing
        let baseHeight = singleLineTextHeight + verticalPadding + internalSpacing
        
        // Each additional line adds the text line height
        let additionalLineHeight: CGFloat = 24
        
        let itemHeight = baseHeight + (max(0, numberOfLines - 1) * additionalLineHeight)
        
        // ADD divider height (except for first item in each store)
        let dividerHeight: CGFloat = isFirstInSection ? 0 : 12.0
        
        return itemHeight + dividerHeight
    }
    private var estimatedHeight: CGFloat {
        let sectionHeaderHeight: CGFloat = 34
        let sectionSpacing: CGFloat = 8
        let listPadding: CGFloat = 24
        
        var totalHeight: CGFloat = listPadding
        
        for store in sortedStoresWithRefresh {
            let storeItems = storeItemsWithRefresh(store)
            if !storeItems.isEmpty {
                totalHeight += sectionHeaderHeight
                
                // Track which item is first in this store
                for (index, (_, item)) in storeItems.enumerated() {
                    let itemName = item?.name ?? "Unknown"
                    let isFirstInStore = index == 0
                    totalHeight += estimateRowHeight(for: itemName, isFirstInSection: isFirstInStore)
                }
                
                // ADD spacing between stores (except after last store)
                if store != sortedStoresWithRefresh.last {
                    totalHeight += sectionSpacing
                }
            }
        }
        
        return totalHeight
    }
    
    var body: some View {
        GeometryReader { geometry in
            let calculatedHeight = estimatedHeight
            let maxAllowedHeight = geometry.size.height * 0.8
            
            List {
                ForEach(Array(sortedStoresWithRefresh.enumerated()), id: \.offset) { (index, store) in
                    let storeItems = storeItemsWithRefresh(store)
                    if !storeItems.isEmpty {
                        StoreSectionListView(
                            store: store,
                            items: storeItems,
                            cart: cart,
                            onToggleFulfillment: onToggleFulfillment,
                            onEditItem: onEditItem,
                            onDeleteItem: onDeleteItem,
                            isLastStore: index == sortedStoresWithRefresh.count - 1
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color(hex: "F7F2ED"))
                    }
                }
            }
            .frame(height: min(calculatedHeight, maxAllowedHeight))
            .listStyle(PlainListStyle())
            .listSectionSpacing(0)
            .background(Color(hex: "F7F2ED").darker(by: 0.02))
            .cornerRadius(16)
        }
    }
}

// Preference key to pass height up the view hierarchy
struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct StoreSectionListView: View {
    let store: String
    let items: [(cartItem: CartItem, item: Item?)]
    let cart: Cart
    let onToggleFulfillment: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    let isLastStore: Bool
    
    private var itemsWithStableIdentifiers: [(id: String, cartItem: CartItem, item: Item?)] {
        items.map { ($0.cartItem.itemId, $0.cartItem, $0.item) }
    }
    
    var body: some View {
        Section(
            header: VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 2) {
                        Image("store")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.white)
                        
                        Text(store)
                            .lexendFont(11, weight: .bold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black)
                    .cornerRadius(6)
                    Spacer()
                }
                .padding(.leading)
            }
                .listRowInsets(EdgeInsets())
                .textCase(nil)
            
        ) {
            ForEach(Array(itemsWithStableIdentifiers.enumerated()), id: \.element.id) { index, tuple in
                VStack(spacing: 0) {
                    CartItemRowListView(
                        cartItem: tuple.cartItem,
                        item: tuple.item,
                        cart: cart,
                        onToggleFulfillment: { onToggleFulfillment(tuple.cartItem) },
                        onEditItem: { onEditItem(tuple.cartItem) },
                        onDeleteItem: { onDeleteItem(tuple.cartItem) },
                        isLastItem: index == itemsWithStableIdentifiers.count - 1
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .background(Color(hex: "F7F2ED"))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDeleteItem(tuple.cartItem)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            onEditItem(tuple.cartItem)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        if cart.isShopping {
                            Button {
                                onToggleFulfillment(tuple.cartItem)
                            } label: {
                                Label(
                                    tuple.cartItem.isFulfilled ? "Mark Unfulfilled" : "Mark Fulfilled",
                                    systemImage: tuple.cartItem.isFulfilled ? "circle" : "checkmark.circle.fill"
                                )
                            }
                            .tint(tuple.cartItem.isFulfilled ? .orange : .green)
                        }
                    }
                    
                    // Add the dashed line divider between items (but not after the last item)
                    if index < itemsWithStableIdentifiers.count - 1 {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 0.5)
                            .foregroundColor(Color(hex: "999").opacity(0.5))
                            .padding(.horizontal, 12)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color(hex: "F7F2ED"))
            }
        }
        .listSectionSpacing(isLastStore ? 0 : 20)
    }
}

