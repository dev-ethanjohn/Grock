import SwiftUI
import Lottie
import SwiftData

struct ShoppingProgressSummary: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    
    @State private var showCompletedItemsSheet = false
    
    // Total items includes ALL active items (vault items + shopping-only items with quantity > 0)
    // Total items includes ONLY ACTIVE items (non-skipped, non-deleted)
    private var totalItems: Int {
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
            !cartItem.isShoppingOnlyItem &&           // Only vault items
            cartItem.isSkippedDuringShopping &&       // Marked as skipped
            cartItem.quantity > 0 &&                  // Still in cart (quantity > 0)
            !cartItem.addedDuringShopping             // NOT added during shopping (these should be deleted, not skipped)
        }.count
    }
    
    
    private var fulfilledItems: Int {
        cart.cartItems.filter { cartItem in
            // Include ALL items (both vault and shopping-only) that are fulfilled
            cartItem.isFulfilled &&
            cartItem.quantity > 0  // Still in cart
        }.count
    }
     
    
    private var fulfilledItemsTotal: String {
        guard let vault = vaultService.vault else {
            return CurrencyFormatter.shared.format(amount: 0)
        }
        
        let fulfilledTotal = cart.cartItems
            .filter { cartItem in
                cartItem.quantity > 0 && cartItem.isFulfilled
            }
            .reduce(0.0) { total, cartItem in
                total + cartItem.getTotalPrice(from: vault, cart: cart)
            }
        
        return CurrencyFormatter.shared.format(amount: fulfilledTotal)
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
                    text: "\(fulfilledItems)/\(totalItems) items fulfilled, totalling \(fulfilledItemsTotal)",
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
        }
    }
    
    private func onUnfulfillItem(_ cartItem: CartItem) {
        // Your existing logic for unfulfilling items
    }
}

class CurrencyFormatter {
    static let shared = CurrencyFormatter()
    
    private let formatter: NumberFormatter
    
    private init() {
        formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
    }
    
    func format(amount: Double, locale: Locale = .current) -> String {
        formatter.locale = locale
        let symbol = CurrencyManager.shared.selectedCurrency.symbol
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)\(String(format: "%.2f", amount))"
    }
    
    func format(amount: Double, currencyCode: String) -> String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currencyCode]))
        return format(amount: amount, locale: locale)
    }
}

struct CharacterRevealView: View {
    let text: String
    let delay: Double
    @State private var revealedCharacters: Int = 0
    @State private var underlineWidth: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var didInitialReveal = false
    @State private var displayedText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if didInitialReveal {
                // After initial reveal, show text with numeric content transition for smooth number updates
                Text(displayedText)
                    .contentTransition(.numericText())
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    textWidth = geometry.size.width
                                    underlineWidth = geometry.size.width
                                }
                                .onChange(of: geometry.size.width) { _, newWidth in
                                    underlineWidth = newWidth
                                }
                        }
                    )
                
                Rectangle()
                    .fill(Color(hex: "717171"))
                    .frame(width: underlineWidth, height: 1)
                    .offset(y: -0.5)
            } else {
                // Character-by-character reveal animation
                HStack(spacing: 0) {
                    ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                        Text(String(character))
                            .opacity(index < revealedCharacters ? 1 : 0)
                            .offset(y: index < revealedCharacters ? 0 : 4)
                            .animation(
                                .interpolatingSpring(stiffness: 240, damping: 14)
                                    .delay(Double(index) * 0.01 + delay),
                                value: revealedCharacters
                            )
                    }
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.onAppear {
                            textWidth = geometry.size.width
                        }
                    }
                )
                
                Rectangle()
                    .fill(Color(hex: "717171"))
                    .frame(width: underlineWidth, height: 1)
                    .offset(y: -0.5)
            }
        }
        .onAppear {
            displayedText = text
            guard !didInitialReveal else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.32)) {
                    revealedCharacters = text.count
                }
                withAnimation(.easeOut(duration: Double(text.count) * 0.01 + 0.32)) {
                    underlineWidth = textWidth
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + (Double(text.count) * 0.01) + 0.6) {
                didInitialReveal = true
            }
        }
        .onChange(of: text) { _, newValue in
            // Update text without re-running the reveal animation
            displayedText = newValue
        }
    }
}
