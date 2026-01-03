//
//  BrowseVaultItemRow.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 1/3/26.
//

import SwiftUI

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
    
    // New badge state (same as in CartItemRowListView)
    @AppStorage private var hasShownNewBadge: Bool
    @State private var showNewBadge: Bool = false
    @State private var badgeScale: CGFloat = 0.1
    @State private var badgeRotation: Double = 0
    
    @State private var showingRemoveConfirmation = false
    @State private var pendingQuantityZero = false
    
    // Store item info for shopping-only items
    private var itemName: String {
        storeItem.item.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var storeName: String {
        storeItem.priceOption.store.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // FIX 1: Added missing state variables
//    @State private var cartItemToDelete: CartItem?
//    @State private var showingDeleteConfirmation = false
//    
    // Custom initializer for AppStorage with dynamic key
    init(storeItem: StoreItem, cart: Cart, action: @escaping () -> Void, onQuantityChange: (() -> Void)? = nil) {
        self.storeItem = storeItem
        self.cart = cart
        self.action = action
        self.onQuantityChange = onQuantityChange
        
        // FIXED: Only create storage key for shopping-only items
        if storeItem.isShoppingOnlyItem {
            let storageKey = "hasShownNewBadge_\(storeItem.id)"
            self._hasShownNewBadge = AppStorage(wrappedValue: false, storageKey)
        } else {
            // For vault items, use a dummy key
            self._hasShownNewBadge = AppStorage(wrappedValue: false, "vault_dummy_\(storeItem.id)")
        }
    }
    
    // MARK: - Computed Properties
    
    // Helper to get current quantity - directly from cart
    private var currentQuantity: Double {
        if let cartItem = findCartItem() {
            return cartItem.quantity
        }
        return 0
    }
    
    private var isActive: Bool {
        currentQuantity > 0
    }
    
    private var itemType: ItemType {
        if storeItem.isShoppingOnlyItem {
            return .shoppingOnly
        }
        
        // Check if it's in cart as a vault item
        if let cartItem = findCartItem() {
            // Vault item is in cart
            if cartItem.quantity > 0 {
                // Active in cart
                return .plannedCart
            } else {
                // In cart but quantity = 0 (deactivated)
                return .vaultOnly // Show as vault-only (inactive)
            }
        }
        
        // Not in cart at all
        return .vaultOnly
    }
    
    // MARK: - UI Properties based on item type and quantity
    
    private var shouldShowIndicator: Bool {
        switch itemType {
        case .vaultOnly:
            return false
        case .plannedCart, .shoppingOnly:
            return currentQuantity > 0
        }
    }
    
    private var indicatorColor: Color {
        switch itemType {
        case .vaultOnly:
            return .clear
        case .plannedCart:
            return .blue
        case .shoppingOnly:
            return .orange
        }
    }
    
    private var textColor: Color {
        switch itemType {
        case .vaultOnly:
            return Color(hex: "333").opacity(0.7)
        case .plannedCart:
            return currentQuantity > 0 ? .black : Color(hex: "333").opacity(0.7)
        case .shoppingOnly:
            return currentQuantity > 0 ? .black : Color(hex: "333").opacity(0.7)
        }
    }
    
    private var priceColor: Color {
        switch itemType {
        case .vaultOnly:
            return Color(hex: "666").opacity(0.7)
        case .plannedCart:
            return currentQuantity > 0 ? .gray : Color(hex: "888").opacity(0.7)
        case .shoppingOnly:
            return currentQuantity > 0 ? .gray : Color(hex: "888").opacity(0.7)
        }
    }
    
    private var contentOpacity: Double {
        switch itemType {
        case .vaultOnly:
            return 0.7
        case .plannedCart:
            return currentQuantity > 0 ? 1.0 : 0.7
        case .shoppingOnly:
            return currentQuantity > 0 ? 1.0 : 0.7
        }
    }
    
    // MARK: - Buttons and UI Components
    
    private var minusButton: some View {
        Button {
            handleMinus()
        } label: {
            Image(systemName: "minus")
                .font(.footnote).bold()
                .foregroundColor(Color(hex: "1E2A36"))
                .frame(width: 24, height: 24)
                .background(.white)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .disabled(currentQuantity <= 0 || isFocused)
        .opacity((currentQuantity <= 0 || isFocused) ? 0.5 : 1)
    }
    
    private var removeButton: some View {
        Button {
            handleRemoveShoppingOnlyItem()
        } label: {
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
    
    // FIX 2: Simplified the plusButton property to avoid type-checking issues
    private var plusButton: some View {
        let buttonColor: Color = {
            switch itemType {
            case .vaultOnly:
                return Color(hex: "888888").opacity(0.7)
            case .plannedCart:
                return currentQuantity > 0 ? Color(hex: "1E2A36") : .blue.opacity(0.7)
            case .shoppingOnly:
                return currentQuantity > 0 ? Color(hex: "1E2A36") : .orange.opacity(0.7)
            }
        }()
        
        let strokeColor: Color = {
            switch itemType {
            case .vaultOnly:
                return Color(hex: "F2F2F2").darker(by: 0.1)
            case .plannedCart:
                return currentQuantity > 0 ? .clear : .blue.opacity(0.3)
            case .shoppingOnly:
                return currentQuantity > 0 ? .clear : .orange.opacity(0.3)
            }
        }()
        
        return Button(action: handlePlus) {
            Image(systemName: "plus")
                .font(.footnote)
                .bold()
                .foregroundColor(buttonColor)
        }
        .frame(width: 24, height: 24)
        .background(.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(strokeColor, lineWidth: 1)
                .opacity(isFocused ? 0.3 : 1)
        )
        .contentShape(Circle())
        .buttonStyle(.plain)
        .disabled(isFocused)
        .opacity(isFocused ? 0.5 : 1)
    }
    
    private var quantityTextField: some View {
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
                .focused($isFocused)
                .normalizedNumber($textValue, allowDecimal: true, maxDecimalPlaces: 2)
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
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            // State indicator based on item type
            VStack {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 9, height: 9)
                    .scaleEffect(shouldShowIndicator ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: shouldShowIndicator)
                    .padding(.top, 8)
                Spacer()
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 4) {
                    Text(storeItem.item.name)
                        .lexendFont(17)
                        .foregroundColor(textColor)
                        .opacity(contentOpacity)
                    
                    // NEW: Use the reusable NewBadgeView component
                    if showNewBadge
                        && storeItem.isShoppingOnlyItem
                        && currentQuantity > 0
                        && cart.isShopping
                        && hasShownNewBadge == false {
                        NewBadgeView(
                            scale: badgeScale,
                            rotation: badgeRotation
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                HStack(spacing: 0) {
                    let price = storeItem.priceOption.pricePerUnit.priceValue
                    let isValidPrice = !price.isNaN && price.isFinite
                    
                    Text("₱\(isValidPrice ? price : 0, specifier: "%g")")
                        .foregroundColor(priceColor)
                        .opacity(contentOpacity)
                    
                    Text("/\(storeItem.priceOption.pricePerUnit.unit)")
                        .foregroundColor(priceColor)
                        .opacity(contentOpacity)
                    
                    Text(" • \(storeItem.categoryName)")
                        .font(.caption)
                        .foregroundColor(priceColor.opacity(0.7))
                        .opacity(contentOpacity)
                    
                    Spacer()
                }
                .lexendFont(12)
            }
            
            Spacer()
            
            // MARK: - Quantity Controls
            HStack(spacing: 8) {
                switch itemType {
                case .vaultOnly:
                    // Vault-only items: only show plus button
                    plusButton
                        .transition(.scale.combined(with: .opacity))
                    
                case .plannedCart:
                    // Planned cart items: show controls based on quantity
                    if currentQuantity > 0 {
                        minusButton
                            .transition(.scale.combined(with: .opacity))
                        quantityTextField
                            .transition(.scale.combined(with: .opacity))
                        plusButton
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // Quantity is 0 - show only plus button (reactivate)
                        plusButton
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                case .shoppingOnly:
                    // Shopping-only items: show controls if active, remove button if quantity is 0
                    if currentQuantity > 0 {
                        minusButton
                            .transition(.scale.combined(with: .opacity))
                        quantityTextField
                            .transition(.scale.combined(with: .opacity))
                        plusButton
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // Show remove button for shopping-only items with quantity 0
                        removeButton
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentQuantity)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
            .padding(.top, 6)
        }
        .padding(.bottom, 4)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.white)
        .scaleEffect(isRemoving ? 0.9 : appearScale)
        .opacity(isRemoving ? 0 : appearOpacity)
        .offset(x: isRemoving ? -UIScreen.main.bounds.width : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isRemoving)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentQuantity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemType)
        .onTapGesture {
            if isFocused {
                isFocused = false
                commitTextField()
            }
        }
        .preference(key: TextFieldFocusPreferenceKey.self, value: isFocused ? storeItem.id : nil)
        .onAppear {
            // Set initial text value to current quantity
            textValue = formatValue(currentQuantity)
            
            // FIXED: Only check for shopping-only items
            if storeItem.isShoppingOnlyItem {
                if let cartItem = findCartItem(), cart.isShopping {
                    let timeSinceAdded = Date().timeIntervalSince(cartItem.addedAt)
                    if timeSinceAdded < 3.0 {
                        // If we've never shown the badge before, show it with animation
                        if !hasShownNewBadge {
                            showNewBadge = true
                            startNewBadgeAnimation()
                        } else {
                            // If we've shown it before, just show it without animation
                            showNewBadge = true
                        }
                    } else if hasShownNewBadge {
                        // If badge was shown before, keep it visible
                        showNewBadge = true
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
        .onChange(of: cart.cartItems.count) { oldCount, newCount in
            // Force update when cart items count changes
            updateTextValue()
        }
        .onChange(of: textValue) { oldValue, newValue in
            if isFocused && newValue.isEmpty {
                return
            }
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if !newValue {
                commitTextField()
            }
        }
        .onChange(of: currentQuantity) { oldValue, newValue in
            print("🔄 currentQuantity changed: \(oldValue) → \(newValue)")
            
            // Only update textValue if not focused
            if !isFocused {
                textValue = formatValue(newValue)
            }
        }
        .onDisappear {
            isNewlyAdded = true
            // Don't hide the badge when view disappears if we've already shown it
            if !hasShownNewBadge {
                showNewBadge = false
            }
        }
        // FIX 3: Replace the incorrect confirmationAlert with a proper alert
        .alert("Remove Item", isPresented: $showingRemoveConfirmation) {
            Button("Cancel", role: .cancel) {
                cancelRemove()
            }
            Button("Remove", role: .destructive) {
                confirmRemoveShoppingOnlyItem()
            }
        } message: {
            // FIXED: Use the itemName property that you already have
            Text("Remove '\(itemName)' from your shopping list?")
        }
    }
    
    // FIX 4: Added the missing getItemName function
    private func getItemName(for cartItem: CartItem?) -> String {
        guard let cartItem = cartItem else { return "" }
        
        if cartItem.isShoppingOnlyItem {
            return cartItem.shoppingOnlyName ?? "Unknown Item"
        } else {
            // FIXED: Use vaultService to find the item instead of cartItem.item
            return vaultService.findItemById(cartItem.itemId)?.name ?? "Unknown Item"
        }
    }
    
    // FIX 5: Added the missing deleteCartItem function
    private func deleteCartItem() {
        // Find the cart item
        guard let cartItem = findCartItem() else { return }
        
        // Find and remove the cart item
        if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
            cart.cartItems.remove(at: index)
            vaultService.updateCartTotals(cart: cart)
            onQuantityChange?()
            
            // Send notification to refresh BrowseVaultView
            NotificationCenter.default.post(
                name: NSNotification.Name("ShoppingDataUpdated"),
                object: nil,
                userInfo: ["cartItemId": cart.id]
            )
        }
    }
    
    private func confirmRemoveShoppingOnlyItem() {
        print("✅ User confirmed removal of shopping-only item: \(itemName)")
        
        if let cartItem = findCartItem(), itemType == .shoppingOnly {
            // Trigger removal animation first
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isRemoving = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                    print("   Removing shopping-only item from cart at index \(index)")
                    cart.cartItems.remove(at: index)
                    vaultService.updateCartTotals(cart: cart)
                    updateTextValue()
                    onQuantityChange?()
                    
                    // Send notification to refresh BrowseVaultView
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShoppingDataUpdated"),
                        object: nil,
                        userInfo: ["cartItemId": cart.id]
                    )
                }
            }
        }
        
        // Reset state
        pendingQuantityZero = false
        showingRemoveConfirmation = false
    }
    
    private func cancelRemove() {
        print("❌ User canceled removal of shopping-only item: \(itemName)")
        
        // Restore the text value to current quantity
        textValue = formatValue(currentQuantity)
        pendingQuantityZero = false
        showingRemoveConfirmation = false
    }
    
    // MARK: - New Badge Animation
    private func startNewBadgeAnimation() {
        guard storeItem.isShoppingOnlyItem else { return }
        
        showNewBadge = true
        
        // Badge appears with spring and slight initial rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 100, damping: 10)) {
                badgeScale = 1.0
                badgeRotation = 3 // Small initial tilt
            }
        }
        
        // Sequence: Single smooth rocking motion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Gentle rocking motion
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 50, damping: 7)) {
                badgeRotation = -2
            }
            
            // Return to center
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 50, damping: 7)) {
                    badgeRotation = 1
                }
                
                // Final settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 60, damping: 8)) {
                        badgeRotation = 0
                    }
                }
            }
        }
        
        // Mark as shown after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            // Save that we've shown the badge
            hasShownNewBadge = true
            
            withAnimation(.easeOut(duration: 0.3)) {
                badgeRotation = 0
            }
        }
    }
    
    // MARK: - Helper Functions
    private func findCartItem() -> CartItem? {
        // For shopping-only items: find by name and store (CASE INSENSITIVE)
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
                // Check vault items - include items even if quantity = 0
                if cartItem.itemId == storeItem.item.id {
                    return cartItem
                }
            }
        }
        
        return nil
    }
    
    private func updateTextValue() {
        // Update text value to match current quantity (only if not focused)
        if !isFocused {
            textValue = formatValue(currentQuantity)
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
    
    private func handleZeroQuantity() {
        guard let cartItem = findCartItem() else {
            textValue = ""
            return
        }
        
        print("🔄 handleZeroQuantity called for: \(itemName)")
        print("   Item type: \(itemType)")
        print("   Current quantity: \(cartItem.quantity)")
        
        switch itemType {
        case .plannedCart:
            print("📋 Setting vault item quantity to 0 (deactivating): \(itemName)")
            
            // Set to 0 but KEEP IN CART (deactivate)
            cartItem.quantity = 0
            cartItem.syncQuantities(cart: cart)
            cartItem.isSkippedDuringShopping = false // Not skipped, just deactivated
            
            vaultService.updateCartTotals(cart: cart)
            textValue = formatValue(0)
            onQuantityChange?()
            sendShoppingUpdateNotification()
            
        case .shoppingOnly:
            print("🛍️ Showing confirmation for shopping-only item: \(itemName)")
            
            // Show confirmation alert instead of immediately removing
            showingRemoveConfirmation = true
            pendingQuantityZero = true
            
        case .vaultOnly:
            // Vault item not in cart or already deactivated - do nothing
            break
        }
    }
    
    private func formatValue(_ val: Double) -> String {
        // Prevent NaN or invalid values
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
    
    // MARK: - Quantity Handlers with Rounding Logic
    private func handlePlus() {
        print("➕ Plus button tapped for: \(itemName)")
        print("   Item type: \(itemType)")
        print("   Current quantity: \(currentQuantity)")
        
        // Calculate new value with rounding
        let newValue: Double
        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
            // If decimal, round UP to nearest whole number
            newValue = ceil(currentQuantity)
        } else {
            // If whole number, add 1
            newValue = currentQuantity + 1
        }
        
        let clamped = min(newValue, 100)
        
        if storeItem.isShoppingOnlyItem {
            // Shopping-only item - always use updateCartItemWithQuantity
            updateCartItemWithQuantity(clamped)
        } else {
            // Vault item
            if findCartItem() != nil {
                // Vault item already in cart
                updateCartItemWithQuantity(clamped)
            } else {
                // Vault item not in cart - add it
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
                print("📋 Added vault item to cart: \(itemName)")
                
                sendShoppingUpdateNotification()
                onQuantityChange?()
            }
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func handleMinus() {
        print("➖ Minus button tapped for: '\(itemName)'")
        print("   Item type: \(itemType)")
        print("   Current quantity: \(currentQuantity)")
        
        let currentQty = currentQuantity
        guard currentQty > 0 else {
            print("⚠️ Quantity is already 0")
            return
        }
        
        // Calculate new value with rounding
        let newValue: Double
        if currentQty.truncatingRemainder(dividingBy: 1) != 0 {
            // If decimal, round DOWN to nearest whole number
            newValue = floor(currentQty)
        } else {
            // If whole number, subtract 1
            newValue = currentQty - 1
        }
        
        if newValue <= 0 {
            handleZeroQuantity()
            return
        }
        
        let clamped = max(newValue, 0)
        
        // For both vault and shopping-only items, use updateCartItemWithQuantity
        updateCartItemWithQuantity(clamped)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func handleRemoveShoppingOnlyItem() {
        print("🗑️ Remove button tapped for shopping-only item: \(itemName)")
        
        // Only for shopping-only items
        guard storeItem.isShoppingOnlyItem else { return }
        
        // Show confirmation alert instead of immediately removing
        showingRemoveConfirmation = true
        pendingQuantityZero = false // This is a direct removal, not from quantity going to 0
    }
    
    private func sendShoppingUpdateNotification() {
        guard let cartItem = findCartItem() else { return }
        
        // Always use cartItem.quantity as the source of truth
        let currentQuantity = cartItem.quantity
        
        print("📢 Sending notification - cartItem.quantity = \(currentQuantity)")
        
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
    
    // MARK: - Update Cart Item Function
    private func updateCartItemWithQuantity(_ quantity: Double) {
        print("🔄 updateCartItemWithQuantity called for: \(itemName)")
        print("   Current quantity: \(currentQuantity)")
        print("   New quantity: \(quantity)")
        print("   Item type: \(itemType)")
        
        if !storeItem.isShoppingOnlyItem {
            // VAULT ITEMS
            if let cartItem = findCartItem() {
                // Update existing vault item
                print("   Updating existing vault item from \(cartItem.quantity) to \(quantity)")
                cartItem.quantity = quantity
                cartItem.syncQuantities(cart: cart)
                cartItem.isSkippedDuringShopping = false
                vaultService.updateCartTotals(cart: cart)
                print("   ✅ Updated vault item quantity to: \(cartItem.quantity)")
            } else {
                // Add new vault item
                print("   Adding new vault item with quantity: \(quantity)")
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
                print("   ✅ Added new vault item")
            }
        } else {
            // SHOPPING-ONLY ITEMS
            if let cartItem = findCartItem() {
                print("   Updating shopping-only item from \(cartItem.quantity) to \(quantity)")
                cartItem.quantity = quantity
                cartItem.syncQuantities(cart: cart)
                vaultService.updateCartTotals(cart: cart)
                print("   ✅ Updated shopping-only item quantity to: \(cartItem.quantity)")
            } else {
                print("   Adding new shopping-only item with quantity: \(quantity)")
                vaultService.addShoppingItemToCart(
                    name: itemName,
                    store: storeName,
                    price: storeItem.priceOption.pricePerUnit.priceValue,
                    unit: storeItem.priceOption.pricePerUnit.unit,
                    cart: cart,
                    quantity: quantity
                )
                print("   ✅ Added new shopping-only item")
            }
        }
        
        // Update the UI after cart update
        DispatchQueue.main.async {
            onQuantityChange?()
            sendShoppingUpdateNotification()
        }
    }
}
