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
            !$0.isShoppingOnlyItem && 
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
                if fulfilledCount > 0 {
                    HStack(spacing: 6) {
                        Text("Fulfilled total so far:")
                            .fuzzyBubblesFont(16, weight: .bold)
                            .foregroundStyle(Color(hex: "666666"))
                        
                        Text(totalAmount.formattedCurrency)
                            .fuzzyBubblesFont(20, weight: .bold)
                            .foregroundStyle(.black)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(12)
                } else if skippedCount > 0 {
                    Text("\(skippedCount) skipped item\(skippedCount == 1 ? "" : "s")")
                        .fuzzyBubblesFont(18, weight: .bold)
                        .foregroundStyle(.orange)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                } else {
                    Text("No fulfilled items yet")
                        .fuzzyBubblesFont(16, weight: .bold)
                        .foregroundStyle(Color(hex: "999999"))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "F5F5F5"))
                        .cornerRadius(12)
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
                                showDivider: index < completedItems.count - 1,
                                onAction: { onUnfulfillItem(tuple.cartItem) }
                            )
                            .id("completed-\(tuple.cartItem.itemId)-\(index)")
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
                                    
                                    Text(skippedItems.count == 1 ? "Skipped Item" : "Skipped Items")
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
                            }
                            .buttonStyle(.plain)
                            .background(Color(hex: "F9F9F9"))
                            .id("skipped-header-\(cart.id)")
                            .zIndex(1)
                            
                            // Skipped items (collapsible)
                            if showSkippedItems {
                                VStack(spacing: 0) {
                                    ForEach(Array(skippedItems.enumerated()), id: \.offset) { index, tuple in
                                        CompletedItemRow(
                                            cartItem: tuple.cartItem,
                                            item: tuple.item,
                                            isSkipped: true,
                                            showDivider: index < skippedItems.count - 1,
                                            onAction: { onUnfulfillItem(tuple.cartItem) }
                                        )
                                        .id("skipped-\(tuple.cartItem.itemId)-\(index)")
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .background(Color(hex: "F9F9F9"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .padding(1)
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
    var showDivider: Bool = false
    let onAction: () -> Void
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartStateManager.self) private var stateManager
    
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
            VStack(spacing: 0) {
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
                
                if showDivider {
                    DashedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                        .frame(height: 0.5)
                        .foregroundColor(Color(hex: "999").opacity(0.5))
                        .padding(.horizontal, 12)
                }
            }
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
                        
                        if cartItem.isShoppingOnlyItem {
                            Text("new")
                                .lexendFont(11, weight: .semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.cartNewDeep)
                                .cornerRadius(10)
                        } else if cartItem.addedDuringShopping {
                            Text("added")
                                .lexendFont(11, weight: .semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.cartAddedDeep)
                                .cornerRadius(10)
                        }
                        
                        if stateManager.showCategoryIcons {
                            if let item = item,
                               let category = vaultService.getCategory(for: item.id),
                               let groceryCat = GroceryCategory.allCases.first(where: { $0.title == category.name }) {
                                Text(groceryCat.emoji)
                                    .font(.caption)
                            } else if cartItem.isShoppingOnlyItem,
                                      let raw = cartItem.shoppingOnlyCategory,
                                      let cat = GroceryCategory(rawValue: raw) {
                                Text(cat.emoji)
                                    .font(.caption)
                            }
                        }
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
                    
                    if showDivider {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 0.5)
                            .foregroundColor(Color(hex: "999").opacity(0.5))
                            .padding(.top, 12)
                    }
                }
                
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
            .padding(.vertical, 8)
            .transition(.opacity)
        }
    }
}
