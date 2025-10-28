import SwiftUI
import SwiftData

struct StoreSectionView: View {
    let store: String
    let items: [(cartItem: CartItem, item: Item?)]
    let cart: Cart
    let onToggleFulfillment: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    let isLastStore: Bool
    var isInScrollableView: Bool = false
    
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 2) {
                Image("store")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
                    .foregroundColor(.white)
                
                Text(store)
                    .lexendFont(11, weight: .bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black)
            .cornerRadius(6)
            .padding(.leading, 12)
            
            LazyVStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.cartItem.itemId) { index, tuple in
                    CartItemRowView(
                        cartItem: tuple.cartItem,
                        item: tuple.item,
                        cart: cart,
                        onToggleFulfillment: { onToggleFulfillment(tuple.cartItem) },
                        onEditItem: { onEditItem(tuple.cartItem) },
                        onDelete: { onDeleteItem(tuple.cartItem) },
                        isLastItem: index == items.count - 1,
                        isInScrollableView: isInScrollableView
                    )
                    
                    if index < items.count - 1 {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 0.5)
                            .foregroundColor(Color(hex: "999").opacity(0.5))
                            .padding(.leading, 12)
                            .padding(.trailing, isInScrollableView ? 4 : 12)
                    }
                }
            }
        }
        .padding(.bottom, isLastStore ? 0 : 8)
    }
}
