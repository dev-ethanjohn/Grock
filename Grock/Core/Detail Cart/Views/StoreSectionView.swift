//
//  StoreSectionView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/22/25.
//
import SwiftUI
import SwiftData

struct StoreSectionView: View {
    let store: String
    let items: [(cartItem: CartItem, item: Item?)]
    let cart: Cart
    let onToggleFulfillment: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
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
                    .symbolRenderingMode(.monochrome)
                    .foregroundColor(.white)
                
                Text(store)
                    .lexendFont(11, weight: .bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black)
            .cornerRadius(6)
            
            LazyVStack(spacing: 0) {
                ForEach(items, id: \.cartItem.itemId) { tuple in
                    CartItemRowView(
                        cartItem: tuple.cartItem,
                        item: tuple.item,
                        cart: cart,
                        onToggleFulfillment: { onToggleFulfillment(tuple.cartItem) },
                        onEditItem: { onEditItem(tuple.cartItem) },
                        isLastItem: tuple.cartItem.itemId == items.last?.cartItem.itemId,
                        isInScrollableView: isInScrollableView
                    )
                }
            }
        }
        .padding(.bottom, isLastStore ? 0 : 8)
    }
}
