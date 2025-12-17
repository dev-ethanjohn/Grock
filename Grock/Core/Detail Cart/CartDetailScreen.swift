import SwiftUI
import SwiftData

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
    
    @State private var bottomSheetDetent: PresentationDetent = .fraction(0.08)
    @State private var showingCompletedSheet = false
    
    @State private var showingShoppingPopover = false
    @State private var selectedCartItemForPopover: CartItem?
    @State private var selectedItemForPopover: Item?
    
    @State private var showingFulfillPopover = false
    
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

        let basicParams = CartDetailContent(
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
            showingFulfillPopover: $showingFulfillPopover,
            cartReady: $cartReady,
            refreshTrigger: $refreshTrigger,
            showFinishTripButton: $showFinishTripButton,
            buttonNamespace: buttonNamespace,
            bottomSheetDetent: $bottomSheetDetent,
            showingCompletedSheet: $showingCompletedSheet,
            showingShoppingPopover: $showingShoppingPopover,
            selectedItemForPopover: $selectedItemForPopover,
            selectedCartItemForPopover: $selectedCartItemForPopover
        )
        
        ZStack {
            basicParams
            
            if showingShoppingPopover {
                ShoppingEditItemPopover(
                    isPresented: $showingShoppingPopover,
                    item: selectedItemForPopover!,
                    cart: cart,
                    cartItem: selectedCartItemForPopover!,
                    onSave: {
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger = UUID()
                    },
                    onDismiss: {
                        showingShoppingPopover = false
                    }
                )
                .environment(vaultService)
                .transition(.opacity)
                .zIndex(100)
            }
            
            if showingFulfillPopover {
                FulfillConfirmationPopover(
                    isPresented: $showingFulfillPopover,
                    item: selectedItemForPopover!,
                    cart: cart,
                    cartItem: selectedCartItemForPopover!,
                    onFulfill: {
                        // Update UI after fulfillment
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger = UUID()
                        
                        // Check if we should show the completed sheet
                        let currentFulfilledCount = cart.cartItems.filter { $0.isFulfilled }.count
                        if currentFulfilledCount > 0 && !showingCompletedSheet {
                            showingCompletedSheet = true
                        }
                    },
                    onDismiss: {
                        showingFulfillPopover = false
                    }
                )
                .environment(vaultService)
                .transition(.opacity)
                .zIndex(101) // Higher than shopping popover
            }
        }
        
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
            
            // Show/hide bottom sheet based on shopping mode
            if newValue == .shopping && hasItems {
                let currentFulfilledCount = cart.cartItems.filter { $0.isFulfilled }.count
                if currentFulfilledCount > 0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingCompletedSheet = true
                    }
                }
            } else if newValue == .planning {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingCompletedSheet = false
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
        
        // Alerts only - no sheets remain
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
                vaultService.returnToPlanning(cart: cart)
                refreshTrigger = UUID()
            }
        } message: {
            Text("Switching back to Planning will reset this trip to your original plan.")
        }
        .alert("Complete Shopping", isPresented: $showingCompleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                vaultService.completeShopping(cart: cart)
                refreshTrigger = UUID()
                // Hide bottom sheet when completing
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingCompletedSheet = false
                }
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
    
    private func handleEditItem(cartItem: CartItem) {
        print("🛒 Editing item in shopping mode")
        
        // Force dismiss any keyboard first
        UIApplication.shared.endEditing()
        
        if let found = vaultService.findItemById(cartItem.itemId) {
            if cart.status == .shopping {
                print("🛍️ Showing shopping popover for: \(found.name)")
                // Set state in a single transaction to avoid race conditions
                DispatchQueue.main.async {
                    selectedItemForPopover = found
                    selectedCartItemForPopover = cartItem
                    showingShoppingPopover = true
                }
            } else {
                print("📝 Planning mode - showing sheet")
                itemToEdit = found
            }
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
            // Ensure button is visible even if celebration was already seen
            manageCartButtonVisible = true
            return
        }
        
        let isFirstCart = cartViewModel.carts.count == 1 || cartViewModel.isFirstCart(cart)
        print(" - Is first cart: \(isFirstCart)")
        
        if isFirstCart {
            print("🎉 First cart celebration triggered!")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showCelebration = true
                
                // Schedule to show manage cart button after celebration
                // CelebrationView typically lasts 2-3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        manageCartButtonVisible = true
                    }
                }
            }
            UserDefaults.standard.set(true, forKey: "hasSeenFirstShoppingCartCelebration")
        } else {
            print("⏭️ Not the first cart - no celebration")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    manageCartButtonVisible = true
                }
            }
        }
    }
}


// Add the simplified extension and helper struct
extension View {
    func completedSheet(
        cart: Cart,
        showing: Binding<Bool>,
        detent: Binding<PresentationDetent>,
        refreshTrigger: Binding<UUID>,
        vaultService: VaultService
    ) -> some View {
        self.sheet(isPresented: showing) {
            CompletedSheetContent(
                cart: cart,
                detent: detent,
                refreshTrigger: refreshTrigger,
                vaultService: vaultService
            )
        }
    }
}

struct CompletedSheetContent: View {
    let cart: Cart
    @Binding var detent: PresentationDetent
    @Binding var refreshTrigger: UUID
    let vaultService: VaultService
    
    //    private var completedItems: [(cartItem: CartItem, item: Item?)] {
    //        cart.cartItems.filter { $0.isFulfilled }.map { c in
    //            (c, vaultService.findItemById(c.itemId))
    //        }
    //    }
    //
    //    private var fulfilledCount: Int {
    //        cart.cartItems.filter { $0.isFulfilled }.count
    //    }
    
    var body: some View {
        CompletedItemsSheet(
            cart: cart,
            onUnfulfillItem: { cartItem in
                if cartItem.isSkippedDuringShopping {
                    // Handle unskipping an item
                    cartItem.isSkippedDuringShopping = false
                    cartItem.isFulfilled = false
                } else {
                    // Handle unfulfilling a regular completed item
                    vaultService.toggleItemFulfillment(cart: cart, itemId: cartItem.itemId)
                }
                refreshTrigger = UUID()
            }
        )
        .conditionalPresentationBackground()
        .presentationDetents([.fraction(0.08), .large], selection: $detent)
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(true)
        .presentationCornerRadius(24)
        .backgroundInteractionForSmallDetent(detent: $detent)
    }
}

extension View {
    @ViewBuilder
    func conditionalPresentationBackground() -> some View {
        if #available(iOS 26, *) {
            self
        } else {
            self.presentationBackground(.white)
        }
    }
}


extension View {
    func backgroundInteractionForSmallDetent(detent: Binding<PresentationDetent>) -> some View {
        self.modifier(BackgroundInteractionModifier(detent: detent))
    }
}

struct BackgroundInteractionModifier: ViewModifier {
    @Binding var detent: PresentationDetent
    
    func body(content: Content) -> some View {
        content
            .presentationBackgroundInteraction(
                detent == .fraction(0.08) ? .enabled(upThrough: .fraction(0.08)) : .disabled
            )
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
    
    //    @Binding var onFulfillItem: (CartItem) -> Void
    @Binding var showingFulfillPopover: Bool
    
    private var completedItemsCount: Int {
        cart.cartItems.filter {
            $0.isFulfilled || $0.isSkippedDuringShopping
        }.count
    }
    
    
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
    
    @State private var fulfilledCount: Int = 0
    
    private var currentFulfilledCount: Int {
        cart.cartItems.filter { $0.isFulfilled }.count
    }
    
    @Binding var bottomSheetDetent: PresentationDetent
    @Binding var showingCompletedSheet: Bool
    
    
    // Add these bindings
    @Binding var showingShoppingPopover: Bool
    @Binding var selectedItemForPopover: Item?
    @Binding var selectedCartItemForPopover: CartItem?
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let fractionHeight = screenHeight * 0.08
            
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
                                            fulfilledCount: $fulfilledCount,
                                            onFulfillItem: { cartItem in
                                                // Handle fulfillment - show the popover
                                                handleFulfillItem(cartItem: cartItem)
                                            },
                                            onEditItem: { cartItem in
                                                handleEditItem(cartItem: cartItem)
                                            },
                                            onDeleteItem: { cartItem in
                                                handleDeleteItem(cartItem)
                                            }
                                        )                                        .transition(.scale)
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
                        .padding(.vertical, 28)
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
                    
                    // Floating Action Bar (position it above everything)
                    if cartReady && !showCelebration && manageCartButtonVisible {
                        VStack {
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
                            .padding(.bottom)
                            
//                            Spacer()
//                                .frame(height: showingCompletedSheet ? fractionHeight : 0)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: manageCartButtonVisible)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingCompletedSheet)
                    }
                } else {
                    ProgressView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                                cartReady = true
                            }
                        }
                }
                
                //
                //                if showingShoppingPopover {
                //                     ShoppingEditItemPopover(
                //                         isPresented: $showingShoppingPopover,
                //                         item: selectedItemForPopover!,
                //                         cart: cart,
                //                         cartItem: selectedCartItemForPopover!,
                //                         onSave: {
                //                             vaultService.updateCartTotals(cart: cart)
                //                             refreshTrigger = UUID()
                //                         },
                //                         onDismiss: {
                //                             showingShoppingPopover = false
                //                         }
                //                     )
                //                     .environment(vaultService)
                //                     .transition(.opacity)
                //                     .zIndex(1)
                //                 }
                //
                
                
                
                
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
        }
        .ignoresSafeArea(.keyboard)
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
        .onAppear {
            // Initialize both with cart's budget
            animatedBudget = cart.budget
            localBudget = cart.budget
            
            // Set initial button state
            if cart.isShopping && hasItems {
                showFinishTripButton = true
            }
            
            if cart.isShopping {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingCompletedSheet = true
                    }
                }
            }
        }
        .onChange(of: cart.status) { oldValue, newValue in
            print("🛒 Cart status changed: \(oldValue) -> \(newValue)")
            
            // Show/hide bottom sheet based on shopping mode
            if newValue == .shopping && hasItems {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingCompletedSheet = true
                }
            } else if newValue == .planning {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingCompletedSheet = false
                }
            }
        }
        .onChange(of: currentFulfilledCount) { oldValue, newValue in
            // Show bottom sheet when we get our first completed item
            if cart.isShopping && !showingCompletedSheet && newValue > 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingCompletedSheet = true
                }
            }
            // Hide bottom sheet when all items are unfulfilled
            else if cart.isShopping && showingCompletedSheet && newValue == 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showingCompletedSheet = false
                }
            }
        }
    }
    
    // In CartDetailContent struct, update handleEditItem:
    private func handleEditItem(cartItem: CartItem) {
        if let found = vaultService.findItemById(cartItem.itemId) {
            if cart.status == .shopping {
                // Shopping mode: Set bindings for popover
                selectedItemForPopover = found
                selectedCartItemForPopover = cartItem
                showingShoppingPopover = true
            } else {
                // Planning mode: Set itemToEdit binding directly
                // This will trigger the .sheet(item: $itemToEdit) in parent
                itemToEdit = found
            }
        }
    }
    
    private func handleDeleteItem(_ cartItem: CartItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            vaultService.removeItemFromCart(cart: cart, itemId: cartItem.itemId)
            vaultService.updateCartTotals(cart: cart)
            refreshTrigger = UUID()
        }
    }
    
    private func handleFulfillItem(cartItem: CartItem) {
        if let found = vaultService.findItemById(cartItem.itemId) {
            // Show the fulfillment confirmation popover
            selectedItemForPopover = found
            selectedCartItemForPopover = cartItem
            
            // This will trigger the popover at the CartDetailScreen level
            showingFulfillPopover = true
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
        let spent = cart.totalSpent // Use the computed property
        return min(spent / localBudget, 1.0)
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
                HStack(alignment: .bottom, spacing: 4) {
                    Text(cart.name)
                        .lexendFont(22, weight: .bold)
                        .foregroundColor(.black)
                    
                    Image("edit")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundStyle(Color(.systemGray2))
                        .frame(width: 16, height: 16)
                        .padding(.bottom, 3)
                }
                
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

struct ItemsListView: View {
    let cart: Cart
    let totalItemCount: Int
    let sortedStoresWithRefresh: [String]
    let storeItemsWithRefresh: (String) -> [(cartItem: CartItem, item: Item?)]
    @Binding var fulfilledCount: Int
    //    let onToggleFulfillment: (CartItem) -> Void
    let onFulfillItem: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    
    // Calculate available width based on screen width minus total padding
    private var availableWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        let cartDetailPadding: CGFloat = 17
        let itemRowPadding: CGFloat = cart.isShopping ? 36 : 28
        let internalSpacing: CGFloat = 4
        let safetyBuffer: CGFloat = 3
        
        let totalPadding = cartDetailPadding + itemRowPadding + internalSpacing + safetyBuffer
        
        let calculatedWidth = screenWidth - totalPadding
        
        return max(min(calculatedWidth, 250), 150)
    }
    
    private func estimateRowHeight(for itemName: String, isFirstInSection: Bool = true) -> CGFloat {
        let averageCharWidth: CGFloat = 8.0
        
        let estimatedTextWidth = CGFloat(itemName.count) * averageCharWidth
        let numberOfLines = ceil(estimatedTextWidth / availableWidth)
        
        let singleLineTextHeight: CGFloat = 22
        let verticalPadding: CGFloat = 24
        let internalSpacing: CGFloat = 10
        
        let baseHeight = singleLineTextHeight + verticalPadding + internalSpacing
        
        let additionalLineHeight: CGFloat = 24
        
        let itemHeight = baseHeight + (max(0, numberOfLines - 1) * additionalLineHeight)
        
        let dividerHeight: CGFloat = isFirstInSection ? 0 : 12.0
        
        return itemHeight + dividerHeight
    }
    
    private var estimatedHeight: CGFloat {
        let sectionHeaderHeight: CGFloat = 34
        let sectionSpacing: CGFloat = 8
        let listPadding: CGFloat = 24
        
        var totalHeight: CGFloat = listPadding
        
        for store in sortedStoresWithRefresh {
            let displayItems = getDisplayItems(for: store)
            
            if !displayItems.isEmpty {
                totalHeight += sectionHeaderHeight
                
                for (index, (_, item)) in displayItems.enumerated() {
                    let itemName = item?.name ?? "Unknown"
                    let isFirstInStore = index == 0
                    totalHeight += estimateRowHeight(for: itemName, isFirstInSection: isFirstInStore)
                }
                
                if store != sortedStoresWithRefresh.last {
                    totalHeight += sectionSpacing
                }
            }
        }
        
        return totalHeight
    }
    
    private var allItemsCompleted: Bool {
        guard cart.isShopping else { return false }
        
        // Get all items across all stores
        let allItems = sortedStoresWithRefresh.flatMap { storeItemsWithRefresh($0) }
        
        // Check if all non-skipped items are fulfilled
        let allUnfulfilledItems = allItems.filter {
            !$0.cartItem.isFulfilled &&
            !$0.cartItem.isSkippedDuringShopping
        }
        
        return allUnfulfilledItems.isEmpty && totalItemCount > 0
    }
    
    // FIXED: Check if ALL stores have no display items
    private var hasDisplayItems: Bool {
        for store in sortedStoresWithRefresh {
            if !getDisplayItems(for: store).isEmpty {
                return true
            }
        }
        return false
    }
    
    private func getDisplayItems(for store: String) -> [(cartItem: CartItem, item: Item?)] {
        let allItems = storeItemsWithRefresh(store)
        
        switch cart.status {
        case .planning:
            // Planning mode: Show ALL items
            return allItems
            
        case .shopping:
            // Shopping mode: Only show unfulfilled, non-skipped items
            return allItems.filter {
                !$0.cartItem.isFulfilled &&
                !$0.cartItem.isSkippedDuringShopping
            }
            
        case .completed:
            // Completed mode: Show all items (for reference)
            return allItems
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let calculatedHeight = estimatedHeight
            let maxAllowedHeight = geometry.size.height * 0.8
            
            VStack(spacing: 0) {
                // FIXED: Only show "Shopping Trip Complete" when in shopping mode AND all items are done
                if cart.isShopping && allItemsCompleted {
                    // Celebration message for completed shopping
                    VStack(spacing: 16) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "FF6B6B"))
                        
                        Text("Shopping Trip Complete! 🎉")
                            .lexendFont(18, weight: .bold)
                            .foregroundColor(Color(hex: "333"))
                            .multilineTextAlignment(.center)
                        
                        Text("Congratulations! You've checked off all items.")
                            .lexendFont(14)
                            .foregroundColor(Color(hex: "666"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("Ready to finish your trip?")
                            .lexendFont(12)
                            .foregroundColor(Color(hex: "999"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                    .frame(height: min(200, maxAllowedHeight))
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "F7F2ED").darker(by: 0.02),
                                Color(hex: "F7F2ED")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "FF6B6B").opacity(0.3), lineWidth: 2)
                    )
                    .transition(.opacity.combined(with: .scale))
                } else if !hasDisplayItems && cart.isPlanning {
                    // FIXED: Only show empty state when in planning mode AND truly no items
                    // Return to the original EmptyCartView
                    EmptyCartView()
                        .transition(.scale)
                        .offset(y: 80)
                } else {
                    List {
                        ForEach(Array(sortedStoresWithRefresh.enumerated()), id: \.offset) { (index, store) in
                            let displayItems = getDisplayItems(for: store)
                            
                            if !displayItems.isEmpty {
                                StoreSectionListView(
                                    store: store,
                                    items: displayItems,
                                    cart: cart,
                                    onFulfillItem: { cartItem in
                                        onFulfillItem(cartItem)
                                    },
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
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: calculatedHeight)
                }
            }
        }
        .onChange(of: cart.cartItems) { oldItems, newItems in
            // Update the fulfilled count when cart items change
            let newFulfilledCount = newItems.filter { $0.isFulfilled }.count
            if fulfilledCount != newFulfilledCount {
                fulfilledCount = newFulfilledCount
            }
        }
        .onChange(of: cart.status) { oldStatus, newStatus in
            print("🔄 Cart status changed in ItemsListView: \(oldStatus) → \(newStatus)")
            print("   Display items will now: \(newStatus == .planning ? "Show ALL items" : "Show only unfulfilled, non-skipped")")
        }
    }
}

