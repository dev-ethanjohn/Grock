//
//  CartItemRowView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/22/25.

import SwiftUI
import SwiftData

struct CartItemRowView: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onToggleFulfillment: () -> Void
    let onEditItem: () -> Void
    let isLastItem: Bool
    var isInScrollableView: Bool = false
    
    @Environment(VaultService.self) private var vaultService
    
    private var itemName: String {
        item?.name ?? "Unknown Item"
    }
    
    private var price: Double {
        guard let vault = vaultService.vault else { return 0.0 }
        return cartItem.getPrice(from: vault, cart: cart)
    }
    
    private var unit: String {
        guard let vault = vaultService.vault else { return "" }
        return cartItem.getUnit(from: vault, cart: cart)
    }
    
    private var quantity: Double {
        cartItem.getQuantity(cart: cart)
    }
    
    private var totalPrice: Double {
        guard let vault = vaultService.vault else { return 0.0 }
        return cartItem.getTotalPrice(from: vault, cart: cart)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                if cart.isShopping {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            onToggleFulfillment()
                        }
                    }) {
                        Image(systemName: cartItem.isFulfilled ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(cartItem.isFulfilled ? .green : Color(hex: "CCCCCC"))
                            .scaleEffect(cartItem.isFulfilled ? 1.0 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(quantityString) \(itemName)")
                        .lexendFont(17, weight: .regular)
                        .foregroundColor(Color(hex: "231F30"))
                        .lineLimit(1)
                    
                    Text("\(formatCurrency(price)) / \(unit)")
                        .lexendFont(12, weight: .medium)
                        .foregroundColor(Color(hex: "666666"))
                }
                .opacity(cartItem.isFulfilled ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: cartItem.isFulfilled)
                
                Spacer()
                
                Text(formatCurrency(totalPrice))
                    .lexendFont(14, weight: .bold)
                    .foregroundColor(Color(hex: "231F30"))
                    .opacity(cartItem.isFulfilled ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: cartItem.isFulfilled)
            }
            .contentShape(Rectangle())
            .onTapGesture { onEditItem() }
            .padding(.top, 12)
            .padding(.bottom)
//            .padding(.leading, 12)
            .padding(.trailing, isInScrollableView ? 4 : 12)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: cart.isShopping)
            
            if !isLastItem {
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                    .frame(height: 0.5)
                    .foregroundColor(Color(hex: "999").opacity(0.5))
                    .padding(.leading, 12)
                    .padding(.trailing, isInScrollableView ? 4 : 12)
            }
        }
    }
    
    private var quantityString: String {
        let qty = cartItem.getQuantity(cart: cart)
        if qty == Double(Int(qty)) {
            return "\(Int(qty))\(unit)"
        } else {
            return String(format: "%.2f\(unit)", qty)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PHP"
        formatter.maximumFractionDigits = value == Double(Int(value)) ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
