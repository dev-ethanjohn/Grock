import SwiftUI
import Lottie
import SwiftData

struct ShoppingProgressSummary: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    
    @State private var showCompletedItemsSheet = false
    
    // Total items includes ALL active items (vault items + shopping-only items with quantity > 0)
    private var totalItems: Int {
        // Count vault items + active shopping-only items
        let vaultItemsCount = cart.cartItems.filter { !$0.isShoppingOnlyItem }.count
        let activeShoppingItemsCount = cart.cartItems.filter {
            $0.isShoppingOnlyItem && $0.quantity > 0
        }.count
        
        return vaultItemsCount + activeShoppingItemsCount
    }

    private var skippedItems: Int {
        cart.cartItems.filter {
            !$0.isShoppingOnlyItem &&
            $0.isSkippedDuringShopping
        }.count
    }
    
    private var fulfilledItems: Int {
        cart.cartItems.filter { $0.isFulfilled && !$0.isShoppingOnlyItem }.count
    }
    
    private var fulfilledItemsTotal: String {
        let fulfilledTotal = cart.cartItems
            .filter { $0.isFulfilled }
            .reduce(0.0) { total, cartItem in
                if cartItem.isShoppingOnlyItem {
                    return total + (cartItem.shoppingOnlyPrice ?? 0)
                } else {
                    let actualPrice = cartItem.actualPrice ?? 0
                    return total + actualPrice
                }
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
        return formatter.string(from: NSNumber(value: amount)) ?? "\(locale.currencySymbol ?? "$")\(String(format: "%.2f", amount))"
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
    @State private var isAnimating = false
    @State private var underlineWidth: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                        .opacity(index < revealedCharacters ? 1 : 0)
                        .offset(y: index < revealedCharacters ? 0 : 4)
                        .animation(
                            .interpolatingSpring(
                                stiffness: 240,
                                damping: 14
                            )
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
            .onAppear {
                // Ensure all characters are revealed after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + delay + (Double(text.count) * 0.01) + 0.5) {
                    revealedCharacters = text.count
                }
            }
            
            Rectangle()
                .fill(Color(hex: "717171"))
                .frame(width: underlineWidth, height: 1)
                .offset(y: -0.5)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(
                    .easeOut(duration: 0.32)
                ) {
                    revealedCharacters = text.count
                }
                
                withAnimation(
                    .easeOut(duration: Double(text.count) * 0.01 + 0.32)
                ) {
                    underlineWidth = textWidth
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.25) {
                withAnimation(
                    .spring(
                        response: 0.2,
                        dampingFraction: 0.8,
                        blendDuration: 0.1
                    )
                ) {
                    isAnimating = true
                }
            }
        }
        .scaleEffect(isAnimating ? 1.007 : 1.0)
        .animation(
            .easeInOut(duration: 0.15)
            .repeatCount(1, autoreverses: true)
            .delay(delay + 0.5),
            value: isAnimating
        )
    }
}
