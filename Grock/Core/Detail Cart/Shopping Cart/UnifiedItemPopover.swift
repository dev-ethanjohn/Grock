import SwiftUI

struct UnifiedItemPopover: View {
    @Binding var isPresented: Bool
    let item: Item
    let cart: Cart
    let cartItem: CartItem
    let mode: PopoverMode
    var onSave: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    @FocusState private var focusedField: Field?
    
    @State private var price: String = ""
    @State private var portion: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    enum Field: Hashable {
        case price, portion
    }
    
    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0
    @State private var keyboardVisible: Bool = false
    
    private var storeName: String {
        cartItem.getStore(cart: cart)
    }
    
    private var plannedPrice: Double {
        cartItem.plannedPrice ?? 0
    }
    
    private var plannedUnit: String {
        cartItem.plannedUnit ?? "piece"
    }
    
    private var currentPrice: Double {
        cartItem.actualPrice ?? plannedPrice
    }
    
    private var currentQuantity: Double {
        cartItem.actualQuantity ?? Double(cartItem.quantity)
    }
    
    private var livePrice: Double {
        Double(price) ?? currentPrice
    }
    
    private var liveQuantity: Double {
        Double(portion) ?? currentQuantity
    }
    
    private var hasChanges: Bool {
        let enteredPrice = Double(price) ?? currentPrice
        let enteredQuantity = Double(portion) ?? currentQuantity
        
        return abs(enteredPrice - currentPrice) > 0.01 ||
        abs(enteredQuantity - currentQuantity) > 0.01
    }
    
    private var categoryInfo: (emoji: String, name: String) {
        if let category = vaultService.getCategory(for: item.id),
           let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == category.name }) {
            return (groceryCategory.emoji, category.name)
        }
        return ("📦", "Uncategorized")
    }
    
    private var currentPrompt: FieldPrompt {
        switch focusedField {
        case .price:
            return .price
        case .portion:
            return .portion
        case .none:
            return .none
        }
    }
    
    private var isFormValid: Bool {
        Double(price) ?? 0 > 0 && Double(portion) ?? 0 > 0
    }
    
    // For fulfill mode only
    private var totalCost: Double {
        livePrice * liveQuantity
    }
    
    private var plannedTotalCost: Double {
        plannedPrice * currentQuantity
    }
    
    private var totalCostDelta: Double {
        totalCost - plannedTotalCost
    }
    
    private var totalCostDeltaColor: Color {
        totalCostDelta > 0 ? Color(hex: "FA003F") : Color(hex: "4CAF50")
    }
    
    private var totalCostDeltaText: String {
        let delta = abs(totalCostDelta)
        let symbol = CurrencyManager.shared.selectedCurrency.symbol
        return String(format: "\(symbol)%.2f", delta)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6 * overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissPopover() }
            
            VStack(spacing: 20) {
                
                ItemDescriptionText(
                    itemName: item.name,
                    categoryEmoji: categoryInfo.emoji,
                    storeName: storeName,
                    livePrice: livePrice,
                    plannedPrice: plannedPrice,
                    plannedUnit: plannedUnit,
                    isShoppingOnlyItem: cartItem.isShoppingOnlyItem
                )
                
                inputFieldsSection
                    .onAppear {
                        price = String(format: "%.2f", currentPrice)
                        portion = String(format: currentQuantity.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", currentQuantity)
                    }
                
                if mode == .fulfill {
                    totalCostDisplay
                }
                
                if let errorMessage {
                    ErrorMessageDisplay(errorMessage: errorMessage)
                }
                
                ActionButtons(
                    mode: mode,
                    hasChanges: hasChanges,
                    isFormValid: isFormValid,
                    isSaving: isSaving,
                    saveChanges: saveChanges,
                    dismissPopover: dismissPopover
                )
                .padding(.top, 4)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(24)
            .padding(.horizontal, UIScreen.main.bounds.width * 0.04)
            .scaleEffect(contentScale)
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1), value: isFormValid)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: keyboardVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: errorMessage)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: price)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: portion)
            .frame(maxHeight: .infinity, alignment: keyboardVisible ? .center : .center)
        }
        .onAppear {
            focusedField = .price
            withAnimation(.easeOut(duration: 0.2)) {
                overlayOpacity = 1
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                contentScale = 1
            }
        }
        .onDisappear {
            onDismiss?()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                keyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                keyboardVisible = false
            }
        }
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text("Price per \(plannedUnit)")
                    .lexendFont(13)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text("Quantity")
                    .lexendFont(13)
                    .foregroundColor(.secondary)
                    .frame(width: 120, alignment: .center)
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 4) {
                PriceField(
                    price: $price,
                    focusedField: $focusedField,
                    plannedUnit: plannedUnit,
                    errorMessage: $errorMessage,
                    plannedPrice: plannedPrice
                )
                .frame(maxWidth: .infinity)
                
                PortionField(
                    portion: $portion,
                    focusedField: $focusedField,
                    plannedUnit: plannedUnit,
                    errorMessage: $errorMessage
                )
                .frame(width: 120)
            }
        }
    }
    
    private var totalCostDisplay: some View {
        VStack(spacing: 4) {
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 0.5)
                .foregroundColor(Color(hex: "999").opacity(0.5))
            
            HStack(alignment: .top) {
                Text("Total Cost:")
                    .lexendFont(16)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(totalCost.formattedCurrency)
                        .lexendFont(28, weight: .bold)
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                        .animation(.snappy, value: CurrencyManager.shared.selectedCurrency)
                    
                    if !cartItem.isShoppingOnlyItem && !cartItem.addedDuringShopping && abs(totalCostDelta) > 0.01 {
                        HStack(spacing: 2) {
                            Image(systemName: totalCostDelta > 0 ? "arrow.up" : "arrow.down")
                                .lexend(.caption2)
                                .foregroundColor(totalCostDeltaColor)
                            
                            Text(totalCostDeltaText)
                                .lexendFont(12, weight: .semibold)
                                .foregroundColor(totalCostDeltaColor)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: CurrencyManager.shared.selectedCurrency)
                            
                            Text("from plan")
                                .lexendFont(12)
                                .foregroundColor(totalCostDeltaColor)
                        }
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.8, anchor: .topTrailing)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)),
                                removal: .scale(scale: 0.8, anchor: .topTrailing)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1))
                            )
                        )
                    }
                }
                .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1), value: abs(totalCostDelta) > 0.01)
            }
            .padding(.top, 4)
        }
    }
    
    private func saveChanges() {
        guard let priceValue = Double(price),
              let portionValue = Double(portion) else {
            errorMessage = "Please enter valid numbers"
            return
        }
        
        isSaving = true
        
        if mode == .edit {
            // EDIT MODE - No animation, just update immediately
            if abs(priceValue - currentPrice) > 0.01 ||
                abs(portionValue - currentQuantity) > 0.01 {
                
                if cartItem.isShoppingOnlyItem {
                    cartItem.shoppingOnlyPrice = priceValue
                    cartItem.shoppingOnlyUnit = plannedUnit
                    cartItem.actualPrice = priceValue
                    cartItem.actualQuantity = portionValue
                    cartItem.quantity = portionValue
                    cartItem.syncQuantities(cart: cart)
                    cartItem.wasEditedDuringShopping = true
                } else {
                    cartItem.actualPrice = priceValue
                    cartItem.actualQuantity = portionValue
                    cartItem.quantity = portionValue
                    cartItem.syncQuantities(cart: cart)
                    cartItem.wasEditedDuringShopping = true
                }
                
                vaultService.updateCartTotals(cart: cart)
                
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShoppingDataUpdated"),
                    object: nil,
                    userInfo: ["cartItemId": cartItem.itemId]
                )
            }
            
            isSaving = false
            onSave?()
            dismissPopover()
            
        } else {
            // FULFILL MODE - Sophisticated animation sequence
            
            // Update data immediately but DON'T mark as fulfilled yet
            if cartItem.isShoppingOnlyItem {
                cartItem.shoppingOnlyPrice = priceValue
                cartItem.shoppingOnlyUnit = plannedUnit
            }
            
            cartItem.actualPrice = priceValue
            cartItem.actualQuantity = portionValue
            cartItem.quantity = portionValue
            cartItem.syncQuantities(cart: cart)
            cartItem.wasEditedDuringShopping = true
            
            // Start animation sequence - use animationState instead of fulfillmentAnimationState
            cartItem.animationState = .checkmarkAppearing
            cartItem.fulfillmentStartTime = Date()
            cartItem.shouldShowCheckmark = true
            
            // Post notification for animation start
            NotificationCenter.default.post(
                name: NSNotification.Name("ItemFulfillmentAnimationStarted"),
                object: nil,
                userInfo: [
                    "cartId": cart.id,
                    "itemId": cartItem.itemId,
                    "price": priceValue,
                    "quantity": portionValue
                ]
            )
            
            // FASTER ANIMATION SEQUENCE:
                 // 1. Checkmark appears with bounce (0.0-0.3s)
                 // 2. Strikethrough starts IMMEDIATELY (no wait)
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                     cartItem.animationState = .strikethroughAnimating
                     cartItem.shouldStrikethrough = true
                     
                     NotificationCenter.default.post(
                         name: NSNotification.Name("ItemStrikethroughAnimating"),
                         object: nil,
                         userInfo: ["cartId": cart.id, "itemId": cartItem.itemId]
                     )
                     
                     // 3. Start removal animation after strikethrough is partially done
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        cartItem.animationState = .removalAnimating
                        
                        // Animate the fulfillment state change so the List removes the row smoothly
                        withAnimation(.easeInOut(duration: 0.3)) {
                            cartItem.isFulfilled = true
                        }
                        
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ItemRemovalAnimating"),
                            object: nil,
                            userInfo: ["cartId": cart.id, "itemId": cartItem.itemId]
                        )
                        
                        // 4. Cleanup after removal
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                             cartItem.animationState = .none
                             cartItem.shouldShowCheckmark = false
                             cartItem.shouldStrikethrough = false
                             cartItem.fulfillmentStartTime = nil
                             
                             vaultService.updateCartTotals(cart: cart)
                             
                             NotificationCenter.default.post(
                                 name: NSNotification.Name("ShoppingDataUpdated"),
                                 object: nil,
                                 userInfo: ["cartItemId": cartItem.itemId]
                             )
                         }
                     }
                 }
            
            // Close popover immediately (animation continues in background)
            isSaving = false
            onSave?()
            dismissPopover()
        }
    }
    
    private func dismissPopover() {
        focusedField = nil
        isPresented = false
        onDismiss?()
    }
}


private struct ActionButtons: View {
    let mode: PopoverMode
    let hasChanges: Bool
    let isFormValid: Bool
    let isSaving: Bool
    let saveChanges: () -> Void
    let dismissPopover: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            // Primary button
            FormCompletionButton(
                title: isSaving ? "Saving..." : mode.buttonTitle,
                isEnabled: shouldEnableButton && !isSaving,
                cornerRadius: 50,
                verticalPadding: 14,
                maxRadius: 1000,
                bounceScale: (0.98, 1.05, 1.0),
                bounceTiming: (0.1, 0.3, 0.3),
                maxWidth: true,
                action: saveChanges
            )
            .frame(maxWidth: .infinity)
            
            // Cancel button
            Button(action: dismissPopover) {
                HStack {
                    Spacer()
                    Text("Cancel")
                        .fuzzyBubblesFont(16, weight: .bold)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .overlay(
                            Capsule()
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private var shouldEnableButton: Bool {
        switch mode {
        case .edit:
            return hasChanges && isFormValid
        case .fulfill:
            return isFormValid // In fulfill mode, always allow confirmation even without changes
        }
    }
}


private struct ErrorMessageDisplay: View {
    let errorMessage: String
    
    var body: some View {
        Text(errorMessage)
            .lexendFont(11)
            .foregroundColor(.red)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
            .cornerRadius(8)
    }
}

private struct ItemDescriptionText: View {
    let itemName: String
    let categoryEmoji: String
    let storeName: String
    let livePrice: Double
    let plannedPrice: Double
    let plannedUnit: String
    let isShoppingOnlyItem: Bool
    
    // Computed properties for delta
    private var livePriceDelta: Double {
        livePrice - plannedPrice
    }
    
    private var showLivePriceDelta: Bool {
        let enteredPrice = livePrice
        return !isShoppingOnlyItem && enteredPrice > 0 && abs(livePriceDelta) > 0.01
    }
    
    private var livePriceDeltaColor: Color {
        if livePriceDelta > 0 {
            return Color(hex: "FA003F")
        } else if livePriceDelta < 0 {
            return .green
        } else {
            return .gray
        }
    }
    
    private var deltaAmountText: String {
        let delta = abs(livePriceDelta)
        let symbol = CurrencyManager.shared.selectedCurrency.symbol
        return String(format: "\(symbol)%.2f", delta)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            // Combined line 1 & 2: You're buying [item] [emoji], from 🧺 [store]
            combinedLine1And2
            
            // Line 3: at ₱[price] per [unit] with delta
            line3WithDelta
        }
        .lineSpacing(4.5)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .padding(.bottom)
    }
    
    // MARK: - Line Components
    
    private var combinedLine1And2: some View {
        HStack(spacing: 0) {
            Text("You're buying  ")
                .foregroundColor(.secondary)
                .lexendFont(18)
            +
            Text(itemName)
                .foregroundColor(.primary)
                .lexendFont(18, weight: .semibold)
            +
            Text(" \(categoryEmoji),  from  ")
                .foregroundColor(.secondary)
                .lexendFont(18)
            +
            Text("\(storeName)  🧺")
                .foregroundColor(.primary)
                .lexendFont(18, weight: .semibold)
        }
    }
    
    private var line3WithDelta: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("at")
                .foregroundColor(.secondary)
                .lexendFont(18)
            
            // Price
            Text(CurrencyManager.shared.selectedCurrency.symbol)
                .foregroundColor(.primary)
                .lexendFont(18, weight: .semibold)
                .contentTransition(.numericText())
                .animation(.snappy, value: CurrencyManager.shared.selectedCurrency.symbol)
            
            animatedPriceText
            
            Text("per \(plannedUnit)")
                .foregroundColor(.primary)
                .lexendFont(18, weight: .semibold)
            
            // Superscript delta after "per unit"
            if showLivePriceDelta {
                superscriptDelta
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.8, anchor: .leading)
                                .combined(with: .opacity)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)),
                            removal: .scale(scale: 0.8, anchor: .leading)
                                .combined(with: .opacity)
                                .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1))
                        )
                    )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showLivePriceDelta)
    }
    
    private var animatedPriceText: some View {
        Text(livePrice, format: .number.precision(.fractionLength(2)))
            .lexendFont(18, weight: .semibold)
            .foregroundColor(.primary)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: livePrice)
    }
    
    private var superscriptDelta: some View {
        HStack(spacing: 0) {
            let arrow = livePriceDelta > 0 ? "↑" : "↓"
            Text(arrow)
                .foregroundColor(livePriceDeltaColor)
                .lexendFont(12, weight: .bold)
                .transition(.scale.combined(with: .opacity))
            
            Text(deltaAmountText)
                .foregroundColor(livePriceDeltaColor)
                .lexendFont(10, weight: .semibold)
                .baselineOffset(4) // Superscript effect
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: deltaAmountText)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: livePriceDelta)
    }
}


private struct PriceField: View {
    @Binding var price: String
    @FocusState.Binding var focusedField: UnifiedItemPopover.Field?
    let plannedUnit: String
    @Binding var errorMessage: String?
    let plannedPrice: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Text(CurrencyManager.shared.selectedCurrency.symbol)
                .lexendFont(14, weight: .semibold)
                .foregroundColor(.secondary)
                .contentTransition(.numericText())
                .animation(.snappy, value: CurrencyManager.shared.selectedCurrency.symbol)
            
            TextField("0.00", text: $price)
                .numbersOnly($price, includeDecimal: true)
                .focused($focusedField, equals: .price)
                .lexendFont(14, weight: .semibold)
                .foregroundColor(.primary)
                .onChange(of: price) { oldValue, newValue in
                    // Clear error when user types
                    errorMessage = nil
                    
                    // Optional: Haptic feedback for price crossing
                    let oldPrice = Double(oldValue) ?? plannedPrice
                    let newPrice = Double(newValue) ?? plannedPrice
                    
                    // Check if price crossed the planned price threshold
                    if (oldPrice <= plannedPrice && newPrice > plannedPrice) ||
                       (oldPrice >= plannedPrice && newPrice < plannedPrice) {
                        HapticManager.shared.playMedium()
                    }
                }
            
            Text("/ \(plannedUnit)")
                .lexendFont(12)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}

private struct PortionField: View {
    @Binding var portion: String
    @FocusState.Binding var focusedField: UnifiedItemPopover.Field?
    let plannedUnit: String
    @Binding var errorMessage: String?
    
    var body: some View {
        HStack {
            TextField("0", text: $portion)
                .numbersOnly($portion, includeDecimal: true)
                .focused($focusedField, equals: .portion)
                .lexendFont(14, weight: .semibold)
                .onChange(of: portion) { _, _ in
                    // Clear error when user types
                    errorMessage = nil
                }
            
            Spacer()
            
            Text(plannedUnit)
                .lexendFont(12)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
