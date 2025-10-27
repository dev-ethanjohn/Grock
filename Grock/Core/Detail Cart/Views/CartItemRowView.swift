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
            HStack(alignment: .bottom, spacing: 2) {
                if cart.isShopping {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            onToggleFulfillment()
                        }
                    }) {
                        Image(systemName: cartItem.isFulfilled ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundColor(cartItem.isFulfilled ? .green : Color(hex: "999"))
                    }
                    .buttonStyle(.plain)
                    .transition(.scale)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 2.5)
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
                
                Spacer()
                
                Text(formatCurrency(totalPrice))
                    .lexendFont(14, weight: .bold)
                    .foregroundColor(Color(hex: "231F30"))
                    .opacity(cartItem.isFulfilled ? 0.5 : 1.0)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                print("🟠 Tapped item row for: \(itemName)") 
                onEditItem()
            }
            .padding(.top, 12)
            .padding(.bottom, isLastItem ? 0 : 12)
            .padding(.trailing, isInScrollableView ? 0 : 12)
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
        let qty = quantity
        return qty == Double(Int(qty)) ? "\(Int(qty))\(unit)" : String(format: "%.2f\(unit)", qty)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PHP"
        formatter.maximumFractionDigits = value == Double(Int(value)) ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
