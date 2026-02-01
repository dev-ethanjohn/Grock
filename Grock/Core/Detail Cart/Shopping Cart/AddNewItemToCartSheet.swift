import SwiftUI

struct AddNewItemToCartSheet: View {
    @Binding var isPresented: Bool
    let cart: Cart
    var onItemAdded: (() -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    
    @State private var currentPage: AddItemPage = .addNew
    @State private var formViewModel = ItemFormViewModel(requiresPortion: true, requiresStore: true)
    @FocusState private var itemNameFieldIsFocused: Bool
    
    @State private var selectedCategory: GroceryCategory?
    @State private var showAddItemPopoverInVault = false
    
    // Keyboard state for done button
    @State private var keyboardResponder = KeyboardResponder()
    @State private var focusedItemId: String?
    
    // Track if changes were made in BrowseVaultView
    @State private var hasUnsavedChanges = false
    @State private var vaultSearchFocusToken = 0
    
    enum AddItemPage: String, CaseIterable, Identifiable {
        case addNew = "Add New Item"
        case browseVault = "Browse All Items"
        
        var id: String { rawValue }
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
                        focusSearchToken: vaultSearchFocusToken,
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
                    // Page indicator - Custom Segmented Control
                    ToolbarItem(placement: .principal) {
                        ModePicker(selectedPage: $currentPage)
                    }
                    
                    // Right side buttons (different for each page)
                    ToolbarItem(placement: .topBarTrailing) {
                        Group {
                            if currentPage == .browseVault {
                                // Done button for BrowseVault page
                                Button(action: {
                                    // Save changes and dismiss
                                    vaultService.updateCartTotals(cart: cart)
                                    onItemAdded?()
                                    resetAndClose()
                                }) {
                                    Image("done")
                                        .resizable()
                                        .renderingMode(.template)
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.black)
                                }
                                .disabled(!hasUnsavedChanges)
                                .opacity(hasUnsavedChanges ? 1.0 : 0.3)
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
                                quantity: 1,
                                category: category
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
        .onChange(of: currentPage) { _, newValue in
            if newValue == .browseVault {
                itemNameFieldIsFocused = false
                vaultSearchFocusToken += 1
            }
        }
        .onChange(of: hasUnsavedChanges) { oldValue, newValue in
            if newValue {
                print("🔄 hasUnsavedChanges set to true in BrowseVaultView")
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
            // Shopping mode: Create shopping-only item (temporary, not in vault yet)
            // Store category so it can be saved to vault later
            vaultService.addShoppingItemToCart(
                name: formViewModel.itemName,
                store: formViewModel.storeName,
                price: priceValue,
                unit: formViewModel.unit,
                cart: cart,
                quantity: formViewModel.portion ?? 1.0,
                category: category
            )
            print("🛍️ Added shopping-only item: \(formViewModel.itemName)")
            
            vaultService.updateCartTotals(cart: cart)
            
            NotificationCenter.default.post(
                name: NSNotification.Name("ShoppingDataUpdated"),
                object: nil,
                userInfo: ["cartItemId": cart.id]
            )
            
        } else {
            // Planning mode: Add to vault and cart
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
                // Note: Temporary shopping items may not have category info
                vaultService.addShoppingItemToCart(
                    name: item.name,
                    store: store,
                    price: price,
                    unit: unit,
                    cart: cart,
                    quantity: 1,
                    category: nil
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

// MARK: - Mode Picker
private struct ModePicker: View {
    @Binding var selectedPage: AddNewItemToCartSheet.AddItemPage
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            modeButton(title: "New Item", page: .addNew)
            modeButton(title: "Vault", page: .browseVault)
        }
        .padding(2)
        .background(Color(hex: "EEEEEE"))
        .clipShape(Capsule())
        .frame(width: 200, height: 32)
    }
    
    private func modeButton(title: String, page: AddNewItemToCartSheet.AddItemPage) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                selectedPage = page
            }
        }) {
            ZStack {
                if selectedPage == page {
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                        .matchedGeometryEffect(id: "selection", in: animation)
                }
                
                Text(title)
                    .lexendFont(13, weight: .medium)
                    .foregroundColor(selectedPage == page ? .black : .gray)
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
    @State private var addButtonShakeOffset: CGFloat = 0
    
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Form ScrollView
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
            .safeAreaInset(edge: .bottom) {
                bottomButton
            }
        }
        .onAppear {
            itemNameFieldIsFocused = true
        }
        .onChange(of: formViewModel.itemName) { oldValue, newValue in
            performRealTimeDuplicateCheck(newValue)
        }
        .onChange(of: formViewModel.storeName) { oldValue, newValue in
            performRealTimeDuplicateCheck(formViewModel.itemName)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .center, spacing: 2) {
            Text("Found an extra item?")
                .lexendFont(20, weight: .medium)
            
            Text("This wasn't on your plan, but you can add it to this trip")
                .lexendFont(12)
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Bottom Button
    private var bottomButton: some View {
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
                } else {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    triggerAddButtonShake()
                }
            }
        )
        .offset(x: addButtonShakeOffset)
        .padding(.horizontal)
        .padding(.vertical, 12)
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
    
    // MARK: - Helper Functions
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
    
    private func triggerAddButtonShake() {
        let shakeSequence = [0, -8, 8, -6, 6, -4, 4, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    self.addButtonShakeOffset = CGFloat(offset)
                }
            }
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
                    .lexendFont(20)
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
