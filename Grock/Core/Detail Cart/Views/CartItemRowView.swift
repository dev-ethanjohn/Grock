import SwiftUI
import SwiftData

struct CartItemRowListView: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onToggleFulfillment: () -> Void
    let onEditItem: () -> Void
    let onDeleteItem: () -> Void
    let isLastItem: Bool
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var isNewlyAdded: Bool = true
    @State private var buttonScale: CGFloat = 0.1
    @State private var buttonVisible: Bool = false
    
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
        HStack(alignment: .top, spacing: cart.isShopping ? 8 : 0) {
            if cart.isShopping {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onToggleFulfillment()
                    }
                }) {
                    Image(systemName: cartItem.isFulfilled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundColor(cartItem.isFulfilled ? .green : Color(hex: "999"))
                        .scaleEffect(buttonScale)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.6)
                                .delay(cartItem.isFulfilled ? 0 : 0.1),
                            value: cartItem.isFulfilled
                        )
                }
                .buttonStyle(.plain)
                .frame(width: 20, height: 20)
                .padding(.top, 2)
                .opacity(buttonVisible ? 1 : 0)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(quantityString) \(itemName)")
                    .lexendFont(17, weight: .regular)
                    .lineLimit(3) 
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 4) {
                    Text("\(formatCurrency(price)) / \(unit)")
                        .lexendFont(12)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(formatCurrency(totalPrice))
                        .lexendFont(14, weight: .bold)
                        .lineLimit(1)
                }
                .foregroundColor(Color(hex: "231F30"))
                .opacity(cartItem.isFulfilled ? 0.5 : 1.0)
            }
            .opacity(cartItem.isFulfilled ? 0.5 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
        .padding(.vertical, 12)
        .padding(.leading, cart.isShopping ? 16 : 16)
        .padding(.trailing, 16)
        .background(Color(hex: "F7F2ED").darker(by: 0.02))
        .contentShape(Rectangle())
        .onTapGesture {
            onEditItem()
        }
        .onChange(of: cart.isShopping) { oldValue, newValue in
            guard oldValue != newValue else { return }
            
            if newValue {
                buttonVisible = true
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 1.0
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    buttonScale = 0.1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    buttonVisible = false
                }
            }
        }
        .task(id: cart.isShopping) {
            buttonVisible = cart.isShopping
            buttonScale = cart.isShopping ? 1.0 : 0.1
        }
        .onAppear {
            if isNewlyAdded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isNewlyAdded = false
                    }
                }
            }
        }
        .onDisappear {
            isNewlyAdded = true
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
