import SwiftUI
import SwiftData

struct CartItemRowListView: View {
    @Bindable var cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onFulfillItem: () -> Void
    let onEditItem: () -> Void
    let onDeleteItem: () -> Void
    let isLastItem: Bool
    
    var body: some View {
        MainRowContent(
            cartItem: cartItem,
            item: item,
            cart: cart,
            onFulfillItem: onFulfillItem,
            onEditItem: onEditItem,
            onDeleteItem: onDeleteItem,
            isLastItem: isLastItem
        )
        .onChange(of: cartItem.quantity) { oldValue, newValue in
                 print("🔄 CartItemRowListView: quantity changed from \(oldValue) to \(newValue)")
                 if newValue <= 0 && cart.status == .planning {
                     print("🗑️ Quantity is 0, this item should be removed from display")
                 }
             }
    }
}

// MARK: - Main Row Content
private struct MainRowContent: View {
    @Bindable var cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onFulfillItem: () -> Void
    let onEditItem: () -> Void
    let onDeleteItem: () -> Void
    let isLastItem: Bool
    
    @Environment(VaultService.self) private var vaultService
    
    // Add back all the missing state variables
    @State private var isNewlyAdded: Bool = true
    @State private var buttonScale: CGFloat = 0.1
    @State private var isFulfilling: Bool = false
    @State private var iconScale: CGFloat = 1.0
    @State private var checkmarkScale: CGFloat = 0.1
    @State private var rowOpacity: Double = 1.0
    
    // Derived state
    @State private var currentQuantity: Double = 0
    @State private var currentPrice: Double = 0
    @State private var currentTotalPrice: Double = 0
    @State private var displayUnit: String = ""
    
    private var itemName: String {
        item?.name ?? "Unknown Item"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if cart.isShopping {
                FulfillmentButton(
                    cartItem: cartItem,
                    isFulfilling: $isFulfilling,
                    iconScale: $iconScale,
                    checkmarkScale: $checkmarkScale,
                    buttonScale: buttonScale,
                    onFulfillItem: onFulfillItem
                )
            }
            
            // Item details using the derived state
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(currentQuantity.formattedQuantity)
                        .lexendFont(16, weight: .regular)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentQuantity)
                    
                    Text(itemName)
                        .lexendFont(16, weight: .regular)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .strikethrough(cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping))
                }
                
                HStack(spacing: 4) {
                    Text("\(currentPrice.formattedCurrency) / \(displayUnit)")
                        .lexendFont(12)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPrice)
                    
                    Spacer()
                    
                    Text(currentTotalPrice.formattedCurrency)
                        .lexendFont(14, weight: .bold)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentTotalPrice)
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
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    buttonScale = 1.0
                }
            } else {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    buttonScale = 0.1
                }
            }
        }
        .onAppear {
            // Set initial scale based on cart mode
            buttonScale = cart.isShopping ? 1.0 : 0.1
            
            // Initialize derived values
            updateDerivedValues()
            
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
        // SIMPLIFIED FIX: Use individual onChange observers instead of tuple
        .onChange(of: cartItem.quantity) { oldValue, newValue in
            if oldValue != newValue {
                print("🔢 cartItem.quantity changed: \(oldValue) → \(newValue)")
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.actualPrice) { oldValue, newValue in
            if oldValue != newValue {
                print("💰 actualPrice changed: \(oldValue ?? 0) → \(newValue ?? 0)")
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.actualQuantity) { oldValue, newValue in
            if oldValue != newValue {
                print("📦 actualQuantity changed: \(oldValue ?? 0) → \(newValue ?? 0)")
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.shoppingOnlyPrice) { oldValue, newValue in
            if oldValue != newValue {
                print("🛍️ shoppingOnlyPrice changed: \(oldValue ?? 0) → \(newValue ?? 0)")
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.isFulfilled) { oldValue, newValue in
            if oldValue != newValue {
                print("✅ isFulfilled changed: \(oldValue) → \(newValue)")
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cartItem.isSkippedDuringShopping) { oldValue, newValue in
            if oldValue != newValue {
                print("⏸️ isSkippedDuringShopping changed: \(oldValue) → \(newValue)")
                updateDerivedValues(animated: true)
            }
        }
        .onChange(of: cart.status) { oldValue, newValue in
            if oldValue != newValue {
                print("🛒 cart.status changed: \(oldValue) → \(newValue)")
                updateDerivedValues(animated: true)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShoppingDataUpdated"))) { _ in
            print("📢 ShoppingDataUpdated received for: \(itemName)")
            updateDerivedValues(animated: true)
        }
    }
    
    private func updateDerivedValues(animated: Bool = false) {
         guard let vault = vaultService.vault else { return }
         
         // FIX: Use cartItem.quantity directly instead of getQuantity(cart:)
         let newQuantity = cartItem.quantity
         let newPrice = cartItem.getPrice(from: vault, cart: cart)
         let newTotalPrice = cartItem.getTotalPrice(from: vault, cart: cart)
         let newUnit = cartItem.getUnit(from: vault, cart: cart)
         
         print("📊 Updating derived values for \(itemName): qty=\(newQuantity), price=\(newPrice), total=\(newTotalPrice)")
        
        cartItem.syncQuantities(cart: cart)  // <-- ADD HERE
         
         if animated {
             withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                 currentQuantity = newQuantity
                 currentPrice = newPrice
                 currentTotalPrice = newTotalPrice
                 displayUnit = newUnit
             }
         } else {
             currentQuantity = newQuantity
             currentPrice = newPrice
             currentTotalPrice = newTotalPrice
             displayUnit = newUnit
         }
     }
}

// MARK: - Fulfillment Button Component (keep your existing one)
private struct FulfillmentButton: View {
    let cartItem: CartItem
    @Binding var isFulfilling: Bool
    @Binding var iconScale: CGFloat
    @Binding var checkmarkScale: CGFloat
    let buttonScale: CGFloat
    let onFulfillItem: () -> Void
    
    var body: some View {
        Button(action: {
            guard !isFulfilling else { return }
            
            // Call the fulfillment handler first
            onFulfillItem()
            
            DispatchQueue.main.async {
                isFulfilling = true
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    iconScale = 1.3
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFulfilling = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        iconScale = 1.0
                    }
                }
            }
        }) {
            ZStack {
                // Always show the circle (for both states)
                Circle()
                    .strokeBorder(
                        cartItem.isFulfilled ? Color.green : Color(hex: "666"),
                        lineWidth: cartItem.isFulfilled ? 0 : 1.5
                    )
                    .frame(width: 18, height: 18)
                    .scaleEffect(iconScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: iconScale)
                
                // Checkmark when fulfilled
                if cartItem.isFulfilled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                        .scaleEffect(checkmarkScale)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: checkmarkScale)
                } else {
                    // Simple circle for unfulfilled
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 18, height: 18)
                }
            }
            .frame(width: 18, height: 18)
            .padding(.trailing, 8)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .scaleEffect(buttonScale)
        }
        .buttonStyle(.plain)
        .disabled(isFulfilling || cartItem.isFulfilled)
        .help(cartItem.isFulfilled ? "Already purchased" : "Tap to confirm purchase")
    }
}

// MARK: - Item Details Content Component
private struct ItemDetailsContent: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let animatedPrice: Double
    let animatedQuantity: Double
    let animatedTotalPrice: Double
    let displayUnit: String
    let itemName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Quantity with numeric transition
            HStack(spacing: 4) {
                Text(animatedQuantity.formattedQuantity)
                    .lexendFont(16, weight: .regular)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animatedQuantity)
                
                Text(itemName)
                    .lexendFont(16, weight: .regular)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .strikethrough(cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping))
            }
            
            HStack(spacing: 4) {
                // Price per unit with numeric transition
                Text("\(animatedPrice.formattedCurrency) / \(displayUnit)")
                    .lexendFont(12)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animatedPrice)
                
                Spacer()
                
                // Total price with numeric transition
                Text(animatedTotalPrice.formattedCurrency)
                    .lexendFont(14, weight: .bold)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: animatedTotalPrice)
            }
            .foregroundColor(Color(hex: "231F30"))
            .opacity(cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping) ? 0.5 : 1.0)
        }
        .opacity(cart.isShopping && (cartItem.isFulfilled || cartItem.isSkippedDuringShopping) ? 0.5 : 1.0)
    }
}


