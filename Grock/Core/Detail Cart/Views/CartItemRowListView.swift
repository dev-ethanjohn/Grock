import SwiftUI
import SwiftData
struct CartItemRowListView: View {
    let cartItem: CartItem
    @State private var item: Item?
    let cart: Cart
    let onFulfillItem: () -> Void
    let onEditItem: () -> Void
    let onDeleteItem: () -> Void
    let isLastItem: Bool
    let isFirstItem: Bool
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartStateManager.self) private var stateManager
    
    // Animation states
    @State private var showCheckmarkAnimation = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var strikethroughProgress: CGFloat = 0
    @State private var rowRemovalOffset: CGFloat = 0
    @State private var rowOpacity: CGFloat = 1
    @State private var removalOffset: CGFloat = 0
    @State private var removalRotation: Double = 0
    @State private var rowScale: CGFloat = 1
    
    var body: some View {
        MainRowContent(
            cartItem: cartItem,
            item: item,
            cart: cart,
            onFulfillItem: onFulfillItem,
            onEditItem: onEditItem,
            onDeleteItem: onDeleteItem,
            isLastItem: isLastItem,
            isFirstItem: isFirstItem,
            removalOffset: $removalOffset,
            removalRotation: $removalRotation,
            rowScale: $rowScale,
            rowOpacity: $rowOpacity
        )
        .onAppear {
            loadItem()
        }
        .onChange(of: cartItem.itemId) { oldValue, newValue in
            loadItem()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("VaultItemUpdated"))) { notification in
            handleVaultItemUpdate(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CartItemUpdated"))) { notification in
            handleCartItemUpdate(notification)
        }
        // Listen for animation notifications
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemFulfillmentAnimationStarted"))) { notification in
            handleAnimationNotification(notification, animationType: .checkmark)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemStrikethroughAnimating"))) { notification in
            handleAnimationNotification(notification, animationType: .strikethrough)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemRemovalAnimating"))) { notification in
            handleAnimationNotification(notification, animationType: .removal)
        }
        .id("\(cartItem.itemId)_\(item?.name ?? "")")
    }
    
    private func loadItem() {
        item = vaultService.findItemById(cartItem.itemId)
    }
    
    private func handleVaultItemUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let updatedItemId = userInfo["itemId"] as? String,
              updatedItemId == cartItem.itemId else { return }
        
        loadItem()
    }
    
    private func handleCartItemUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let updatedItemId = userInfo["itemId"] as? String,
              updatedItemId == cartItem.itemId else { return }
        
        if let plannedPrice = userInfo["plannedPrice"] as? Double {
            cartItem.plannedPrice = plannedPrice
        }
        if let plannedUnit = userInfo["plannedUnit"] as? String {
            cartItem.plannedUnit = plannedUnit
        }
        if let plannedStore = userInfo["plannedStore"] as? String {
            cartItem.plannedStore = plannedStore
        }
    }
    
    private func handleAnimationNotification(_ notification: Notification, animationType: AnimationType) {
        guard let userInfo = notification.userInfo,
              let itemId = userInfo["itemId"] as? String,
              itemId == cartItem.itemId,
              let cartId = userInfo["cartId"] as? String,
              cartId == cart.id else { return }
        
        switch animationType {
        case .checkmark:
            // Quick checkmark bounce
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                checkmarkScale = 1.0
            }
            showCheckmarkAnimation = true
            
        case .strikethrough:
            // Start strikethrough IMMEDIATELY (no delay)
            withAnimation(.easeInOut(duration: 0.3)) {
                strikethroughProgress = 1.0
            }
            
        case .removal:
            // Smooth removal animation
            withAnimation(.easeOut(duration: 0.3)) {
                removalOffset = 100
                removalRotation = 5
                rowScale = 0.9
                rowOpacity = 0
            }
            
            // Reset after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    removalOffset = 0
                    removalRotation = 0
                    rowScale = 1
                    rowOpacity = 1
                }
                strikethroughProgress = 0
                showCheckmarkAnimation = false
                checkmarkScale = 0
            }
        }
    }
    
    enum AnimationType {
        case checkmark, strikethrough, removal
    }
}

// MARK: - MainRowContent (Updated with animation bindings)
private struct MainRowContent: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onFulfillItem: () -> Void
    let onEditItem: () -> Void
    let onDeleteItem: () -> Void
    let isLastItem: Bool
    let isFirstItem: Bool
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartStateManager.self) private var stateManager
    
    @AppStorage private var hasShownNewBadge: Bool
    @State private var showNewBadge: Bool = false
    
    // Animation states
    @State private var badgeScale: CGFloat = 0.1
    @State private var badgeRotation: Double = 0
    @State private var rowHighlight: Bool = false
    @State private var buttonScale: CGFloat = 0.1
    @State private var isFulfilling: Bool = false
    @State private var iconScale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0.1
    
    // Animation bindings from parent
    @Binding var removalOffset: CGFloat
    @Binding var removalRotation: Double
    @Binding var rowScale: CGFloat
    @Binding var rowOpacity: CGFloat
    
    // Derived state
    @State private var currentQuantity: Double = 0
    @State private var currentPrice: Double = 0
    @State private var currentTotalPrice: Double = 0
    @State private var displayUnit: String = ""
    @State private var pendingUpdateWorkItem: DispatchWorkItem?
    
    private func scheduleDebouncedUpdate(animated: Bool = false, delay: TimeInterval = 0.05) {
        pendingUpdateWorkItem?.cancel()
        let work = DispatchWorkItem {
            updateDerivedValues(animated: animated)
        }
        pendingUpdateWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
    init(cartItem: CartItem, item: Item?, cart: Cart, onFulfillItem: @escaping () -> Void, onEditItem: @escaping () -> Void, onDeleteItem: @escaping () -> Void, isLastItem: Bool, isFirstItem: Bool, removalOffset: Binding<CGFloat>, removalRotation: Binding<Double>, rowScale: Binding<CGFloat>, rowOpacity: Binding<CGFloat>) {
        self.cartItem = cartItem
        self.item = item
        self.cart = cart
        self.onFulfillItem = onFulfillItem
        self.onEditItem = onEditItem
        self.onDeleteItem = onDeleteItem
        self.isLastItem = isLastItem
        self.isFirstItem = isFirstItem
        self._removalOffset = removalOffset
        self._removalRotation = removalRotation
        self._rowScale = rowScale
        self._rowOpacity = rowOpacity
        
        if cartItem.isShoppingOnlyItem, let shoppingName = cartItem.shoppingOnlyName {
            let storageKey = "hasShownNewBadge_\(cart.id)_\(shoppingName)"
            self._hasShownNewBadge = AppStorage(wrappedValue: false, storageKey)
        } else {
            self._hasShownNewBadge = AppStorage(wrappedValue: true, "vault_item_no_badge")
        }
    }
    
    var body: some View {
        ZStack {
            CartRowMainContent(
                cartItem: cartItem,
                item: item,
                cart: cart,
                currentQuantity: currentQuantity,
                currentPrice: currentPrice,
                currentTotalPrice: currentTotalPrice,
                displayUnit: displayUnit,
                shouldDisplayBadge: shouldDisplayBadge,
                badgeScale: badgeScale,
                badgeRotation: badgeRotation,
                buttonScale: buttonScale,
                isFulfilling: $isFulfilling,
                iconScale: $iconScale,
                checkmarkScale: $checkmarkScale,
                onFulfillItem: onFulfillItem,
                isFirstItem: isFirstItem
            )
            .applyRowBackground(
                isShoppingOnlyItem: isShoppingOnlyItem,
                showNewBadge: showNewBadge,
                hasShownNewBadge: hasShownNewBadge,
                rowHighlight: rowHighlight,
                isItemFulfilled: isItemFulfilled
            )
        }
        .opacity(rowOpacity)
        .animation(nil, value: cart.isShopping)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isFulfilling else { return }
            onEditItem()
        }
        .onAppear {
            setupInitialState()
        }
        .onDisappear {
            if isShoppingOnlyItem && !hasShownNewBadge {
                rowHighlight = false
            }
        }
        .onChange(of: cart.isShopping) { oldValue, newValue in
            handleShoppingModeChange(oldValue: oldValue, newValue: newValue)
        }
        .onReceive(NotificationCenter.default.publisher(for: .shoppingItemQuantityChanged)) { notification in
            guard let userInfo = notification.userInfo,
                  let cartId = userInfo["cartId"] as? String,
                  cartId == cart.id else { return }
            
            if let itemId = userInfo["itemId"] as? String {
                if itemId == cartItem.itemId {
                    scheduleDebouncedUpdate(animated: true)
                }
            } else {
                scheduleDebouncedUpdate(animated: false)
            }
        }
        .onChange(of: cartItem.quantity) { oldValue, newValue in
            scheduleDebouncedUpdate(animated: true)
        }
    }
    
    // MARK: - Computed Properties
    private var isItemFulfilled: Bool {
        cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping)
    }
    
    private var isShoppingOnlyItem: Bool {
        if let item = item, item.isTemporaryShoppingItem == true {
            return true
        }
        return cartItem.isShoppingOnlyItem && cartItem.shoppingOnlyName != nil
    }
    
    private var shouldDisplayBadge: Bool {
        if isShoppingOnlyItem {
            return showNewBadge
        } else if cartItem.addedDuringShopping {
            return false
        } else {
            return showNewBadge
        }
    }
    
    // MARK: - Setup & State Management
    
    private func setupInitialState() {
        buttonScale = cart.isShopping ? 1.0 : 0.1
        updateDerivedValues()
        checkAndShowBadgeIfNeeded()
    }
    
    private func handleShoppingModeChange(oldValue: Bool, newValue: Bool) {
        guard oldValue != newValue else { return }
        
        if newValue {
            withAnimation(
                .spring(
                    response: 0.55,
                    dampingFraction: 0.68,
                    blendDuration: 0.2
                )
                .delay(0.05)
            ) {
                buttonScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    if buttonScale < 1.0 {
                        buttonScale = 1.0
                    }
                }
            }
        } else {
            withAnimation(
                .spring(
                    response: 0.45,
                    dampingFraction: 0.72,
                    blendDuration: 0.15
                )
            ) {
                buttonScale = 0.1
            }
        }
    }
    
    private func updateDerivedValues(animated: Bool = false) {
        guard let vault = vaultService.vault else { return }
        
        let newQuantity = cartItem.quantity
        let newPrice = cartItem.getPrice(from: vault, cart: cart)
        let newTotalPrice = newPrice * newQuantity
        let newUnit = cartItem.getUnit(from: vault, cart: cart)
        
        cartItem.syncQuantities(cart: cart)
        
        if animated {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                currentQuantity = newQuantity
                currentPrice = newPrice
                currentTotalPrice = newTotalPrice
                displayUnit = newUnit
            }
        } else {
            currentQuantity = newQuantity
            currentPrice = newPrice
            currentTotalPrice = newTotalPrice
            displayUnit = newUnit
        }
    }
    
    private func checkAndShowBadgeIfNeeded() {
        guard cart.isShopping && isShoppingOnlyItem else {
            showNewBadge = false
            return
        }
        
        let timeSinceAdded = Date().timeIntervalSince(cartItem.addedAt ?? Date.distantPast)
        
        if timeSinceAdded < 5.0 && !hasShownNewBadge {
            showNewBadge = true
            startNewItemAnimation()
        } else if hasShownNewBadge {
            showNewBadge = true
            badgeScale = 1.0
        } else {
            showNewBadge = false
        }
    }
    
    private func startNewItemAnimation() {
        guard isShoppingOnlyItem else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            rowHighlight = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 100, damping: 10)) {
                badgeScale = 1.0
                badgeRotation = 3
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 50, damping: 7)) {
                badgeRotation = -2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 50, damping: 7)) {
                    badgeRotation = 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 60, damping: 8)) {
                        badgeRotation = 0
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.6).delay(0.1)) {
                rowHighlight = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    rowHighlight = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        rowHighlight = false
                    }
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            hasShownNewBadge = true
            
            withAnimation(.easeOut(duration: 0.3)) {
                badgeRotation = 0
                rowHighlight = false
            }
        }
    }
}



private struct CartRowMainContent: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let currentQuantity: Double
    let currentPrice: Double
    let currentTotalPrice: Double
    let displayUnit: String
    let shouldDisplayBadge: Bool
    let badgeScale: CGFloat
    let badgeRotation: Double
    let buttonScale: CGFloat
    @Binding var isFulfilling: Bool
    @Binding var iconScale: CGFloat
    @Binding var checkmarkScale: CGFloat // Add this binding
    let onFulfillItem: () -> Void
    let isFirstItem: Bool
    
    @Environment(CartStateManager.self) private var stateManager
    @State private var leadingPadding: CGFloat = 16
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if cart.isShopping {
                FulfillmentButton(
                    cartItem: cartItem,
                    isFulfilling: $isFulfilling,
                    iconScale: $iconScale,
                    checkmarkScale: $checkmarkScale, // Pass the binding
                    buttonScale: buttonScale,
                    onFulfillItem: onFulfillItem
                )
                .offset(x: cart.isShopping ? 0 : -30)
                .opacity(cart.isShopping ? 1 : 0)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.7),
                    value: cart.isShopping
                )
            }
            
            ItemDetailsSection(
                cartItem: cartItem,
                item: item,
                cart: cart,
                currentQuantity: currentQuantity,
                currentPrice: currentPrice,
                currentTotalPrice: currentTotalPrice,
                displayUnit: displayUnit,
                shouldDisplayBadge: shouldDisplayBadge,
                badgeScale: badgeScale,
                badgeRotation: badgeRotation,
                isFirstItem: isFirstItem
            )
            .offset(x: cart.isShopping ? 0 : 0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.7),
                value: cart.isShopping
            )
        }
        .padding(.vertical, 12)
        .padding(.leading, cart.isShopping ? 16 : 16)
        .padding(.trailing, 16)
        .cornerRadius(8)
    }
}

private struct ItemDetailsSection: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let currentQuantity: Double
    let currentPrice: Double
    let currentTotalPrice: Double
    let displayUnit: String
    let shouldDisplayBadge: Bool
    let badgeScale: CGFloat
    let badgeRotation: Double
    let isFirstItem: Bool
    
    @Environment(CartStateManager.self) private var stateManager
    
    private var isItemFulfilled: Bool {
        cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                ItemNameRow(
                    cartItem: cartItem,
                    item: item,
                    cart: cart,
                    currentQuantity: currentQuantity,
                    shouldDisplayBadge: shouldDisplayBadge,
                    badgeScale: badgeScale,
                    badgeRotation: badgeRotation,
                    isItemFulfilled: isItemFulfilled,
                    isFirstItem: isFirstItem,
                    displayUnit: displayUnit
                )
                
                ItemPriceRow(
                    cartItem: cartItem,
                    item: item,
                    currentPrice: currentPrice,
                    displayUnit: displayUnit,
                    isItemFulfilled: isItemFulfilled
                )
            }
            
            
            Text(currentTotalPrice.formattedCurrency)
                .lexendFont(13, weight: .semibold)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(nil, value: currentTotalPrice)
                .foregroundColor(stateManager.hasBackgroundImage ? .white : .black)
                .opacity(isItemFulfilled ? 0.5 : 1.0)
        }
    }
}

private struct ItemNameRow: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let currentQuantity: Double
    let shouldDisplayBadge: Bool
    let badgeScale: CGFloat
    let badgeRotation: Double
    let isItemFulfilled: Bool
    let isFirstItem: Bool
    let displayUnit: String
    
    @Environment(CartStateManager.self) private var stateManager
    @State private var animatedStrikethroughWidth: CGFloat = 0
    @State private var animatedStrikethroughOpacity: Double = 0
    
    private var textColor: Color {
        if isItemFulfilled {
            // Dimmed text for fulfilled items
            return stateManager.hasBackgroundImage ? .white.opacity(0.5) : .black.opacity(0.5)
        } else {
            // Normal text color
            return stateManager.hasBackgroundImage ? .white : .primary
        }
    }
    
    private var staticStrikethroughColor: Color {
        // BLACK (or white) strikethrough for fulfilled items with appropriate opacity
        if isItemFulfilled {
            return stateManager.hasBackgroundImage ? .white.opacity(0.5) : .black.opacity(0.5)
        } else {
            return .clear // No static strikethrough when not fulfilled
        }
    }
    
    // Animation timing constants
    private let animationDuration: Double = 0.3
    private let fadeOutDelay: Double = 0.4
    
    var body: some View {
        HStack(spacing: 4) {
            ZStack(alignment: .leading) {
                // Item name text
                Text("\(currentQuantity.formattedQuantity)\(displayUnit) \(item?.name ?? cartItem.shoppingOnlyName ?? "Unknown Item") ")
                    .lexendFont(16, weight: stateManager.hasBackgroundImage ? .semibold : .regular)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .strikethrough(isItemFulfilled && !cartItem.shouldStrikethrough, color: staticStrikethroughColor)
                    .foregroundColor(textColor)
                    .id(item?.name ?? cartItem.shoppingOnlyName ?? "Unknown")
                    .contentTransition(.numericText())
                    .animation(nil, value: currentQuantity)
                    .opacity(cartItem.animationState == .removalAnimating ? 0.25 : 1.0)
                
                // Layer 1: Animated red strikethrough (only during fulfillment animation)
                if cartItem.shouldStrikethrough && !isItemFulfilled {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(Color(hex: "FF6B6B")) // Red for animation
                            .frame(height: 1.5)
                            .frame(width: animatedStrikethroughWidth)
                            .offset(y: geometry.size.height / 2)
                            .opacity(animatedStrikethroughOpacity)
                            .onAppear {
                                // Start animation
                                withAnimation(.easeInOut(duration: animationDuration)) {
                                    animatedStrikethroughWidth = geometry.size.width
                                    animatedStrikethroughOpacity = 1.0
                                }
                                
                                // Auto-hide after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.1) {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        animatedStrikethroughOpacity = 0
                                    }
                                    
                                    // Reset after fade out
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        animatedStrikethroughWidth = 0
                                    }
                                }
                            }
                    }
                    .frame(height: 1)
                }
                
                // Layer 2: Static black/white strikethrough for fulfilled items
                if isItemFulfilled && !cartItem.shouldStrikethrough {
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(staticStrikethroughColor)
                            .frame(height: 1.5)
                            .frame(width: geometry.size.width)
                            .offset(y: geometry.size.height / 2)
                            .onAppear {
                                // Ensure animated strikethrough is hidden when static one appears
                                animatedStrikethroughOpacity = 0
                                animatedStrikethroughWidth = 0
                            }
                    }
                    .frame(height: 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            if shouldDisplayBadge {
                NewBadgeView(
                    scale: badgeScale,
                    rotation: badgeRotation
                )
                .transition(.scale.combined(with: .opacity))
                .opacity(isItemFulfilled ? 0.5 : 1.0)
            }
        }
        .onChange(of: cartItem.shouldStrikethrough) { oldValue, newValue in
            handleStrikethroughAnimationChange(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: isItemFulfilled) { oldValue, newValue in
            handleFulfillmentStateChange(oldValue: oldValue, newValue: newValue)
        }
        .onAppear {
            setupInitialState()
        }
    }
    
    // MARK: - Setup and State Management
    
    private func setupInitialState() {
        // Reset animated strikethrough on appear
        animatedStrikethroughWidth = 0
        animatedStrikethroughOpacity = 0
    }
    
    private func handleStrikethroughAnimationChange(oldValue: Bool, newValue: Bool) {
        guard newValue != oldValue else { return }
        
        if newValue {
            // Start red strikethrough animation
            animatedStrikethroughWidth = 0
            animatedStrikethroughOpacity = 0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeInOut(duration: animationDuration)) {
                    animatedStrikethroughWidth = UIScreen.main.bounds.width * 0.7
                    animatedStrikethroughOpacity = 1.0
                }
                
                // Schedule fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.1) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        animatedStrikethroughOpacity = 0
                    }
                    
                    // Reset after fade out
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        animatedStrikethroughWidth = 0
                    }
                }
            }
        } else {
            // Hide animated strikethrough
            withAnimation(.easeOut(duration: 0.2)) {
                animatedStrikethroughOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animatedStrikethroughWidth = 0
            }
        }
    }
    
    private func handleFulfillmentStateChange(oldValue: Bool, newValue: Bool) {
        guard newValue != oldValue else { return }
        
        if newValue {
            // Item became fulfilled - ensure animated strikethrough is hidden
            animatedStrikethroughOpacity = 0
            animatedStrikethroughWidth = 0
            
            // If there was an active animation, cancel it
            cartItem.shouldStrikethrough = false
        } else {
            // Item is no longer fulfilled - ensure static strikethrough is hidden
            // The static strikethrough will automatically hide because isItemFulfilled is false
        }
    }
}


// MARK: - Item Price Row (Updated)
private struct ItemPriceRow: View {
    let cartItem: CartItem
    let item: Item?
    let currentPrice: Double
    let displayUnit: String
    let isItemFulfilled: Bool
    
    @Environment(CartStateManager.self) private var stateManager
    
    private var textColor: Color {
        if isItemFulfilled {
            // Gray text for fulfilled items
            return stateManager.hasBackgroundImage ? .white.opacity(0.4) : Color(hex: "888888")
        } else {
            // Normal text color
            return stateManager.hasBackgroundImage ? .white.opacity(0.7) : Color(hex: "231F30")
        }
    }
    
    var body: some View {
        Text("\(currentPrice.formattedCurrency) / \(displayUnit)")
            .lexendFont(12)
            .lineLimit(1)
            .contentTransition(.numericText())
            .animation(nil, value: currentPrice)
            .foregroundColor(textColor)
            .opacity(isItemFulfilled ? 0.5 : 1.0)
    }
}

extension View {
    @ViewBuilder
    func applyRowBackground(
        isShoppingOnlyItem: Bool,
        showNewBadge: Bool,
        hasShownNewBadge: Bool,
        rowHighlight: Bool,
        isItemFulfilled: Bool
    ) -> some View {
        self.background(
            RowBackgroundView(
                isShoppingOnlyItem: isShoppingOnlyItem,
                showNewBadge: showNewBadge,
                hasShownNewBadge: hasShownNewBadge,
                rowHighlight: rowHighlight,
                isItemFulfilled: isItemFulfilled
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isShoppingOnlyItem && showNewBadge && !hasShownNewBadge && rowHighlight ?
                    Color(hex: "FFB300").opacity(0.4) :
                    (isItemFulfilled ? Color.gray.opacity(0.3) : Color.clear),
                    lineWidth: 1.0
                )
        )
    }
}

private struct RowBackgroundView: View {
    let isShoppingOnlyItem: Bool
    let showNewBadge: Bool
    let hasShownNewBadge: Bool
    let rowHighlight: Bool
    let isItemFulfilled: Bool
    
    @Environment(CartStateManager.self) private var stateManager
    
    private var backgroundColor: Color {
        if isItemFulfilled {
            // Instant change - no animation
            return stateManager.hasBackgroundImage ?
                Color.white.opacity(0.05) :
                Color(hex: "F5F5F5")
        } else {
            return stateManager.effectiveRowBackgroundColor
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .animation(.none, value: isItemFulfilled) // NO ANIMATION
            
            // Highlight only for shopping-only items with badge animation
            if isShoppingOnlyItem && showNewBadge && !hasShownNewBadge && rowHighlight {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "FFE082").opacity(0.15),
                                Color(hex: "FFD54F").opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
    }
}


private struct FulfillmentButtonContent: View {
    let cartItem: CartItem
    let iconScale: CGFloat
    @Binding var checkmarkScale: CGFloat
    let buttonScale: CGFloat
    
    @Environment(CartStateManager.self) private var stateManager
    @State private var circleScale: CGFloat = 1.0
    
    private var checkmarkColor: Color {
         // ALWAYS use green for checkmarks
        return Color(hex: "98F476")
     }
    
    var body: some View {
        ZStack {
            // Checkmark for fulfilled state
            if cartItem.isFulfilled || cartItem.shouldShowCheckmark {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(checkmarkColor) // Always green!
                    .scaleEffect(checkmarkScale * circleScale)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.6),
                        value: checkmarkScale
                    )
                    .onAppear {
                        // Bounce animation when checkmark appears
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.1)) {
                            checkmarkScale = 1.0
                            circleScale = 1.2
                        }
                        
                        // Quick bounce back
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                circleScale = 1.0
                            }
                        }
                    }
                    .onChange(of: cartItem.shouldShowCheckmark) { oldValue, newValue in
                        if newValue && !oldValue {
                            // Bounce animation
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                checkmarkScale = 1.0
                                circleScale = 1.2
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                    circleScale = 1.0
                                }
                            }
                        } else if !newValue && cartItem.isFulfilled {
                            // Keep checkmark if already fulfilled
                            checkmarkScale = 1.0
                        } else if !newValue {
                            // Reset if not fulfilled
                            checkmarkScale = 0
                        }
                    }
            } else {
                // Empty circle for unfulfilled
                Circle()
                    .strokeBorder(
                        stateManager.hasBackgroundImage ? Color.white.opacity(0.7) : Color(hex: "666"),
                        lineWidth: 1.5
                    )
                    .frame(width: 18, height: 18)
                    .scaleEffect(iconScale)
            }
        }
        .frame(width: 18, height: 18)
        .padding(.trailing, 8)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .scaleEffect(buttonScale)
    }
}


private struct FulfillmentButton: View {
    let cartItem: CartItem
    @Binding var isFulfilling: Bool
    @Binding var iconScale: CGFloat
    @Binding var checkmarkScale: CGFloat
    let buttonScale: CGFloat
    let onFulfillItem: () -> Void
    
    var body: some View {
        Button(action: handleButtonTap) {
            FulfillmentButtonContent(
                cartItem: cartItem,
                iconScale: iconScale,
                checkmarkScale: $checkmarkScale, // Pass as binding
                buttonScale: buttonScale
            )
        }
        .buttonStyle(.plain)
        .disabled(isFulfilling || cartItem.isFulfilled)
    }
    
    private func handleButtonTap() {
        guard !isFulfilling else { return }
        
        onFulfillItem()
        
        DispatchQueue.main.async {
            isFulfilling = true
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                iconScale = 1.3
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFulfilling = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    iconScale = 1.0
                }
            }
        }
    }
}
