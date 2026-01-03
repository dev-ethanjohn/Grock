import SwiftUI

struct AddNewItemToCartSheet: View {
    @Binding var isPresented: Bool
    let cart: Cart
    var onItemAdded: (() -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    
    @State private var currentPage: AddItemPage = .addNew
    @State private var formViewModel = ItemFormViewModel(requiresPortion: false, requiresStore: true)
    @FocusState private var itemNameFieldIsFocused: Bool
    
    @State private var selectedCategory: GroceryCategory?
    @State private var showAddItemPopoverInVault = false
    
    // Keyboard state for done button
    @State private var keyboardResponder = KeyboardResponder()
    @State private var focusedItemId: String?
    
    // Pulse animation states - icons only
    @State private var vaultIconScale: CGFloat = 1.0
    @State private var addItemIconScale: CGFloat = 1.0
    @State private var vaultIconOpacity: Double = 1.0
    @State private var addItemIconOpacity: Double = 1.0
    
    // Track if changes were made in BrowseVaultView
    @State private var hasUnsavedChanges = false
    
    enum AddItemPage {
        case addNew
        case browseVault
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                ZStack {
                    // Page 1: Add New Item
                    AddNewItemView(
                        cart: cart,
                        formViewModel: $formViewModel,
                        itemNameFieldIsFocused: $itemNameFieldIsFocused,
                        onAddToCart: {
                            handleAddToCart()
                        }
                    )
                    .offset(x: currentPage == .addNew ? 0 : -UIScreen.main.bounds.width)
                    .opacity(currentPage == .addNew ? 1 : 0)
                    
                    // Page 2: Browse Vault
                    BrowseVaultView(
                        cart: cart,
                        selectedCategory: $selectedCategory,
                        onItemSelected: { item in
                            handleVaultItemSelection(item)
                            hasUnsavedChanges = true
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                currentPage = .addNew
                            }
                        },
                        onAddNewItem: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                currentPage = .addNew
                            }
                        },
                        hasUnsavedChanges: $hasUnsavedChanges
                    )
                    .offset(x: currentPage == .browseVault ? 0 : UIScreen.main.bounds.width)
                    .opacity(currentPage == .browseVault ? 1 : 0)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Page indicator dots (shown on both pages)
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(currentPage == .addNew ? Color.black : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .scaleEffect(currentPage == .addNew ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                            
                            Circle()
                                .fill(currentPage == .browseVault ? Color.black : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .scaleEffect(currentPage == .browseVault ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    // Left side buttons (different for each page)
                    ToolbarItem(placement: .topBarLeading) {
                        Group {
                            if currentPage == .browseVault {
                                // Done button for BrowseVault page - NOW ON THE LEFT
                                Button(action: {
                                    // Save changes and dismiss
                                    vaultService.updateCartTotals(cart: cart)
                                    onItemAdded?()
                                    resetAndClose()
                                }) {
                                    Text("Done")
                                        .fuzzyBubblesFont(14, weight: .bold)
                                        .foregroundColor(.blue)
                                }
                                .disabled(!hasUnsavedChanges)
                                .opacity(hasUnsavedChanges ? 1.0 : 0.5)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                    
                    // Right side buttons (different for each page)
                    ToolbarItem(placement: .topBarTrailing) {
                        Group {
                            if currentPage == .addNew {
                                // Vault button with icon pulse only - ON THE RIGHT FOR ADD NEW PAGE
                                HStack(spacing: 8) {
                                    Text("check vault?")
                                        .fuzzyBubblesFont(14, weight: .bold)
                                        .foregroundColor(.gray)
                                        .contentTransition(.interpolate)
                                    
                                    // Pulsing vault icon only
                                    Image(systemName: "shippingbox")
                                        .resizable()
                                        .frame(width: 18, height: 18)
                                        .symbolRenderingMode(.monochrome)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                        .scaleEffect(vaultIconScale)
                                        .opacity(vaultIconOpacity)
                                        .onAppear {
                                            startVaultPulse()
                                        }
                                        .onDisappear {
                                            vaultIconScale = 1.0
                                            vaultIconOpacity = 1.0
                                        }
                                }
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                        currentPage = .browseVault
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                                
                            } else if currentPage == .browseVault {
                                // Add Item button - ON THE RIGHT FOR BROWSE VAULT PAGE
                                Button(action: {
                                    // Navigate back to Add New Item page
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                        currentPage = .addNew
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                            .symbolRenderingMode(.monochrome)
                                            .fontWeight(.medium)
                                            .foregroundColor(.blue)
                                        
                                        Text("Add Item")
                                            .fuzzyBubblesFont(14, weight: .bold)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
            }
            .presentationDetents(currentPage == .addNew ? [.height(500)] : [.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
            .sheet(isPresented: $showAddItemPopoverInVault) {
                AddItemPopover(
                    isPresented: $showAddItemPopoverInVault,
                    createCartButtonVisible: .constant(false),
                    onSave: { itemName, category, store, unit, price in
                        if cart.isShopping {
                            vaultService.addShoppingItemToCart(
                                name: itemName,
                                store: store,
                                price: price,
                                unit: unit,
                                cart: cart,
                                quantity: 1
                            )
                            hasUnsavedChanges = true
                            onItemAdded?()
                            resetAndClose()
                        } else {
                            let success = addNewItemToVaultAndCart(
                                name: itemName,
                                category: category,
                                store: store,
                                unit: unit,
                                price: price
                            )
                            
                            if success {
                                hasUnsavedChanges = true
                                onItemAdded?()
                                showAddItemPopoverInVault = false
                                resetAndClose()
                            }
                        }
                    }
                )
            }
            
            // Keyboard Done Button overlay (shows on top of everything)
            if keyboardResponder.isVisible && focusedItemId != nil {
                KeyboardDoneButton(
                    keyboardHeight: keyboardResponder.currentHeight,
                    onDone: {
                        // Dismiss keyboard
                        UIApplication.shared.endEditing()
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .onPreferenceChange(TextFieldFocusPreferenceKey.self) { itemId in
            focusedItemId = itemId
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: hasUnsavedChanges) { oldValue, newValue in
            if newValue {
                print("🔄 hasUnsavedChanges set to true in BrowseVaultView")
            }
        }
    }
    
    
    // MARK: - Pulse Animation Functions (Icons Only)
    
    private func startVaultPulse() {
        // Reset to initial state
        vaultIconScale = 1.0
        vaultIconOpacity = 1.0
        
        // Pronounced scale pulse animation
        withAnimation(
            .easeInOut(duration: 0.9)
            .repeatForever(autoreverses: true)
        ) {
            vaultIconScale = 1.25
        }
        
        // Opacity pulse (slightly delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(
                .easeInOut(duration: 1.1)
                .repeatForever(autoreverses: true)
            ) {
                vaultIconOpacity = 0.7
            }
        }
    }
    
    private func startAddItemPulse() {
        // Reset to initial state
        addItemIconScale = 1.0
        addItemIconOpacity = 1.0
        
        // Pronounced scale pulse animation
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            addItemIconScale = 1.22
        }
        
        // Opacity pulse (slightly delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                addItemIconOpacity = 0.75
            }
        }
    }
    
    // MARK: - Business Logic Functions
    
    private func handleAddToCart() {
        guard formViewModel.attemptSubmission(),
              let category = formViewModel.selectedCategory,
              let priceValue = Double(formViewModel.itemPrice) else {
            return
        }
        
        if cart.isShopping {
            vaultService.addShoppingItemToCart(
                name: formViewModel.itemName,
                store: formViewModel.storeName,
                price: priceValue,
                unit: formViewModel.unit,
                cart: cart,
                quantity: 1
            )
            print("🛍️ Added shopping-only item: \(formViewModel.itemName)")
            
            vaultService.updateCartTotals(cart: cart)
            
            NotificationCenter.default.post(
                name: NSNotification.Name("ShoppingDataUpdated"),
                object: nil,
                userInfo: ["cartItemId": cart.id]
            )
            
        } else {
            let success = addNewItemToVaultAndCart(
                name: formViewModel.itemName,
                category: category,
                store: formViewModel.storeName,
                unit: formViewModel.unit,
                price: priceValue
            )
            
            if success {
                print("📋 Added vault item: \(formViewModel.itemName)")
            }
        }
        
        onItemAdded?()
        resetAndClose()
        
        NotificationCenter.default.post(
                   name: .shoppingItemQuantityChanged,
                   object: nil,
                   userInfo: ["cartId": cart.id]
               )
    }
    
    private func handleVaultItemSelection(_ item: Item) {
        // Check if it's a temporary shopping-only item
        if item.isTemporaryShoppingItem == true {
            // Handle shopping-only item selection
            guard let price = item.shoppingPrice,
                  let store = item.priceOptions.first?.store,
                  let unit = item.shoppingUnit else { return }
            
            // Find the existing cartItem (shopping-only)
            if let existingCartItem = cart.cartItems.first(where: {
                $0.isShoppingOnlyItem &&
                $0.shoppingOnlyName?.lowercased() == item.name.lowercased() &&
                $0.shoppingOnlyStore?.lowercased() == store.lowercased()
            }) {
                // Item exists, activate it if skipped
                if existingCartItem.isSkippedDuringShopping {
                    existingCartItem.isSkippedDuringShopping = false
                    existingCartItem.quantity = 1
                } else {
                    // Already active, just update quantity
                    existingCartItem.quantity += 1
                }
                vaultService.updateCartTotals(cart: cart)
            } else {
                // This shouldn't happen, but fallback
                vaultService.addShoppingItemToCart(
                    name: item.name,
                    store: store,
                    price: price,
                    unit: unit,
                    cart: cart,
                    quantity: 1
                )
            }
            
        } else {
            // Handle regular Vault item - FIXED!
            guard let priceOption = item.priceOptions.first else { return }
            
            if cart.isShopping {
                // FIX: Check if vault item already exists in cart
                if let existingCartItem = cart.cartItems.first(where: {
                    !$0.isShoppingOnlyItem && $0.itemId == item.id
                }) {
                    // Already exists as vault item - activate it
                    existingCartItem.quantity += 1
                    existingCartItem.isSkippedDuringShopping = false
                    vaultService.updateCartTotals(cart: cart)
                    print("🔄 Activated existing vault item: \(item.name)")
                } else {
                    // Doesn't exist - add as vault item using addVaultItemToCart
                    vaultService.addVaultItemToCart(
                        item: item,
                        cart: cart,
                        quantity: 1,
                        selectedStore: priceOption.store
                    )
                    print("📋 Added new vault item to shopping cart: \(item.name)")
                }
            } else {
                // Planning mode
                vaultService.addVaultItemToCart(
                    item: item,
                    cart: cart,
                    quantity: 1,
                    selectedStore: priceOption.store
                )
                print("📋 Selected vault item for planning: \(item.name)")
            }
        }
        
        hasUnsavedChanges = true
        onItemAdded?()
        
        if let cartItem = cart.cartItems.first(where: {
              $0.itemId == item.id ||
              ($0.isShoppingOnlyItem && $0.shoppingOnlyName?.lowercased() == item.name.lowercased())
          }) {
              sendQuantityChangeNotification(for: cartItem, itemName: item.name)
          }
    }
    
    private func sendQuantityChangeNotification(for cartItem: CartItem, itemName: String) {
         let itemTypeString = cartItem.isShoppingOnlyItem ? "shoppingOnly" : "plannedCart"
         
         NotificationCenter.default.post(
             name: .shoppingItemQuantityChanged,
             object: nil,
             userInfo: [
                 "cartId": cart.id,
                 "itemId": cartItem.itemId,
                 "itemName": itemName,
                 "newQuantity": cartItem.quantity,
                 "itemType": itemTypeString
             ]
         )
     }
    
    private func addNewItemToVaultAndCart(name: String, category: GroceryCategory, store: String, unit: String, price: Double) -> Bool {
        let success = vaultService.addItem(
            name: name,
            to: category,
            store: store,
            price: price,
            unit: unit
        )
        
        if success {
            let newItems = vaultService.findItemsByName(name)
            if let newItem = newItems.first(where: { item in
                item.priceOptions.contains { $0.store == store }
            }) {
                vaultService.addVaultItemToCart(
                    item: newItem,
                    cart: cart,
                    quantity: 1,
                    selectedStore: store
                )
                return true
            }
        }
        return false
    }
    
    private func resetAndClose() {
        formViewModel.resetForm()
        currentPage = .addNew
        hasUnsavedChanges = false
        isPresented = false
    }
}

// MARK: - Add New Item View (Page 1)
struct AddNewItemView: View {
    let cart: Cart
    @Binding var formViewModel: ItemFormViewModel
    @FocusState.Binding var itemNameFieldIsFocused: Bool
    let onAddToCart: () -> Void
    
    @State private var duplicateError: String?
    @State private var isCheckingDuplicate = false
    
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(alignment: .center, spacing: 2) {
                Text("Found an extra item?")
                    .fuzzyBubblesFont(20, weight: .bold)
                
                Text("This wasn't on your plan, but you can add it to this trip")
                    .lexendFont(12, weight: .light)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 32)
            
            // Main form content
            ScrollView {
                VStack(spacing: 20) {
                    ItemFormContent(
                        formViewModel: formViewModel,
                        itemNameFieldIsFocused: _itemNameFieldIsFocused,
                        showCategoryTooltip: false,
                        duplicateError: duplicateError,
                        isCheckingDuplicate: isCheckingDuplicate,
                        onStoreChange: {
                            performRealTimeDuplicateCheck(formViewModel.itemName)
                        }
                    )
                    .padding(.top)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            
            VStack(spacing: 16) {
                FormCompletionButton(
                    title: "Add to Cart",
                    isEnabled: formViewModel.isFormValid && duplicateError == nil,
                    cornerRadius: 100,
                    verticalPadding: 12,
                    maxRadius: 1000,
                    bounceScale: (0.95, 1.05, 1.0),
                    bounceTiming: (0.1, 0.3, 0.3),
                    maxWidth: true,
                    action: {
                        if formViewModel.isFormValid && duplicateError == nil {
                            onAddToCart()
                        }
                    }
                )
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.5),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                itemNameFieldIsFocused = true
            }
        }
        .onChange(of: formViewModel.itemName) { oldValue, newValue in
            performRealTimeDuplicateCheck(newValue)
        }
        .onChange(of: formViewModel.storeName) { oldValue, newValue in
            performRealTimeDuplicateCheck(formViewModel.itemName)
        }
    }
    
    private func performRealTimeDuplicateCheck(_ itemName: String) {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let storeName = formViewModel.storeName
        
        guard !trimmedName.isEmpty else {
            duplicateError = nil
            isCheckingDuplicate = false
            return
        }
        
        let validation = vaultService.validateItemName(trimmedName, store: storeName)
        if validation.isValid {
            duplicateError = nil
        } else {
            duplicateError = validation.errorMessage
        }
    }
}



struct BrowseVaultStoreSection: View {
    let storeName: String
    let items: [StoreItem]
    let cart: Cart
    let onItemSelected: (Item) -> Void
    let onQuantityChange: (() -> Void)?  // Add this
    let isLastStore: Bool
    
    private var itemsWithStableIdentifiers: [(id: String, storeItem: StoreItem)] {
          items.map { ($0.id, $0) }
      }
      
    
    var body: some View {
        Section(
            header: HStack {
                HStack(spacing: 2) {
                    Image("store")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundColor(.white)
                    
                    Text(storeName)
                        .fuzzyBubblesFont(11, weight: .bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black)
                .cornerRadius(6)
                Spacer()
            }
            .padding(.leading)
            .listRowInsets(EdgeInsets())
        ) {
            ForEach(itemsWithStableIdentifiers, id: \.id) { tuple in
                VStack(spacing: 0) {
                    BrowseVaultItemRow(
                        storeItem: tuple.storeItem,
                        cart: cart,
                        action: {
                            onItemSelected(tuple.storeItem.item)
                        },
                        onQuantityChange: onQuantityChange  // Pass it here
                    )
                    
                    if tuple.id != itemsWithStableIdentifiers.last?.id {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "ddd"))
                            .padding(.horizontal, 16)
                            .padding(.leading, 14)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .transition(.asymmetric(
                    insertion: .move(edge: .top)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal: .move(edge: .leading)
                        .combined(with: .opacity)
                ))
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: itemsWithStableIdentifiers.map { $0.id })
            }
        }
    }
}

struct StoreItem: Identifiable {
    let id: String
    let item: Item
    let categoryName: String
    let priceOption: PriceOption
    let isShoppingOnlyItem: Bool
    
    init(item: Item, categoryName: String, priceOption: PriceOption, isShoppingOnlyItem: Bool = false) {
        self.id = "\(item.id)-\(priceOption.store)"
        self.item = item
        self.categoryName = categoryName
        self.priceOption = priceOption
        self.isShoppingOnlyItem = isShoppingOnlyItem
    }
}

struct BrowseVaultItemRow: View {
    let storeItem: StoreItem
    let cart: Cart
    let action: () -> Void
    let onQuantityChange: (() -> Void)?
    
    @State private var appearScale: CGFloat = 0.9
    @State private var appearOpacity: Double = 0
    @State private var isNewlyAdded: Bool = true
    @State private var isRemoving: Bool = false
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    // New badge state (same as in CartItemRowListView)
    @AppStorage private var hasShownNewBadge: Bool
    @State private var showNewBadge: Bool = false
    @State private var badgeScale: CGFloat = 0.1
    @State private var badgeRotation: Double = 0
    
    // Store item info for shopping-only items
    private var itemName: String {
        storeItem.item.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var storeName: String {
        storeItem.priceOption.store.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Custom initializer for AppStorage with dynamic key
    init(storeItem: StoreItem, cart: Cart, action: @escaping () -> Void, onQuantityChange: (() -> Void)? = nil) {
        self.storeItem = storeItem
        self.cart = cart
        self.action = action
        self.onQuantityChange = onQuantityChange
        
        // FIXED: Only create storage key for shopping-only items
        if storeItem.isShoppingOnlyItem {
            let storageKey = "hasShownNewBadge_\(storeItem.id)"
            self._hasShownNewBadge = AppStorage(wrappedValue: false, storageKey)
        } else {
            // For vault items, use a dummy key
            self._hasShownNewBadge = AppStorage(wrappedValue: false, "vault_dummy_\(storeItem.id)")
        }
    }
    
    // MARK: - Computed Properties
    
    // Helper to get current quantity - directly from cart
    private var currentQuantity: Double {
        if let cartItem = findCartItem() {
            return cartItem.quantity
        }
        return 0
    }
    
    private var isActive: Bool {
        currentQuantity > 0
    }
    
    private var itemType: ItemType {
        if storeItem.isShoppingOnlyItem {
            return .shoppingOnly
        }
        
        // Check if it's in cart as a planned item (vault item with same ID)
        if let cartItem = findCartItem() {
            // If cart item exists but quantity is 0, treat it as vault-only for UI purposes
            if cartItem.quantity <= 0 {
                return .vaultOnly
            }
            return .plannedCart
        }
        
        return .vaultOnly
    }
    
    // MARK: - UI Properties based on item type and quantity
    
    private var shouldShowIndicator: Bool {
        switch itemType {
        case .vaultOnly:
            return false
        case .plannedCart, .shoppingOnly:
            return currentQuantity > 0
        }
    }
    
    private var indicatorColor: Color {
        switch itemType {
        case .vaultOnly:
            return .clear
        case .plannedCart:
            return .blue
        case .shoppingOnly:
            return .orange
        }
    }
    
    private var textColor: Color {
        switch itemType {
        case .vaultOnly:
            return Color(hex: "333").opacity(0.7)
        case .plannedCart:
            return currentQuantity > 0 ? .black : Color(hex: "333").opacity(0.7)
        case .shoppingOnly:
            return currentQuantity > 0 ? .black : Color(hex: "333").opacity(0.7)
        }
    }
    
    private var priceColor: Color {
        switch itemType {
        case .vaultOnly:
            return Color(hex: "666").opacity(0.7)
        case .plannedCart:
            return currentQuantity > 0 ? .gray : Color(hex: "888").opacity(0.7)
        case .shoppingOnly:
            return currentQuantity > 0 ? .gray : Color(hex: "888").opacity(0.7)
        }
    }
    
    private var contentOpacity: Double {
        switch itemType {
        case .vaultOnly:
            return 0.7
        case .plannedCart:
            return currentQuantity > 0 ? 1.0 : 0.7
        case .shoppingOnly:
            return currentQuantity > 0 ? 1.0 : 0.7
        }
    }
    
    // MARK: - Buttons and UI Components
    
    private var minusButton: some View {
        Button {
            handleMinus()
        } label: {
            Image(systemName: "minus")
                .font(.footnote).bold()
                .foregroundColor(Color(hex: "1E2A36"))
                .frame(width: 24, height: 24)
                .background(.white)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .disabled(currentQuantity <= 0)
        .opacity(currentQuantity <= 0 ? 0.5 : 1)
    }
    
    private var removeButton: some View {
        Button {
            handleRemove()
        } label: {
            Image(systemName: "trash")
                .font(.footnote)
                .foregroundColor(.red)
                .frame(width: 24, height: 24)
                .background(.white)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var plusButton: some View {
        Button(action: handlePlus) {
            Image(systemName: "plus")
                .font(.footnote)
                .bold()
                .foregroundColor(plusButtonColor)
        }
        .frame(width: 24, height: 24)
        .background(.white)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(plusButtonStrokeColor, lineWidth: 1)
        )
        .contentShape(Circle())
        .buttonStyle(.plain)
    }
    
    private var plusButtonColor: Color {
        switch itemType {
        case .vaultOnly:
            return Color(hex: "888888").opacity(0.7)
        case .plannedCart:
            return currentQuantity > 0 ? Color(hex: "1E2A36") : .blue.opacity(0.7)
        case .shoppingOnly:
            return currentQuantity > 0 ? Color(hex: "1E2A36") : .orange.opacity(0.7)
        }
    }
    
    private var plusButtonStrokeColor: Color {
        switch itemType {
        case .vaultOnly:
            return Color(hex: "F2F2F2").darker(by: 0.1)
        case .plannedCart:
            return currentQuantity > 0 ? .clear : .blue.opacity(0.3)
        case .shoppingOnly:
            return currentQuantity > 0 ? .clear : .orange.opacity(0.3)
        }
    }
    
    private var quantityTextField: some View {
        ZStack {
            Text(textValue)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: "2C3E50"))
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: textValue)
                .fixedSize()

            TextField("", text: $textValue)
                .keyboardType(.decimalPad)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.clear)
                .multilineTextAlignment(.center)
                .focused($isFocused)
                .normalizedNumber($textValue, allowDecimal: true, maxDecimalPlaces: 2)
                .onChange(of: textValue) { _, newText in
                    if let number = Double(newText), number > 100 {
                        textValue = "100"
                    }
                }
        }
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(hex: "F2F2F2").darker(by: 0.1), lineWidth: 1)
        )
        .frame(minWidth: 40)
        .frame(maxWidth: 80)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            // State indicator based on item type
            VStack {
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 9, height: 9)
                    .scaleEffect(shouldShowIndicator ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: shouldShowIndicator)
                    .padding(.top, 8)
                Spacer()
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 4) {
                    Text(storeItem.item.name)
                        .lexendFont(17)
                        .foregroundColor(textColor)
                        .opacity(contentOpacity)
                    
                    // NEW: Use the reusable NewBadgeView component
                    if showNewBadge
                        && storeItem.isShoppingOnlyItem
                        && currentQuantity > 0
                        && cart.isShopping
                        && hasShownNewBadge == false {
                        NewBadgeView(
                            scale: badgeScale,
                            rotation: badgeRotation
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                HStack(spacing: 0) {
                    let price = storeItem.priceOption.pricePerUnit.priceValue
                    let isValidPrice = !price.isNaN && price.isFinite
                    
                    Text("₱\(isValidPrice ? price : 0, specifier: "%g")")
                        .foregroundColor(priceColor)
                        .opacity(contentOpacity)
                    
                    Text("/\(storeItem.priceOption.pricePerUnit.unit)")
                        .foregroundColor(priceColor)
                        .opacity(contentOpacity)
                    
                    Text(" • \(storeItem.categoryName)")
                        .font(.caption)
                        .foregroundColor(priceColor.opacity(0.7))
                        .opacity(contentOpacity)
                    
                    Spacer()
                }
                .lexendFont(12)
            }
            
            Spacer()
            
            // MARK: - Quantity Controls
            HStack(spacing: 8) {
                switch itemType {
                case .vaultOnly:
                    // Vault-only items: only show plus button
                    plusButton
                        .transition(.scale.combined(with: .opacity))
                    
                case .plannedCart:
                    // Planned cart items: show controls based on quantity
                    if currentQuantity > 0 {
                        minusButton
                            .transition(.scale.combined(with: .opacity))
                        quantityTextField
                            .transition(.scale.combined(with: .opacity))
                        plusButton
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // Quantity is 0 - show only plus button (reactivate)
                        plusButton
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                case .shoppingOnly:
                    // Shopping-only items: show controls if active, remove button if skipped
                    if currentQuantity > 0 {
                        minusButton
                            .transition(.scale.combined(with: .opacity))
                        quantityTextField
                            .transition(.scale.combined(with: .opacity))
                        plusButton
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // Show remove button for skipped/empty shopping-only items
                        removeButton
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentQuantity)
            .padding(.top, 6)
        }
        .padding(.bottom, 4)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.white)
        .scaleEffect(isRemoving ? 0.9 : appearScale)
        .opacity(isRemoving ? 0 : appearOpacity)
        .offset(x: isRemoving ? -UIScreen.main.bounds.width : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isRemoving)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentQuantity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemType)
        .onTapGesture {
            if isFocused {
                isFocused = false
                commitTextField()
            }
        }
        .preference(key: TextFieldFocusPreferenceKey.self, value: isFocused ? storeItem.id : nil)
        .onAppear {
            // Set initial text value to current quantity
            textValue = formatValue(currentQuantity)
            
            // FIXED: Only check for shopping-only items
            if storeItem.isShoppingOnlyItem {
                if let cartItem = findCartItem(), cart.isShopping {
                    let timeSinceAdded = Date().timeIntervalSince(cartItem.addedAt)
                    if timeSinceAdded < 3.0 {
                        // If we've never shown the badge before, show it with animation
                        if !hasShownNewBadge {
                            showNewBadge = true
                            startNewBadgeAnimation()
                        } else {
                            // If we've shown it before, just show it without animation
                            showNewBadge = true
                        }
                    } else if hasShownNewBadge {
                        // If badge was shown before, keep it visible
                        showNewBadge = true
                    }
                }
            }
            
            if isNewlyAdded {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    appearScale = 1.0
                    appearOpacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isNewlyAdded = false
                }
            } else {
                appearScale = 1.0
                appearOpacity = 1.0
            }
        }
        .onChange(of: cart.cartItems.count) { oldCount, newCount in
            // Force update when cart items count changes
            updateTextValue()
        }
        .onChange(of: textValue) { oldValue, newValue in
            if isFocused && newValue.isEmpty {
                return
            }
        }
        .onChange(of: isFocused) { oldValue, newValue in
            if !newValue {
                commitTextField()
            }
        }
        .onDisappear {
            isNewlyAdded = true
            // Don't hide the badge when view disappears if we've already shown it
            if !hasShownNewBadge {
                showNewBadge = false
            }
        }
    }
    
    // MARK: - New Badge Animation
    private func startNewBadgeAnimation() {
        guard storeItem.isShoppingOnlyItem else { return }
        
        showNewBadge = true
        
        // Badge appears with spring and slight initial rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 100, damping: 10)) {
                badgeScale = 1.0
                badgeRotation = 3 // Small initial tilt
            }
        }
        
        // Sequence: Single smooth rocking motion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Gentle rocking motion
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 50, damping: 7)) {
                badgeRotation = -2
            }
            
            // Return to center
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 50, damping: 7)) {
                    badgeRotation = 1
                }
                
                // Final settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 60, damping: 8)) {
                        badgeRotation = 0
                    }
                }
            }
        }
        
        // Mark as shown after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            // Save that we've shown the badge
            hasShownNewBadge = true
            
            withAnimation(.easeOut(duration: 0.3)) {
                badgeRotation = 0
            }
        }
    }
    
    // MARK: - Helper Functions
    private func findCartItem() -> CartItem? {
        // For shopping-only items: find by name and store (CASE INSENSITIVE)
        let searchName = itemName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let searchStore = storeName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        for cartItem in cart.cartItems {
            if cartItem.isShoppingOnlyItem {
                let cartItemName = cartItem.shoppingOnlyName?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let cartItemStore = cartItem.shoppingOnlyStore?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                
                if cartItemName == searchName && cartItemStore == searchStore {
                    return cartItem
                }
            } else {
                // Check vault items
                if cartItem.itemId == storeItem.item.id {
                    return cartItem
                }
            }
        }
        
        return nil
    }
    
    private func updateTextValue() {
        // Update text value to match current quantity (only if not focused)
        if !isFocused {
            textValue = formatValue(currentQuantity)
        }
    }
    
    private func commitTextField() {
        guard !textValue.isEmpty else {
            handleZeroQuantity()
            return
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        if let number = formatter.number(from: textValue) {
            let doubleValue = number.doubleValue
            
            if doubleValue <= 0 {
                handleZeroQuantity()
                return
            } else {
                let clamped = min(max(doubleValue, 0.01), 100)
                // Use the new updateCartItem function
                updateCartItem(quantity: clamped)
                textValue = formatValue(clamped)
            }
        } else {
            textValue = formatValue(currentQuantity)
        }
    }
    
    private func handleZeroQuantity() {
        guard let cartItem = findCartItem() else {
            textValue = ""
            return
        }
        
        print("🔄 handleZeroQuantity called for: \(itemName)")
        print("   Item type: \(itemType)")
        print("   Current quantity: \(cartItem.quantity)")
        
        switch itemType {
        case .plannedCart:
            print("📋 Setting quantity to 0 (keeping in cart): \(itemName)")
            
            // Set to 0 but KEEP IN CART
            cartItem.quantity = 0
            cartItem.syncQuantities(cart: cart)
            
            if cart.isShopping {
                cartItem.isSkippedDuringShopping = true
                print("   🛒 Marked as skipped (hidden)")
            }
            
            vaultService.updateCartTotals(cart: cart)
            textValue = formatValue(0)
            onQuantityChange?()
            sendShoppingUpdateNotification()
            
        case .shoppingOnly:
            print("🛍️ Removing shopping-only item from cart (WITH slide animation): \(itemName)")
            
            // Sync before removing
            cartItem.syncQuantities(cart: cart)
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isRemoving = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                    print("   Removing from cart at index \(index)")
                    cart.cartItems.remove(at: index)
                    vaultService.updateCartTotals(cart: cart)
                    sendShoppingUpdateNotification()
                }
            }
            
        case .vaultOnly:
            break // Nothing to do for vault-only items
        }
    }
    
    private func formatValue(_ val: Double) -> String {
        // Prevent NaN or invalid values
        guard !val.isNaN && val.isFinite && val >= 0 else {
            return "0"
        }
        
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            var result = String(format: "%.2f", val)
            while result.last == "0" { result.removeLast() }
            if result.last == "." { result.removeLast() }
            return result
        }
    }
    
    // MARK: - Quantity Handlers
    private func handlePlus() {
        print("➕ Plus button tapped for: \(itemName)")
        
        let newQuantity = currentQuantity + 1
        
        // Use the new updateCartItem function
        updateCartItem(quantity: newQuantity)
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func handleMinus() {
        print("➖ Minus button tapped for: '\(itemName)'")
        
        let currentQty = currentQuantity
        guard currentQty > 0 else {
            print("⚠️ Quantity is already 0")
            return
        }
        
        let newQuantity = currentQty - 1
        
        if newQuantity <= 0 {
            handleZeroQuantity()
            return
        }
        
        // Use the new updateCartItem function
        updateCartItem(quantity: newQuantity)
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func handleRemove() {
        print("🗑️ Remove button tapped for shopping-only item: \(itemName)")
        
        // Trigger removal animation first
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            isRemoving = true
        }
        
        // Wait for animation to complete, then remove from cart
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let cartItem = findCartItem(), itemType == .shoppingOnly {
                if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                    print("   Removing from cart at index \(index)")
                    cart.cartItems.remove(at: index)
                    vaultService.updateCartTotals(cart: cart)
                    updateTextValue()
                    onQuantityChange?()
                }
            }
        }
    }
    
    private func sendShoppingUpdateNotification() {
        guard let cartItem = findCartItem() else { return }
        
        // Always use cartItem.quantity as the source of truth
        let currentQuantity = cartItem.quantity
        
        print("📢 DEBUG: Sending notification - cartItem.quantity = \(currentQuantity), actualQuantity = \(cartItem.actualQuantity ?? -1)")
        
        NotificationCenter.default.post(
            name: .shoppingItemQuantityChanged,
            object: nil,
            userInfo: [
                "cartId": cart.id,
                "itemId": storeItem.item.id,
                "itemName": itemName,
                "newQuantity": currentQuantity,  // Use quantity field
                "itemType": String(describing: itemType)
            ]
        )
    }
    
    // MARK: - Update Cart Item Function
    private func updateCartItem(quantity: Double) {
        // Check if item is already in cart and was it added during shopping
        let isAlreadyInCart = cart.cartItems.contains { $0.itemId == storeItem.item.id }
        let wasAddedDuringShopping = cart.cartItems.first { $0.itemId == storeItem.item.id }?.addedDuringShopping ?? false
        
        if cart.isShopping {
            if isAlreadyInCart && !wasAddedDuringShopping {
                // Planned vault item already in cart - just update quantity
                vaultService.addVaultItemToCart(
                    item: storeItem.item,
                    cart: cart,
                    quantity: quantity - currentQuantity
                )
            } else {
                // New vault item or was added during shopping - use shopping method
                vaultService.addVaultItemToCartDuringShopping(
                    item: storeItem.item,
                    store: storeItem.priceOption.store,
                    price: storeItem.priceOption.pricePerUnit.priceValue,
                    unit: storeItem.priceOption.pricePerUnit.unit,
                    cart: cart,
                    quantity: quantity - currentQuantity
                )
            }
        } else {
            // Planning mode
            vaultService.addVaultItemToCart(
                item: storeItem.item,
                cart: cart,
                quantity: quantity - currentQuantity
            )
        }
        
        // Update the UI after cart update
        DispatchQueue.main.async {
            // Force UI refresh
            onQuantityChange?()
            
            // Post notification for quantity change
            sendShoppingUpdateNotification()
        }
    }
}

enum ItemType {
    case vaultOnly      // Never been in any cart
    case plannedCart    // Vault item added to cart during planning
    case shoppingOnly   // Added via add form during shopping
}

enum ItemState {
    case active
    case skipped
    case inactive
}

struct CategoryChip: View {
    let category: GroceryCategory
    let isSelected: Bool
    let hasItems: Bool
    let itemCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(category.emoji)
                    .font(.system(size: 20))
                Text(category.title)
                    .lexendFont(10, weight: .medium)
                    .lineLimit(1)
            }
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.black : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.black : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? .white : .black)
            .overlay(alignment: .topTrailing) {
                if hasItems && itemCount > 0 && !isSelected {
                    Text("\(itemCount)")
                        .lexendFont(9, weight: .bold)
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
}


