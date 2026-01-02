import SwiftUI
import SwiftData

struct CartItemRowListView: View {
    @Bindable var cartItem: CartItem
    @State private var item: Item? // Local state for the item
    let cart: Cart
    let onFulfillItem: () -> Void
    let onEditItem: () -> Void
    let onDeleteItem: () -> Void
    let isLastItem: Bool
    
    @Environment(VaultService.self) private var vaultService
    @State private var refreshTrigger = 0
    
    var body: some View {
        MainRowContent(
            cartItem: cartItem,
            item: item, // Pass the locally fetched item
            cart: cart,
            onFulfillItem: onFulfillItem,
            onEditItem: onEditItem,
            onDeleteItem: onDeleteItem,
            isLastItem: isLastItem
        )
        .onAppear {
            loadItem() // Load item when view appears
        }
        .onChange(of: cartItem.itemId) { oldValue, newValue in
            loadItem() // Reload if itemId changes
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("VaultItemUpdated"))) { notification in
            handleVaultItemUpdate(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CartItemUpdated"))) { notification in
            handleCartItemUpdate(notification)
        }
        .id("\(cartItem.itemId)_\(refreshTrigger)_\(item?.name ?? "")") // Include item name in ID
    }
    
    private func loadItem() {
        // Always fetch fresh from vault
        item = vaultService.findItemById(cartItem.itemId)
        print("🔄 Loaded item for \(cartItem.itemId): \(item?.name ?? "nil")")
    }
    
    private func handleVaultItemUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let updatedItemId = userInfo["itemId"] as? String,
              updatedItemId == cartItem.itemId else {
            return
        }
        
        print("📢 VaultItemUpdated received - reloading item")
        loadItem()
        refreshTrigger += 1
    }
    
    private func handleCartItemUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let updatedItemId = userInfo["itemId"] as? String,
              updatedItemId == cartItem.itemId else {
            return
        }
        
        print("📢 CartItemUpdated received")
        // Update cart item properties
        if let plannedPrice = userInfo["plannedPrice"] as? Double {
            cartItem.plannedPrice = plannedPrice
        }
        if let plannedUnit = userInfo["plannedUnit"] as? String {
            cartItem.plannedUnit = plannedUnit
        }
        if let plannedStore = userInfo["plannedStore"] as? String {
            cartItem.plannedStore = plannedStore
        }
        
        refreshTrigger += 1
    }
}

// MARK: - Main Row Content (WITH PERSISTENT BADGE)
private struct MainRowContent: View {
    @Bindable var cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onFulfillItem: () -> Void
    let onEditItem: () -> Void
    let onDeleteItem: () -> Void
    let isLastItem: Bool
    
    @Environment(VaultService.self) private var vaultService
    
    // PERSISTENT badge state using AppStorage
    @AppStorage private var hasShownNewBadge: Bool
    @State private var showNewBadge: Bool = false
    
    // Animation state for badge
    @State private var sparkleOpacity: Double = 0.0
    @State private var sparkleScale: CGFloat = 0.8
    @State private var badgeScale: CGFloat = 0.1
    @State private var badgeRotation: Double = 0
    @State private var rowHighlight: Bool = false
    
    // Existing state variables
    @State private var buttonScale: CGFloat = 0.1
    @State private var isFulfilling: Bool = false
    @State private var iconScale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0.1
    @State private var rowOpacity: Double = 1.0
    
    // Derived state
    @State private var currentQuantity: Double = 0
    @State private var currentPrice: Double = 0
    @State private var currentTotalPrice: Double = 0
    @State private var displayUnit: String = ""
    
    // Custom initializer with AppStorage key
    init(cartItem: CartItem, item: Item?, cart: Cart, onFulfillItem: @escaping () -> Void, onEditItem: @escaping () -> Void, onDeleteItem: @escaping () -> Void, isLastItem: Bool) {
        self.cartItem = cartItem
        self.item = item
        self.cart = cart
        self.onFulfillItem = onFulfillItem
        self.onEditItem = onEditItem
        self.onDeleteItem = onDeleteItem
        self.isLastItem = isLastItem
        
        // Create unique storage key for each shopping-only item
        // Only create for shopping-only items, vault items don't need badge persistence
        if cartItem.isShoppingOnlyItem, let shoppingName = cartItem.shoppingOnlyName {
            // Use a combination of cart ID and item name for unique key
            let storageKey = "hasShownNewBadge_\(cart.id)_\(shoppingName)"
            self._hasShownNewBadge = AppStorage(wrappedValue: false, storageKey)
        } else {
            // For vault items, use a dummy key that never shows badge
            self._hasShownNewBadge = AppStorage(wrappedValue: true, "vault_item_no_badge")
        }
    }
    
    var body: some View {
        ZStack {
            // Background sparkle effect - ONLY for shopping-only items with badge
            if isShoppingOnlyItem && showNewBadge && !hasShownNewBadge {
                SparkleEffectView(opacity: sparkleOpacity, scale: sparkleScale)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }
            
            HStack(alignment: .top, spacing: 0) {
                if cart.isShopping {
                    FulfillmentButton(
                        cartItem: cartItem,
                        isFulfilling: $isFulfilling,
                        iconScale: $iconScale,
                        checkmarkScale: $checkmarkScale,
                        buttonScale: buttonScale,
                        onFulfillItem: onFulfillItem
                    )
                }
                
                // Item details
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 4) {
                        Text(currentQuantity.formattedQuantity)
                            .lexendFont(16, weight: .regular)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentQuantity)
                        
                        Text(item?.name ?? cartItem.shoppingOnlyName ?? "Unknown Item")
                            .lexendFont(16, weight: .regular)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .strikethrough(cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping))
                            .id(item?.name ?? cartItem.shoppingOnlyName ?? "Unknown")
                        
                        Spacer()
                        
                        // PERSISTENT BADGE: Only show for shopping-only items that haven't been marked as shown
                        if shouldDisplayBadge {
                            NewBadgeView(
                                scale: hasShownNewBadge ? 1.0 : badgeScale,
                                rotation: hasShownNewBadge ? 0 : badgeRotation
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Text("\(currentPrice.formattedCurrency) / \(displayUnit)")
                            .lexendFont(12)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPrice)
                        
                        Spacer()
                        
                        Text(currentTotalPrice.formattedCurrency)
                            .lexendFont(14, weight: .bold)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentTotalPrice)
                    }
                    .foregroundColor(Color(hex: "231F30"))
                    .opacity(cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping) ? 0.5 : 1.0)
                }
                .opacity(cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping) ? 0.5 : 1.0)
            }
            .padding(.vertical, 12)
            .padding(.leading, cart.isShopping ? 16 : 16)
            .padding(.trailing, 16)
            .background(
                ZStack {
                    Color(hex: "F7F2ED").darker(by: 0.02)
                    
                    // Highlight only for shopping-only items with badge animation
                    if isShoppingOnlyItem && showNewBadge && !hasShownNewBadge && rowHighlight {
                        LinearGradient(
                            colors: [
                                Color(hex: "FFE082").opacity(0.15),
                                Color(hex: "FFD54F").opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .cornerRadius(8)
                    }
                }
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isShoppingOnlyItem && showNewBadge && !hasShownNewBadge && rowHighlight ?
                        Color(hex: "FFB300").opacity(0.4) : Color.clear,
                        lineWidth: isShoppingOnlyItem && showNewBadge && !hasShownNewBadge && rowHighlight ? 1.5 : 0
                    )
            )
        }
        .opacity(rowOpacity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cart.isShopping)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isFulfilling {
                onEditItem()
            }
        }
        .onChange(of: cart.isShopping) { oldValue, newValue in
            guard oldValue != newValue else { return }
            
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    buttonScale = 1.0
                }
            } else {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    buttonScale = 0.1
                }
            }
        }
        .onAppear {
            buttonScale = cart.isShopping ? 1.0 : 0.1
            updateDerivedValues()
            
            // Check if we should show badge
            checkAndShowBadgeIfNeeded()
        }
        .onDisappear {
            // Don't reset showNewBadge - let AppStorage handle persistence
            // Only reset animation states
            if isShoppingOnlyItem && !hasShownNewBadge {
                rowHighlight = false
            }
        }
        .onChange(of: cartItem.plannedPrice) { oldValue, newValue in
            if oldValue != newValue {
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.plannedUnit) { oldValue, newValue in
            if oldValue != newValue {
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: item?.name) { oldValue, newValue in
            if oldValue != newValue {
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.quantity) { oldValue, newValue in
            if oldValue != newValue {
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.actualPrice) { oldValue, newValue in
            if oldValue != newValue {
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.actualQuantity) { oldValue, newValue in
            if oldValue != newValue {
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.shoppingOnlyPrice) { oldValue, newValue in
            if oldValue != newValue {
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.isFulfilled) { oldValue, newValue in
            if oldValue != newValue {
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.isSkippedDuringShopping) { oldValue, newValue in
            if oldValue != newValue {
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cart.status) { oldValue, newValue in
            if oldValue != newValue {
                updateDerivedValues(animated: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShoppingDataUpdated"))) { _ in
            print("📢 ShoppingDataUpdated received for: \(item?.name ?? "Unknown")")
            updateDerivedValues(animated: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CartItemUpdated"))) { notification in
            if let userInfo = notification.userInfo,
               let updatedItemId = userInfo["itemId"] as? String,
               updatedItemId == cartItem.itemId {
                updateDerivedValues(animated: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("VaultItemUpdated"))) { notification in
            if let userInfo = notification.userInfo,
               let updatedItemId = userInfo["itemId"] as? String,
               updatedItemId == cartItem.itemId {
                updateDerivedValues(animated: true)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isShoppingOnlyItem: Bool {
        // Check if it's a shopping-only item in multiple ways
        if let item = item, item.isTemporaryShoppingItem == true {
            return true
        }
        return cartItem.isShoppingOnlyItem && cartItem.shoppingOnlyName != nil
    }
    
    private var shouldDisplayBadge: Bool {
        // Must be shopping-only item AND showNewBadge is true
        // The badge will stay visible until hasShownNewBadge is set to true
        return isShoppingOnlyItem && showNewBadge
    }
    
    // MARK: - Helper Methods
    
    private func updateDerivedValues(animated: Bool = false) {
        guard let vault = vaultService.vault else { return }
        
        let newQuantity = cartItem.quantity
        let newPrice = cartItem.getPrice(from: vault, cart: cart)
        let newTotalPrice = cartItem.getTotalPrice(from: vault, cart: cart)
        let newUnit = cartItem.getUnit(from: vault, cart: cart)
        
        cartItem.syncQuantities(cart: cart)
        
        if animated {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
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
        // Only check for shopping-only items in shopping mode
        guard cart.isShopping && isShoppingOnlyItem else {
            // Vault items or not in shopping mode - never show badge
            showNewBadge = false
            return
        }
        
        // Check if item was added very recently (less than 5 seconds ago)
        let timeSinceAdded = Date().timeIntervalSince(cartItem.addedAt)
        
        // Only show badge if:
        // 1. Item was recently added (< 5 seconds ago) AND
        // 2. We haven't shown the badge before for this item
        if timeSinceAdded < 5.0 && !hasShownNewBadge {
            showNewBadge = true
            startNewItemAnimation()
        } else if hasShownNewBadge {
            // Badge was shown before - keep it visible but no animation
            showNewBadge = true
        } else {
            // Item is too old and badge hasn't been shown - don't show badge
            showNewBadge = false
        }
    }
    
    private func startNewItemAnimation() {
        // Safety check
        guard isShoppingOnlyItem else { return }
        
        print("🎬 Starting new badge animation for shopping-only item: \(cartItem.shoppingOnlyName ?? "Unknown")")
        
        // Sequence 1: Row highlight pulse
        withAnimation(.easeInOut(duration: 0.3)) {
            rowHighlight = true
        }
        
        // Sequence 2: Badge appears with spring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 100, damping: 10)) {
                badgeScale = 1.0
                badgeRotation = 3
            }
            
            withAnimation(.easeInOut(duration: 0.5)) {
                sparkleOpacity = 0.25
                sparkleScale = 1.0
            }
        }
        
        // Sequence 3: Single smooth rocking motion
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
        
        // Sequence 4: Row highlight pulses smoothly
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
        
        // Sequence 5: Mark as shown in persistent storage and keep badge visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            // Mark badge as shown in persistent storage
            hasShownNewBadge = true
            print("💾 Marked badge as shown for: \(cartItem.shoppingOnlyName ?? "Unknown")")
            
            // Fade out animations but keep badge visible
            withAnimation(.easeOut(duration: 0.3)) {
                sparkleOpacity = 0
                sparkleScale = 0.8
                badgeRotation = 0
                rowHighlight = false
            }
            
            // Keep showNewBadge = true so badge stays visible
            // Badge will now be static (no animation)
        }
    }
}

// MARK: - Fulfillment Button Component
private struct FulfillmentButton: View {
    let cartItem: CartItem
    @Binding var isFulfilling: Bool
    @Binding var iconScale: CGFloat
    @Binding var checkmarkScale: CGFloat
    let buttonScale: CGFloat
    let onFulfillItem: () -> Void
    
    var body: some View {
        Button(action: {
            guard !isFulfilling else { return }
            
            // Call the fulfillment handler first
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
        }) {
            ZStack {
                // Always show the circle (for both states)
                Circle()
                    .strokeBorder(
                        cartItem.isFulfilled ? Color.green : Color(hex: "666"),
                        lineWidth: cartItem.isFulfilled ? 0 : 1.5
                    )
                    .frame(width: 18, height: 18)
                    .scaleEffect(iconScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: iconScale)
                
                // Checkmark when fulfilled
                if cartItem.isFulfilled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                        .scaleEffect(checkmarkScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: checkmarkScale)
                } else {
                    // Simple circle for unfulfilled
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 18, height: 18)
                }
            }
            .frame(width: 18, height: 18)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .scaleEffect(buttonScale)
        }
        .buttonStyle(.plain)
        .disabled(isFulfilling || cartItem.isFulfilled)
        .help(cartItem.isFulfilled ? "Already purchased" : "Tap to confirm purchase")
    }
}

// MARK: - Sparkle Effect Component
struct SparkleEffectView: View {
    let opacity: Double
    let scale: CGFloat
    
    @State private var sparkles: [Sparkle] = []
    
    struct Sparkle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let delay: Double
    }
    
    init(opacity: Double, scale: CGFloat) {
        self.opacity = opacity
        self.scale = scale
        
        // Generate random sparkle positions
        var sparkles: [Sparkle] = []
        for _ in 0..<8 {
            sparkles.append(Sparkle(
                x: CGFloat.random(in: 0.1...0.9),
                y: CGFloat.random(in: 0.1...0.9),
                size: CGFloat.random(in: 0.5...1.5),
                delay: Double.random(in: 0...0.5)
            ))
        }
        _sparkles = State(initialValue: sparkles)
    }
    
    var body: some View {
        ZStack {
            ForEach(sparkles) { sparkle in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color(hex: "FFE082").opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .center,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: sparkle.size * 15, height: sparkle.size * 15)
                    .position(x: sparkle.x * UIScreen.main.bounds.width,
                             y: sparkle.y * 60) // Limit to row height
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .blur(radius: 1)
            }
        }
    }
}
