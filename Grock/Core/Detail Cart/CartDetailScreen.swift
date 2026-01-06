import SwiftUI
import SwiftData

// MARK: - Image Cache Manager (Put this OUTSIDE CartDetailContent, at top level)
class ImageCacheManager {
    static let shared = ImageCacheManager()
    private var cache: [String: UIImage] = [:]
    
    private init() {}
    
    func getImage(forCartId cartId: String) -> UIImage? {
        return cache[cartId]
    }
    
    func saveImage(_ image: UIImage, forCartId cartId: String) {
        cache[cartId] = image
    }
    
    func deleteImage(forCartId cartId: String) {
        cache.removeValue(forKey: cartId)
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

//struct CartDetailScreen: View {
//    let cart: Cart
//    @Environment(VaultService.self) private var vaultService
//    @Environment(CartViewModel.self) private var cartViewModel
//    @Environment(\.dismiss) private var dismiss
//    
//    // All @State properties (from the simpler version)
//    @State private var showingDeleteAlert = false
//    @State private var editingItem: CartItem?
//    @State private var showingCompleteAlert = false
//    @State private var showingStartShoppingAlert = false
//    @State private var showingSwitchToPlanningAlert = false
//    @State private var anticipationOffset: CGFloat = 0
//    @State private var selectedFilter: FilterOption = .all
//    @State private var showingFilterSheet = false
//    @State private var headerHeight: CGFloat = 0
//    @State private var animatedFulfilledAmount: Double = 0
//    @State private var animatedFulfilledPercentage: Double = 0
//    @State private var itemToEdit: Item? = nil
//    
//    @State private var previousHasItems = false
//    @State private var showCelebration = false
//    @State private var manageCartButtonVisible = false
//    @State private var buttonScale: CGFloat = 1.0
//    @State private var shouldBounceAfterCelebration = false
////    @State private var cartReady = false
//    @State private var refreshTrigger = UUID()
//    @State private var showFinishTripButton = false
//    @Namespace private var buttonNamespace
//    @State private var bottomSheetDetent: PresentationDetent = .fraction(0.08)
//    @State private var showingCompletedSheet = false
//    @State private var showingShoppingPopover = false
//    @State private var selectedCartItemForPopover: CartItem?
//    @State private var selectedItemForPopover: Item?
//    @State private var showingFulfillPopover = false
//    @State private var showingEditCartName = false
//    @State private var showingCartSheet = false
//    
//    @State private var alertManager = AlertManager()
//    
//    // Computed properties
//    private var cartInsights: CartInsights {
//        vaultService.getCartInsights(cart: cart)
//    }
//    
//    private var allItemsCompleted: Bool {
//        guard cart.isShopping else { return false }
//        
//        // Get all active items (not skipped)
//        let activeItems = cart.cartItems.filter { !$0.isSkippedDuringShopping }
//        
//        // Check if all active items are fulfilled
//        let allFulfilled = activeItems.allSatisfy { $0.isFulfilled }
//        
//        return allFulfilled && !activeItems.isEmpty
//    }
//    
//    private func groupCartItemsByStore(_ cartItems: [CartItem]) -> [String: [(cartItem: CartItem, item: Item?)]] {
//        let cartItemsWithDetails = cartItems.map { cartItem -> (CartItem, Item?) in
//            // Check if it's a shopping-only item first
//            if cartItem.isShoppingOnlyItem {
//                // Create a temporary Item object for shopping-only items
//                let tempItem = Item(
//                    id: cartItem.itemId,
//                    name: cartItem.shoppingOnlyName ?? "Unknown Item",
//                    priceOptions: cartItem.shoppingOnlyPrice.map { price in
//                        [PriceOption(
//                            store: cartItem.shoppingOnlyStore ?? "Unknown Store",
//                            pricePerUnit: PricePerUnit(
//                                priceValue: price,
//                                unit: cartItem.shoppingOnlyUnit ?? ""
//                            )
//                        )]
//                    } ?? [],
//                    isTemporaryShoppingItem: true,
//                    shoppingPrice: cartItem.shoppingOnlyPrice,
//                    shoppingUnit: cartItem.shoppingOnlyUnit
//                )
//                return (cartItem, tempItem)
//            } else {
//                // Regular vault item
//                return (cartItem, vaultService.findItemById(cartItem.itemId))
//            }
//        }
//        
//        let grouped = Dictionary(grouping: cartItemsWithDetails) { element -> String in
//            let (cartItem, _) = element
//            return cartItem.getStore(cart: cart)
//        }
//        
//        return grouped.filter { !$0.key.isEmpty && !$0.value.isEmpty }
//    }
//    
//    private var itemsByStore: [String: [(cartItem: CartItem, item: Item?)]] {
//        _ = refreshTrigger // This ensures refresh when needed
//        return groupCartItemsByStore(cart.cartItems.sorted { $0.addedAt > $1.addedAt })
//    }
//    
//    private var sortedStores: [String] {
//        Array(itemsByStore.keys).sorted()
//    }
//    
//    private var totalItemCount: Int {
//        cart.cartItems.count
//    }
//    
//    private var hasItems: Bool {
//        totalItemCount > 0 && !sortedStores.isEmpty
//    }
//    
//    private var shouldAnimateTransition: Bool {
//        previousHasItems != hasItems
//    }
//    
//    private func storeItems(for store: String) -> [(cartItem: CartItem, item: Item?)] {
//        itemsByStore[store] ?? []
//    }
//    
//    private var currentFulfilledCount: Int {
//        cart.cartItems.filter { $0.isFulfilled }.count
//    }
//    
//    @ViewBuilder
//    private var mainContent: some View {
//        // Create a computed property with all the bindings
//        let content = createCartDetailContent()
//        content
//    }
//    
//    private func createCartDetailContent() -> CartDetailContent {
//        return CartDetailContent(
//            cart: cart,
//            cartInsights: cartInsights,
//            itemsByStore: itemsByStore,
//            sortedStores: sortedStores,
//            totalItemCount: totalItemCount,
//            hasItems: hasItems,
//            shouldAnimateTransition: shouldAnimateTransition,
//            storeItems: storeItems(for:),
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
//            showingCartSheet: $showingCartSheet,
//            previousHasItems: $previousHasItems,
//            showCelebration: $showCelebration,
//            manageCartButtonVisible: $manageCartButtonVisible,
//            buttonScale: $buttonScale,
//            shouldBounceAfterCelebration: $shouldBounceAfterCelebration,
//            showingFulfillPopover: $showingFulfillPopover,
////            cartReady: $cartReady,
//            refreshTrigger: $refreshTrigger,
//            showFinishTripButton: $showFinishTripButton,
//            buttonNamespace: buttonNamespace,
//            bottomSheetDetent: $bottomSheetDetent,
//            showingCompletedSheet: $showingCompletedSheet,
//            showingShoppingPopover: $showingShoppingPopover,
//            selectedItemForPopover: $selectedItemForPopover,
//            selectedCartItemForPopover: $selectedCartItemForPopover,
//            showingEditCartName: $showingEditCartName
//        )
//    }
//    
//    var body: some View {
//        ZStack {
//            mainContent
//            
//            // Popovers (unchanged)
//            if showingShoppingPopover,
//               let item = selectedItemForPopover,
//               let cartItem = selectedCartItemForPopover {
//                UnifiedItemPopover.edit(
//                    isPresented: $showingShoppingPopover,
//                    item: item,
//                    cart: cart,
//                    cartItem: cartItem,
//                    onSave: {
//                        vaultService.updateCartTotals(cart: cart)
//                        refreshTrigger = UUID()
//                    },
//                    onDismiss: {
//                        showingShoppingPopover = false
//                    }
//                )
//                .environment(vaultService)
//                .transition(.opacity)
//                .zIndex(100)
//            }
//            
//            if showingFulfillPopover,
//               let item = selectedItemForPopover,
//               let cartItem = selectedCartItemForPopover {
//                UnifiedItemPopover.fulfill(
//                    isPresented: $showingFulfillPopover,
//                    item: item,
//                    cart: cart,
//                    cartItem: cartItem,
//                    onSave: {
//                        vaultService.updateCartTotals(cart: cart)
//                        refreshTrigger = UUID()
//                        
//                        if currentFulfilledCount > 0 && !showingCompletedSheet {
//                            showingCompletedSheet = true
//                        }
//                    },
//                    onDismiss: {
//                        showingFulfillPopover = false
//                    }
//                )
//                .environment(vaultService)
//                .transition(.opacity)
//                .zIndex(101)
//            }
//            
//            if showingEditCartName {
//                RenameCartNamePopover(
//                    isPresented: $showingEditCartName,
//                    currentName: cart.name,
//                    onSave: { newName in
//                        cart.name = newName
//                        vaultService.updateCartTotals(cart: cart)
//                        refreshTrigger = UUID()
//                    },
//                    onDismiss: nil
//                )
//                .environment(vaultService)
//                .transition(.opacity)
//                .zIndex(102)
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .background(Color.black.opacity(0.4))
//                .ignoresSafeArea()
//            }
//        }
//        .environment(alertManager) // Provide to environment
//        .alert(
//            alertManager.alertTitle,
//            isPresented: $alertManager.showAlert
//        ) {
//            Button("Cancel", role: .cancel) {
//                alertManager.confirmAction = nil
//            }
//            Button("Remove", role: .destructive) {
//                alertManager.confirmAction?()
//                alertManager.confirmAction = nil
//            }
//        } message: {
//            Text(alertManager.alertMessage)
//        }
//        .editItemSheet(
//            itemToEdit: $itemToEdit,
//            cart: cart,
//            vaultService: vaultService,
//            refreshTrigger: $refreshTrigger
//        )
//        .cartSheets(
//            cart: cart,
//            showingCartSheet: $showingCartSheet,  // Pass the new single binding
//            showingFilterSheet: $showingFilterSheet,
//            selectedFilter: $selectedFilter,
//            vaultService: vaultService,
//            cartViewModel: cartViewModel,
//            refreshTrigger: $refreshTrigger
//        )
//        // Inline alerts to avoid .wrappedValue error
//        .alert("Start Shopping", isPresented: $showingStartShoppingAlert) {
//            Button("Cancel", role: .cancel) { }
//            Button("Start Shopping") {
//                vaultService.startShopping(cart: cart)
//                refreshTrigger = UUID()
//            }
//        } message: {
//            Text("This will freeze your planned prices. You'll be able to update actual prices during shopping.")
//        }
//        .alert("Switch to Planning", isPresented: $showingSwitchToPlanningAlert) {
//            Button("Cancel", role: .cancel) { }
//            Button("Switch to Planning") {
//                vaultService.returnToPlanning(cart: cart)
//                refreshTrigger = UUID()
//            }
//        } message: {
//            Text("Switching back to Planning will reset this trip to your original plan.")
//        }
//        .alert("Delete Cart", isPresented: $showingDeleteAlert) {
//            Button("Cancel", role: .cancel) { }
//            Button("Delete", role: .destructive) {
//                vaultService.deleteCart(cart)
//                dismiss()
//            }
//        } message: {
//            Text("Are you sure you want to delete this cart? This action cannot be undone.")
//        }
//        .cartLifecycle(
//            cart: cart,
//            hasItems: hasItems,
//            showFinishTripButton: $showFinishTripButton,
//            previousHasItems: $previousHasItems,
//            cartStatusChanged: handleCartStatusChange,
//            itemsChanged: handleItemsChange,
//            checkAndShowCelebration: checkAndShowCelebration
//        )
//        .onReceive(NotificationCenter.default.publisher(for: .shoppingItemQuantityChanged)) { notification in
//            handleShoppingItemQuantityChange(notification)
//        }
//        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShoppingItemQuantityChanged"))) { notification in
//            print("🔄 Received ShoppingItemQuantityChanged notification")
//            
//            // Check if this notification is for our current cart
//            if let cartId = notification.userInfo?["cartId"] as? String,
//               cartId == cart.id {
//                
//                // Get the updated quantity from the notification
//                if let newQuantity = notification.userInfo?["newQuantity"] as? Double {
//                    print("✅ Received quantity update: \(newQuantity)")
//                    
//                    // CRITICAL: Sync quantity across all fields
//                    if let itemId = notification.userInfo?["itemId"] as? String,
//                       let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }) {
//                        
//                        // Update both quantity and actualQuantity
//                        cartItem.quantity = newQuantity
//                        cartItem.syncQuantities(cart: cart)
//                        
//                        // If in shopping mode, also update actualQuantity
//                        if cart.isShopping {
//                            cartItem.actualQuantity = newQuantity
//                        }
//                        
//                        print("🔁 Synced cartItem.quantity to: \(cartItem.quantity)")
//                    }
//                }
//                
//                // Force UI refresh
//                DispatchQueue.main.async {
//                    vaultService.updateCartTotals(cart: cart)
//                    refreshTrigger = UUID()
//                }
//            }
//        }
//        // Keep the existing notification listener too
//        .onReceive(NotificationCenter.default.publisher(for: .shoppingDataUpdated)) { notification in
//            print("🔄 Received ShoppingDataUpdated notification")
//            
//            DispatchQueue.main.async {
//                refreshTrigger = UUID()
//                vaultService.updateCartTotals(cart: cart)
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    refreshTrigger = UUID()
//                }
//            }
//        }
//        .finishTripSheet(
//            cart: cart,
//            showing: $showingCompleteAlert,
//            vaultService: vaultService
//        )
//        // Auto-trigger sheet when all items are completed
//        .onChange(of: allItemsCompleted) { oldValue, newValue in
//            if newValue && !showingCompleteAlert {
//                // Small delay to let the user see the checkmark animation
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    showingCompleteAlert = true
//                }
//            }
//        }
//    }
//    
//    // MARK: - Helper Methods
//    
//    private func handleShoppingItemQuantityChange(_ notification: Notification) {
//        print("🔄 Received ShoppingItemQuantityChanged notification")
//        
//        guard let cartId = notification.userInfo?["cartId"] as? String,
//              cartId == cart.id else {
//            print("❌ Notification not for current cart")
//            return
//        }
//        
//        if let itemName = notification.userInfo?["itemName"] as? String,
//           let newQuantity = notification.userInfo?["newQuantity"] as? Double,
//           let itemType = notification.userInfo?["itemType"] as? String {
//            
//            print("✅ Quantity changed for: \(itemName)")
//            print("   New quantity: \(newQuantity)")
//            print("   Item type: \(itemType)")
//            
//            // Verify the actual cart item quantity
//            if let itemId = notification.userInfo?["itemId"] as? String {
//                if let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }) {
//                    print("   🔍 Verification - CartItem.quantity: \(cartItem.quantity)")
//                    
//                    // If there's a mismatch, update the cart item
//                    if cartItem.quantity != newQuantity {
//                        print("   ⚠️ Mismatch detected! Updating cartItem.quantity from \(cartItem.quantity) to \(newQuantity)")
//                        cartItem.quantity = newQuantity
//                    }
//                }
//            }
//            
//            // Force UI refresh
//            DispatchQueue.main.async {
//                vaultService.updateCartTotals(cart: cart)
//                refreshTrigger = UUID()
//                
//                // Additional refresh to ensure UI is updated
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                    refreshTrigger = UUID()
//                }
//            }
//        }
//    }
//    
//    private func checkAndShowCelebration() {
//        let hasSeenCelebration = UserDefaults.standard.bool(forKey: "hasSeenFirstShoppingCartCelebration")
//        let isFirstCart = cartViewModel.carts.count == 1 || cartViewModel.isFirstCart(cart)
//        
//#if DEBUG
//        print("🎉 Cart Celebration Debug:")
//        print("   - hasSeenCelebration: \(hasSeenCelebration)")
//        print("   - Total carts: \(cartViewModel.carts.count)")
//        print("   - Current cart: \(cart.name) (ID: \(cart.id))")
//        print("   - Is first cart: \(isFirstCart)")
//#endif
//        
//        if !hasSeenCelebration && isFirstCart {
//#if DEBUG
//            print("🎉 First cart celebration triggered!")
//#endif
//            
//            showCelebration = true
//            UserDefaults.standard.set(true, forKey: "hasSeenFirstShoppingCartCelebration")
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//                withAnimation {
//                    manageCartButtonVisible = true
//                }
//            }
//        } else {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                withAnimation {
//                    manageCartButtonVisible = true
//                }
//            }
//        }
//    }
//    
//    private func handleCartStatusChange(oldValue: CartStatus, newValue: CartStatus) {
//#if DEBUG
//        print("🛒 Cart status changed: \(oldValue) -> \(newValue)")
//#endif
//        
//        if oldValue != newValue {
//            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                if newValue == .shopping && hasItems {
//                    showFinishTripButton = true
//                } else if newValue == .planning {
//                    showFinishTripButton = false
//                }
//            }
//        }
//        
//        // Combine conditions to avoid duplicate animations
//        let currentFulfilledCount = cart.cartItems.filter { $0.isFulfilled }.count
//        let shouldShowCompletedSheet = newValue == .shopping && hasItems && currentFulfilledCount > 0
//        
//        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//            showingCompletedSheet = shouldShowCompletedSheet
//        }
//    }
//    
//    private func handleItemsChange(oldValue: Bool, newValue: Bool) {
//#if DEBUG
//        print("📦 Items changed: \(oldValue) -> \(newValue)")
//#endif
//        
//        if oldValue != newValue {
//            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                if cart.isShopping && newValue {
//                    showFinishTripButton = true
//                } else if !newValue {
//                    showFinishTripButton = false
//                }
//            }
//        }
//    }
//}

struct CartDetailScreen: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Use state manager for UI state
    @Environment(CartStateManager.self) private var stateManager
    
    // Only keep truly local state
    @State private var showingDeleteAlert = false
    @State private var showingCompleteAlert = false
    @State private var itemToEdit: Item? = nil
    @State private var editingItem: CartItem? = nil
    @State private var refreshTrigger = UUID()
    @State private var previousHasItems = false
    @State private var alertManager = AlertManager()
    @Namespace private var buttonNamespace
    
    // Computed properties
    private var cartInsights: CartInsights {
        vaultService.getCartInsights(cart: cart)
    }
    
    private var allItemsCompleted: Bool {
        guard cart.isShopping else { return false }
        let activeItems = cart.cartItems.filter { !$0.isSkippedDuringShopping }
        return activeItems.allSatisfy { $0.isFulfilled } && !activeItems.isEmpty
    }
    
    private func groupCartItemsByStore(_ cartItems: [CartItem]) -> [String: [(cartItem: CartItem, item: Item?)]] {
        let cartItemsWithDetails = cartItems.map { cartItem -> (CartItem, Item?) in
            if cartItem.isShoppingOnlyItem {
                let tempItem = Item(
                    id: cartItem.itemId,
                    name: cartItem.shoppingOnlyName ?? "Unknown Item",
                    priceOptions: cartItem.shoppingOnlyPrice.map { price in
                        [PriceOption(
                            store: cartItem.shoppingOnlyStore ?? "Unknown Store",
                            pricePerUnit: PricePerUnit(
                                priceValue: price,
                                unit: cartItem.shoppingOnlyUnit ?? ""
                            )
                        )]
                    } ?? [],
                    isTemporaryShoppingItem: true,
                    shoppingPrice: cartItem.shoppingOnlyPrice,
                    shoppingUnit: cartItem.shoppingOnlyUnit
                )
                return (cartItem, tempItem)
            } else {
                return (cartItem, vaultService.findItemById(cartItem.itemId))
            }
        }
        
        let grouped = Dictionary(grouping: cartItemsWithDetails) { element -> String in
            let (cartItem, _) = element
            return cartItem.getStore(cart: cart)
        }
        
        return grouped.filter { !$0.key.isEmpty && !$0.value.isEmpty }
    }
    
    private var itemsByStore: [String: [(cartItem: CartItem, item: Item?)]] {
        _ = refreshTrigger
        return groupCartItemsByStore(cart.cartItems.sorted { $0.addedAt > $1.addedAt })
    }
    
    private var sortedStores: [String] {
        Array(itemsByStore.keys).sorted()
    }
    
    private var totalItemCount: Int {
        cart.cartItems.count
    }
    
    private var hasItems: Bool {
        totalItemCount > 0 && !sortedStores.isEmpty
    }
    
    private var currentFulfilledCount: Int {
        cart.cartItems.filter { $0.isFulfilled }.count
    }
    
    var body: some View {
        ZStack {
            mainContent
            
            // Popovers using state manager
            if stateManager.showingShoppingPopover,
               let item = stateManager.selectedItemForPopover,
               let cartItem = stateManager.selectedCartItemForPopover {
                UnifiedItemPopover.edit(
                    isPresented: Binding(
                        get: { stateManager.showingShoppingPopover },
                        set: { stateManager.showingShoppingPopover = $0 }
                    ),
                    item: item,
                    cart: cart,
                    cartItem: cartItem,
                    onSave: {
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger = UUID()
                    },
                    onDismiss: {
                        stateManager.showingShoppingPopover = false
                    }
                )
                .environment(vaultService)
                .transition(.opacity)
                .zIndex(100)
            }
            
            if stateManager.showingFulfillPopover,
               let item = stateManager.selectedItemForPopover,
               let cartItem = stateManager.selectedCartItemForPopover {
                UnifiedItemPopover.fulfill(
                    isPresented: Binding(
                        get: { stateManager.showingFulfillPopover },
                        set: { stateManager.showingFulfillPopover = $0 }
                    ),
                    item: item,
                    cart: cart,
                    cartItem: cartItem,
                    onSave: {
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger = UUID()
                        
                        if currentFulfilledCount > 0 && !stateManager.showingCompletedSheet {
                            stateManager.showingCompletedSheet = true
                        }
                    },
                    onDismiss: {
                        stateManager.showingFulfillPopover = false
                    }
                )
                .environment(vaultService)
                .transition(.opacity)
                .zIndex(101)
            }
            
            if stateManager.showingEditCartName {
                RenameCartNamePopover(
                    isPresented: Binding(
                        get: { stateManager.showingEditCartName },
                        set: { stateManager.showingEditCartName = $0 }
                    ),
                    currentName: cart.name,
                    onSave: { newName in
                        cart.name = newName
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger = UUID()
                    },
                    onDismiss: nil
                )
                .environment(vaultService)
                .transition(.opacity)
                .zIndex(102)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.4))
                .ignoresSafeArea()
            }
            
            // CelebrationView with manual binding
            if stateManager.showCelebration {
                CelebrationView(
                    isPresented: Binding(
                        get: { stateManager.showCelebration },
                        set: { stateManager.showCelebration = $0 }
                    ),
                    title: "WOW! Your First Shopping Cart! 🎉",
                    subtitle: nil
                )
                .transition(.scale)
                .zIndex(1001)
            }
            
            // EditBudgetPopover with manual binding
            if stateManager.showingEditBudget {
                EditBudgetPopover(
                    isPresented: Binding(
                        get: { stateManager.showingEditBudget },
                        set: { stateManager.showingEditBudget = $0 }
                    ),
                    currentBudget: stateManager.localBudget,
                    onSave: { newBudget in
                        stateManager.isSavingBudget = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            stateManager.localBudget = newBudget
                            
                            withAnimation(.spring(duration: 0.3)) {
                                stateManager.animatedBudget = newBudget
                            }
                            
                            stateManager.isSavingBudget = false
                        }
                    },
                    onDismiss: {
                        if !stateManager.isSavingBudget {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                stateManager.animatedBudget = stateManager.localBudget
                            }
                        }
                    }
                )
                .environment(vaultService)
                .zIndex(1000)
            }
        }
        .environment(stateManager)
        .environment(alertManager)
        .alert(
            alertManager.alertTitle,
            isPresented: $alertManager.showAlert
        ) {
            Button("Cancel", role: .cancel) {
                alertManager.confirmAction = nil
            }
            Button("Remove", role: .destructive) {
                alertManager.confirmAction?()
                alertManager.confirmAction = nil
            }
        } message: {
            Text(alertManager.alertMessage)
        }
        .editItemSheet(
            itemToEdit: $itemToEdit,
            cart: cart,
            vaultService: vaultService,
            refreshTrigger: $refreshTrigger
        )
        .cartSheets(
            cart: cart,
            showingCartSheet: Binding(
                get: { stateManager.showingCartSheet },
                set: { stateManager.showingCartSheet = $0 }
            ),
            showingFilterSheet: Binding(
                get: { stateManager.showingFilterSheet },
                set: { stateManager.showingFilterSheet = $0 }
            ),
            selectedFilter: Binding(
                get: { stateManager.selectedFilter },
                set: { stateManager.selectedFilter = $0 }
            ),
            vaultService: vaultService,
            cartViewModel: cartViewModel,
            refreshTrigger: $refreshTrigger
        )
        .alert("Start Shopping", isPresented: Binding(
            get: { stateManager.showingStartShoppingAlert },
            set: { stateManager.showingStartShoppingAlert = $0 }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Start Shopping") {
                vaultService.startShopping(cart: cart)
                refreshTrigger = UUID()
            }
        } message: {
            Text("This will freeze your planned prices. You'll be able to update actual prices during shopping.")
        }
        .alert("Switch to Planning", isPresented: Binding(
            get: { stateManager.showingSwitchToPlanningAlert },
            set: { stateManager.showingSwitchToPlanningAlert = $0 }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Switch to Planning") {
                vaultService.returnToPlanning(cart: cart)
                refreshTrigger = UUID()
            }
        } message: {
            Text("Switching back to Planning will reset this trip to your original plan.")
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
        .cartLifecycle(
            cart: cart,
            hasItems: hasItems,
            showFinishTripButton: Binding(
                get: { stateManager.showFinishTripButton },
                set: { stateManager.showFinishTripButton = $0 }
            ),
            previousHasItems: $previousHasItems,
            cartStatusChanged: handleCartStatusChange,
            itemsChanged: handleItemsChange,
            checkAndShowCelebration: checkAndShowCelebration
        )
        .finishTripSheet(
            cart: cart,
            showing: $showingCompleteAlert,
            vaultService: vaultService
        )
        .onAppear {
            initializeState()
        }
        .onDisappear {
            saveStateOnDismiss()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShoppingItemQuantityChanged"))) { notification in
            handleShoppingItemQuantityChange(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .shoppingDataUpdated)) { notification in
            handleShoppingDataUpdated(notification)
        }
        .onChange(of: allItemsCompleted) { oldValue, newValue in
            if newValue && !showingCompleteAlert {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingCompleteAlert = true
                }
            }
        }
    }
    
    private var mainContent: some View {
        CartDetailContent(
            cart: cart,
            cartInsights: cartInsights,
            itemsByStore: itemsByStore,
            sortedStores: sortedStores,
            totalItemCount: totalItemCount,
            hasItems: hasItems,
            shouldAnimateTransition: previousHasItems != hasItems,
            storeItems: { store in itemsByStore[store] ?? [] },
            showingDeleteAlert: $showingDeleteAlert,
            editingItem: $editingItem,
            showingCompleteAlert: $showingCompleteAlert,
            itemToEdit: $itemToEdit,
            refreshTrigger: $refreshTrigger,
            previousHasItems: $previousHasItems,
            buttonNamespace: buttonNamespace
        )
    }
    
    // MARK: - Initialization
    private func initializeState() {
        // Initialize budget
        stateManager.localBudget = cart.budget
        stateManager.animatedBudget = cart.budget
        
        // Load saved color
        if let savedHex = UserDefaults.standard.string(forKey: "cartBackgroundColor_\(cart.id)"),
           let savedColor = ColorOption.options.first(where: { $0.hex == savedHex }) {
            stateManager.selectedColor = savedColor
        }
        
        // Load background image
        stateManager.hasBackgroundImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cart.id)
        if stateManager.hasBackgroundImage {
            stateManager.backgroundImage = CartBackgroundImageManager.shared.loadImage(forCartId: cart.id)
        }
        
        // Set initial shopping state
        if cart.isShopping && hasItems {
            stateManager.showFinishTripButton = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    stateManager.showingCompletedSheet = true
                }
            }
        }
    }
    
    private func saveStateOnDismiss() {
        if stateManager.localBudget != cart.budget {
            cart.budget = stateManager.localBudget
            vaultService.updateCartTotals(cart: cart)
        }
    }
    
    // MARK: - Helper Methods
    private func handleShoppingItemQuantityChange(_ notification: Notification) {
        guard let cartId = notification.userInfo?["cartId"] as? String,
              cartId == cart.id,
              let newQuantity = notification.userInfo?["newQuantity"] as? Double,
              let itemId = notification.userInfo?["itemId"] as? String else { return }
        
        if let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }) {
            cartItem.quantity = newQuantity
            cartItem.syncQuantities(cart: cart)
            
            if cart.isShopping {
                cartItem.actualQuantity = newQuantity
            }
        }
        
        DispatchQueue.main.async {
            vaultService.updateCartTotals(cart: cart)
            refreshTrigger = UUID()
        }
    }
    
    private func handleShoppingDataUpdated(_ notification: Notification) {
        DispatchQueue.main.async {
            refreshTrigger = UUID()
            vaultService.updateCartTotals(cart: cart)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                refreshTrigger = UUID()
            }
        }
    }
    
    private func checkAndShowCelebration() {
        let hasSeenCelebration = UserDefaults.standard.bool(forKey: "hasSeenFirstShoppingCartCelebration")
        let isFirstCart = cartViewModel.carts.count == 1 || cartViewModel.isFirstCart(cart)
        
        if !hasSeenCelebration && isFirstCart {
            stateManager.showCelebration = true
            UserDefaults.standard.set(true, forKey: "hasSeenFirstShoppingCartCelebration")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    stateManager.manageCartButtonVisible = true
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    stateManager.manageCartButtonVisible = true
                }
            }
        }
    }
    
    private func handleCartStatusChange(oldValue: CartStatus, newValue: CartStatus) {
        if oldValue != newValue {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                if newValue == .shopping && hasItems {
                    stateManager.showFinishTripButton = true
                } else if newValue == .planning {
                    stateManager.showFinishTripButton = false
                }
            }
        }
        
        let shouldShowCompletedSheet = newValue == .shopping && hasItems && currentFulfilledCount > 0
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            stateManager.showingCompletedSheet = shouldShowCompletedSheet
        }
    }
    
    private func handleItemsChange(oldValue: Bool, newValue: Bool) {
        if oldValue != newValue {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                if cart.isShopping && newValue {
                    stateManager.showFinishTripButton = true
                } else if !newValue {
                    stateManager.showFinishTripButton = false
                }
            }
        }
    }
}


// ... rest of the file remains the same (enum PopoverMode, extensions, etc.) ...

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

//struct CartDetailContent: View {
//    let cart: Cart
//    let cartInsights: CartInsights
//    let itemsByStore: [String: [(cartItem: CartItem, item: Item?)]]
//    let sortedStores: [String]
//    let totalItemCount: Int
//    let hasItems: Bool
//    let shouldAnimateTransition: Bool
//    let storeItems: (String) -> [(cartItem: CartItem, item: Item?)]
//    
//    @Binding var showingDeleteAlert: Bool
//    @Binding var editingItem: CartItem?
//    @Binding var showingCompleteAlert: Bool
//    
//    @Binding var showingStartShoppingAlert: Bool
//    @Binding var showingSwitchToPlanningAlert: Bool
//    
//    @Binding var anticipationOffset: CGFloat
//    
//    @Binding var selectedFilter: FilterOption
//    @Binding var showingFilterSheet: Bool
//    
//    @Binding var headerHeight: CGFloat
//    
//    @Binding var animatedFulfilledAmount: Double
//    @Binding var animatedFulfilledPercentage: Double
//    
//    @Binding var itemToEdit: Item?
//    
//    @Binding var showingCartSheet: Bool
//    
//    @Binding var previousHasItems: Bool
//    
//    @Binding var showCelebration: Bool
//    
//    @Binding var manageCartButtonVisible: Bool
//    @Binding var buttonScale: CGFloat
//    @Binding var shouldBounceAfterCelebration: Bool
//    
//    @Binding var showingFulfillPopover: Bool
//    
////    @Binding var cartReady: Bool
//    @Binding var refreshTrigger: UUID
//    
//    @State private var localBudget: Double = 0
//    @State private var isSavingBudget = false
//    @State private var animatedBudget: Double = 0
//    @State private var showEditBudget = false
//    
//    @State private var backgroundImage: UIImage? = nil
//    @State private var hasBackgroundImage = false
//    
//    @Environment(VaultService.self) private var vaultService
//    @Environment(CartViewModel.self) private var cartViewModel
//    @Environment(\.dismiss) private var dismiss
//    
//    @Binding var showFinishTripButton: Bool
//    var buttonNamespace: Namespace.ID
//    
//    @State private var fulfilledCount: Int = 0
//    
//    private var currentFulfilledCount: Int {
//        cart.cartItems.filter { $0.isFulfilled }.count
//    }
//    
//    @Binding var bottomSheetDetent: PresentationDetent
//    @Binding var showingCompletedSheet: Bool
//    
//    @Binding var showingShoppingPopover: Bool
//    @Binding var selectedItemForPopover: Item?
//    @Binding var selectedCartItemForPopover: CartItem?
//    
//    @Binding var showingEditCartName: Bool
//    
//    @Bindable var colorManager = CartColorManager.shared
//    
//    private var selectedColor: ColorOption {
//        colorManager.getColor(for: cart.id)
//    }
//    
//    private var backgroundColor: Color {
//        selectedColor.hex == "FFFFFF" ? Color.clear : selectedColor.color.darker(by: 0.02)
//    }
//    
//    private var rowBackgroundColor: Color {
//        selectedColor.hex == "FFFFFF" ? Color.clear : selectedColor.color
//    }
//    
//    private var effectiveBackgroundColor: Color {
//        if hasBackgroundImage {
//            return Color.clear
//        } else {
//            return selectedColor.hex == "FFFFFF" ? Color.clear : selectedColor.color.darker(by: 0.02)
//        }
//    }
//    
//    private var effectiveRowBackgroundColor: Color {
//        if hasBackgroundImage {
//            return .clear
//        } else {
//            return selectedColor.hex == "FFFFFF" ? Color.clear : selectedColor.color.darker(by: 0.02)
//        }
//    }
//    
//    // MARK: - Body
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                //                if cartReady { // Check both flags
//                ZStack(alignment: .top) {
//                    VStack(spacing: 12) {
//                        ModeToggleView(
//                            cart: cart,
//                            anticipationOffset: $anticipationOffset,
//                            showingStartShoppingAlert: $showingStartShoppingAlert,
//                            showingSwitchToPlanningAlert: $showingSwitchToPlanningAlert,
//                            headerHeight: $headerHeight,
//                            refreshTrigger: $refreshTrigger,
//                            selectedColor: Binding(
//                                get: { selectedColor },
//                                set: { newColor in
//                                    colorManager.setColor(newColor, for: cart.id)
//                                }
//                            )
//                        )
//                        
//                        ZStack {
//                            if hasItems {
//                                VStack(spacing: 24) {
//                                    ItemsListView(
//                                        cart: cart,
//                                        totalItemCount: totalItemCount,
//                                        sortedStoresWithRefresh: sortedStores,
//                                        storeItemsWithRefresh: storeItems,
//                                        fulfilledCount: $fulfilledCount,
//                                        backgroundColor: effectiveBackgroundColor,
//                                        rowBackgroundColor: effectiveRowBackgroundColor,
//                                        hasBackgroundImage: hasBackgroundImage,
//                                        backgroundImage: backgroundImage,
//                                        onFulfillItem: { cartItem in
//                                            handleFulfillItem(cartItem: cartItem)
//                                        },
//                                        onEditItem: { cartItem in
//                                            handleEditItem(cartItem: cartItem)
//                                        },
//                                        onDeleteItem: { cartItem in
//                                            handleDeleteItem(cartItem)
//                                        }
//                                    )
//                                    .transition(.scale)
//                                }
//                            } else {
//                                EmptyCartView()
//                                    .transition(.scale)
//                                    .offset(y: 80)
//                            }
//                        }
//                        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: hasItems)
//                        
//                        Spacer(minLength: 0)
//                    }
//                    .padding(.vertical, 28)
//                    .padding(.horizontal)
//                    .frame(maxHeight: .infinity, alignment: .top)
//                    
//                    HeaderView(
//                        cart: cart,
//                        animatedBudget: animatedBudget,
//                        localBudget: localBudget,
//                        showingDeleteAlert: $showingDeleteAlert,
//                        showingCompleteAlert: $showingCompleteAlert,
//                        showingStartShoppingAlert: $showingStartShoppingAlert,
//                        headerHeight: $headerHeight,
//                        dismiss: dismiss,
//                        showingEditCartName: $showingEditCartName,
//                        refreshTrigger: $refreshTrigger,
//                        onBudgetTap: {
//                            showEditBudget = true
//                        }
//                    )
//                }
//                
//                // Floating Action Bar
//                // Floating Action Bar
//                if !showCelebration && manageCartButtonVisible {
//                    VStack {
//                        Spacer()
//                        
//                        CartDetailActionBar(
//                            showFinishTrip: showFinishTripButton,
//                            onManageCart: {
//                                showingCartSheet = true
//                            },
//                            onFinishTrip: {
//                                showingCompleteAlert = true
//                            },
//                            namespace: buttonNamespace
//                        )
//                        .padding(.horizontal, 16)
//                    }
//                    .transition(.move(edge: .bottom).combined(with: .opacity))
//                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: manageCartButtonVisible)
//                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showingCompletedSheet)
//                }
//            }
//            
//            if showEditBudget {
//                EditBudgetPopover(
//                    isPresented: $showEditBudget,
//                    currentBudget: localBudget,
//                    onSave: { newBudget in
//                        isSavingBudget = true
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//                            localBudget = newBudget
//                            
//                            withAnimation(.spring(duration: 0.3)) {
//                                animatedBudget = newBudget
//                            }
//                            
//                            isSavingBudget = false
//                        }
//                    },
//                    onDismiss: {
//                        if !isSavingBudget {
//                            withAnimation(.easeInOut(duration: 0.3)) {
//                                animatedBudget = localBudget
//                            }
//                        }
//                    }
//                )
//                .environment(vaultService)
//                .zIndex(1000)
//            }
//            
//            if showCelebration {
//                CelebrationView(
//                    isPresented: $showCelebration,
//                    title: "WOW! Your First Shopping Cart! 🎉",
//                    subtitle: nil
//                )
//                .transition(.scale)
//                .zIndex(1001)
//            }
//        }
//    
//        .ignoresSafeArea(.keyboard)
//        .onAppear {
//            // Initialize budget and preload image
//            animatedBudget = cart.budget
//            localBudget = cart.budget
//            
//            // Set initial button state
//            if cart.isShopping && hasItems {
//                showFinishTripButton = true
//            }
//            
//            // Preload background image on appear
////            preloadBackgroundImage()
//            loadBackgroundImageAsync()
//            
//            if cart.isShopping {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                        showingCompletedSheet = true
//                    }
//                }
//            }
//        }
//        .onDisappear {
//            // Save to actual cart ONLY when dismissing CartDetailScreen
//            if localBudget != cart.budget {
//                cart.budget = localBudget
//                vaultService.updateCartTotals(cart: cart)
//#if DEBUG
//                print("💾 Saved budget update: \(cart.name) = \(localBudget)")
//#endif
//            }
//        }
//        .onChange(of: cart.budget) { oldValue, newValue in
//            if localBudget != newValue {
//                localBudget = newValue
//                withAnimation(.easeInOut(duration: 0.3)) {
//                    animatedBudget = newValue
//                }
//            }
//        }
//        .onChange(of: cart.status) { oldValue, newValue in
//#if DEBUG
//            print("🛒 Cart status changed: \(oldValue) -> \(newValue)")
//#endif
//            
//            // Show/hide bottom sheet based on shopping mode
//            if newValue == .shopping && hasItems {
//                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                    showingCompletedSheet = true
//                }
//            } else if newValue == .planning {
//                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                    showingCompletedSheet = false
//                }
//            }
//        }
//        .onChange(of: currentFulfilledCount) { oldValue, newValue in
//            // Show bottom sheet when we get our first completed item
//            if cart.isShopping && !showingCompletedSheet && newValue > 0 {
//                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                    showingCompletedSheet = true
//                }
//            }
//            // Hide bottom sheet when all items are unfulfilled
//            else if cart.isShopping && showingCompletedSheet && newValue == 0 {
//                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                    showingCompletedSheet = false
//                }
//            }
//        }
//        .onChange(of: selectedColor) { oldValue, newValue in
//            // When color changes to white, check for background image
//            loadBackgroundImage()
//            
//            // Post notification for color change
//            NotificationCenter.default.post(
//                name: Notification.Name("CartColorChanged"),
//                object: nil,
//                userInfo: ["cartId": cart.id, "colorHex": newValue.hex]
//            )
//        }
//        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CartBackgroundImageChanged"))) { notification in
//            // Reload image when notification is received
//            if let cartId = notification.userInfo?["cartId"] as? String,
//               cartId == cart.id {
//                loadBackgroundImage()
//            }
//        }
//    }
//    
//    // MARK: - Background Image Loading
//    
//    private func loadBackgroundImageAsync() {
//        // Check if we have a background image saved
//        hasBackgroundImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cart.id)
//        
//        if hasBackgroundImage {
//            // Try cache first (instant)
//            if let cachedImage = ImageCacheManager.shared.getImage(forCartId: cart.id) {
//                backgroundImage = cachedImage
//                return
//            }
//            
//            // Load from disk async
//            DispatchQueue.global(qos: .userInitiated).async {
//                if let image = CartBackgroundImageManager.shared.loadImage(forCartId: cart.id) {
//                    // Cache it
//                    ImageCacheManager.shared.saveImage(image, forCartId: cart.id)
//                    
//                    DispatchQueue.main.async {
//                        backgroundImage = image
//                    }
//                } else {
//                    // If loading fails, clear the flag
//                    DispatchQueue.main.async {
//                        hasBackgroundImage = false
//                    }
//                }
//            }
//        }
//    }
//    
//    private func preloadBackgroundImage() {
//        // Check cache first - this is instant
//        if let cachedImage = ImageCacheManager.shared.getImage(forCartId: cart.id) {
//            self.backgroundImage = cachedImage
//            self.hasBackgroundImage = true
////            self.isImageLoaded = true
//            return
//        }
//        
//        // Check if we should have an image
//        hasBackgroundImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cart.id)
//        
//        if hasBackgroundImage {
//            // Load from disk once, then cache
//            DispatchQueue.global(qos: .userInitiated).async {
//                if let image = CartBackgroundImageManager.shared.loadImage(forCartId: cart.id) {
//                    ImageCacheManager.shared.saveImage(image, forCartId: cart.id)
//                    
//                    DispatchQueue.main.async {
//                        self.backgroundImage = image
////                        self.isImageLoaded = true
//                    }
//                } else {
//                    DispatchQueue.main.async {
//                        self.hasBackgroundImage = false
////                        self.isImageLoaded = true
//                    }
//                }
//            }
//        } else {
//            // No image needed, mark as loaded immediately
////            self.isImageLoaded = true
//        }
//    }
//    
//    private func loadBackgroundImage() {
//        // Check if we have a background image
//        hasBackgroundImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cart.id)
//        
//        // If we have white background selected OR have an image, load it
//        if selectedColor.hex == "FFFFFF" || hasBackgroundImage {
//            // Try cache first
//            if let cachedImage = ImageCacheManager.shared.getImage(forCartId: cart.id) {
//                backgroundImage = cachedImage
//                hasBackgroundImage = true
//            } else {
//                // Load from disk
//                backgroundImage = CartBackgroundImageManager.shared.loadImage(forCartId: cart.id)
//                hasBackgroundImage = backgroundImage != nil
//            }
//        } else {
//            backgroundImage = nil
//            hasBackgroundImage = false
//        }
//    }
//    
//    // MARK: - Item Handlers
//    
//    private func handleEditItem(cartItem: CartItem) {
//        if let found = vaultService.findItemById(cartItem.itemId) {
//            if cart.status == .shopping {
//                // Shopping mode: Use UnifiedItemPopover
//                selectedItemForPopover = found
//                selectedCartItemForPopover = cartItem
//                showingShoppingPopover = true
//            } else {
//                // Planning mode: Use EditItemSheet
//                itemToEdit = found
//            }
//        }
//    }
//    
//    private func handleDeleteItem(_ cartItem: CartItem) {
//        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//            // This should remove the item from cart
//            vaultService.removeItemFromCart(cart: cart, itemId: cartItem.itemId)
//            vaultService.updateCartTotals(cart: cart)
//            refreshTrigger = UUID() // This triggers a gentle refresh
//        }
//    }
//    
//    private func handleFulfillItem(cartItem: CartItem) {
//        if let found = vaultService.findItemById(cartItem.itemId) {
//            // Show the fulfillment confirmation popover
//            selectedItemForPopover = found
//            selectedCartItemForPopover = cartItem
//            
//            // This will trigger the popover at the CartDetailScreen level
//            showingFulfillPopover = true
//        }
//    }
//}

struct CartDetailContent: View {
    let cart: Cart
    let cartInsights: CartInsights
    let itemsByStore: [String: [(cartItem: CartItem, item: Item?)]]
    let sortedStores: [String]
    let totalItemCount: Int
    let hasItems: Bool
    let shouldAnimateTransition: Bool
    let storeItems: (String) -> [(cartItem: CartItem, item: Item?)]
    
    // Only essential bindings
    @Binding var showingDeleteAlert: Bool
    @Binding var editingItem: CartItem?
    @Binding var showingCompleteAlert: Bool
    @Binding var itemToEdit: Item?
    @Binding var refreshTrigger: UUID
    @Binding var previousHasItems: Bool
    var buttonNamespace: Namespace.ID
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss  // Make sure this is available
    
    // Access state manager
    @Environment(CartStateManager.self) private var stateManager
    
    @State private var fulfilledCount: Int = 0
    
    private var currentFulfilledCount: Int {
        cart.cartItems.filter { $0.isFulfilled }.count
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack(alignment: .top) {
                    VStack(spacing: 12) {
                        // CORRECTED: Just pass cart, no bindings needed
                        ModeToggleView(cart: cart)
                        
                        ZStack {
                            if hasItems {
                                VStack(spacing: 24) {
                                    ItemsListView(
                                        cart: cart,
                                        totalItemCount: totalItemCount,
                                        sortedStoresWithRefresh: sortedStores,
                                        storeItemsWithRefresh: storeItems,
                                        fulfilledCount: $fulfilledCount,
                                        onFulfillItem: handleFulfillItem,
                                        onEditItem: handleEditItem,
                                        onDeleteItem: handleDeleteItem
                                    )
                                    .transition(.scale)
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
                    
                    // CORRECTED: HeaderView with proper parameters
                    HeaderView(
                        cart: cart,
                        dismiss: dismiss,
                        onBudgetTap: {
                            stateManager.showingEditBudget = true
                        }
                    )
                }
                
                // Floating Action Bar
                if !stateManager.showCelebration && stateManager.manageCartButtonVisible {
                    VStack {
                        Spacer()
                        
                        CartDetailActionBar(
                            showFinishTrip: stateManager.showFinishTripButton,
                            onManageCart: {
                                stateManager.showingCartSheet = true
                            },
                            onFinishTrip: {
                                showingCompleteAlert = true
                            },
                            namespace: buttonNamespace
                        )
                        .padding(.horizontal, 16)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: stateManager.manageCartButtonVisible)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: stateManager.showingCompletedSheet)
                }
            }
            
            if stateManager.showingEditBudget {
                EditBudgetPopover(
                    isPresented: Binding(
                        get: { stateManager.showingEditBudget },
                        set: { stateManager.showingEditBudget = $0 }
                    ),
                    currentBudget: stateManager.localBudget,
                    onSave: { newBudget in
                        stateManager.isSavingBudget = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            stateManager.localBudget = newBudget
                            
                            withAnimation(.spring(duration: 0.3)) {
                                stateManager.animatedBudget = newBudget
                            }
                            
                            stateManager.isSavingBudget = false
                        }
                    },
                    onDismiss: {
                        if !stateManager.isSavingBudget {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                stateManager.animatedBudget = stateManager.localBudget
                            }
                        }
                    }
                )
                .environment(vaultService)
                .zIndex(1000)
            }
            
            if stateManager.showCelebration {
                CelebrationView(
                    isPresented: Binding(
                        get: { stateManager.showCelebration },
                        set: { stateManager.showCelebration = $0 }
                    ),
                    title: "WOW! Your First Shopping Cart! 🎉",
                    subtitle: nil
                )
                .transition(.scale)
                .zIndex(1001)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: cart.budget) { oldValue, newValue in
            if stateManager.localBudget != newValue {
                stateManager.localBudget = newValue
                withAnimation(.easeInOut(duration: 0.3)) {
                    stateManager.animatedBudget = newValue
                }
            }
        }
        .onChange(of: cart.status) { oldValue, newValue in
            handleCartStatusChange(newValue)
        }
        .onChange(of: currentFulfilledCount) { oldValue, newValue in
            handleFulfilledCountChange(newValue)
        }
        .onChange(of: stateManager.selectedColor) { oldValue, newValue in
            handleColorChange(newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CartBackgroundImageChanged"))) { notification in
            handleBackgroundImageChange(notification)
        }
    }
    
    // MARK: - Event Handlers
    private func handleCartStatusChange(_ newValue: CartStatus) {
        if newValue == .shopping && hasItems {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                stateManager.showingCompletedSheet = true
            }
        } else if newValue == .planning {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                stateManager.showingCompletedSheet = false
            }
        }
    }
    
    private func handleFulfilledCountChange(_ newValue: Int) {
        if cart.isShopping && !stateManager.showingCompletedSheet && newValue > 0 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                stateManager.showingCompletedSheet = true
            }
        } else if cart.isShopping && stateManager.showingCompletedSheet && newValue == 0 {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                stateManager.showingCompletedSheet = false
            }
        }
    }
    
    private func handleColorChange(_ newColor: ColorOption) {
        loadBackgroundImage()
        NotificationCenter.default.post(
            name: Notification.Name("CartColorChanged"),
            object: nil,
            userInfo: ["cartId": cart.id, "colorHex": newColor.hex]
        )
    }
    
    private func handleBackgroundImageChange(_ notification: Notification) {
        if let cartId = notification.userInfo?["cartId"] as? String,
           cartId == cart.id {
            loadBackgroundImage()
        }
    }
    
    private func loadBackgroundImage() {
        stateManager.hasBackgroundImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cart.id)
        
        if stateManager.selectedColor.hex == "FFFFFF" || stateManager.hasBackgroundImage {
            if let cachedImage = ImageCacheManager.shared.getImage(forCartId: cart.id) {
                stateManager.backgroundImage = cachedImage
                stateManager.hasBackgroundImage = true
            } else {
                stateManager.backgroundImage = CartBackgroundImageManager.shared.loadImage(forCartId: cart.id)
                stateManager.hasBackgroundImage = stateManager.backgroundImage != nil
            }
        } else {
            stateManager.backgroundImage = nil
            stateManager.hasBackgroundImage = false
        }
    }
    
    // MARK: - Item Handlers
    private func handleEditItem(cartItem: CartItem) {
        if let found = vaultService.findItemById(cartItem.itemId) {
            if cart.status == .shopping {
                stateManager.selectedItemForPopover = found
                stateManager.selectedCartItemForPopover = cartItem
                stateManager.showingShoppingPopover = true
            } else {
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
            stateManager.selectedItemForPopover = found
            stateManager.selectedCartItemForPopover = cartItem
            stateManager.showingFulfillPopover = true
        }
    }
}



extension View {
    func cartSheets(
        cart: Cart,
        showingCartSheet: Binding<Bool>,
        showingFilterSheet: Binding<Bool>,
        selectedFilter: Binding<FilterOption>,
        vaultService: VaultService,
        cartViewModel: CartViewModel,
        refreshTrigger: Binding<UUID>
    ) -> some View {
        self
            .sheet(isPresented: showingCartSheet) {
                if cart.isPlanning {
                    ManageCartSheet(cart: cart)
                        .environment(vaultService)
                        .environment(cartViewModel)
                        .onDisappear {
                            vaultService.updateCartTotals(cart: cart)
                            refreshTrigger.wrappedValue = UUID()
                        }
                } else {
                    AddNewItemToCartSheet(
                        isPresented: showingCartSheet,
                        cart: cart,
                        onItemAdded: {
                            print("🎯 Shopping-only item added callback triggered")
                            
                            // Force multiple updates
                            vaultService.updateCartTotals(cart: cart)
                            
                            // Send notification
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShoppingDataUpdated"),
                                object: nil,
                                userInfo: ["cartItemId": cart.id]
                            )
                            
                            // Update refresh trigger multiple times to ensure update
                            refreshTrigger.wrappedValue = UUID()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                refreshTrigger.wrappedValue = UUID()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    refreshTrigger.wrappedValue = UUID()
                                }
                            }
                        }
                    )
                    .environment(vaultService)
                    .environment(cartViewModel)
                    .onDisappear {
                        print("🔄 Shopping sheet dismissed, forcing refresh")
                        vaultService.updateCartTotals(cart: cart)
                        refreshTrigger.wrappedValue = UUID()
                    }
                }
            }
            .sheet(isPresented: showingFilterSheet) {
                FilterSheet(selectedFilter: selectedFilter)
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
    
    func finishTripSheet(
        cart: Cart,
        showing: Binding<Bool>,
        vaultService: VaultService
    ) -> some View {
        self.sheet(isPresented: showing) {
            FinishTripSheet(cart: cart)
                .environment(vaultService)
        }
    }
}

