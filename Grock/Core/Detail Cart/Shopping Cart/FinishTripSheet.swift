import SwiftUI
import SwiftData
 
struct HeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

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
    
    private var cartTotal: Double {
        vaultService.getTotalCartValue(for: cart)
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
    
    // MARK: - Display models for subviews
    private var changedItemsDisplay: [ChangedItemDisplay] {
        changedItemsList.map { cartItem in
            let itemName = vaultService.findItemById(cartItem.itemId)?.name
                ?? cartItem.vaultItemNameSnapshot
                ?? "Unknown Item"
            let plannedPrice = cartItem.plannedPrice ?? 0
            let actualPrice = cartItem.actualPrice ?? plannedPrice
            let plannedQty = cartItem.originalPlanningQuantity ?? cartItem.quantity
            let actualQty = cartItem.actualQuantity ?? cartItem.quantity
            let unit = cartItem.actualUnit ?? cartItem.plannedUnit ?? ""
            return ChangedItemDisplay(
                id: cartItem.itemId,
                name: itemName,
                plannedPrice: plannedPrice,
                actualPrice: actualPrice,
                plannedQty: plannedQty,
                actualQty: actualQty,
                unit: unit
            )
        }
    }
    
    private var addedDuringShoppingDisplay: [AddedItemDisplay] {
        addedDuringShoppingVaultFulfilled.map { cartItem in
            let itemName = vaultService.findItemById(cartItem.itemId)?.name
                ?? cartItem.vaultItemNameSnapshot
                ?? "Unknown Item"
            let qty = cartItem.actualQuantity ?? cartItem.quantity
            return AddedItemDisplay(id: cartItem.itemId, name: itemName, qty: qty)
        }
    }
    
    private var skippedItemsDisplay: [SkippedItemDisplay] {
        skippedPlannedItems.map { cartItem in
            let itemName = vaultService.findItemById(cartItem.itemId)?.name
                ?? cartItem.vaultItemNameSnapshot
                ?? "Unknown Item"
            let qty = max(1, cartItem.actualQuantity ?? cartItem.originalPlanningQuantity ?? cartItem.quantity)
            return SkippedItemDisplay(id: cartItem.itemId, name: itemName, qty: qty)
        }
    }
    
    private var newItemsDisplay: [NewItemDisplay] {
        newItemsList.map { cartItem in
            let item = vaultService.findItemById(cartItem.itemId)
            let name = item?.name ?? cartItem.shoppingOnlyName ?? "Unknown Item"
            let unit = vaultService.vault.map { vault in
                cartItem.getUnit(from: vault, cart: cart)
            } ?? ""
            let price = vaultService.vault.map { vault in
                cartItem.getPrice(from: vault, cart: cart)
            } ?? 0.0
            var emoji: String? = nil
            var title: String? = nil
            if cartItem.isShoppingOnlyItem, let raw = cartItem.shoppingOnlyCategory, let cat = GroceryCategory(rawValue: raw) {
                emoji = cat.emoji
                title = cat.title
            } else if let vaultItem = item, let category = vaultService.getCategory(for: vaultItem.id) {
                title = category.name
                emoji = vaultService.displayEmoji(forCategoryName: category.name)
            }
            return NewItemDisplay(id: cartItem.itemId, name: name, unit: unit, price: price, categoryEmoji: emoji, categoryTitle: title)
        }
    }
    
    // MARK: - Accordion states
    @State private var showChangedSection: Bool = false
    @State private var showAddedDuringShoppingSection: Bool = false
    @State private var showSkippedSection: Bool = false
    @State private var headerHeight: CGFloat = 0
    
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
            ZStack(alignment: .top) {
                VStack(spacing: 8) {
                        Color.white.frame(height: headerHeight)
           
                        AccordionSectionView(
                            icon: "arrow.left.arrow.right",
                            title: "What changed (\(max(changedItemsList.count, 0)))",
                            subtitle: "Price or quantity differed from plan",
                            accentDeep: .cartChangedDeep,
                            isExpanded: $showChangedSection,
                            hasContent: !changedItemsList.isEmpty,
                            background: Color.cartChangedBackground
                        ) {
                            ChangedItemsListView(items: changedItemsDisplay)
                        }
                        .padding(.horizontal, 20)
                        
                        AccordionSectionView(
                            icon: "shippingbox.fill",
                            title: "Added during shopping (\(addedDuringShoppingVaultFulfilled.count))",
                            subtitle: "Saved items you decided to include mid-trip",
                            accentDeep: .cartAddedDeep,
                            isExpanded: $showAddedDuringShoppingSection,
                            hasContent: !addedDuringShoppingVaultFulfilled.isEmpty,
                            background: Color.cartAddedBackground
                        ) {
                            AddedDuringShoppingListView(items: addedDuringShoppingDisplay)
                        }
                        .padding(.horizontal, 20)
                        
                        AccordionSectionView(
                            icon: "minus.circle.fill",
                            title: "Skipped items (\(skippedPlannedItems.count))",
                            subtitle: "Planned items not bought",
                            accentDeep: .cartSkippedDeep,
                            isExpanded: $showSkippedSection,
                            hasContent: !skippedPlannedItems.isEmpty,
                            background: Color.cartSkippedBackground
                        ) {
                            SkippedItemsListView(items: skippedItemsDisplay)
                        }
                        .padding(.horizontal, 20)
                        
                        Text("• • •")
                            .font(.headline)
                            .foregroundStyle(.gray)
                            .bold()
          
                        if !newItemsList.isEmpty {
                            NewItemsListView(titleCount: newItemsList.count, toggles: $newItemToggles, items: newItemsDisplay)
                        }
                        
                        Color.clear.frame(height: 120)
                    }
                    .padding(.vertical, 20)
                    .blurScroll(scale: 2.3)
                
                // Gradient Overlay
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.white.opacity(0), .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: UIScreen.main.bounds.height * 0.15)
                    .allowsHitTesting(false)
                }
                .ignoresSafeArea(edges: .bottom)

                // Bottom Actions Overlay
                VStack(spacing: 0) {
                    Spacer()
                    
                    CompletionActionsView(
                        onFinish: {
                            mergeSelectedNewItemsToVault()
                            vaultService.completeShopping(cart: cart)
                        },
                        onContinue: {
                            dismiss()
                        }
                    )
                    .padding(.horizontal, 20)
                }
                
                FinishSheetHeaderView(
                    headerSummaryText: headerSummaryText,
                    cart: cart,
                    cartBudget: cartBudget,
                    cartTotal: cartTotal,
                    totalSpent: totalSpent
                )
                .background(
                    Color.white
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: HeaderHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
            }
            .onPreferenceChange(HeaderHeightPreferenceKey.self) { headerHeight = $0 }
            
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
        .presentationBackground(.white)
        .interactiveDismissDisabled(false) // Allow dismissal
        .background(Color.white)
        .onAppear {
            // Start collapsed every time the sheet is presented.
            showChangedSection = false
            showAddedDuringShoppingSection = false
            showSkippedSection = false
        }
        // Add this to observe cart changes
        .onChange(of: cart.budget) { oldValue, newValue in
            print("💰 Cart budget changed: \(oldValue) → \(newValue)")
        }
    }
}

@MainActor
private func makeFinishTripPreview() -> some View {
    let container = try! ModelContainer(
        for: User.self, Vault.self, Category.self, Item.self, PriceOption.self, PricePerUnit.self, Cart.self, CartItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let service = VaultService(modelContext: context)
    
    let previewCart = Cart(name: "Preview Trip", budget: 200, status: .shopping)
    let chips = CartItem.createShoppingOnlyItem(
        name: "Chips",
        store: "Store A",
        price: 2.99,
        unit: "bag",
        quantity: 1,
        category: .pantry
    )
    chips.isFulfilled = true
    let addedVaultItem = CartItem(
        itemId: "vault-3",
        quantity: 1,
        plannedStore: "Store A",
        isFulfilled: true,
        plannedPrice: nil,
        plannedUnit: "ea",
        actualStore: "Store A",
        actualPrice: 2.49,
        actualQuantity: 1,
        actualUnit: "ea",
        isShoppingOnlyItem: false,
        addedDuringShopping: true
    )
    previewCart.cartItems = [
        CartItem(
            itemId: "vault-1",
            quantity: 1,
            plannedStore: "Store A",
            isFulfilled: true,
            plannedPrice: 3.0,
            plannedUnit: "ea",
            actualStore: "Store A",
            actualPrice: 3.5,
            actualQuantity: 2,
            actualUnit: "ea"
        ),
        CartItem(
            itemId: "vault-2",
            quantity: 1,
            plannedStore: "Store A",
            isFulfilled: false,
            plannedPrice: 5.0,
            plannedUnit: "ea"
        ),
        addedVaultItem,
        chips
    ]
    
    return FinishTripSheet(cart: previewCart)
        .environment(service)
        .presentationDetents([.large])
        .background(Color.white)
}

#Preview("FinishTripSheet") {
    makeFinishTripPreview()
}
