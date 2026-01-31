import SwiftUI

enum ItemType {
    case vaultOnly
    case plannedCart
    case shoppingOnly
}

struct BrowseVaultItemRow: View {
    let storeItem: StoreItem
    let cart: Cart
    let action: () -> Void
    let onQuantityChange: (() -> Void)?
    
    @State private var appearScale: CGFloat = 0.9
    @State private var appearOpacity: Double = 0
    @State private var isNewlyAdded: Bool = true
    @State private var isRemoving: Bool = false
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    @AppStorage private var hasShownNewBadge: Bool
    @State private var showNewBadge: Bool = false
    @State private var badgeScale: CGFloat = 0.1
    @State private var badgeRotation: Double = 0
    
    @State private var showingRemoveConfirmation = false
    @State private var pendingQuantityZero = false
    
    @Environment(CartStateManager.self) private var stateManager
    
    // MARK: - Initializer
    
    init(storeItem: StoreItem, cart: Cart, action: @escaping () -> Void, onQuantityChange: (() -> Void)? = nil) {
        self.storeItem = storeItem
        self.cart = cart
        self.action = action
        self.onQuantityChange = onQuantityChange
        
        if storeItem.isShoppingOnlyItem {
            let storageKey = "hasShownNewBadge_\(storeItem.id)"
            self._hasShownNewBadge = AppStorage(wrappedValue: false, storageKey)
        } else {
            self._hasShownNewBadge = AppStorage(wrappedValue: false, "vault_dummy_\(storeItem.id)")
        }
    }
    
    // MARK: - Computed Properties
    
    private var itemName: String {
        storeItem.item.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var storeName: String {
        storeItem.priceOption.store.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var currentQuantity: Double {
        if let cartItem = findCartItem() {
            return cartItem.quantity
        }
        return 0
    }
    
    private var itemType: ItemType {
        if storeItem.isShoppingOnlyItem {
            return .shoppingOnly
        }
        
        if let cartItem = findCartItem() {
            if cartItem.originalPlanningQuantity != nil {
                return .plannedCart
            }
            if cartItem.quantity > 0 {
                return .vaultOnly
            }
        }
        
        return .vaultOnly
    }
    
    private var badgeText: String {
        if storeItem.isShoppingOnlyItem {
            return "New"
        }
        
        if let cartItem = findCartItem() {
            if cartItem.originalPlanningQuantity != nil {
                return "Planned"
            }
            if cartItem.addedDuringShopping {
                return "Added"
            } else {
                return "Vault"
            }
        }
        
        return "Vault"
    }
    
    private var shouldShowNewBadge: Bool {
        showNewBadge
            && storeItem.isShoppingOnlyItem
            && currentQuantity > 0
            && cart.isShopping
            && hasShownNewBadge == false
    }
    
    // MARK: - Main Body
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            StateIndicator(
                color: indicatorColor,
                shouldShow: shouldShowIndicator
            )
            
            ItemDetails(
                storeItem: storeItem,
                itemType: itemType,
                badgeText: badgeText,
                textColor: textColor,
                priceColor: priceColor,
                contentOpacity: contentOpacity,
                shouldShowNewBadge: shouldShowNewBadge,
                badgeScale: badgeScale,
                badgeRotation: badgeRotation
            )
            
            Spacer()
            
            QuantityControlsView(
                itemType: itemType,
                currentQuantity: currentQuantity,
                isFocused: isFocused,
                textValue: $textValue,
                focusBinding: $isFocused,
                onMinus: handleMinus,
                onPlus: handlePlus,
                onRemove: handleRemoveShoppingOnlyItem,
                onTextCommit: commitTextField
            )
        }
        .modifier(RowContainerModifier(
            isRemoving: isRemoving,
            appearScale: appearScale,
            appearOpacity: appearOpacity,
            currentQuantity: currentQuantity,
            isNewItem: badgeText == "New",
            itemType: itemType,
            isFocused: isFocused,
            storeItemId: storeItem.item.id,
            isSkippedPlannedItem: isSkippedPlannedItem,
            itemName: itemName,
            onTap: handleRowTap
        ))
        .onAppear(perform: handleAppear)
        .onChange(of: cart.cartItems.count) { _, _ in updateTextValue() }
        .onChange(of: isFocused) { _, newValue in
            if !newValue { commitTextField() }
        }
        .onChange(of: currentQuantity) { _, newValue in
            if !isFocused {
                textValue = formatValue(newValue)
            }
        }
        .onDisappear {
            isNewlyAdded = true
            if !hasShownNewBadge {
                showNewBadge = false
            }
        }
        .alert("Remove Item", isPresented: $showingRemoveConfirmation) {
            Button("Cancel", role: .cancel, action: cancelRemove)
            Button("Remove", role: .destructive, action: confirmRemoveShoppingOnlyItem)
        } message: {
            Text("Remove '\(itemName)' from your shopping list?")
        }
    }
    
    // MARK: - UI State Properties
    
    private var isSkippedPlannedItem: Bool {
        guard let cartItem = findCartItem() else { return false }
        return !storeItem.isShoppingOnlyItem &&
            cartItem.originalPlanningQuantity != nil &&
            cartItem.isSkippedDuringShopping
    }
    
    private var shouldShowIndicator: Bool {
        badgeText == "Planned" && currentQuantity > 0 && !isSkippedPlannedItem
    }
    
    private var indicatorColor: Color {
        badgeText == "Planned" ? .blue : .clear
    }
    
    private var textColor: Color {
        switch itemType {
        case .vaultOnly:
            return currentQuantity > 0 ? .black : Color(hex: "333").opacity(0.7)
        case .plannedCart, .shoppingOnly:
            return currentQuantity > 0 ? .black : Color(hex: "333").opacity(0.7)
        }
    }
    
    private var priceColor: Color {
        switch itemType {
        case .vaultOnly:
            return currentQuantity > 0 ? .gray : Color(hex: "666").opacity(0.7)
        case .plannedCart, .shoppingOnly:
            return currentQuantity > 0 ? .gray : Color(hex: "888").opacity(0.7)
        }
    }
    
    private var contentOpacity: Double {
        switch itemType {
        case .vaultOnly: 
            return currentQuantity > 0 ? 1.0 : 0.7
        case .plannedCart, .shoppingOnly: 
            return currentQuantity > 0 ? 1.0 : 0.7
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleRowTap() {
        if isSkippedPlannedItem {
            handleUnskipPlannedItem()
            return
        }
        
        if isFocused {
            isFocused = false
            commitTextField()
        }
    }
    
    private func handleAppear() {
        textValue = formatValue(currentQuantity)
        
        if storeItem.isShoppingOnlyItem {
            if let cartItem = findCartItem(), cart.isShopping {
                let timeSinceAdded = Date().timeIntervalSince(cartItem.addedAt ?? Date.distantPast)
                if timeSinceAdded < 3.0 {
                    if !hasShownNewBadge {
                        showNewBadge = true
                        startNewBadgeAnimation()
                    } else {
                        showNewBadge = true
                        badgeScale = 1.0
                    }
                } else if hasShownNewBadge {
                    showNewBadge = true
                    badgeScale = 1.0
                }
            }
        }
        
        if isNewlyAdded {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                appearScale = 1.0
                appearOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isNewlyAdded = false
            }
        } else {
            appearScale = 1.0
            appearOpacity = 1.0
        }
    }
    
    private func handlePlus() {
        let newValue: Double
        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
            newValue = ceil(currentQuantity)
        } else {
            newValue = currentQuantity + 1
        }
        
        let clamped = min(newValue, 100)
        
        // Always try to activate if current quantity is 0
        if currentQuantity == 0 {
             if !storeItem.isShoppingOnlyItem {
                 if findCartItem() == nil {
                     if cart.isShopping {
                         vaultService.addVaultItemToCartDuringShopping(
                             item: storeItem.item,
                             store: storeName,
                             price: storeItem.priceOption.pricePerUnit.priceValue,
                             unit: storeItem.priceOption.pricePerUnit.unit,
                             cart: cart,
                             quantity: 1
                         )
                     } else {
                         vaultService.addVaultItemToCart(
                             item: storeItem.item,
                             cart: cart,
                             quantity: 1,
                             selectedStore: storeName
                         )
                     }
                     // Force an immediate UI update
                     textValue = formatValue(1)
                     onQuantityChange?()
                     sendShoppingUpdateNotification()
                     UIImpactFeedbackGenerator(style: .light).impactOccurred()
                     return
                 }
             }
        }
        
        if storeItem.isShoppingOnlyItem {
            updateCartItemWithQuantity(clamped)
        } else {
            if findCartItem() != nil {
                updateCartItemWithQuantity(clamped)
            } else {
                if cart.isShopping {
                    vaultService.addVaultItemToCartDuringShopping(
                        item: storeItem.item,
                        store: storeName,
                        price: storeItem.priceOption.pricePerUnit.priceValue,
                        unit: storeItem.priceOption.pricePerUnit.unit,
                        cart: cart,
                        quantity: 1
                    )
                } else {
                    vaultService.addVaultItemToCart(
                        item: storeItem.item,
                        cart: cart,
                        quantity: 1,
                        selectedStore: storeName
                    )
                }
                // Force an immediate UI update
                textValue = formatValue(1)
                onQuantityChange?()
                sendShoppingUpdateNotification()
            }
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func handleMinus() {
        let currentQty = currentQuantity
        guard currentQty > 0 else { return }
        
        let newValue: Double
        if currentQty.truncatingRemainder(dividingBy: 1) != 0 {
            newValue = floor(currentQty)
        } else {
            newValue = currentQty - 1
        }
        
        if newValue <= 0 {
            handleZeroQuantity()
            return
        }
        
        let clamped = max(newValue, 0)
        updateCartItemWithQuantity(clamped)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func handleUnskipPlannedItem() {
        guard let cartItem = findCartItem() else { return }
        let restoredQuantity = max(1, cartItem.originalPlanningQuantity ?? 1)
        updateCartItemWithQuantity(restoredQuantity)
    }

    private func handleRemoveShoppingOnlyItem() {
        guard storeItem.isShoppingOnlyItem else { return }
        showingRemoveConfirmation = true
        pendingQuantityZero = false
    }
    
    private func confirmRemoveShoppingOnlyItem() {
        if let cartItem = findCartItem(), itemType == .shoppingOnly {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isRemoving = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                    cart.cartItems.remove(at: index)
                    vaultService.updateCartTotals(cart: cart)
                    updateTextValue()
                    onQuantityChange?()
                    
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShoppingDataUpdated"),
                        object: nil,
                        userInfo: ["cartItemId": cart.id]
                    )
                }
            }
        }
        
        pendingQuantityZero = false
        showingRemoveConfirmation = false
    }
    
    private func cancelRemove() {
        textValue = formatValue(currentQuantity)
        pendingQuantityZero = false
        showingRemoveConfirmation = false
    }
    
    private func handleZeroQuantity() {
        guard let cartItem = findCartItem() else {
            textValue = ""
            return
        }
        
        switch itemType {
        case .plannedCart:
            cartItem.quantity = 0
            cartItem.syncQuantities(cart: cart)
            cartItem.isSkippedDuringShopping = true
            vaultService.updateCartTotals(cart: cart)
            textValue = formatValue(0)
            onQuantityChange?()
            sendShoppingUpdateNotification()
            
        case .shoppingOnly:
            showingRemoveConfirmation = true
            pendingQuantityZero = true
            
        case .vaultOnly:
            if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                cart.cartItems.remove(at: index)
                vaultService.updateCartTotals(cart: cart)
            }
            textValue = ""
            onQuantityChange?()
            sendShoppingUpdateNotification()
        }
    }
    
    private func commitTextField() {
        guard !textValue.isEmpty else {
            handleZeroQuantity()
            return
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        if let number = formatter.number(from: textValue) {
            let doubleValue = number.doubleValue
            
            if doubleValue <= 0 {
                handleZeroQuantity()
                return
            } else {
                let clamped = min(max(doubleValue, 0.01), 100)
                updateCartItemWithQuantity(clamped)
                textValue = formatValue(clamped)
            }
        } else {
            textValue = formatValue(currentQuantity)
        }
    }
    
    // MARK: - Helper Functions
    
    private func findCartItem() -> CartItem? {
        let searchName = itemName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let searchStore = storeName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        for cartItem in cart.cartItems {
            if cartItem.isShoppingOnlyItem {
                let cartItemName = cartItem.shoppingOnlyName?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let cartItemStore = cartItem.shoppingOnlyStore?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                if cartItemName == searchName && cartItemStore == searchStore {
                    return cartItem
                }
            } else {
                if cartItem.itemId == storeItem.item.id {
                    return cartItem
                }
            }
        }
        
        return nil
    }
    
    private func updateTextValue() {
        if !isFocused {
            textValue = formatValue(currentQuantity)
        }
    }
    
    private func formatValue(_ val: Double) -> String {
        guard !val.isNaN && val.isFinite && val >= 0 else {
            return "0"
        }
        
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            var result = String(format: "%.2f", val)
            while result.last == "0" { result.removeLast() }
            if result.last == "." { result.removeLast() }
            return result
        }
    }
    
    private func startNewBadgeAnimation() {
        guard storeItem.isShoppingOnlyItem else { return }
        
        showNewBadge = true
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            hasShownNewBadge = true
            
            withAnimation(.easeOut(duration: 0.3)) {
                badgeRotation = 0
            }
        }
    }
    
    private func sendShoppingUpdateNotification() {
        guard let cartItem = findCartItem() else { return }
        
        let currentQuantity = cartItem.quantity
        
        NotificationCenter.default.post(
            name: .shoppingItemQuantityChanged,
            object: nil,
            userInfo: [
                "cartId": cart.id,
                "itemId": storeItem.item.id,
                "itemName": itemName,
                "newQuantity": currentQuantity,
                "itemType": String(describing: itemType)
            ]
        )
    }
    
    private func updateCartItemWithQuantity(_ quantity: Double) {
        if !storeItem.isShoppingOnlyItem {
            if let cartItem = findCartItem() {
                cartItem.quantity = quantity
                cartItem.syncQuantities(cart: cart)
                cartItem.isSkippedDuringShopping = false
                vaultService.updateCartTotals(cart: cart)
            } else {
                if cart.isShopping {
                    vaultService.addVaultItemToCartDuringShopping(
                        item: storeItem.item,
                        store: storeName,
                        price: storeItem.priceOption.pricePerUnit.priceValue,
                        unit: storeItem.priceOption.pricePerUnit.unit,
                        cart: cart,
                        quantity: quantity
                    )
                } else {
                    vaultService.addVaultItemToCart(
                        item: storeItem.item,
                        cart: cart,
                        quantity: quantity,
                        selectedStore: storeName
                    )
                }
            }
        } else {
            if let cartItem = findCartItem() {
                cartItem.quantity = quantity
                cartItem.syncQuantities(cart: cart)
                vaultService.updateCartTotals(cart: cart)
            } else {
                vaultService.addShoppingItemToCart(
                    name: itemName,
                    store: storeName,
                    price: storeItem.priceOption.pricePerUnit.priceValue,
                    unit: storeItem.priceOption.pricePerUnit.unit,
                    cart: cart,
                    quantity: quantity
                )
            }
        }
        
        DispatchQueue.main.async {
            onQuantityChange?()
            sendShoppingUpdateNotification()
        }
    }
}

// MARK: - Supporting Views

private struct StateIndicator: View {
    let color: Color
    let shouldShow: Bool
    
    var body: some View {
        VStack {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
                .scaleEffect(shouldShow ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: shouldShow)
                .padding(.top, 8)
            Spacer()
        }
    }
}

private struct ItemDetails: View {
    let storeItem: StoreItem
    let itemType: ItemType
    let badgeText: String
    let textColor: Color
    let priceColor: Color
    let contentOpacity: Double
    let shouldShowNewBadge: Bool
    let badgeScale: CGFloat
    let badgeRotation: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center, spacing: 4) {
                Text(storeItem.item.name)
                    .lexendFont(17)
                    .foregroundColor(textColor)
                    .opacity(contentOpacity)
                
                Text(badgeText)
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(badgeColor.opacity(0.15))
                    .foregroundColor(badgeColor)
                    .clipShape(Capsule())
                
                if shouldShowNewBadge {
                    NewBadgeView(
                        scale: badgeScale,
                        rotation: badgeRotation,
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            HStack(spacing: 0) {
                let price = storeItem.priceOption.pricePerUnit.priceValue
                let isValidPrice = !price.isNaN && price.isFinite
                
                Text("\(CurrencyManager.shared.selectedCurrency.symbol)\(isValidPrice ? price : 0, specifier: "%g")")
                    .foregroundColor(priceColor)
                    .opacity(contentOpacity)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: CurrencyManager.shared.selectedCurrency.symbol)
                
                Text("/\(storeItem.priceOption.pricePerUnit.unit)")
                    .foregroundColor(priceColor)
                    .opacity(contentOpacity)
                
                if let category = GroceryCategory.allCases.first(where: { $0.title == storeItem.categoryName }), stateManager.showCategoryIcons {
                    Text(category.emoji)
                        .font(.caption)
                        .padding(.leading, 6)
                        .opacity(contentOpacity)
                }
                
                Spacer()
            }
            .lexendFont(12)
        }
    }
    
    @Environment(CartStateManager.self) private var stateManager
    
    private var badgeColor: Color {
        switch badgeText {
        case "Planned": return .blue
        case "New": return .cartNewDeep
        case "Added": return .cartAddedDeep
        default: return .cartVaultDeep
        }
    }
}

private struct QuantityControlsView: View {
    let itemType: ItemType
    let currentQuantity: Double
    let isFocused: Bool
    @Binding var textValue: String
    let focusBinding: FocusState<Bool>.Binding
    let onMinus: () -> Void
    let onPlus: () -> Void
    let onRemove: () -> Void
    let onTextCommit: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            switch itemType {
            case .vaultOnly:
                if currentQuantity > 0 {
                    ControlMinusButton(isFocused: isFocused, action: onMinus)
                    QuantityTextField(
                        textValue: $textValue,
                        focusBinding: focusBinding,
                        onCommit: onTextCommit
                    )
                    ControlPlusButton(
                        color: Color(hex: "1E2A36"),
                        strokeColor: .clear,
                        isFocused: isFocused,
                        action: onPlus
                    )
                } else {
                    ControlPlusButton(
                        color: Color(hex: "888888").opacity(0.7),
                        strokeColor: Color(hex: "F2F2F2").darker(by: 0.1),
                        isFocused: isFocused,
                        action: onPlus
                    )
                }
                
            case .plannedCart:
                if currentQuantity > 0 {
                    ControlMinusButton(isFocused: isFocused, action: onMinus)
                    QuantityTextField(
                        textValue: $textValue,
                        focusBinding: focusBinding,
                        onCommit: onTextCommit
                    )
                    ControlPlusButton(
                        color: Color(hex: "1E2A36"),
                        strokeColor: .clear,
                        isFocused: isFocused,
                        action: onPlus
                    )
                } else {
                    ControlPlusButton(
                        color: .blue.opacity(0.7),
                        strokeColor: .blue.opacity(0.3),
                        isFocused: isFocused,
                        action: onPlus
                    )
                }
                
            case .shoppingOnly:
                if currentQuantity > 0 {
                    ControlMinusButton(isFocused: isFocused, action: onMinus)
                    QuantityTextField(
                        textValue: $textValue,
                        focusBinding: focusBinding,
                        onCommit: onTextCommit
                    )
                    ControlPlusButton(
                        color: Color(hex: "1E2A36"),
                        strokeColor: .clear,
                        isFocused: isFocused,
                        action: onPlus
                    )
                } else {
                    ControlRemoveButton(isFocused: isFocused, action: onRemove)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentQuantity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        .padding(.top, 6)
    }
}

private struct ControlMinusButton: View {
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "minus")
                .font(.footnote).bold()
                .foregroundColor(Color(hex: "1E2A36"))
                .frame(width: 24, height: 24)
                .background(.white)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(isFocused)
        .opacity(isFocused ? 0.5 : 1)
    }
}

private struct ControlPlusButton: View {
    let color: Color
    let strokeColor: Color
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.footnote)
                .bold()
                .foregroundColor(color)
        }
        .frame(width: 24, height: 24)
        .background(.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(strokeColor, lineWidth: 1)
                .opacity(isFocused ? 0.3 : 1)
        )
        .buttonStyle(.plain)
        .disabled(isFocused)
        .opacity(isFocused ? 0.5 : 1)
    }
}

private struct ControlRemoveButton: View {
    let isFocused: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "trash")
                .font(.footnote)
                .foregroundColor(.red)
                .frame(width: 24, height: 24)
                .background(.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        .opacity(isFocused ? 0.3 : 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(isFocused)
        .opacity(isFocused ? 0.5 : 1)
    }
}

private struct QuantityTextField: View {
    @Binding var textValue: String
    let focusBinding: FocusState<Bool>.Binding
    let onCommit: () -> Void
    
    var body: some View {
        ZStack {
            Text(textValue)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "2C3E50"))
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: textValue)
                .fixedSize()

            TextField("", text: $textValue)
                .keyboardType(.decimalPad)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.clear)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .focused(focusBinding)
                .numbersOnly($textValue, includeDecimal: true)
                .onChange(of: textValue) { _, newText in
                    if let number = Double(newText), number > 100 {
                        textValue = "100"
                    }
                }
        }
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "F2F2F2").darker(by: 0.1), lineWidth: 1)
        )
        .frame(minWidth: 40)
        .frame(maxWidth: 80)
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - View Modifiers

private struct RowContainerModifier: ViewModifier {
    let isRemoving: Bool
    let appearScale: CGFloat
    let appearOpacity: Double
    let currentQuantity: Double
    let isNewItem: Bool
    let itemType: ItemType
    let isFocused: Bool
    let storeItemId: String
    let isSkippedPlannedItem: Bool
    let itemName: String
    let onTap: () -> Void
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, 4)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isNewItem ? Color.cartNewBackground : .white)
            .overlay {
                if isSkippedPlannedItem {
                    ZStack {
                        Color.cartSkippedBackground
                        
                        Text("Unskip \(itemName) item")
                            .fuzzyBubblesFont(15, weight: .bold)
                            .foregroundColor(.cartSkippedDeep)
                            .underline()
                    }
                }
            }
            .scaleEffect(isRemoving ? 0.9 : appearScale)
            .opacity(isRemoving ? 0 : appearOpacity)
            .offset(x: isRemoving ? -UIScreen.main.bounds.width : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isRemoving)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentQuantity)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemType)
            .onTapGesture(perform: onTap)
            .preference(key: TextFieldFocusPreferenceKey.self, value: isFocused ? storeItemId : nil)
    }
}
