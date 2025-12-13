import SwiftUI
import SwiftData

struct CompletedItemsSheet: View {
    let cart: Cart
    let completedItems: [(cartItem: CartItem, item: Item?)]
    let fulfilledCount: Int
    let onUnfulfillItem: (CartItem) -> Void
    
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        VStack(spacing: 0) {
            CompletedHeader(
                fulfilledCount: fulfilledCount,
                cart: cart,
                completedItems: completedItems
            )
            
            CompletedItemsList(
                cart: cart,
                completedItems: completedItems,
                onUnfulfillItem: onUnfulfillItem
            )
        }
        .padding()
    }
}

private struct CompletedHeader: View {
    let fulfilledCount: Int
    let cart: Cart
    let completedItems: [(cartItem: CartItem, item: Item?)]
    
    private var totalItems: Int {
        cart.cartItems.count
    }
    
    private var totalAmount: Double {
        completedItems.reduce(0) { sum, tuple in
            let cartItem = tuple.cartItem
            let price = cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
            let quantity = cartItem.actualQuantity ?? cartItem.quantity
            return sum + (price * quantity)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 24)
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("\(fulfilledCount)/\(totalItems)")
                        .fuzzyBubblesFont(16, weight: .bold)
                        .contentTransition(.numericText())
                        .foregroundStyle(.primary)
                     Text("  items fulfilled worth  ")
                        .lexendFont(16)
                        .foregroundStyle(.black.opacity(0.6))
                     Text(totalAmount.formattedCurrency)
                        .fuzzyBubblesFont(16, weight: .bold)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                }
            }
        }
    }
}

private struct CompletedItemsList: View {
    let cart: Cart
    let completedItems: [(cartItem: CartItem, item: Item?)]
    let onUnfulfillItem: (CartItem) -> Void
    
    var body: some View {
        ScrollView {
            if completedItems.isEmpty {
                EmptyStateView()
            } else {
                CompletedItemsListView(
                    cart: cart,
                    completedItems: completedItems,
                    onUnfulfillItem: onUnfulfillItem
                )
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

private struct CompletedItemsListView: View {
    let cart: Cart
    let completedItems: [(cartItem: CartItem, item: Item?)]
    let onUnfulfillItem: (CartItem) -> Void
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(completedItems.enumerated()), id: \.element.cartItem.itemId) { index, tuple in
                SimpleCompletedItemRow(
                    cartItem: tuple.cartItem,
                    item: tuple.item,
                    cart: cart,
                    onUnfulfill: { onUnfulfillItem(tuple.cartItem) }
                )
                
                if index < completedItems.count - 1 {
                    Divider()
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

private struct SimpleCompletedItemRow: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onUnfulfill: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item?.name ?? "Unknown Item")
                    .lexendFont(16, weight: .medium)
                    .foregroundColor(Color(hex: "333"))
                
                Text("Qty: \(cartItem.quantity, specifier: "%.0f")")
                    .lexendFont(14)
                    .foregroundColor(Color(hex: "666"))
            }
            
            Spacer()
            
            Button(action: onUnfulfill) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
    }
}

#Preview {
    let schema = Schema([
        User.self,
        Vault.self,
        Store.self,
        Category.self,
        Item.self,
        PriceOption.self,
        PricePerUnit.self,
        Cart.self,
        CartItem.self
    ])
    
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    do {
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let modelContext = ModelContext(container)
        
        let vaultService = VaultService(modelContext: modelContext)
        
        let mockCart = Cart(
            id: "preview-cart",
            name: "Grocery Shopping",
            budget: 200.0,
            status: .shopping
        )
        
        let mockCartItem = CartItem(
            itemId: "product-123",
            quantity: 2,
            plannedStore: "Walmart",
            isFulfilled: true,
            plannedPrice: 0.99,
            plannedUnit: "each"
        )
        
        let mockItem = Item(id: "product-123", name: "Bananas")
        
        modelContext.insert(mockItem)
        
        let mockCompletedItems = [(cartItem: mockCartItem, item: mockItem)]
        
        return CompletedItemsSheet(
            cart: mockCart,
            completedItems: mockCompletedItems,
            fulfilledCount: 20,
            onUnfulfillItem: { _ in }
        )
        .environment(vaultService)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
