import SwiftUI
import SwiftData

struct StoreSectionListView: View {
    let store: String
    let items: [(cartItem: CartItem, item: Item?)]
    let cart: Cart
    let onToggleFulfillment: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    let isLastStore: Bool
    
    private var unfulfilledItems: [(cartItem: CartItem, item: Item?)] {
        items.filter { !$0.cartItem.isFulfilled }
    }
    
    private var itemsWithStableIdentifiers: [(id: String, cartItem: CartItem, item: Item?)] {
        unfulfilledItems.map { ($0.cartItem.itemId, $0.cartItem, $0.item) }
    }
    
    var body: some View {
        Section(
            header: VStack(spacing: 0) {
                HStack {
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
                    Spacer()
                }
                .padding(.leading)
            }
            .listRowInsets(EdgeInsets())
            .textCase(nil)
            
        ) {
            ForEach(Array(itemsWithStableIdentifiers.enumerated()), id: \.element.id) { index, tuple in
                VStack(spacing: 0) {
                    CartItemRowListView(
                        cartItem: tuple.cartItem,
                        item: tuple.item,
                        cart: cart,
                        onToggleFulfillment: { onToggleFulfillment(tuple.cartItem) },
                        onEditItem: { onEditItem(tuple.cartItem) },
                        onDeleteItem: { onDeleteItem(tuple.cartItem) },
                        isLastItem: index == itemsWithStableIdentifiers.count - 1
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .background(Color(hex: "F7F2ED"))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDeleteItem(tuple.cartItem)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            onEditItem(tuple.cartItem)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        if cart.isShopping {
                            Button {
                                onToggleFulfillment(tuple.cartItem)
                            } label: {
                                Label(
                                    tuple.cartItem.isFulfilled ? "Mark Unfulfilled" : "Mark Fulfilled",
                                    systemImage: tuple.cartItem.isFulfilled ? "circle" : "checkmark.circle.fill"
                                )
                            }
                            .tint(tuple.cartItem.isFulfilled ? .orange : .green)
                        }
                    }
                    
                    if index < itemsWithStableIdentifiers.count - 1 {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 0.5)
                            .foregroundColor(Color(hex: "999").opacity(0.5))
                            .padding(.horizontal, 12)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color(hex: "F7F2ED"))
            }
        }
        .listSectionSpacing(isLastStore ? 0 : 20)
    }
}

struct CompletedItemRow: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onUnfulfill: () -> Void
    
    @Environment(VaultService.self) private var vaultService
    
    private var displayPrice: Double {
        if cart.isShopping {
            return (cartItem.actualPrice ?? cartItem.plannedPrice) ?? 0
        }
        return cartItem.plannedPrice ?? 0
    }
    
    private var displayQuantity: Double {
        if cart.isShopping {
            return cartItem.actualQuantity ?? cartItem.quantity
        }
        return cartItem.quantity
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            
            Button(action: onUnfulfill) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item?.name ?? "Unknown Item")
                    .lexendFont(15, weight: .medium)
                    .foregroundColor(Color(hex: "333"))
                    .strikethrough(true, color: Color(hex: "999"))
                
                HStack(spacing: 8) {
                    Text("\(displayQuantity.formatQuantity()) × \(displayPrice.formattedCurrency)")
                        .lexendFont(13)
                        .foregroundColor(Color(hex: "666"))
                    
//                    if let storeName = item?.store {
//                        Text("• \(storeName)")
//                            .lexendFont(12)
//                            .foregroundColor(Color(hex: "999"))
//                    }
                }
            }
            
            Spacer()
            
            Text((displayPrice * displayQuantity).formattedCurrency)
                .lexendFont(15, weight: .bold)
                .foregroundColor(Color(hex: "333"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.5))
    }
}
extension Double {
    func formatQuantity() -> String {
        self == floor(self) ? String(Int(self)) : String(self)
    }
}


