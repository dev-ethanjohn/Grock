import SwiftUI
import SwiftData

struct CartItemRowView: View {
    //    MARK: put in a viewmodel + reaarange
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onToggleFulfillment: () -> Void
    let onEditItem: () -> Void
    let onDelete: () -> Void
    let isLastItem: Bool
    var isInScrollableView: Bool = false
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var dragPosition: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isDeleting: Bool = false
    @State private var isNewlyAdded: Bool = true
    @State private var buttonScale: CGFloat = 0.1
    @State private var buttonVisible: Bool = false
    @State private var hasInitialized: Bool = false 
    
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
    
    private var totalOffset: CGFloat {
        isDeleting ? -400 : (dragPosition + dragOffset)
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            
//            delete
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isDeleting = true
                    }
                }) {
                    ZStack {
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 80)
                        
                        VStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.title3)
                                .foregroundColor(.white)
                            Text("Delete")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 80)
                }
                .buttonStyle(.plain)
                .opacity(isNewlyAdded ? 0 : 1)
            }
            .offset(x: isDeleting ? totalOffset : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDeleting)
            
            HStack(alignment: .bottom, spacing: 2) {
                // Checkmark/circle button with smooth scale transition
                if cart.isShopping || buttonVisible {
                    Button(action: {
                        if cart.isShopping {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                onToggleFulfillment()
                            }
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
                    .frame(maxHeight: .infinity, alignment: .top)
                    .frame(width: buttonScale > 0.5 ? nil : 0)
                    .padding(.top, 2.75)
                    .onChange(of: cart.isShopping) { oldValue, newValue in
                        // Only animate when shopping mode actually changes
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
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(quantityString) \(itemName)")
                        .lexendFont(17, weight: .regular)
                        .lineLimit(1)
                    
                    Text("\(formatCurrency(price)) / \(unit)")
                        .lexendFont(12)
                }
                .opacity(cartItem.isFulfilled ? 0.5 : 1.0)
                .foregroundColor(Color(hex: "231F30"))
                
                Spacer()
                
                Text(formatCurrency(totalPrice))
                    .lexendFont(14, weight: .bold)
                    .foregroundColor(Color(hex: "231F30"))
                    .opacity(cartItem.isFulfilled ? 0.5 : 1.0)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
            .padding(.top, 12)
            .padding(.bottom, isLastItem ? 0 : 12)
            .padding(.leading, 12)
            .padding(.trailing, isInScrollableView ? 0 : 12)
            .background(Color(hex: "FAFAFA").darker(by: 0.03))
            .offset(x: totalOffset)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: totalOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        let translation = value.translation.width
                        if translation < 0 {
                            let proposed = dragPosition + translation
                            if proposed < -80 {
                                let excess = proposed + 80
                                state = -80 - dragPosition + (excess * 0.3)
                            } else {
                                state = translation
                            }
                        } else if dragPosition < 0 {
                            state = translation * 0.5
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            if value.translation.width < -50 {
                                dragPosition = -80
                            } else {
                                dragPosition = 0
                            }
                        }
                    }
            )
            .disabled(isDeleting)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: cart.isShopping)
        .contentShape(Rectangle())
        .onTapGesture {
            if dragPosition < 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragPosition = 0
                }
            } else {
                onEditItem()
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isDeleting = true
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onEditItem()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            if cart.isShopping {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onToggleFulfillment()
                    }
                } label: {
                    Label(
                        cartItem.isFulfilled ? "Mark as Unfulfilled" : "Mark as Fulfilled",
                        systemImage: cartItem.isFulfilled ? "circle" : "checkmark.circle.fill"
                    )
                }
            }
        }
        .onChange(of: isDeleting) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDelete()
                }
            }
        }
        .onAppear {
            dragPosition = 0
            isDeleting = false
            
            // Only initialize once to prevent re-animation on every appearance
            if !hasInitialized {
                buttonVisible = cart.isShopping
                buttonScale = cart.isShopping ? 1.0 : 0.1
                hasInitialized = true
            }
            
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
