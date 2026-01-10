import SwiftUI
import SwiftData

struct CartItemRowListView: View {
    @Bindable var cartItem: CartItem
    @State private var item: Item?
    let cart: Cart
    let onFulfillItem: () -> Void
    let onEditItem: () -> Void
    let onDeleteItem: () -> Void
    let isLastItem: Bool
    let isFirstItem: Bool
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartStateManager.self) private var stateManager
    @State private var refreshTrigger = 0
    
    var body: some View {
        MainRowContent(
            cartItem: cartItem,
            item: item,
            cart: cart,
            onFulfillItem: onFulfillItem,
            onEditItem: onEditItem,
            onDeleteItem: onDeleteItem,
            isLastItem: isLastItem,
            isFirstItem: isFirstItem
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
        .id("\(cartItem.itemId)_\(refreshTrigger)_\(item?.name ?? "")")
    }
    
    private func loadItem() {
        item = vaultService.findItemById(cartItem.itemId)
    }
    
    private func handleVaultItemUpdate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let updatedItemId = userInfo["itemId"] as? String,
              updatedItemId == cartItem.itemId else { return }
        
        loadItem()
        refreshTrigger += 1
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
        
        refreshTrigger += 1
    }
}

// MARK: - Main Row Content (Updated)
private struct MainRowContent: View {
    @Bindable var cartItem: CartItem
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
    @State private var rowOpacity: Double = 1.0
    
    // Derived state
    @State private var currentQuantity: Double = 0
    @State private var currentPrice: Double = 0
    @State private var currentTotalPrice: Double = 0
    @State private var displayUnit: String = ""
    
    init(cartItem: CartItem, item: Item?, cart: Cart, onFulfillItem: @escaping () -> Void, onEditItem: @escaping () -> Void, onDeleteItem: @escaping () -> Void, isLastItem: Bool, isFirstItem: Bool) {
        self.cartItem = cartItem
        self.item = item
        self.cart = cart
        self.onFulfillItem = onFulfillItem
        self.onEditItem = onEditItem
        self.onDeleteItem = onDeleteItem
        self.isLastItem = isLastItem
        self.isFirstItem = isFirstItem
        
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
                badgeScale: hasShownNewBadge ? 1.0 : badgeScale,
                badgeRotation: hasShownNewBadge ? 0 : badgeRotation,
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
                rowHighlight: rowHighlight
            )
        }
        .opacity(rowOpacity)
        // Smoother animation aligned with list height animation
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: cart.isShopping)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isFulfilling {
                onEditItem()
            }
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
        .applyDataChangeObservers(
            cartItem: cartItem,
            item: item,
            cart: cart,
            onUpdate: { animated in
                updateDerivedValues(animated: animated)
            }
        )
    }
    
    // MARK: - Computed Properties
    
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
        
        // Smoother animation aligned with list height animation
        if newValue {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                buttonScale = 1.0
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.88)) {
                buttonScale = 0.1
            }
        }
    }
    
    private func updateDerivedValues(animated: Bool = false) {
        guard let vault = vaultService.vault else { return }
        
        let newQuantity = cartItem.quantity
        let newPrice = cartItem.getPrice(from: vault, cart: cart)
        let newTotalPrice = cartItem.getTotalPrice(from: vault, cart: cart)
        let newUnit = cartItem.getUnit(from: vault, cart: cart)
        
        cartItem.syncQuantities(cart: cart)
        
        if animated {
            // Smoother animation aligned with list height animation
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
        
        let timeSinceAdded = Date().timeIntervalSince(cartItem.addedAt)
        
        if timeSinceAdded < 5.0 && !hasShownNewBadge {
            showNewBadge = true
            startNewItemAnimation()
        } else if hasShownNewBadge {
            showNewBadge = true
        } else {
            showNewBadge = false
        }
    }
    
    private func startNewItemAnimation() {
        guard isShoppingOnlyItem else { return }
        
        // Row highlight pulse
        withAnimation(.easeInOut(duration: 0.3)) {
            rowHighlight = true
        }
        
        // Badge appears with spring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 100, damping: 10)) {
                badgeScale = 1.0
                badgeRotation = 3
            }
        }
        
        // Single smooth rocking motion
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
        
        // Row highlight pulses
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
        
        // Mark as shown in persistent storage
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            hasShownNewBadge = true
            
            withAnimation(.easeOut(duration: 0.3)) {
                badgeRotation = 0
                rowHighlight = false
            }
        }
    }
}

// MARK: - Cart Row Main Content (Updated)
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
    @Binding var checkmarkScale: CGFloat
    let onFulfillItem: () -> Void
    let isFirstItem: Bool
    
    @Environment(CartStateManager.self) private var stateManager
    
    var body: some View {
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
        }
        .padding(.vertical, 12)
        .padding(.leading, cart.isShopping ? 16 : 16)
        .padding(.trailing, 16)
        .cornerRadius(8)
    }
}

// MARK: - Item Details Section (Updated)
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
                isFirstItem: isFirstItem
            )
            
            ItemPriceRow(
                cartItem: cartItem,
                item: item,
                currentPrice: currentPrice,
                displayUnit: displayUnit,
                currentTotalPrice: currentTotalPrice,
                isItemFulfilled: isItemFulfilled
            )
        }
        .opacity(isItemFulfilled ? 0.5 : 1.0)
    }
}

// MARK: - Item Name Row (Updated)
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
    
    @Environment(CartStateManager.self) private var stateManager
    
    var body: some View {
        HStack(spacing: 4) {
            itemNameText
            
            Spacer()
            
            if shouldDisplayBadge {
                NewBadgeView(
                    scale: badgeScale,
                    rotation: badgeRotation
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    @ViewBuilder
    private var itemNameText: some View {
        let baseText = Text("\(currentQuantity.formattedQuantity) \(item?.name ?? cartItem.shoppingOnlyName ?? "Unknown Item")")
            .lexendFont(17, weight: stateManager.hasBackgroundImage ? .semibold : .regular)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .strikethrough(isItemFulfilled)
            .id(item?.name ?? cartItem.shoppingOnlyName ?? "Unknown")
            .foregroundColor(stateManager.hasBackgroundImage ? .white.opacity(0.95) : .primary)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentQuantity)
        
        baseText
    }
}

// MARK: - Item Price Row (Updated)
private struct ItemPriceRow: View {
    let cartItem: CartItem
    let item: Item?
    let currentPrice: Double
    let displayUnit: String
    let currentTotalPrice: Double
    let isItemFulfilled: Bool
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartStateManager.self) private var stateManager
    
    var body: some View {
        HStack(spacing: 4) {
            // Changed from emoji to category title
            Text("\(currentPrice.formattedCurrency) / \(displayUnit) • \(categoryTitle)")
                .lexendFont(12)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPrice)
                .foregroundColor(stateManager.hasBackgroundImage ? .white.opacity(0.9) : Color(hex: "231F30"))
            
            Spacer()
            
            Text(currentTotalPrice.formattedCurrency)
                .lexendFont(14, weight: .bold)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentTotalPrice)
                .foregroundColor(stateManager.hasBackgroundImage ? .white : Color(hex: "231F30"))
        }
        .opacity(isItemFulfilled ? 0.5 : 1.0)
    }
    
    private var categoryTitle: String {
        // Check if it's a shopping-only item with stored category
        if cartItem.isShoppingOnlyItem, let categoryRawValue = cartItem.shoppingOnlyCategory,
           let groceryCategory = GroceryCategory(rawValue: categoryRawValue) {
            return groceryCategory.title
        }
        
        // For vault items, look up category from vault
        guard let item = item,
              let category = vaultService.getCategory(for: item.id) else {
            return "Uncategorized"
        }
        // Find the matching GroceryCategory by title
        if let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == category.name }) {
            return groceryCategory.title
        }
        return category.name
    }
}

// MARK: - View Modifiers (Updated)
private extension View {
    @ViewBuilder
    func applyRowBackground(
        isShoppingOnlyItem: Bool,
        showNewBadge: Bool,
        hasShownNewBadge: Bool,
        rowHighlight: Bool
    ) -> some View {
        self.background(
            RowBackgroundView(
                isShoppingOnlyItem: isShoppingOnlyItem,
                showNewBadge: showNewBadge,
                hasShownNewBadge: hasShownNewBadge,
                rowHighlight: rowHighlight
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isShoppingOnlyItem && showNewBadge && !hasShownNewBadge && rowHighlight ?
                    Color(hex: "FFB300").opacity(0.4) : Color.clear,
                    lineWidth: isShoppingOnlyItem && showNewBadge && !hasShownNewBadge && rowHighlight ? 1.5 : 0
                )
        )
    }
    
    func applyDataChangeObservers(
        cartItem: CartItem,
        item: Item?,
        cart: Cart,
        onUpdate: @escaping (Bool) -> Void
    ) -> some View {
        self
            .onChange(of: cartItem.plannedPrice) { oldValue, newValue in
                if oldValue != newValue { onUpdate(true) }
            }
            .onChange(of: cartItem.plannedUnit) { oldValue, newValue in
                if oldValue != newValue { onUpdate(true) }
            }
            .onChange(of: item?.name) { oldValue, newValue in
                if oldValue != newValue { onUpdate(true) }
            }
            .onChange(of: cartItem.quantity) { oldValue, newValue in
                if oldValue != newValue { onUpdate(true) }
            }
            .onChange(of: cartItem.actualPrice) { oldValue, newValue in
                if oldValue != newValue { onUpdate(true) }
            }
            .onChange(of: cartItem.actualQuantity) { oldValue, newValue in
                if oldValue != newValue { onUpdate(true) }
            }
            .onChange(of: cartItem.shoppingOnlyPrice) { oldValue, newValue in
                if oldValue != newValue { onUpdate(true) }
            }
            .onChange(of: cartItem.isFulfilled) { oldValue, newValue in
                if oldValue != newValue { onUpdate(true) }
            }
            .onChange(of: cartItem.isSkippedDuringShopping) { oldValue, newValue in
                if oldValue != newValue { onUpdate(true) }
            }
            .onChange(of: cart.status) { oldValue, newValue in
                if oldValue != newValue { onUpdate(true) }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShoppingDataUpdated"))) { _ in
                onUpdate(true)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CartItemUpdated"))) { notification in
                if let userInfo = notification.userInfo,
                   let updatedItemId = userInfo["itemId"] as? String,
                   updatedItemId == cartItem.itemId {
                    onUpdate(true)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("VaultItemUpdated"))) { notification in
                if let userInfo = notification.userInfo,
                   let updatedItemId = userInfo["itemId"] as? String,
                   updatedItemId == cartItem.itemId {
                    onUpdate(true)
                }
            }
    }
}

// MARK: - Row Background View (Updated)
private struct RowBackgroundView: View {
    let isShoppingOnlyItem: Bool
    let showNewBadge: Bool
    let hasShownNewBadge: Bool
    let rowHighlight: Bool
    
    @Environment(CartStateManager.self) private var stateManager
    
    var body: some View {
        ZStack {
            stateManager.effectiveRowBackgroundColor
            
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
    }
}

// MARK: - Fulfillment Button Content (Updated)
private struct FulfillmentButtonContent: View {
    let cartItem: CartItem
    let iconScale: CGFloat
    let checkmarkScale: CGFloat
    let buttonScale: CGFloat
    
    @Environment(CartStateManager.self) private var stateManager
    
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    cartItem.isFulfilled ?
                        (stateManager.hasBackgroundImage ? Color.white : Color.green) :
                        (stateManager.hasBackgroundImage ? Color.white.opacity(0.7) : Color(hex: "666")),
                    lineWidth: cartItem.isFulfilled ? 0 : 1.5
                )
                .frame(width: 18, height: 18)
                .scaleEffect(iconScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: iconScale)
            
            if cartItem.isFulfilled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(stateManager.hasBackgroundImage ? .white : .green)
                    .scaleEffect(checkmarkScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: checkmarkScale)
            } else {
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
}

// MARK: - Fulfillment Button Component (Updated)
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
                checkmarkScale: checkmarkScale,
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

