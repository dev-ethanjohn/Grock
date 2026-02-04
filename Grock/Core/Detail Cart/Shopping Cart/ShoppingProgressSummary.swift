import SwiftUI
import Lottie
import SwiftData

struct ShoppingProgressSummary: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    
    @State private var showCompletedItemsSheet = false
    
    // Total items includes ALL active items (vault items + shopping-only items with quantity > 0)
    // Total items includes ONLY ACTIVE items (non-skipped, non-deleted)
    private var totalItemsBought: Int {
        cart.cartItems.filter { cartItem in
            // Exclude items that should not be counted:
            // 1. Shopping-only items with quantity <= 0 (effectively deleted/removed)
            // 2. Vault items that are skipped during shopping
            // 3. Vault items with quantity <= 0 (effectively inactive)
            
            if cartItem.isShoppingOnlyItem {
                // Shopping-only items: only count if quantity > 0
                return cartItem.quantity > 0
            } else {
                // Vault items: only count if quantity > 0 AND not skipped
                return cartItem.quantity > 0 && !cartItem.isSkippedDuringShopping
            }
        }.count
    }

    private var skippedItems: Int {
        cart.cartItems.filter { cartItem in
            !cartItem.isShoppingOnlyItem &&           // Only vault items (planned items)
            cartItem.isSkippedDuringShopping &&       // Marked as skipped
            !cartItem.addedDuringShopping             // NOT added during shopping (these should be deleted, not skipped)
        }.count
    }
    
    
    // Fulfilled items: only vault items that are fulfilled
    private var fulfilledItems: Int {
        cart.cartItems.filter { cartItem in
            cartItem.isFulfilled &&
            cartItem.quantity > 0
        }.count
    }
    
    private var fulfilledItemsTotal: String {
        let fulfilledTotal = cart.cartItems
            .filter { cartItem in
                // Only include items that are still in cart (quantity > 0)
                cartItem.quantity > 0 && cartItem.isFulfilled
            }
            .reduce(0.0) { total, cartItem in
                if cartItem.isShoppingOnlyItem {
                    return total + (cartItem.shoppingOnlyPrice ?? 0)
                } else {
                    let actualPrice = cartItem.actualPrice ?? 0
                    return total + actualPrice
                }
            }
        
        return formatCurrency(amount: fulfilledTotal)
    }
    
    private var completedItems: [(cartItem: CartItem, item: Item?)] {
        cart.cartItems.filter {
            $0.isFulfilled && !$0.isSkippedDuringShopping
        }.map { c in
            (c, vaultService.findItemById(c.itemId))
        }
    }
    
    
    private func formatCurrency(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.currencyCode = CurrencyManager.shared.selectedCurrency.code
        formatter.currencySymbol = CurrencyManager.shared.selectedCurrency.symbol
        
        return formatter.string(from: NSNumber(value: amount)) ?? "\(CurrencyManager.shared.selectedCurrency.symbol)\(String(format: "%.2f", amount))"
    }
    
    private var totalAmountSpent: String {
        let completedTotal = completedItems.reduce(0) { sum, tuple in
            let cartItem = tuple.cartItem
            let price = cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
            let quantity = cartItem.actualQuantity ?? cartItem.quantity
            return sum + (price * quantity)
        }
        
        return formatCurrency(amount: completedTotal)
    }
    
    
    @State private var pulseOpacity = 0.0
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            LottieView(animation: .named("Arrow"))
                .playing(.fromProgress(0, toProgress: 0.5, loopMode: .playOnce))
                .scaleEffect(x: -0.8, y: -0.8)
                .allowsHitTesting(false)
                .frame(height: 32)
                .frame(width: 40)
                .rotationEffect(.degrees(210))
                .offset(y: -4)
            
            VStack(alignment: .leading, spacing: 4) {
                CharacterRevealView(
                    text: "\(fulfilledItems)/\(totalItemsBought) items fulfilled, totalling \(totalAmountSpent)",
                    delay: 0.15
                )
                .fuzzyBubblesFont(13, weight: .bold)
                .foregroundColor(Color(hex: "717171"))
                
                // Show skipped items (only vault items)
                if skippedItems > 0 {
                    CharacterRevealView(
                        text: "\(skippedItems) item\(skippedItems == 1 ? "" : "s") skipped ",
                        delay: 0.25
                    )
                    .fuzzyBubblesFont(13, weight: .bold)
                    .foregroundColor(Color(hex: "717171"))
                }
            }
            .padding(.top, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                showCompletedItemsSheet = true
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showCompletedItemsSheet) {
            CompletedItemsSheet(cart: cart) { cartItem in
                onUnfulfillItem(cartItem)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
            .presentationBackground(.white)
        }
    }
    
    private func onUnfulfillItem(_ cartItem: CartItem) {
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
            vaultService.toggleItemFulfillment(cart: cart, itemId: cartItem.itemId)
        }
    }
}

struct CharacterRevealView: View {
    let text: String
    let delay: Double
    var animateOnChange: Bool = false
    var animateOnAppear: Bool = true
    var showsUnderline: Bool = true
    var underlineColor: Color = Color(hex: "717171")
    @State private var revealedCharacters: Int = 0
    @State private var isAnimating = false
    @State private var underlineWidth: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var didAppear = false
    
    private func revealAnimation(for index: Int) -> Animation {
        Animation.interpolatingSpring(stiffness: 240, damping: 14)
            .delay(Double(index) * 0.01 + delay)
    }
    
    var body: some View {
        let characters = Array(text)
        let effectiveRevealedCharacters = animateOnAppear ? revealedCharacters : characters.count
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(characters.indices, id: \.self) { index in
                    Text(String(characters[index]))
                        .opacity(index < effectiveRevealedCharacters ? 1 : 0)
                        .offset(y: index < effectiveRevealedCharacters ? 0 : 4)
                        .animation(
                            revealAnimation(for: index),
                            value: revealedCharacters
                        )
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            textWidth = geometry.size.width
                        }
                        .onChange(of: geometry.size.width) { _, newValue in
                            textWidth = newValue
                        }
                }
            )
            if showsUnderline {
                Rectangle()
                    .fill(underlineColor)
                    .frame(width: underlineWidth, height: 1)
                    .offset(y: -0.5)
            }
        }
        .onAppear {
            guard !didAppear else { return }
            didAppear = true
            
            if !animateOnAppear {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.32)) {
                    revealedCharacters = text.count
                }
                withAnimation(.easeOut(duration: Double(text.count) * 0.01 + 0.32)) {
                    underlineWidth = textWidth
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.25) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.1)) {
                    isAnimating = true
                }
            }
        }
        .onChange(of: text) { _, _ in
            if animateOnChange {
                withAnimation(.easeOut(duration: 0.2)) {
                    revealedCharacters = text.count
                    underlineWidth = textWidth
                }
            } else {
                revealedCharacters = animateOnAppear ? text.count : revealedCharacters
                underlineWidth = animateOnAppear ? textWidth : underlineWidth
                isAnimating = false
            }
        }
//        .scaleEffect(isAnimating ? 1.007 : 1.0)
        .animation(
            .easeInOut(duration: 0.15)
            .repeatCount(1, autoreverses: true)
            .delay(delay + 0.5),
            value: isAnimating
        )
    }
}



struct ReverseCharacterRevealModifier: ViewModifier, Animatable {
    var progress: Double
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    private var safeProgress: Double {
        max(0, min(1, progress))
    }
    
    func body(content: Content) -> some View {
        content
            .mask(
                GeometryReader { geometry in
                    Rectangle()
                        .frame(width: max(0, geometry.size.width * CGFloat(safeProgress)))
                        .frame(maxHeight: .infinity, alignment: .leading)
                }
            )
            .opacity(safeProgress > 0.1 ? 1 : 0)
    }
}
