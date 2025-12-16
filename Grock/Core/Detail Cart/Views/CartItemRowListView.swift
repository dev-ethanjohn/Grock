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
    @State private var isBeingRemoved: Bool = false
    @State private var slideOffset: CGFloat = 0
    
    // NEW: State for fulfillment animation
    @State private var isFulfilling: Bool = false
    @State private var iconScale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0.1
    @State private var rowOpacity: Double = 1.0
    
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
                    guard !isFulfilling else { return }
                    
                    isFulfilling = true
                    
                    // 1. Animate icon bouncing
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        iconScale = 1.3
                    }
                    
                    // 2. Show checkmark with delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            checkmarkScale = 1.0
                        }
                    }
                    
                    // 3. Fade out the row
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            rowOpacity = 0
                        }
                    }
                    
                    // 4. After animation completes, trigger fulfillment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onToggleFulfillment()
                        isFulfilling = false
                        iconScale = 1.0
                        checkmarkScale = 0.1
                        rowOpacity = 1.0
                    }
                }) {
                    ZStack {
                        // Circle background
                        if !cartItem.isFulfilled {
                            Circle()
                                .strokeBorder(Color(hex: "999"), lineWidth: 1)
                                .frame(width: 20, height: 20)
                                .scaleEffect(iconScale)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: iconScale)
                        }
                        
                        // Checkmark when fulfilled
                        if cartItem.isFulfilled {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                                .scaleEffect(checkmarkScale)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: checkmarkScale)
                        } else {
                            // Empty circle
                            Image(systemName: "circle")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "999"))
                                .scaleEffect(buttonScale)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: buttonScale)
                        }
                    }
                    .frame(width: 20, height: 20)
                    .padding(.top, 2)
                    .scaleEffect(buttonScale)
                }
                .buttonStyle(.plain)
                .disabled(isFulfilling || cartItem.isFulfilled)
                // FIXED: Remove the opacity animation here
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
        .opacity(rowOpacity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cart.isShopping)
        .padding(.vertical, 12)
        .padding(.leading, cart.isShopping ? 16 : 16)
        .padding(.trailing, 16)
        .background(Color(hex: "F7F2ED").darker(by: 0.02))
        .contentShape(Rectangle())
        .onTapGesture {
            if !isFulfilling {
                onEditItem()
            }
        }
        .onChange(of: cart.isShopping) { oldValue, newValue in
            guard oldValue != newValue else { return }
            
            if newValue {
                // Shopping mode: Scale up from 0.1 to 1.0
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    buttonScale = 1.0
                }
            } else {
                // Planning mode: Scale down from 1.0 to 0.1
                // FIXED: Actually animate the scale down
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    buttonScale = 0.1
                }
                
                // FIXED: Hide the entire icon container after scale animation
                // The button will disappear when cart.isShopping becomes false
                // because of the if statement: `if cart.isShopping { ... }`
            }
        }
        .onAppear {
            // Set initial scale based on cart mode
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
