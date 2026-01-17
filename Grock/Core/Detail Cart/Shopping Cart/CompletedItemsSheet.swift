import SwiftUI
import SwiftData
import Lottie

struct CompletedItemsSheet: View {
    let cart: Cart
    let onUnfulfillItem: (CartItem) -> Void
    
    @Environment(VaultService.self) private var vaultService
    @State private var refreshKey = UUID()
    
    @State private var showSkippedItems = false
    
    private var completedItems: [(cartItem: CartItem, item: Item?)] {
        cart.cartItems.filter {
            $0.isFulfilled && !$0.isSkippedDuringShopping
        }.map { c in
            (c, vaultService.findItemById(c.itemId))
        }
    }

    private var skippedItems: [(cartItem: CartItem, item: Item?)] {
        cart.cartItems.filter {
            !$0.isShoppingOnlyItem && // Only vault items
            $0.isSkippedDuringShopping
        }.map { c in
            (c, vaultService.findItemById(c.itemId))
        }
    }
    private var fulfilledCount: Int {
        cart.cartItems.filter {
            $0.isFulfilled && !$0.isSkippedDuringShopping
        }.count
    }
    
    private var skippedCount: Int {
        cart.cartItems.filter { $0.isSkippedDuringShopping }.count
    }
    
    private var totalItemCount: Int {
        cart.cartItems.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CompletedHeader(
                fulfilledCount: fulfilledCount,
                skippedCount: skippedCount,
                cart: cart,
                completedItems: completedItems,
                skippedItems: skippedItems
            )
            .padding(.bottom, 24)
            
            CompletedItemsList(
                cart: cart,
                completedItems: completedItems,
                skippedItems: skippedItems,
                showSkippedItems: $showSkippedItems,
                onUnfulfillItem: onUnfulfillItem
            )
        }
        .padding()
        .id(refreshKey)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CartItemFulfillmentToggled"))) { notification in
            guard let userInfo = notification.userInfo,
                  let cartId = userInfo["cartId"] as? String,
                  cartId == cart.id else { return }
            refreshKey = UUID()
        }
    }
}

private struct CompletedHeader: View {
    let fulfilledCount: Int
    let skippedCount: Int
    let cart: Cart
    let completedItems: [(cartItem: CartItem, item: Item?)]
    let skippedItems: [(cartItem: CartItem, item: Item?)]
    
    // Calculate denominator (total items that can be fulfilled)
    private var totalFulfillableItems: Int {
        cart.cartItems.count - skippedCount
    }
    
    private var totalAmount: Double {
        let completedTotal = completedItems.reduce(0) { sum, tuple in
            let cartItem = tuple.cartItem
            let price = cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
            let quantity = cartItem.actualQuantity ?? cartItem.quantity
            return sum + (price * quantity)
        }
        
        return completedTotal
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 16)
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    if fulfilledCount > 0 {
                        Text("Fulfilled total so far:")
                            .lexendFont(16)
                            .foregroundStyle(.black)
                        
                        + Text(" \(totalAmount.formattedCurrency)")
                            .lexendFont(16)
                            .foregroundStyle(.black.opacity(0.6))
                    } else if skippedCount > 0 {
                        Text("\(skippedCount) skipped item\(skippedCount == 1 ? "" : "s")")
                            .lexendFont(16)
                            .foregroundStyle(.orange.opacity(0.8))
                    } else {
                        
                        Text("No fulfilled items yet")
                            .lexendFont(16)
                            .foregroundStyle(.black)
                    }
                }
            }
        }
    }
}

private struct CompletedItemsList: View {
    let cart: Cart
    let completedItems: [(cartItem: CartItem, item: Item?)]
    let skippedItems: [(cartItem: CartItem, item: Item?)]
    @Binding var showSkippedItems: Bool
    let onUnfulfillItem: (CartItem) -> Void
    
    var body: some View {
        ScrollView {
            if completedItems.isEmpty && skippedItems.isEmpty {
                EmptyStateView()
            } else {
                LazyVStack(spacing: 0) {
                    // Show completed items first
                    if !completedItems.isEmpty {
                        ForEach(Array(completedItems.enumerated()), id: \.offset) { index, tuple in
                            CompletedItemRow(
                                cartItem: tuple.cartItem,
                                item: tuple.item,
                                isSkipped: false,
                                onAction: { onUnfulfillItem(tuple.cartItem) }
                            )
                            .id("completed-\(tuple.cartItem.itemId)-\(index)")
                            
                            if index < completedItems.count - 1 || !skippedItems.isEmpty {
                                DashedLine()
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                                    .frame(height: 0.5)
                                    .foregroundColor(Color(hex: "999").opacity(0.5))
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                    
                    // Show skipped items in accordion
                    if !skippedItems.isEmpty {
                        VStack(spacing: 0) {
                            // Accordion header for skipped items
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showSkippedItems.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Spacer()
                                    
                                    Text("(\(skippedItems.count))")
                                        .lexendFont(13)
                                    
                                    Text("Skipped Items")
                                        .lexendFont(13)
        
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .medium))
                                        .rotationEffect(.degrees(showSkippedItems ? 90 : 0))
                                    
                                    Spacer()
                                }
                                .foregroundColor(.gray)
                                .padding(.vertical)
                                .padding(.trailing)
                                .padding(.leading, 4)
                                .frame(maxWidth: .infinity)
                                .contentShape(Rectangle())
                                .background(!showSkippedItems ? Color(hex: "F9F9F9") : Color.clear)
                            }
                            .buttonStyle(.plain)
                            .id("skipped-header-\(cart.id)")
                            
                            // Skipped items (collapsible)
                            if showSkippedItems {
                                VStack(spacing: 0) {
                                    ForEach(Array(skippedItems.enumerated()), id: \.offset) { index, tuple in
                                        CompletedItemRow(
                                            cartItem: tuple.cartItem,
                                            item: tuple.item,
                                            isSkipped: true,
                                            onAction: { onUnfulfillItem(tuple.cartItem) }
                                        )
                                        .id("skipped-\(tuple.cartItem.itemId)-\(index)")
                                        
                                        if index < skippedItems.count - 1 {
                                            DashedLine()
                                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                                                .frame(height: 0.5)
                                                .foregroundColor(Color(hex: "999").opacity(0.5))
                                                .padding(.horizontal, 12)
                                        }
                                    }
                                }
                                .offset(y: showSkippedItems ? 0 : -10)
                                .opacity(showSkippedItems ? 1 : 0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showSkippedItems)
                            }
                        }
                        .background(showSkippedItems ? Color(hex: "F9F9F9") : Color.clear)
                        .clipped()
                    }
                }
            }
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            LottieView(animation: .named("Empty"))
                .playing(.fromProgress(0, toProgress: 0.5, loopMode: .loop))
                .allowsHitTesting(false)
                .frame(height: 140)
                .frame(width: 140)
                .rotationEffect(.degrees(0))
            
            Text("Start by fulfilling items or continue your shopping")
                .lexendFont(14)
                .foregroundColor(Color(hex: "777"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .offset(y: -40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

private struct CompletedItemRow: View {
    let cartItem: CartItem
    let item: Item?
    let isSkipped: Bool
    let onAction: () -> Void
    
    private var itemName: String {
        item?.name ?? "Unknown Item"
    }
    
    private var price: Double {
        cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
    }
    
    private var unit: String {
        cartItem.actualUnit ?? cartItem.plannedUnit ?? "ea"
    }
    
    private var quantity: Double {
        cartItem.actualQuantity ?? cartItem.quantity
    }
    
    private var totalPrice: Double {
        price * quantity
    }
    
    var body: some View {
        if isSkipped {
            Text("Unskip \(itemName) item")
                .lexendFont(15, weight: .medium)
                .foregroundColor(Color(hex: "333333"))
                .underline()
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
                .onTapGesture(perform: onAction)
                .padding(.bottom, 4)
                .padding(.horizontal)
                .padding(.vertical)
                .background(Color(hex: "F9F9F9"))
                .transition(.opacity)
        } else {
            HStack(alignment: .top, spacing: 8) {
                Button(action: onAction) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(quantity, specifier: "%g") \(unit) \(itemName)")
                            .lexendFont(16, weight: .regular)
                            .foregroundColor(.black)
                            .contentTransition(.numericText())
                    }
                    
                    HStack(spacing: 0) {
                        Text("\(CurrencyManager.shared.selectedCurrency.symbol)\(price, specifier: "%g")")
                            .foregroundColor(.gray)
                            .contentTransition(.numericText())
                        
                        Text("/\(unit)")
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(totalPrice.formattedCurrency)
                            .lexendFont(13, weight: .semibold)
                            .foregroundColor(Color(hex: "231F30"))
                            .contentTransition(.numericText())
                    }
                    .lexendFont(12)
                }
                
                Spacer()
            }
            .padding(.bottom, 4)
            .padding(.horizontal, 0)
            .padding(.vertical, 8)
            .background(.white)
            .transition(.opacity)
        }
    }
}
