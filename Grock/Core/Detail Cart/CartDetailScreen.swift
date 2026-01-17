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
    
    // Computed properties
    private var cartInsights: CartInsights {
        vaultService.getCartInsights(cart: cart)
    }
    
    private var itemsByStore: [String: [(cartItem: CartItem, item: Item?)]] {
        return groupCartItemsByStore(cart.cartItems.sorted { ($0.addedAt ?? Date.distantPast) > ($1.addedAt ?? Date.distantPast) })
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
        .environment(alertManager)
        .modifier(CartDetailAllModifiers(
            cart: cart,
            showingDeleteAlert: $showingDeleteAlert,
            showingCompleteAlert: $showingCompleteAlert,
            itemToEdit: $itemToEdit,
            previousHasItems: $previousHasItems,
            alertManager: $alertManager,
            hasItems: hasItems,
            currentFulfilledCount: currentFulfilledCount,
            cartStatusChanged: handleCartStatusChange,
            itemsChanged: handleItemsChange,
            checkAndShowCelebration: checkAndShowCelebration
        ))
        .onAppear(perform: initializeState)
        .onDisappear(perform: saveStateOnDismiss)
        .onChange(of: allItemsCompleted) { oldValue, newValue in
            if newValue && !showingCompleteAlert {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingCompleteAlert = true
                }
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
            buttonNamespace: buttonNamespace
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
                .environment(vaultService)
                .transition(.opacity)
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
                .environment(vaultService)
                .transition(.opacity)
                .zIndex(101)
            }
            
            // Edit cart name popover
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
        }
    }
    
    // MARK: - Helper Functions
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
    
    private func initializeState() {
        stateManager.localBudget = cart.budget
        stateManager.animatedBudget = cart.budget
        
        if let savedHex = UserDefaults.standard.string(forKey: "cartBackgroundColor_\(cart.id)"),
           let savedColor = ColorOption.options.first(where: { $0.hex == savedHex }) {
            stateManager.selectedColor = savedColor
        }
        
        stateManager.hasBackgroundImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cart.id)
        if stateManager.hasBackgroundImage {
            stateManager.backgroundImage = CartBackgroundImageManager.shared.loadImage(forCartId: cart.id)
        }
        
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
    
    let hasItems: Bool
    let currentFulfilledCount: Int
    
    let cartStatusChanged: (CartStatus, CartStatus) -> Void
    let itemsChanged: (Bool, Bool) -> Void
    let checkAndShowCelebration: () -> Void
    
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
                }
            } message: {
                Text("Are you sure you want to delete this cart? This action cannot be undone.")
            }
            
            // Sheets
            .editItemSheet(
                itemToEdit: $itemToEdit,
                cart: cart,
                vaultService: vaultService
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
                vaultService: vaultService
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
//                    Color(hex: "#f7f7f7").ignoresSafeArea()
                    
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
        // Auto-dismiss if cart is completed
        if newValue == .completed {
            dismiss()
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
        cartViewModel: CartViewModel
    ) -> some View {
        self
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
        vaultService: VaultService
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
