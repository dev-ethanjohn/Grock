import SwiftUI
import SwiftData

struct FulfillConfirmationPopover: View {
    @Binding var isPresented: Bool
    let item: Item
    let cart: Cart
    let cartItem: CartItem
    var onFulfill: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var price: String = ""
    @State private var portion: String = ""
    @State private var isConfirming = false
    @State private var errorMessage: String?
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case price, portion
    }
    
    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0
    @State private var keyboardVisible: Bool = false
    
    // Computed properties
    private var storeName: String {
        cartItem.getStore(cart: cart)
    }
    
    private var plannedPrice: Double {
        cartItem.plannedPrice ?? 0
    }
    
    private var plannedUnit: String {
        cartItem.plannedUnit ?? "piece"
    }
    
    private var currentPrice: Double {
        cartItem.actualPrice ?? plannedPrice
    }
    
    private var currentQuantity: Double {
        cartItem.actualQuantity ?? Double(cartItem.quantity)
    }
    
    private var livePrice: Double {
        Double(price) ?? currentPrice
    }
    
    private var liveQuantity: Double {
        Double(portion) ?? currentQuantity
    }
    
    private var categoryInfo: (emoji: String, name: String) {
        if let category = vaultService.getCategory(for: item.id),
           let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == category.name }) {
            return (groceryCategory.emoji, category.name)
        }
        return ("📦", "Uncategorized")
    }
    
    private var totalCost: Double {
        livePrice * liveQuantity
    }
    
    private var plannedTotalCost: Double {
        plannedPrice * currentQuantity
    }
    
    private var totalCostDelta: Double {
        totalCost - plannedTotalCost
    }
    
    private var totalCostDeltaColor: Color {
        totalCostDelta > 0 ? Color(hex: "FA003F") : Color(hex: "4CAF50")
    }
    
    private var totalCostDeltaText: String {
        let delta = abs(totalCostDelta)
        return String(format: "₱%.2f", delta)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4 * overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissPopover() }
            
            VStack(spacing: 20) {
                // Header with title
                Text("Confirm this purchase.")
                    .fuzzyBubblesFont(20, weight: .bold)
                    .foregroundColor(.primary)
                
                // Item description text
                ItemDescriptionText(
                    itemName: item.name,
                    categoryEmoji: categoryInfo.emoji,
                    storeName: storeName,
                    pricePerUnit: currentPrice,
                    unit: plannedUnit
                )
                
                // Quick edit fields (optional adjustments)
                quickEditFields
                
                // Total cost display
                totalCostDisplay
                
                // Error message if any
                if let errorMessage {
                    ErrorMessageDisplay(errorMessage: errorMessage)
                }
                
                // Action buttons
                actionButtons
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(24)
            .padding(.horizontal, UIScreen.main.bounds.width * 0.06)
            .scaleEffect(contentScale)
            .shadow(color: .black.opacity(0.2), radius: 30, y: 15)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: keyboardVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: errorMessage)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .onAppear {
            // Initialize with current values
            price = String(format: "%.2f", currentPrice)
            portion = String(format: currentQuantity.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.2f", currentQuantity)
            
            withAnimation(.easeOut(duration: 0.2)) {
                overlayOpacity = 1
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                contentScale = 1
            }
        }
        .onDisappear {
            onDismiss?()
        }
    }
    
    // MARK: - Quick Edit Fields
    private var quickEditFields: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick adjustments")
                .lexendFont(13, weight: .medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            HStack(spacing: 16) {
                // Price field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Actual Price")
                        .lexendFont(12)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text("₱")
                            .lexendFont(14, weight: .semibold)
                            .foregroundColor(.primary)
                        
                        TextField("", text: $price)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .price)
                            .lexendFont(14, weight: .semibold)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onChange(of: price) { _, _ in
                                errorMessage = nil
                            }
                    }
                }
                
                // Quantity field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Quantity")
                        .lexendFont(12)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("", text: $portion)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .portion)
                            .lexendFont(14, weight: .semibold)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .onChange(of: portion) { _, _ in
                                errorMessage = nil
                            }
                        
                        Text(plannedUnit)
                            .lexendFont(12)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Total Cost Display
    private var totalCostDisplay: some View {
        VStack(spacing: 8) {
            Divider()
            
            HStack {
                Text("Total Cost:")
                    .lexendFont(16)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(totalCost.formattedCurrency)
                        .fuzzyBubblesFont(18, weight: .bold)
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    
                    if abs(totalCostDelta) > 0.01 {
                        HStack(spacing: 2) {
                            Image(systemName: totalCostDelta > 0 ? "arrow.up" : "arrow.down")
                                .font(.caption2)
                                .foregroundColor(totalCostDeltaColor)
                            
                            Text("\(totalCostDeltaText) from plan")
                                .lexendFont(11)
                                .foregroundColor(totalCostDeltaColor)
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Confirm button
            FormCompletionButton(
                title: isConfirming ? "Confirming..." : "Confirm Purchase",
                isEnabled: !isConfirming && validateInputs(),
                cornerRadius: 50,
                verticalPadding: 16,
                maxRadius: 1000,
                bounceScale: (0.95, 1.03, 1.0),
                bounceTiming: (0.1, 0.3, 0.3),
                maxWidth: true,
                action: confirmPurchase
            )
            .frame(maxWidth: .infinity)
            
            // Cancel button
            Button(action: dismissPopover) {
                Text("Cancel")
                    .lexendFont(15, weight: .medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Methods
    private func validateInputs() -> Bool {
        guard let priceValue = Double(price),
              let portionValue = Double(portion) else {
            Task { @MainActor in
                errorMessage = "Please enter valid numbers"
            }
            return false
        }
        
        guard priceValue > 0 else {
            Task { @MainActor in
                errorMessage = "Price must be greater than 0"
            }
            return false
        }
        
        guard portionValue > 0 else {
            Task { @MainActor in
                errorMessage = "Quantity must be greater than 0"
            }
            return false
        }
        
        // Clear any previous error if validation passes
        Task { @MainActor in
            errorMessage = nil
        }
        
        return true
    }
    
    private func confirmPurchase() {
        guard let priceValue = Double(price),
              let portionValue = Double(portion),
              priceValue > 0, portionValue > 0 else {
            errorMessage = "Please enter valid numbers"
            return
        }
        
        isConfirming = true
        
        // Update cart item with actual data
        cartItem.actualPrice = priceValue
        cartItem.actualQuantity = portionValue
        cartItem.isFulfilled = true
        cartItem.wasEditedDuringShopping = true
        
        // Update totals
        vaultService.updateCartTotals(cart: cart)
        
        // Trigger haptic feedback
        // HapticManager.shared.playSuccess()
        
        // Small delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isConfirming = false
            onFulfill?()
            dismissPopover()
        }
    }
    
    private func dismissPopover() {
        focusedField = nil
        isPresented = false
        onDismiss?()
    }
}

// MARK: - Item Description Text Component
private struct ItemDescriptionText: View {
    let itemName: String
    let categoryEmoji: String
    let storeName: String
    let pricePerUnit: Double
    let unit: String
    
    var body: some View {
        HStack(spacing: 0) {
            Text(itemName)
                .foregroundColor(.primary)
                .lexendFont(14, weight: .semibold)
            +
            Text(" (\(categoryEmoji)) from ")
                .foregroundColor(.secondary)
                .lexendFont(14)
            +
            Text(storeName)
                .foregroundColor(.primary)
                .lexendFont(14, weight: .semibold)
            +
            Text("\nPrice: ")
                .foregroundColor(.secondary)
                .lexendFont(14)
            +
            Text(String(format: "₱%.2f", pricePerUnit))
                .foregroundColor(.primary)
                .lexendFont(14, weight: .semibold)
            +
            Text(" per \(unit)")
                .foregroundColor(.secondary)
                .lexendFont(14)
        }
        .multilineTextAlignment(.center)
        .lineSpacing(4)
        .padding(.horizontal, 8)
    }
}

// MARK: - Helper Views
private struct ErrorMessageDisplay: View {
    let errorMessage: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.red)
            
            Text(errorMessage)
                .lexendFont(13)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}
