import SwiftUI
import SwiftData

struct CartDetailScreen: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    // All @State properties (from the simpler version)
    @State private var showingDeleteAlert = false
    @State private var editingItem: CartItem?
    @State private var showingCompleteAlert = false
    @State private var showingStartShoppingAlert = false
    @State private var showingSwitchToPlanningAlert = false
    @State private var anticipationOffset: CGFloat = 0
    @State private var selectedFilter: FilterOption = .all
    @State private var showingFilterSheet = false
    @State private var headerHeight: CGFloat = 0
    @State private var animatedFulfilledAmount: Double = 0
    @State private var animatedFulfilledPercentage: Double = 0
    @State private var itemToEdit: Item? = nil
    
    // Changed: We need TWO different sheet states
    @State private var showingManageCartSheet = false  // For planning mode
    @State private var showingAddItemSheet = false     // For shopping mode
    
    @State private var previousHasItems = false
    @State private var showCelebration = false
    @State private var manageCartButtonVisible = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var shouldBounceAfterCelebration = false
    @State private var cartReady = false
    @State private var refreshTrigger = UUID()
    @State private var showFinishTripButton = false
    @Namespace private var buttonNamespace
    @State private var bottomSheetDetent: PresentationDetent = .fraction(0.08)
    @State private var showingCompletedSheet = false
    @State private var showingShoppingPopover = false
    @State private var selectedCartItemForPopover: CartItem?
    @State private var selectedItemForPopover: Item?
    @State private var showingFulfillPopover = false
    @State private var showingEditCartName = false
    
    // Computed properties
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
    
    private var itemsByStoreWithRefresh: [String: [(cartItem: CartItem, item: Item?)]] {
        _ = refreshTrigger
        let sortedCartItems = cart.cartItems.sorted { $0.addedAt > $1.addedAt }
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
    
    private var currentFulfilledCount: Int {
        cart.cartItems.filter { $0.isFulfilled }.count
    }
    
    @ViewBuilder
      private var mainContent: some View {
          // Create a computed property with all the bindings
          let content = createCartDetailContent()
          content
      }
      
      private func createCartDetailContent() -> CartDetailContent {
          // Determine which sheet to show based on cart status
          let vaultViewBinding = cart.isPlanning ? $showingManageCartSheet : $showingAddItemSheet
          
          return CartDetailContent(
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
              showingVaultView: vaultViewBinding,
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
              selectedCartItemForPopover: $selectedCartItemForPopover,
              showingEditCartName: $showingEditCartName,
              showingAddItemSheet: $showingAddItemSheet,
              showingManageCartSheet: $showingManageCartSheet
          )
      }
      
    
    var body: some View {
        ZStack {
            mainContent
            
            // Popovers (unchanged)
            if showingShoppingPopover,
               let item = selectedItemForPopover,
               let cartItem = selectedCartItemForPopover {
                UnifiedItemPopover.edit(
                    isPresented: $showingShoppingPopover,
                    item: item,
                    cart: cart,
                    cartItem: cartItem,
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
            
            if showingFulfillPopover,
               let item = selectedItemForPopover,
               let cartItem = selectedCartItemForPopover {
                UnifiedItemPopover.fulfill(
                    isPresented: $showingFulfillPopover,
                    item: item,
                    cart: cart,
                    cartItem: cartItem,
                    onSave: {
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger = UUID()
                        
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
                .zIndex(101)
            }
            
            if showingEditCartName {
                RenameCartNamePopover(
                    isPresented: $showingEditCartName,
                    currentName: cart.name,
                    onSave: { newName in
                        cart.name = newName
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger = UUID()
                    },
                    onDismiss: nil
                )
                .transition(.opacity)
                .environment(vaultService)
                .zIndex(102)
            }
        }
        .editItemSheet(
                  itemToEdit: $itemToEdit,
                  cart: cart,
                  vaultService: vaultService,
                  refreshTrigger: $refreshTrigger
              )
              .cartSheets(
                  cart: cart,
                  showingManageCartSheet: $showingManageCartSheet,
                  showingAddItemSheet: $showingAddItemSheet,
                  showingFilterSheet: $showingFilterSheet,
                  selectedFilter: $selectedFilter,
                  vaultService: vaultService,
                  cartViewModel: cartViewModel,
                  refreshTrigger: $refreshTrigger
              )
              .cartAlerts(
                  showingStartShoppingAlert: $showingStartShoppingAlert,
                  showingSwitchToPlanningAlert: $showingSwitchToPlanningAlert,
                  showingCompleteAlert: $showingCompleteAlert,
                  showingDeleteAlert: $showingDeleteAlert,
                  vaultService: vaultService,
                  cart: cart,
                  dismiss: dismiss,
                  refreshTrigger: $refreshTrigger,
                  showingCompletedSheet: $showingCompletedSheet
              )
              .cartLifecycle(
                  cart: cart,
                  hasItems: hasItems,
                  showFinishTripButton: $showFinishTripButton,
                  previousHasItems: $previousHasItems,
                  cartStatusChanged: handleCartStatusChange,
                  itemsChanged: handleItemsChange,
                  checkAndShowCelebration: checkAndShowCelebration
              )
    }
    
    // MARK: - Helper Methods
    
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
    
    private func handleCartStatusChange(oldValue: CartStatus, newValue: CartStatus) {
        print("🛒 Cart status changed: \(oldValue) -> \(newValue)")
        
        if oldValue != newValue {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                if newValue == .shopping && hasItems {
                    showFinishTripButton = true
                } else if newValue == .planning {
                    showFinishTripButton = false
                }
            }
        }
        
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
    
    private func handleItemsChange(oldValue: Bool, newValue: Bool) {
        print("📦 Items changed: \(oldValue) -> \(newValue)")
        
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
}

enum PopoverMode {
    case edit // For clicking item row - shows "Update" button
    case fulfill // For clicking checkmark - shows "Confirm Purchase" button
    
    var buttonTitle: String {
        switch self {
        case .edit:
            return "Update"
        case .fulfill:
            return "Confirm Purchase"
        }
    }
    
    var showPromptText: Bool {
        switch self {
        case .edit:
            return true
        case .fulfill:
            return false
        }
    }
}


// MARK: - Helper Types
enum FieldPrompt: Hashable {
    case none
    case price
    case portion
    
    var text: String {
        switch self {
        case .none:
            return "Confirm what you're buying"
        case .price:
            return "How much is it?"
        case .portion:
            return "How many did you get?"
        }
    }
}

// MARK: - Usage Examples
extension UnifiedItemPopover {
    // Convenience initializer for edit mode
    static func edit(
        isPresented: Binding<Bool>,
        item: Item,
        cart: Cart,
        cartItem: CartItem,
        onSave: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> UnifiedItemPopover {
        UnifiedItemPopover(
            isPresented: isPresented,
            item: item,
            cart: cart,
            cartItem: cartItem,
            mode: .edit,
            onSave: onSave,
            onDismiss: onDismiss
        )
    }
    
    // Convenience initializer for fulfill mode
    static func fulfill(
        isPresented: Binding<Bool>,
        item: Item,
        cart: Cart,
        cartItem: CartItem,
        onSave: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> UnifiedItemPopover {
        UnifiedItemPopover(
            isPresented: isPresented,
            item: item,
            cart: cart,
            cartItem: cartItem,
            mode: .fulfill,
            onSave: onSave,
            onDismiss: onDismiss
        )
    }
}

// MARK: - Supporting Views (need to be defined or imported)

// Note: The following supporting views need to be available:
// - ItemDescriptionText (from your ShoppingEditItemPopover)
// - PriceField (from your ShoppingEditItemPopover)
// - PortionField (from your ShoppingEditItemPopover)
// - ErrorMessageDisplay (from your ShoppingEditItemPopover)
// - FormCompletionButton (already defined elsewhere)
// - FuzzyBubblesFont, LexendFont modifiers (should be available)

// MARK: - The rest of the file remains the same...

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
    
    @Binding var showingFulfillPopover: Bool
    
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
    
    // ADD THIS: Binding for Edit Cart Name popover
    @Binding var showingEditCartName: Bool
    
    @Binding var showingAddItemSheet: Bool
    @Binding var showingManageCartSheet: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content area
                if cartReady {
                    ZStack(alignment: .top) {
                        VStack(spacing: 8) {
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
                            showingEditCartName: $showingEditCartName,
                            refreshTrigger: $refreshTrigger,  // MOVE THIS TO THE END
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
                                                  // IMPORTANT: Show different sheets based on cart status
                                                  if cart.isPlanning {
                                                      showingManageCartSheet = true
                                                  } else {
                                                      showingAddItemSheet = true
                                                  }
                                              },
                                              onFinishTrip: {
                                                  showingCompleteAlert = true
                                              },
                                              namespace: buttonNamespace
                                          )
                                          .padding(.horizontal, 16)
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
    
     private func handleEditItem(cartItem: CartItem) {
         if let found = vaultService.findItemById(cartItem.itemId) {
             if cart.status == .shopping {
                 // Shopping mode: Use UnifiedItemPopover
                 selectedItemForPopover = found
                 selectedCartItemForPopover = cartItem
                 showingShoppingPopover = true
             } else {
                 // Planning mode: Use EditItemSheet
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
                    .cornerRadius(24)
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







extension View {
    func cartSheets(
        cart: Cart,
        showingManageCartSheet: Binding<Bool>,
        showingAddItemSheet: Binding<Bool>,
        showingFilterSheet: Binding<Bool>,
        selectedFilter: Binding<FilterOption>,
        vaultService: VaultService,
        cartViewModel: CartViewModel,
        refreshTrigger: Binding<UUID>
    ) -> some View {
        self
            .sheet(isPresented: showingManageCartSheet) {
                       ManageCartSheet(cart: cart)  // Remove the onDismiss parameter
                           .environment(vaultService)
                           .environment(cartViewModel)
                           .onDisappear {
                               vaultService.updateCartTotals(cart: cart)
                               refreshTrigger.wrappedValue = UUID()
                           }
                   }
            .sheet(isPresented: showingAddItemSheet) {
                AddNewItemToCartSheet(
                    isPresented: showingAddItemSheet,
                    cart: cart,
                    onItemAdded: {
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger.wrappedValue = UUID()
                    }
                )
                .environment(vaultService)
                .environment(cartViewModel)
            }
            .sheet(isPresented: showingFilterSheet) {
                FilterSheet(selectedFilter: selectedFilter)
            }
    }
    
    func cartAlerts(
        showingStartShoppingAlert: Binding<Bool>,
        showingSwitchToPlanningAlert: Binding<Bool>,
        showingCompleteAlert: Binding<Bool>,
        showingDeleteAlert: Binding<Bool>,
        vaultService: VaultService,
        cart: Cart,
        dismiss: DismissAction,
        refreshTrigger: Binding<UUID>,
        showingCompletedSheet: Binding<Bool>
    ) -> some View {
        self
            .alert("Start Shopping", isPresented: showingStartShoppingAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Start Shopping") {
                    vaultService.startShopping(cart: cart)
                    refreshTrigger.wrappedValue = UUID()
                }
            } message: {
                Text("This will freeze your planned prices. You'll be able to update actual prices during shopping.")
            }
            .alert("Switch to Planning", isPresented: showingSwitchToPlanningAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Switch to Planning") {
                    vaultService.returnToPlanning(cart: cart)
                    refreshTrigger.wrappedValue = UUID()
                }
            } message: {
                Text("Switching back to Planning will reset this trip to your original plan.")
            }
            .alert("Complete Shopping", isPresented: showingCompleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Complete") {
                    vaultService.completeShopping(cart: cart)
                    refreshTrigger.wrappedValue = UUID()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingCompletedSheet.wrappedValue = false
                    }
                }
            } message: {
                Text("This will preserve your shopping data for review.")
            }
            .alert("Delete Cart", isPresented: showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    vaultService.deleteCart(cart)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this cart? This action cannot be undone.")
            }
    }
    
    func cartLifecycle(
        cart: Cart,
        hasItems: Bool,
        showFinishTripButton: Binding<Bool>,
        previousHasItems: Binding<Bool>,
        cartStatusChanged: @escaping (CartStatus, CartStatus) -> Void,
        itemsChanged: @escaping (Bool, Bool) -> Void,
        checkAndShowCelebration: @escaping () -> Void
    ) -> some View {
        self
            .onAppear {
                previousHasItems.wrappedValue = hasItems
                checkAndShowCelebration()
                
                if cart.isShopping && hasItems {
                    showFinishTripButton.wrappedValue = true
                }
            }
            .onChange(of: cart.status) { oldValue, newValue in
                cartStatusChanged(oldValue, newValue)
            }
            .onChange(of: hasItems) { oldValue, newValue in
                itemsChanged(oldValue, newValue)
            }
            .navigationBarBackButtonHidden(true)
    }
    
    func editItemSheet(
        itemToEdit: Binding<Item?>,
        cart: Cart,
        vaultService: VaultService,
        refreshTrigger: Binding<UUID>
    ) -> some View {
        self
            .sheet(item: itemToEdit) { item in
                EditItemSheet(
                    item: item,
                    cart: cart,
                    cartItem: cart.cartItems.first { $0.itemId == item.id },
                    onSave: { updatedItem in
                        print("💾 EditItemSheet saved")
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger.wrappedValue = UUID()
                    },
                    context: .cart
                )
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(24)
                .environment(vaultService)
            }
    }
}
