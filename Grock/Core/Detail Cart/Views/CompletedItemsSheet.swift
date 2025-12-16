import SwiftUI
import SwiftData

struct CompletedItemsSheet: View {
    let cart: Cart
    let onUnfulfillItem: (CartItem) -> Void
    
    @Environment(VaultService.self) private var vaultService
    
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
            
            CompletedItemsList(
                cart: cart,
                completedItems: completedItems,
                skippedItems: skippedItems,
                showSkippedItems: $showSkippedItems,
                onUnfulfillItem: onUnfulfillItem
            )
        }
        .padding()
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
                .frame(height: 24)
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("\(fulfilledCount)/\(totalFulfillableItems)")
                        .fuzzyBubblesFont(16, weight: .bold)
                        .contentTransition(.numericText())
                        .foregroundStyle(.primary)
                    
                    Text("items fulfilled")
                        .lexendFont(16)
                        .foregroundStyle(.black.opacity(0.6))
                }
                
                if skippedCount > 0 {
                    Text("+ \(skippedCount) skipped for this trip")
                        .lexendFont(14)
                        .foregroundStyle(.orange)
                }
                
                HStack(spacing: 8) {
                    Text("Total spent:")
                        .lexendFont(16)
                        .foregroundStyle(.black.opacity(0.6))
                    
                    Text(totalAmount.formattedCurrency)
                        .fuzzyBubblesFont(16, weight: .bold)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
                .padding(.top, 4)
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
                            SimpleCompletedItemRow(
                                cartItem: tuple.cartItem,
                                item: tuple.item,
                                cart: cart,
                                isSkipped: false,
                                onUnfulfill: { onUnfulfillItem(tuple.cartItem) }
                            )
                            .id("completed-\(tuple.cartItem.itemId)-\(index)")
                            
                            if index < completedItems.count - 1 || !skippedItems.isEmpty {
                                Divider()
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // Show skipped items in accordion
                    if !skippedItems.isEmpty {
                        // Accordion header for skipped items
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showSkippedItems.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: showSkippedItems ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                                
                                Text("\(skippedItems.count) skipped for this trip")
                                    .lexendFont(14, weight: .medium)
                                    .foregroundColor(.orange)
                                
                                Spacer()
                                
                                Text("Tap to \(showSkippedItems ? "hide" : "show")")
                                    .lexendFont(12)
                                    .foregroundColor(.orange.opacity(0.7))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id("skipped-header-\(cart.id)")
                        
                        // Skipped items (collapsible)
                        if showSkippedItems {
                            ForEach(Array(skippedItems.enumerated()), id: \.offset) { index, tuple in
                                SimpleCompletedItemRow(
                                    cartItem: tuple.cartItem,
                                    item: tuple.item,
                                    cart: cart,
                                    isSkipped: true,
                                    onUnfulfill: { onUnfulfillItem(tuple.cartItem) }
                                )
                                .id("skipped-\(tuple.cartItem.itemId)-\(index)")
                                
                                if index < skippedItems.count - 1 {
                                    Divider()
                                        .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: "999"))
            
            Text("No completed items yet")
                .lexendFont(14)
                .foregroundColor(Color(hex: "666"))
            
            Text("Start by fulfilling items or continue your shopping")
                .lexendFont(12)
                .foregroundColor(Color(hex: "999"))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}


private struct SimpleCompletedItemRow: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let isSkipped: Bool
    let onUnfulfill: () -> Void
    
    var body: some View {
        HStack {
            // Status indicator
            if isSkipped {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item?.name ?? "Unknown Item")
                    .lexendFont(16, weight: .medium)
                    .foregroundColor(isSkipped ? Color(hex: "999") : Color(hex: "333"))
                    .strikethrough(isSkipped, color: Color(hex: "999"))
                
                Text("Qty: \(cartItem.quantity, specifier: "%.0f")")
                    .lexendFont(14)
                    .foregroundColor(isSkipped ? Color(hex: "999") : Color(hex: "666"))
            }
            
            Spacer()
            
            // Show price if not skipped (skipped items have 0 value)
            if !isSkipped, let price = cartItem.actualPrice ?? cartItem.plannedPrice {
                Text("\(price.formattedCurrency)")
                    .lexendFont(14, weight: .medium)
                    .foregroundColor(Color(hex: "333"))
            } else if isSkipped {
                Text("Skipped")
                    .lexendFont(12)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Button(action: onUnfulfill) {
                if isSkipped {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
    }
}

//#Preview("Completed Items") {
//    let mockCart = Cart(name: "Preview Cart", budget: 100.0, status: .shopping)
//    
//    // Add some items
//    let item1 = CartItem(
//        itemId: UUID().uuidString,
//        quantity: 2,
//        plannedStore: "Store 1",
//        isFulfilled: true,
//        plannedPrice: 10.0,
//        plannedUnit: "each"
//    )
//    
//    let item2 = CartItem(
//        itemId: UUID().uuidString,
//        quantity: 1,
//        plannedStore: "Store 2",
//        isFulfilled: false,
//        isSkippedDuringShopping: true,
//        plannedPrice: 5.0,
//        plannedUnit: "each"
//    )
//    
//    mockCart.cartItems = [item1, item2]
//    
//    // Create a mock environment - include ALL models
//    let schema = Schema([
//        User.self,
//        Vault.self,
//        Store.self,
//        Category.self,
//        Item.self,
//        PriceOption.self,
//        PricePerUnit.self,
//        Cart.self,
//        CartItem.self
//    ])
//    
//    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
//    let container = try! ModelContainer(for: schema, configurations: [config])
//    let modelContext = ModelContext(container)
//    
//    CompletedItemsSheet(
//        cart: mockCart,
//        onUnfulfillItem: { _ in }
//    )
//    .environment(VaultService(modelContext: modelContext))
//}
