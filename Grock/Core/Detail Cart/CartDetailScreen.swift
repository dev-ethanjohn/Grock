import SwiftUI
import SwiftData

// MARK: - Image Cache Manager (Put this OUTSIDE CartDetailContent, at top level)
class ImageCacheManager: @unchecked Sendable {
    static let shared = ImageCacheManager()
    private var cache: [String: UIImage] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    func getImage(forCartId cartId: String) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        return cache[cartId]
    }
    
    func saveImage(_ image: UIImage, forCartId cartId: String) {
        lock.lock()
        defer { lock.unlock() }
        cache[cartId] = image
    }
    
    func deleteImage(forCartId cartId: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeValue(forKey: cartId)
    }
    
    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}

struct CartDetailScreen: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    @Environment(CartStateManager.self) private var stateManager
    
    @State private var showingDeleteAlert = false
    @State private var showingCompleteAlert = false
    @State private var itemToEdit: Item? = nil
    @State private var editingItem: CartItem? = nil
    @State private var previousHasItems = false
    @State private var alertManager = AlertManager()
    @Namespace private var buttonNamespace
    
    @State private var itemsByStore: [String: [(cartItem: CartItem, item: Item?)]] = [:]
    @State private var cartInsights: CartInsights = CartInsights()
    @State private var sortedStores: [String] = []
    @State private var didLoadData = false
    
    private var totalItemCount: Int {
        cart.cartItems.count
    }
    
    private var hasItems: Bool {
        totalItemCount > 0
    }
    
    private var currentFulfilledCount: Int {
        cart.cartItems.filter { $0.isFulfilled }.count
    }
    
    private var allItemsCompleted: Bool {
        guard cart.isShopping else { return false }
        let activeItems = cart.cartItems.filter { !$0.isSkippedDuringShopping }
        return activeItems.allSatisfy { $0.isFulfilled } && !activeItems.isEmpty
    }
    
    var body: some View {
        ZStack {
            mainContent
            popoverOverlays
        }
        .environment(stateManager)
        .environment(\.cartStateManager, stateManager)
        .environment(alertManager)
        .modifier(CartDetailAllModifiers(
            cart: cart,
            showingDeleteAlert: $showingDeleteAlert,
            showingCompleteAlert: $showingCompleteAlert,
            itemToEdit: $itemToEdit,
            previousHasItems: $previousHasItems,
            alertManager: $alertManager,
            dismiss: dismiss,
            hasItems: hasItems,
            currentFulfilledCount: currentFulfilledCount,
            onDeleteItem: handleDeleteItem,
            cartStatusChanged: handleCartStatusChange,
            itemsChanged: handleItemsChange,
            checkAndShowCelebration: checkAndShowCelebration,
            onShoppingDataUpdated: handleShoppingDataRefresh
        ))
        .onAppear(perform: initializeState)
        .task(id: cart.id) {
            await loadData()
        }
        .onDisappear(perform: saveStateOnDismiss)
        .onChange(of: cart.cartItems) { _, _ in
            if shouldReloadForItemChanges() {
                Task {
                    await loadData(animate: true)
                }
            }
        }
        .onChange(of: allItemsCompleted) { oldValue, newValue in
            if newValue && !showingCompleteAlert {
                showingCompleteAlert = true
            }
        }
    }
    
    // MARK: - Main Content
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
            previousHasItems: $previousHasItems,
            buttonNamespace: buttonNamespace,
            onDeleteItem: handleDeleteItem
        )
    }
    
    // MARK: - Popover Overlays
    private var popoverOverlays: some View {
        Group {
            // Shopping popover
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
                    },
                    onDismiss: {
                        stateManager.showingShoppingPopover = false
                    }
                )
                .id(stateManager.shoppingPopoverPresentationID)
                .environment(vaultService)
                .zIndex(100)
            }
            
            // Fulfill popover
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
                        
                        if currentFulfilledCount > 0 && !stateManager.showingCompletedSheet {
                            stateManager.showingCompletedSheet = true
                        }
                    },
                    onDismiss: {
                        stateManager.showingFulfillPopover = false
                    }
                )
                .id(stateManager.fulfillPopoverPresentationID)
                .environment(vaultService)
                .zIndex(101)
            }
            
            // Edit cart name popover
            if stateManager.showingEditCartName {
                RenamePopover(
                    isPresented: Binding(
                        get: { stateManager.showingEditCartName },
                        set: { stateManager.showingEditCartName = $0 }
                    ),
                    currentName: cart.name,
                    onSave: { newName in
                        cart.name = newName
                        vaultService.updateCartTotals(cart: cart)
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
            
            // Celebration view
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
            
            // Trip completion celebration (must stay above all other popovers/sheets in this ZStack)
            if stateManager.showTripCompletionCelebration {
                TripCompletionCelebrationOverlay(
                    isPresented: Binding(
                        get: { stateManager.showTripCompletionCelebration },
                        set: { stateManager.showTripCompletionCelebration = $0 }
                    ),
                    message: stateManager.tripCompletionMessage,
                    autoDismissAfter: 2.0,
                    onDismiss: {
                        stateManager.isTripFinishingFromSheet = false
                        stateManager.showingShoppingPopover = false
                        stateManager.showingFulfillPopover = false
                        stateManager.showingEditCartName = false
                        stateManager.showingEditBudget = false
                        stateManager.showingCartSheet = false
                        stateManager.showingFilterSheet = false
                        stateManager.showingCompletedSheet = false
                        
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ShowInsightsAfterTrip"),
                            object: nil,
                            userInfo: ["cartId": cart.id]
                        )
                    }
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(2002)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    @MainActor
    private func loadData(animate: Bool = false) async {
        let sortedItems = cart.cartItems.sorted { ($0.addedAt ?? Date.distantPast) > ($1.addedAt ?? Date.distantPast) }
        let grouped = groupCartItemsByStore(sortedItems)
        
        if animate {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                itemsByStore = grouped
                sortedStores = Array(grouped.keys).sorted()
                cartInsights = vaultService.getCartInsights(cart: cart)
            }
        } else {
            itemsByStore = grouped
            sortedStores = Array(grouped.keys).sorted()
            cartInsights = vaultService.getCartInsights(cart: cart)
        }
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
            let store = cartItem.getStore(cart: cart)
            return store.isEmpty ? "Unknown Store" : store
        }
        
        // Don't filter out valid items even if something weird happened with the key
        return grouped
    }
    
    private func initializeState() {
        // Reset transient state to prevent bleeding from other carts (since StateManager is shared)
        stateManager.showingEditBudget = false
        stateManager.showingShoppingPopover = false
        stateManager.showingFulfillPopover = false
        stateManager.showingEditCartName = false
        stateManager.selectedItemForPopover = nil
        stateManager.selectedCartItemForPopover = nil
        stateManager.showTripCompletionCelebration = false
        stateManager.tripCompletionMessage = ""
        stateManager.isTripFinishingFromSheet = false
        
        stateManager.localBudget = cart.budget
        stateManager.animatedBudget = cart.budget
        
        if let savedHex = UserDefaults.standard.string(forKey: "cartBackgroundColor_\(cart.id)"),
           let savedColor = ColorOption.options.first(where: { $0.hex == savedHex }) {
            stateManager.selectedColor = savedColor
        }
        
        stateManager.hasBackgroundImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cart.id)
        if stateManager.hasBackgroundImage {
            let cartId = cart.id
            if let cached = ImageCacheManager.shared.getImage(forCartId: cartId) {
                stateManager.backgroundImage = cached
            } else {
                Task.detached(priority: .userInitiated) {
                    let image = CartBackgroundImageManager.shared.loadImage(forCartId: cartId)
                    await MainActor.run {
                        stateManager.backgroundImage = image
                        if let image {
                            ImageCacheManager.shared.saveImage(image, forCartId: cartId)
                        }
                    }
                }
            }
        }
        
        if cart.isShopping && hasItems {
            stateManager.showFinishTripButton = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                stateManager.showingCompletedSheet = true
            }
        } else {
            stateManager.showFinishTripButton = false
            stateManager.showingCompletedSheet = false
        }
        
        NotificationCenter.default.post(
            name: Notification.Name("CartDetailPresented"),
            object: nil,
            userInfo: ["cartId": cart.id]
        )
    }
    
    private func saveStateOnDismiss() {
        // Prevent action bar state from bleeding into the next cart detail view.
        stateManager.showFinishTripButton = false
        stateManager.showingCompletedSheet = false

        if stateManager.localBudget != cart.budget {
            cart.budget = stateManager.localBudget
            vaultService.updateCartTotals(cart: cart)
        }
        
        // Post on the next run loop so the destination (Home) view has a chance to re-attach observers.
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("CartDetailDismissed"),
                object: nil,
                userInfo: ["cartId": cart.id]
            )
        }
    }
    
    private func checkAndShowCelebration() {
        let hasSeenCelebration = UserDefaults.standard.bool(forKey: "hasSeenFirstShoppingCartCelebration")
        let isFirstCart = cartViewModel.carts.count == 1 || cartViewModel.isFirstCart(cart)
        
        if !hasSeenCelebration && isFirstCart {
            stateManager.showCelebration = false
            stateManager.manageCartButtonVisible = false
            stateManager.showCelebration = true
            UserDefaults.standard.set(true, forKey: "hasSeenFirstShoppingCartCelebration")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    stateManager.manageCartButtonVisible = true
                }
            }
        } else {
            stateManager.showCelebration = false
            withAnimation {
                stateManager.manageCartButtonVisible = true
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
    
    private func handleDeleteItem(_ cartItem: CartItem) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            // 1. Manually update local state for instant UI response
            let storeKeys = Array(itemsByStore.keys)
            var storeToRemove: String? = nil
            
            for store in storeKeys {
                if var items = itemsByStore[store],
                   let index = items.firstIndex(where: { $0.cartItem.itemId == cartItem.itemId }) {
                    
                    items.remove(at: index)
                    
                    if items.isEmpty {
                        storeToRemove = store
                        itemsByStore.removeValue(forKey: store)
                    } else {
                        itemsByStore[store] = items
                    }
                    break
                }
            }
            
            if let store = storeToRemove {
                sortedStores.removeAll { $0 == store }
            }
            
            // 2. Update Data Source
            vaultService.removeItemFromCart(cart: cart, itemId: cartItem.itemId)
            vaultService.updateCartTotals(cart: cart)
        }
    }
    
    private func handleShoppingDataRefresh() {
        if shouldReloadForItemChanges() {
            Task {
                await loadData(animate: true)
            }
        }
    }
    
    private func shouldReloadForItemChanges() -> Bool {
        let displayedSignature = displayedItemsSignature()
        let cartSignature = cartItemsSignature(from: cart.cartItems)
        return displayedSignature != cartSignature
    }
    
    private func displayedItemsSignature() -> [String] {
        itemsByStore
            .flatMap { store, items in
                items.map { "\(store)|\($0.cartItem.itemId)" }
            }
            .sorted()
    }
    
    private func cartItemsSignature(from items: [CartItem]) -> [String] {
        items
            .map { cartItem in
                let store = cartItem.getStore(cart: cart)
                let resolvedStore = store.isEmpty ? "Unknown Store" : store
                return "\(resolvedStore)|\(cartItem.itemId)"
            }
            .sorted()
    }
}
// Put this in a separate file or at the bottom of CartDetailScreen.swift (outside the struct)

struct CartDetailAllModifiers: ViewModifier {
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(CartStateManager.self) private var stateManager
    
    let cart: Cart
    @Binding var showingDeleteAlert: Bool
    @Binding var showingCompleteAlert: Bool
    @Binding var itemToEdit: Item?
    @Binding var previousHasItems: Bool
    @Binding var alertManager: AlertManager
    
    let dismiss: DismissAction
    let hasItems: Bool
    let currentFulfilledCount: Int
    
    let onDeleteItem: (CartItem) -> Void
    
    let cartStatusChanged: (CartStatus, CartStatus) -> Void
    let itemsChanged: (Bool, Bool) -> Void
    let checkAndShowCelebration: () -> Void
    let onShoppingDataUpdated: () -> Void
    
    func body(content: Content) -> some View {
        content
            // Alerts
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
            .alert("Start Shopping", isPresented: Binding(
                get: { stateManager.showingStartShoppingAlert },
                set: { stateManager.showingStartShoppingAlert = $0 }
            )) {
                Button("Cancel", role: .cancel) { }
                Button("Start Shopping") {
                    vaultService.startShopping(cart: cart)
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
            
            // Sheets
            .editItemSheet(
                itemToEdit: $itemToEdit,
                cart: cart,
                vaultService: vaultService,
                onRemoveFromCart: onDeleteItem
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
                cartViewModel: cartViewModel
            )
            .finishTripSheet(
                cart: cart,
                showing: $showingCompleteAlert,
                vaultService: vaultService,
                cartStateManager: stateManager,
                onTripCompletionSequenceFinished: {
                    stateManager.showingShoppingPopover = false
                    stateManager.showingFulfillPopover = false
                    stateManager.showingEditCartName = false
                    stateManager.showingEditBudget = false
                    stateManager.showingCartSheet = false
                    stateManager.showingFilterSheet = false
                    stateManager.showingCompletedSheet = false
                    stateManager.showTripCompletionCelebration = false
                    stateManager.isTripFinishingFromSheet = false
                    showingCompleteAlert = false

                    dismiss()
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowInsightsAfterTrip"),
                        object: nil,
                        userInfo: ["cartId": cart.id]
                    )
                }
            )
            
            // Lifecycle
            .cartLifecycle(
                cart: cart,
                hasItems: hasItems,
                showFinishTripButton: Binding(
                    get: { stateManager.showFinishTripButton },
                    set: { stateManager.showFinishTripButton = $0 }
                ),
                previousHasItems: $previousHasItems,
                cartStatusChanged: cartStatusChanged,
                itemsChanged: itemsChanged,
                checkAndShowCelebration: checkAndShowCelebration
            )
            
            // Notifications
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShoppingItemQuantityChanged"))) { notification in
                handleShoppingItemQuantityChange(notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: .shoppingDataUpdated)) { notification in
                handleShoppingDataUpdated(notification)
            }
            // Add haptic feedback notifications
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemFulfillmentAnimationStarted"))) { _ in
                // Optional: Add haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemStrikethroughAnimating"))) { _ in
                // Optional: Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemRemovalAnimating"))) { _ in
                // Optional: Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
    }
    
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
        }
    }
    
    private func handleShoppingDataUpdated(_ notification: Notification) {
        if let cartId = notification.userInfo?["cartItemId"] as? String,
           cartId != cart.id {
            return
        }
        if let cartId = notification.userInfo?["cartId"] as? String,
           cartId != cart.id {
            return
        }
        
        onShoppingDataUpdated()
        DispatchQueue.main.async {
            vaultService.updateCartTotals(cart: cart)
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
        vaultService: VaultService
    ) -> some View {
        self.sheet(isPresented: showing) {
            CompletedSheetContent(
                cart: cart,
                detent: detent,
                vaultService: vaultService
            )
        }
    }
}

struct CompletedSheetContent: View {
    let cart: Cart
    @Binding var detent: PresentationDetent
    let vaultService: VaultService
    
    var body: some View {
        CompletedItemsSheet(
            cart: cart,
            onUnfulfillItem: { cartItem in
                if cartItem.isSkippedDuringShopping {
                    let restoredQuantity = max(1, cartItem.originalPlanningQuantity ?? 1)
                    cartItem.quantity = restoredQuantity
                    cartItem.syncQuantities(cart: cart)
                    cartItem.isSkippedDuringShopping = false
                    cartItem.isFulfilled = false
                    vaultService.updateCartTotals(cart: cart)
                    NotificationCenter.default.post(
                        name: .shoppingItemQuantityChanged,
                        object: nil,
                        userInfo: [
                            "cartId": cart.id,
                            "itemId": cartItem.itemId,
                            "itemName": vaultService.findItemById(cartItem.itemId)?.name ?? "",
                            "newQuantity": restoredQuantity,
                            "itemType": "plannedCart"
                        ]
                    )
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShoppingDataUpdated"),
                        object: nil,
                        userInfo: ["cartItemId": cart.id]
                    )
                } else {
                    // Handle unfulfilling a regular completed item
                    vaultService.toggleItemFulfillment(cart: cart, itemId: cartItem.itemId)
                }
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
        self.presentationBackground(.white)
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
    @Binding var previousHasItems: Bool
    var buttonNamespace: Namespace.ID
    let onDeleteItem: (CartItem) -> Void
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss  // Make sure this is available
    
    // Access state manager
    @Environment(CartStateManager.self) private var stateManager
    
    @State private var fulfilledCount: Int = 0
    
    private var currentFulfilledCount: Int {
        cart.cartItems.filter { $0.isFulfilled }.count
    }

    private var shouldShowFinishTripButton: Bool {
        cart.isShopping && hasItems
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack(alignment: .top) {
//                    Color(hex: "#f7f7f7").ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        // CORRECTED: Just pass cart, no bindings needed
                        if hasItems {
                            ModeToggleView(cart: cart)
                        }
                        
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
                                        onDeleteItem: onDeleteItem
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
                        },
                        onDeleteCart: {
                            showingDeleteAlert = true
                        }
                    )
                }
                
                // Floating Action Bar
                if !stateManager.showCelebration && !stateManager.showTripCompletionCelebration && stateManager.manageCartButtonVisible {
                    VStack {
                        Spacer()
                        
                        CartDetailActionBar(
                            showFinishTrip: shouldShowFinishTripButton,
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
//            
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
                            
                            cart.budget = newBudget
                            vaultService.updateCartTotals(cart: cart)
                            NotificationCenter.default.post(name: .cartBudgetUpdated, object: nil, userInfo: ["cartId": cart.id, "budget": newBudget])
                            
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
            handleCartStatusChange(oldValue: oldValue, newValue: newValue)
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
    private func handleCartStatusChange(oldValue: CartStatus, newValue: CartStatus) {
        if oldValue != .completed && newValue == .completed {
            // If FinishTripSheet is currently presented, let the sheet control
            // the celebration + dismissal sequence.
            if showingCompleteAlert {
                return
            }

            if stateManager.isTripFinishingFromSheet {
                return
            }

            showingCompleteAlert = false
            stateManager.tripCompletionMessage = makeTripCompletionMessage()
            stateManager.showTripCompletionCelebration = true
            return
        }

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

    private func makeTripCompletionMessage() -> String {
        let spent = fulfilledSpentTotal()
        let budget = cart.budget
        let epsilon = 0.01
        
        if budget <= 0 {
            let spentText = formatCurrencyNoDecimals(spent)
            return "Trip complete! \(spentText) spent — nice work."
        }
        
        let delta = spent - budget
        let spentText = formatCurrencyNoDecimals(spent)
        let diffText = formatCurrencyNoDecimals(abs(delta))
        
        if delta < -epsilon {
            let templates = [
                "Nicely done! \(spentText) spent, \(diffText) under plan — every choice added up.",
                "Great job! \(spentText) spent, \(diffText) saved — smart decisions made the difference.",
                "On track! \(spentText) spent, \(diffText) under plan — careful planning paid off.",
                "Smart move! \(spentText) spent, \(diffText) under plan — your choices added up.",
                "Well done! \(spentText) spent, \(diffText) below plan — small actions, big result.",
                "Success! \(spentText) spent, \(diffText) under plan — you stayed ahead of your budget.",
                "Smooth trip! \(spentText) spent, \(diffText) under plan — your plan guided you well.",
                "Excellent! \(spentText) spent, \(diffText) under plan — each item counted wisely.",
                "You did it! \(spentText) spent, \(diffText) less than planned — thoughtful shopping wins.",
                "Ahead of plan! \(spentText) spent, \(diffText) under — your choices added up perfectly."
            ]
            return templates.randomElement() ?? "Nice work! \(spentText) spent, \(diffText) under plan."
        }
        
        if delta > epsilon {
            let templates = [
                "Reality check! \(spentText) spent, \(diffText) over plan — now you know what to adjust next time.",
                "Heads up! \(spentText) spent, \(diffText) over plan — prices shifted, lessons learned.",
                "Slightly over! \(spentText) spent, \(diffText) above plan — now your next trip can be smarter.",
                "Take note! \(spentText) spent, \(diffText) over plan — insights gained for next time.",
                "Learning moment! \(spentText) spent, \(diffText) over plan — now you know where to adjust.",
                "Watch out! \(spentText) spent, \(diffText) over plan — prices changed, now you’re informed.",
                "Important insight! \(spentText) spent, \(diffText) over plan — your plan vs reality revealed.",
                "Lesson learned! \(spentText) spent, \(diffText) above plan — use it to shop smarter next time.",
                "Slightly off track! \(spentText) spent, \(diffText) over plan — now you know the real cost.",
                "Reality update! \(spentText) spent, \(diffText) above plan — planning next trip will be easier."
            ]
            return templates.randomElement() ?? "Trip complete! \(spentText) spent, \(diffText) over plan."
        }
        
        let templates = [
            "Perfect match! \(spentText) spent — your plan worked exactly as intended.",
            "Spot on! \(spentText) spent — reality met your plan seamlessly.",
            "Right on target! \(spentText) spent — your shopping went exactly as planned.",
            "Exactly as planned! \(spentText) spent — smooth and precise trip.",
            "Nailed it! \(spentText) spent — your plan was right on point.",
            "Perfect trip! \(spentText) spent — your planning and execution aligned.",
            "On point! \(spentText) spent — your shopping followed the plan perfectly.",
            "Flawless! \(spentText) spent — your plan guided you accurately.",
            "Just right! \(spentText) spent — the plan and reality matched.",
            "All lined up! \(spentText) spent — your planning worked beautifully."
        ]
        
        return templates.randomElement() ?? "On budget! \(spentText) spent."
    }
    
    private func fulfilledSpentTotal() -> Double {
        cart.cartItems
            .filter { $0.quantity > 0 && $0.isFulfilled }
            .reduce(0.0) { total, cartItem in
                let price: Double
                let quantity: Double
                
                if cartItem.isShoppingOnlyItem {
                    price = cartItem.shoppingOnlyPrice ?? 0
                    quantity = cartItem.actualQuantity ?? cartItem.quantity
                } else {
                    price = cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
                    quantity = cartItem.actualQuantity ?? cartItem.quantity
                }
                
                return total + (price * quantity)
            }
    }
    
    private func formatCurrencyNoDecimals(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.currencyCode = CurrencyManager.shared.selectedCurrency.code
        formatter.currencySymbol = CurrencyManager.shared.selectedCurrency.symbol
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: amount))
            ?? "\(CurrencyManager.shared.selectedCurrency.symbol)\(String(format: "%.0f", amount))"
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
        let cartId = cart.id
        let hasImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cartId)
        stateManager.hasBackgroundImage = hasImage
        
        if !(stateManager.selectedColor.hex == "FFFFFF" || hasImage) {
            stateManager.backgroundImage = nil
            stateManager.hasBackgroundImage = false
            return
        }
        
        if let cached = ImageCacheManager.shared.getImage(forCartId: cartId) {
            stateManager.backgroundImage = cached
            stateManager.hasBackgroundImage = true
            return
        }
        
        Task.detached(priority: .userInitiated) { [cartId] in
            let image = CartBackgroundImageManager.shared.loadImage(forCartId: cartId)?.resized(to: 1800)
            await MainActor.run {
                stateManager.backgroundImage = image
                stateManager.hasBackgroundImage = image != nil
                if let image {
                    ImageCacheManager.shared.saveImage(image, forCartId: cartId)
                }
            }
        }
    }
    
    // MARK: - Item Handlers
    private func handleEditItem(cartItem: CartItem) {
        var itemToUse = vaultService.findItemById(cartItem.itemId)
        
        if itemToUse == nil, cartItem.isShoppingOnlyItem {
            itemToUse = Item(
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
        }
        
        if let found = itemToUse {
            if cart.status == .shopping {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    stateManager.shoppingPopoverPresentationID = UUID()
                    stateManager.selectedItemForPopover = found
                    stateManager.selectedCartItemForPopover = cartItem
                    stateManager.showingShoppingPopover = true
                }
            } else {
                itemToEdit = found
            }
        }
    }
    
    private func handleFulfillItem(cartItem: CartItem) {
        if let found = vaultService.findItemById(cartItem.itemId) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                stateManager.fulfillPopoverPresentationID = UUID()
                stateManager.selectedItemForPopover = found
                stateManager.selectedCartItemForPopover = cartItem
                stateManager.showingFulfillPopover = true
            }
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
        cartViewModel: CartViewModel
    ) -> some View {
        return self
            .sheet(isPresented: showingCartSheet) {
                if cart.isPlanning {
                    ManageCartSheet(cart: cart)
                        .environment(vaultService)
                        .environment(cartViewModel)
                        .onDisappear {
                            vaultService.updateCartTotals(cart: cart)
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
                        }
                    )
                    .environment(vaultService)
                    .environment(cartViewModel)
                    .presentationDetents([.large])
                    .presentationBackground(.white)
                    .onDisappear {
                        print("🔄 Shopping sheet dismissed, forcing refresh")
                        vaultService.updateCartTotals(cart: cart)
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
        onRemoveFromCart: ((CartItem) -> Void)? = nil
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
                    },
                    onRemoveFromCart: onRemoveFromCart,
                    context: .cart
                )
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(24)
                .presentationBackground(.white)
                .environment(vaultService)
            }
    }
    
    func finishTripSheet(
        cart: Cart,
        showing: Binding<Bool>,
        vaultService: VaultService,
        cartStateManager: CartStateManager,
        onTripCompletionSequenceFinished: (() -> Void)? = nil
    ) -> some View {
        self.sheet(isPresented: showing) {
            FinishTripSheet(
                cart: cart,
                onTripCompletionSequenceFinished: onTripCompletionSequenceFinished
            )
                .environment(vaultService)
                .environment(\.cartStateManager, cartStateManager)
        }
    }
}
