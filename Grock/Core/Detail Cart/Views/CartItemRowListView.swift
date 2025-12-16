import SwiftUI
import SwiftData

struct CartItemRowListView: View {
    @Bindable var cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onToggleFulfillment: () -> Void
    let onEditItem: () -> Void
    let onDeleteItem: () -> Void
    let isLastItem: Bool
    
    @State private var refreshID = UUID()
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var isNewlyAdded: Bool = true
    @State private var buttonScale: CGFloat = 0.1
    @State private var buttonVisible: Bool = false
    @State private var slideOffset: CGFloat = 0
    
    // Add refresh states
    @State private var refreshTrigger = UUID()
    @State private var displayPrice: Double = 0
    @State private var displayUnit: String = ""
    @State private var displayQuantity: Double = 0
    @State private var displayTotalPrice: Double = 0
    
    private var itemName: String {
        item?.name ?? "Unknown Item"
    }
    
    private var price: Double {
        guard let vault = vaultService.vault else { return 0.0 }
        let price = cartItem.getPrice(from: vault, cart: cart)
        return price
    }
    
    private var unit: String {
        guard let vault = vaultService.vault else { return "" }
        return cartItem.getUnit(from: vault, cart: cart)
    }
    
    private var quantity: Double {
        return cartItem.getQuantity(cart: cart)
    }
    
    private var totalPrice: Double {
        guard let vault = vaultService.vault else { return 0.0 }
        return cartItem.getTotalPrice(from: vault, cart: cart)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: cart.isShopping ? 8 : 0) {
            if cart.isShopping {
                Button(action: {
                    // Trigger slide out animation
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        slideOffset = -UIScreen.main.bounds.width
                    }
                    
                    // Wait for animation to complete, then trigger fulfillment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onToggleFulfillment()
                    }
                }) {
                    Image(systemName: cartItem.isFulfilled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundColor(cartItem.isFulfilled ? .green : Color(hex: "999"))
                        .scaleEffect(buttonScale)
                }
                .buttonStyle(.plain)
                .frame(width: 20, height: 20)
                .padding(.top, 2)
                // FIXED: Animate opacity smoothly
                .opacity(buttonVisible ? 1 : 0)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(quantityString) \(itemName)")
                    .lexendFont(17, weight: .regular)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .strikethrough(cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping))
                
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
                .opacity(cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping) ? 0.5 : 1.0)
            }
            .opacity(cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping) ? 0.5 : 1.0)
        }
        .offset(x: slideOffset)
        .opacity(slideOffset != 0 ? 0 : 1)
        // FIXED: Apply spring animation for the entire HStack spacing change
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cart.isShopping)
        .padding(.vertical, 12)
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .background(Color(hex: "F7F2ED").darker(by: 0.02))
        .contentShape(Rectangle())
        .onTapGesture {
            onEditItem()
        }
        .onChange(of: cart.isShopping) { oldValue, newValue in
            guard oldValue != newValue else { return }
            
            if newValue {
                // FIXED: Animate both button visibility and scale together
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    buttonVisible = true
                    buttonScale = 1.0
                }
            } else {
                // FIXED: Animate button hiding
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    buttonScale = 0.1
                }
                // Delay hiding the button until scale animation is done
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        buttonVisible = false
                    }
                }
            }
        }
        .onAppear {
            // Set initial state
            buttonVisible = cart.isShopping
            buttonScale = cart.isShopping ? 1.0 : 0.1
            
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
            slideOffset = 0
        }
        .onChange(of: cart.status) { oldValue, newValue in
            updateDisplayValues()
        }
        .id(refreshID)
    }
    
    private func updateDisplayValues() {
        guard let vault = vaultService.vault else { return }
        
        displayPrice = cartItem.getPrice(from: vault, cart: cart)
        displayUnit = cartItem.getUnit(from: vault, cart: cart)
        displayQuantity = cartItem.getQuantity(cart: cart)
        displayTotalPrice = cartItem.getTotalPrice(from: vault, cart: cart)
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
