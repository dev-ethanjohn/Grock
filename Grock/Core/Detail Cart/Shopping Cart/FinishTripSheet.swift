import SwiftUI

struct FinishTripSheet: View {
    @Bindable var cart: Cart  // CHANGED: Make cart mutable
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditBudget = false
    @State private var newItemToggles: [String: Bool] = [:]
    
    // Computed properties
    private var cartInsights: CartInsights {
        vaultService.getCartInsights(cart: cart)
    }
    
    private var fulfilledCount: Int {
        cart.cartItems.filter { $0.isFulfilled }.count
    }
    
    private var skippedCount: Int {
        cart.cartItems.filter { $0.isSkippedDuringShopping }.count
    }
    
    private var addedDuringShoppingCount: Int {
        cart.cartItems.filter { $0.addedDuringShopping || $0.isShoppingOnlyItem }.count
    }
    
    
    // FIXED: Only count fulfilled items' total value
    private var totalSpent: Double {
        guard let vault = vaultService.vault else { return 0.0 }
        
        return cart.cartItems
            .filter { cartItem in
                // Only include fulfilled items with quantity > 0
                cartItem.isFulfilled && cartItem.quantity > 0
            }
            .reduce(0.0) { total, cartItem in
                total + cartItem.getTotalPrice(from: vault, cart: cart)
            }
    }
    
    // The cart's budget - now reacts to changes in cart.budget
    private var cartBudget: Double {
        cart.budget
    }
    
    // Difference between actual spent (fulfilled items only) and budget
    private var budgetDifference: Double {
        totalSpent - cartBudget
    }
    
    private var differenceText: String {
        // Handle case where cart has no budget
        if cartBudget <= 0 {
            return "No budget set"
        }
        
        let difference = abs(budgetDifference)
        let symbol = CurrencyManager.shared.selectedCurrency.symbol
        
        if budgetDifference > 0.01 {
            // Over budget by more than 1 cent
            return "\(symbol)\(String(format: "%.0f", difference)) over budget"
        } else if budgetDifference < -0.01 {
            // Under budget by more than 1 cent
            return "\(symbol)\(String(format: "%.0f", difference)) under budget"
        } else {
            // Within 1 cent of budget - considered as on budget
            return "Exactly on budget"
        }
    }
    
    private var differenceColor: Color {
        if cartBudget <= 0 {
            return Color(hex: "666") // Gray for no budget
        }
        
        if budgetDifference > 0.01 {
            return Color(hex: "FA003F") // Red for over budget
        } else if budgetDifference < -0.01 {
            return Color(hex: "4CAF50") // Green for under budget
        } else {
            return Color(hex: "666") // Gray for on budget
        }
    }
    
    private var emojiForDifference: String {
        if cartBudget <= 0 {
            return "📊" // Chart for no budget
        }
        
        if budgetDifference < -0.01 {
            return "🎉" // Celebration for under budget
        } else if budgetDifference > 0.01 {
            return "📈" // Neutral for over budget
        } else {
            return "🎯" // Bullseye for on budget
        }
    }
    
    private var headerSummaryText: String {
        let symbol = CurrencyManager.shared.selectedCurrency.symbol
        if cartBudget <= 0 {
            return "Set a plan to make sense of this trip later."
        }
        if budgetDifference > 0.01 {
            return "You set a \(symbol)\(String(format: "%.0f", cartBudget)) plan, and this trip went a bit over."
        } else {
            return "You set a \(symbol)\(String(format: "%.0f", cartBudget)) plan, and this trip stayed comfortably within it."
        }
    }
    
    private func categoryColor(for cartItem: CartItem) -> Color {
        if cartItem.isShoppingOnlyItem, let raw = cartItem.shoppingOnlyCategory,
           let groceryCategory = GroceryCategory(rawValue: raw) {
            return groceryCategory.pastelColor.darker(by: 0.4).saturated(by: 0.4)
        }
        if let item = vaultService.findItemById(cartItem.itemId),
           let category = vaultService.getCategory(for: item.id) {
            if let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == category.name }) {
                return groceryCategory.pastelColor.darker(by: 0.4).saturated(by: 0.4)
            }
        }
        return Color(hex: "CCCCCC")
    }
    
    private var changedItemsCount: Int {
        guard let vault = vaultService.vault else { return 0 }
        let epsilon = 0.005
        
        func hasPriceChange(_ item: CartItem) -> Bool {
            if item.isShoppingOnlyItem || !item.isFulfilled { return false }
            let planned = item.plannedPrice ?? item.getCurrentPrice(from: vault, store: item.plannedStore) ?? 0.0
            if let actual = item.actualPrice {
                return abs(actual - planned) > epsilon
            }
            return false
        }
        
        func hasQuantityChange(_ item: CartItem) -> Bool {
            if item.isShoppingOnlyItem || !item.isFulfilled { return false }
            let plannedQ = item.originalPlanningQuantity ?? item.quantity
            if let actualQ = item.actualQuantity {
                return abs(actualQ - plannedQ) > epsilon
            }
            return false
        }
        
        return cart.cartItems.filter { !($0.isShoppingOnlyItem) && $0.isFulfilled && (hasPriceChange($0) || hasQuantityChange($0)) }.count
    }
    
    // MARK: - Computed lists for accordion sections
    private var changedItemsList: [CartItem] {
        guard let vault = vaultService.vault else { return [] }
        let epsilon = 0.005
        return cart.cartItems.filter { item in
            if item.isShoppingOnlyItem || !item.isFulfilled { return false }
            let plannedPrice = item.plannedPrice ?? item.getCurrentPrice(from: vault, store: item.plannedStore) ?? 0.0
            let priceChanged = (item.actualPrice.map { abs($0 - plannedPrice) > epsilon } ?? false)
            let plannedQty = item.originalPlanningQuantity ?? item.quantity
            let qtyChanged = (item.actualQuantity.map { abs($0 - plannedQty) > epsilon } ?? false)
            return priceChanged || qtyChanged
        }
    }
    
    private var addedDuringShoppingVaultFulfilled: [CartItem] {
        cart.cartItems.filter { item in
            item.addedDuringShopping && !item.isShoppingOnlyItem && item.isFulfilled
        }
    }
    
    private var skippedPlannedItems: [CartItem] {
        cart.cartItems.filter { item in
            // Only planned items (not new/shopping-only and not added during shopping) that were not fulfilled
            !item.isShoppingOnlyItem && !item.addedDuringShopping && !item.isFulfilled
        }
    }
    
    private var newItemsList: [CartItem] {
        // Only shopping-only items that were fulfilled appear in New Items
        cart.cartItems.filter { $0.isShoppingOnlyItem && $0.isFulfilled }
    }
    
    // MARK: - Accordion states
    @State private var showChangedSection: Bool = true
    @State private var showAddedDuringShoppingSection: Bool = false
    @State private var showSkippedSection: Bool = false
    
    // MARK: - Merge new items into vault
    private func mergeSelectedNewItemsToVault() {
        guard vaultService.vault != nil else { return }
        
        for cartItem in newItemsList {
            let isSelected = newItemToggles[cartItem.itemId] ?? true
            guard isSelected else { continue }
            
            let name = cartItem.shoppingOnlyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !name.isEmpty else { continue }
            
            let store = (cartItem.shoppingOnlyStore ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !store.isEmpty else { continue }
            
            let price = cartItem.shoppingOnlyPrice ?? 0
            let unit = (cartItem.shoppingOnlyUnit ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            let category: GroceryCategory
            if let raw = cartItem.shoppingOnlyCategory,
               let parsed = GroceryCategory(rawValue: raw) {
                category = parsed
            } else {
                category = .pantry
            }
            
            _ = vaultService.addItem(
                name: name,
                to: category,
                store: store,
                price: price,
                unit: unit.isEmpty ? "ea" : unit
            )
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Sticky header
                FinishSheetHeaderView(
                    headerSummaryText: headerSummaryText,
                    cart: cart,
                    cartBudget: cartBudget,
                    totalSpent: totalSpent
                )
                .background(.white)
                .shadow(color: .black.opacity(0.16), radius: 7, x: 0, y: 3)
                
                // Scrollable content below header
                ScrollView {
                    VStack(spacing: 0) {
                        // What changed accordion
                        AccordionSectionView(
                            icon: "arrow.left.arrow.right",
                            title: "What changed (\(max(changedItemsList.count, 0)))",
                            subtitle: "Price or quantity differed from plan",
                            background: Color(hex: "F0E2FF"),
                            accent: Color(hex: "7300DF"),
                            isExpanded: $showChangedSection,
                            hasContent: !changedItemsList.isEmpty
                        ) {
                            VStack(spacing: 10) {
                                ForEach(changedItemsList, id: \.itemId) { cartItem in
                                    let itemName = vaultService.findItemById(cartItem.itemId)?.name ?? "Unknown Item"
                                    let plannedPrice = cartItem.plannedPrice ?? 0
                                    let actualPrice = cartItem.actualPrice ?? plannedPrice
                                    let plannedQty = cartItem.originalPlanningQuantity ?? cartItem.quantity
                                    let actualQty = cartItem.actualQuantity ?? cartItem.quantity
                                    let unit = cartItem.actualUnit ?? cartItem.plannedUnit ?? ""
                                    let delta = max(0, actualPrice - plannedPrice)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(itemName)
                                            .lexendFont(16, weight: .regular)
                                            .foregroundColor(.black)
                                        
                                        HStack(spacing: 6) {
                                            let priceChanged = abs(actualPrice - plannedPrice) > 0.0001
                                            let qtyChanged = abs(actualQty - plannedQty) > 0.0001
                                            
                                            if priceChanged {
                                                Text("\(plannedPrice.formattedCurrency)")
                                                    .strikethrough()
                                                    .foregroundColor(Color(hex: "777"))
                                                
                                                Text("→ \(actualPrice.formattedCurrency) / \(unit)")
                                                    .foregroundColor(Color(hex: "231F30"))
                                            }
                                            
                                            if priceChanged && qtyChanged {
                                                Text("•")
                                                    .foregroundColor(Color(hex: "999"))
                                            }
                                            
                                            if qtyChanged {
                                                Text("\(plannedQty.formattedQuantity) → \(actualQty.formattedQuantity)\(unit.isEmpty ? "" : " \(unit)")")
                                                    .foregroundColor(Color(hex: "231F30"))
                                            }
                                            
                                            Spacer()
                                            
                                            if priceChanged && delta > 0.0001 {
                                                Text("↑ \(delta.formattedCurrency)")
                                                    .foregroundColor(Color(hex: "FA003F"))
                                            }
                                        }
                                        .lexendFont(13)
                                    }
                                    .padding(.vertical, 6)
                                    
                                    if cartItem != changedItemsList.last {
                                        DashedLine()
                                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                                            .frame(height: 0.5)
                                            .foregroundColor(Color(hex: "999").opacity(0.5))
                                    }
                                }
                            }
                            .padding(.leading, 16)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Added during shopping (vault items) accordion
                        AccordionSectionView(
                            icon: "shippingbox.fill",
                            title: "Added during shopping (\(addedDuringShoppingVaultFulfilled.count))",
                            subtitle: "Saved items you decided to include mid-trip",
                            background: Color(hex: "EFEFEF"),
                            accent: Color(hex: "6D6D6D"),
                            isExpanded: $showAddedDuringShoppingSection,
                            hasContent: !addedDuringShoppingVaultFulfilled.isEmpty
                        ) {
                            VStack(spacing: 6) {
                                ForEach(addedDuringShoppingVaultFulfilled, id: \.itemId) { cartItem in
                                    let itemName = vaultService.findItemById(cartItem.itemId)?.name ?? "Unknown Item"
                                    let qty = cartItem.actualQuantity ?? cartItem.quantity
                                    Text("\(qty.formattedQuantity) \(itemName)")
                                        .lexendFont(13)
                                        .foregroundColor(Color(hex: "231F30"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Skipped items accordion (planned items not fulfilled)
                        AccordionSectionView(
                            icon: "minus.circle.fill",
                            title: "Skipped items (\(skippedPlannedItems.count))",
                            subtitle: "Planned items not bought",
                            background: Color(hex: "FFE7D8"),
                            accent: Color(hex: "FF7F50"),
                            isExpanded: $showSkippedSection,
                            hasContent: !skippedPlannedItems.isEmpty
                        ) {
                            VStack(spacing: 6) {
                                ForEach(skippedPlannedItems, id: \.itemId) { cartItem in
                                    let itemName = vaultService.findItemById(cartItem.itemId)?.name ?? "Unknown Item"
                                    let qty = cartItem.quantity
                                    Text("\(qty.formattedQuantity) \(itemName)")
                                        .lexendFont(13)
                                        .foregroundColor(Color(hex: "231F30"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 4)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        if !newItemsList.isEmpty {
                            VStack(spacing: 8) {
                                HStack {
                                    Text("New items (\(newItemsList.count))")
                                        .lexendFont(16, weight: .semibold)
                                        .foregroundColor(Color(hex: "231F30"))
                                    
                                    Spacer()
                                    
                                    Text("save to vault?")
                                        .lexendFont(12)
                                        .foregroundColor(Color(hex: "666"))
                                }
                                .padding(.horizontal, 24)
                                
                                DashedLine()
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                                    .frame(height: 0.5)
                                    .foregroundColor(Color(hex: "999").opacity(0.5))
                                    .padding(.horizontal, 24)
                                
                                ForEach(newItemsList, id: \.itemId) { cartItem in
                                    let item = vaultService.findItemById(cartItem.itemId)
                                    let name = item?.name ?? cartItem.shoppingOnlyName ?? "Unknown Item"
                                    let unit = vaultService.vault.map { vault in
                                        cartItem.getUnit(from: vault, cart: cart)
                                    } ?? ""
                                    let price = vaultService.vault.map { vault in
                                        cartItem.getPrice(from: vault, cart: cart)
                                    } ?? 0.0
                                    
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(name)
                                                .lexendFont(14, weight: .medium)
                                                .foregroundColor(Color(hex: "231F30"))
                                            Text("\(price.formattedCurrency) / \(unit)")
                                                .lexendFont(12)
                                                .foregroundColor(Color(hex: "888"))
                                        }
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: Binding(
                                            get: { newItemToggles[cartItem.itemId] ?? true },
                                            set: { newItemToggles[cartItem.itemId] = $0 }
                                        ))
                                        .labelsHidden()
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(.bottom, 24)
                        }
                    }
                    .padding(.vertical)
                }
                
                // Completion actions
                VStack(spacing: 6) {
                    FormCompletionButton(
                        title: "Finish and Save Changes",
                        isEnabled: true,
                        cornerRadius: 100,
                        verticalPadding: 12,
                        maxRadius: 1000,
                        bounceScale: (0.98, 1.05, 1.0),
                        bounceTiming: (0.1, 0.3, 0.3),
                        maxWidth: true,
                        action: {
                            mergeSelectedNewItemsToVault()
                            vaultService.completeShopping(cart: cart)
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShowInsightsAfterTrip"),
                                object: nil,
                                userInfo: ["cartId": cart.id]
                            )
                        }
                    )
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        dismiss()
                    }, label: {
                        Text("Continue Shopping")
                            .fuzzyBubblesFont(14, weight: .bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .cornerRadius(100)
                            .overlay {
                                Capsule()
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            }
                    })
                }
                .padding(.horizontal, 20)
                .padding(.bottom)
            }
            
            if showingEditBudget {
                EditBudgetPopover(
                    isPresented: $showingEditBudget,
                    currentBudget: cart.budget,
                    onSave: { newBudget in
                        cart.budget = newBudget
                        vaultService.updateCartTotals(cart: cart)
                    },
                    onDismiss: nil
                )
                .zIndex(1)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .interactiveDismissDisabled(false) // Allow dismissal
        .background(Color.white)
        // Add this to observe cart changes
        .onChange(of: cart.budget) { oldValue, newValue in
            print("💰 Cart budget changed: \(oldValue) → \(newValue)")
        }
    }
}

// MARK: - Header and Highlights subviews
private struct FinishSheetHeaderView: View {
    let headerSummaryText: String
    let cart: Cart
    let cartBudget: Double
    let totalSpent: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Text(headerSummaryText)
                .fuzzyBubblesFont(18, weight: .bold)
                .foregroundColor(Color(hex: "231F30"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
                .padding(.top, 32)
            
            HStack(spacing: 8) {
                FluidBudgetPillView(
                    cart: cart,
                    animatedBudget: cartBudget,
                    onBudgetTap: nil,
                    hasBackgroundImage: false,
                    isHeader: true,
                    customIndicatorSpent: totalSpent
                )
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

private struct AccordionSectionView<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let background: Color
    let accent: Color
    @Binding var isExpanded: Bool
    let hasContent: Bool
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accent)
                            .padding(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .lexendFont(15, weight: .semibold)
                                .foregroundColor(accent)
                            Text(subtitle)
                                .lexendFont(11)
                                .foregroundColor(accent.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    VStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            .foregroundColor(.black)
                    }
                }
                .contentShape(Rectangle())
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(background.opacity(1))
                )
            }
            .buttonStyle(.plain)
            
            Group {
                if isExpanded && hasContent {
                    content()
                        .padding(.top, 8)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            )
                        )
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
            .clipped()
        }
    }
}
// MARK: - Helper Components
private struct ReflectionButton: View {
    let text: String
    let emoji: String
    @State private var isSelected = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isSelected.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Text(emoji)
                Text(text)
                    .lexendFont(14, weight: .medium)
            }
            .padding(.horizontal, 16)
            .background(isSelected ? Color.black : Color(hex: "F5F5F5"))
            .foregroundColor(isSelected ? .white : .black)
            .cornerRadius(20)
        }
    }
}


// MARK: - Stat Pill Component
private struct StatPill: View {
    let emoji: String
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(emoji)
                    .font(.system(size: 16))
                
                Text("\(count)")
                    .lexendFont(18, weight: .semibold)
            }
            
            Text(label)
                .lexendFont(12)
                .foregroundColor(Color(hex: "666"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F7F2ED"))
        )
    }
}

private struct AccordionCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    let background: Color
    let accent: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(background.opacity(0.9))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .lexendFont(14, weight: .semibold)
                    .foregroundColor(Color(hex: "231F30"))
                Text(subtitle)
                    .lexendFont(12)
                    .foregroundColor(Color(hex: "666"))
            }
            
            Spacer()
            
            Image(systemName: "chevron.up")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "231F30"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(background.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(background.opacity(0.8), lineWidth: 1)
        )
    }
}
