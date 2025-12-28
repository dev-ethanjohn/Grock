import SwiftUI

//struct AddNewItemToCartSheet: View {
//    @Binding var isPresented: Bool
//    let cart: Cart
//    var onItemAdded: (() -> Void)?
//    
//    @Environment(VaultService.self) private var vaultService
//    @Environment(CartViewModel.self) private var cartViewModel
//    
//    @State private var currentPage: AddItemPage = .addNew
//    @State private var formViewModel = ItemFormViewModel(requiresPortion: false, requiresStore: true)
//    @FocusState private var itemNameFieldIsFocused: Bool
//    
//    @State private var selectedCategory: GroceryCategory?
//    @State private var showAddItemPopoverInVault = false
//    
//    enum AddItemPage {
//        case addNew
//        case browseVault
//    }
//    
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                // Page 1: Add New Item
//                AddNewItemView(
//                    cart: cart,
//                    formViewModel: $formViewModel,
//                    itemNameFieldIsFocused: $itemNameFieldIsFocused,
//                    onAddToCart: {
//                        handleAddToCart()
//                    }
//                )
//                .offset(x: currentPage == .addNew ? 0 : -UIScreen.main.bounds.width)
//                .opacity(currentPage == .addNew ? 1 : 0)
//                
//                // Page 2: Browse Vault
//                BrowseVaultView(
//                    cart: cart,
//                    selectedCategory: $selectedCategory,
//                    onItemSelected: { item in
//                        handleVaultItemSelection(item)
//                    },
//                    onBack: {
//                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
//                            currentPage = .addNew
//                        }
//                    },
//                    onAddNewItem: {
//                        showAddItemPopoverInVault = true
//                    }
//                )
//                .offset(x: currentPage == .browseVault ? 0 : UIScreen.main.bounds.width)
//                .opacity(currentPage == .browseVault ? 1 : 0)
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button {
//                        resetAndClose()
//                    } label: {
//                        Image(systemName: "xmark")
//                            .font(.system(size: 14, weight: .bold))
//                            .foregroundStyle(.black)
//                    }
//                }
//                        
//                ToolbarItem(placement: .principal) {
//                    HStack(spacing: 8) {
//                        Circle()
//                            .fill(currentPage == .addNew ? Color.black : Color.gray.opacity(0.3))
//                            .frame(width: 6, height: 6)
//                            .scaleEffect(currentPage == .addNew ? 1.2 : 1.0)
//                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
//                        
//                        Circle()
//                            .fill(currentPage == .browseVault ? Color.black : Color.gray.opacity(0.3))
//                            .frame(width: 6, height: 6)
//                            .scaleEffect(currentPage == .browseVault ? 1.2 : 1.0)
//                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
//                    }
//                }
//                
//                ToolbarItem(placement: .topBarTrailing) {
//                    if currentPage == .addNew {
//                        Button(action: {
//                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
//                                currentPage = .browseVault
//                            }
//                        }) {
//                            HStack(spacing: 8) {
//                                Text("vault")
//                                    .fuzzyBubblesFont(13, weight: .bold)
//                                Image(systemName: "shippingbox")
//                                    .resizable()
//                                    .frame(width: 15, height: 15)
//                                    .symbolRenderingMode(.monochrome)
//                                    .fontWeight(.medium)
//                            }
//                            .padding(.horizontal, 12)
//                            .padding(.vertical, 6)
//                            .foregroundColor(.black)
//                            .background(
//                                ZStack {
//                                    Color(.systemGray6)
//                                    LinearGradient(
//                                        colors: [
//                                            .white.opacity(0.2),
//                                            .clear,
//                                            .black.opacity(0.1),
//                                        ],
//                                        startPoint: .topLeading,
//                                        endPoint: .bottomTrailing
//                                    )
//                                }
//                            )
//                            .clipShape(Capsule())
//                            .shadow(
//                                color: .black.opacity(0.4),
//                                radius: 1,
//                                x: 0,
//                                y: 0.5
//                            )
//                        }
//                        
//                    } else {
//                        // Back button when on browse vault page
//                        Button(action: {
//                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
//                                currentPage = .addNew
//                            }
//                        }) {
//                            HStack(spacing: 4) {
//                                Image(systemName: "chevron.left")
//                                    .font(.system(size: 12))
//                                Text("Back")
//                                    .lexendFont(14, weight: .medium)
//                            }
//                            .foregroundColor(.blue)
//                        }
//                    }
//                }
//            }
//        }
//        .presentationDetents(currentPage == .addNew ? [.height(500)] : [.large])
//        .presentationDragIndicator(.visible)
//        .presentationCornerRadius(24)
//        .sheet(isPresented: $showAddItemPopoverInVault) {
//            AddItemPopover(
//                isPresented: $showAddItemPopoverInVault,
//                createCartButtonVisible: .constant(false),
//                onSave: { itemName, category, store, unit, price in
//                    if cart.isShopping {
//                        vaultService.addShoppingItemToCart(
//                            name: itemName,
//                            store: store,
//                            price: price,
//                            unit: unit,
//                            cart: cart,
//                            quantity: 1
//                        )
//                        onItemAdded?()
//                        resetAndClose()
//                    } else {
//                        let success = addNewItemToVaultAndCart(
//                            name: itemName,
//                            category: category,
//                            store: store,
//                            unit: unit,
//                            price: price
//                        )
//                        
//                        if success {
//                            onItemAdded?()
//                            showAddItemPopoverInVault = false
//                            resetAndClose()
//                        }
//                    }
//                }
//            )
//        }
//    }
//    
//    private func handleAddToCart() {
//        guard formViewModel.attemptSubmission(),
//              let category = formViewModel.selectedCategory,
//              let priceValue = Double(formViewModel.itemPrice) else {
//            return
//        }
//        
//        if cart.isShopping {
//            vaultService.addShoppingItemToCart(
//                name: formViewModel.itemName,
//                store: formViewModel.storeName,
//                price: priceValue,
//                unit: formViewModel.unit,
//                cart: cart,
//                quantity: 1
//            )
//            print("🛍️ Added shopping-only item: \(formViewModel.itemName)")
//            
//            vaultService.updateCartTotals(cart: cart)
//            
//            NotificationCenter.default.post(
//                name: NSNotification.Name("ShoppingDataUpdated"),
//                object: nil,
//                userInfo: ["cartItemId": cart.id]
//            )
//            
//        } else {
//            let success = addNewItemToVaultAndCart(
//                name: formViewModel.itemName,
//                category: category,
//                store: formViewModel.storeName,
//                unit: formViewModel.unit,
//                price: priceValue
//            )
//            
//            if success {
//                print("📋 Added vault item: \(formViewModel.itemName)")
//            }
//        }
//        
//        onItemAdded?()
//        resetAndClose()
//    }
//    
//    private func handleVaultItemSelection(_ item: Item) {
//        // Check if it's a temporary shopping-only item
//        if item.isTemporaryShoppingItem == true {
//            // Handle shopping-only item selection
//            guard let price = item.shoppingPrice,
//                  let store = item.priceOptions.first?.store,
//                  let unit = item.shoppingUnit else { return }
//            
//            // Find the existing cartItem (shopping-only)
//            if let existingCartItem = cart.cartItems.first(where: {
//                $0.isShoppingOnlyItem &&
//                $0.shoppingOnlyName?.lowercased() == item.name.lowercased() &&
//                $0.shoppingOnlyStore?.lowercased() == store.lowercased()
//            }) {
//                // Item exists, activate it if skipped
//                if existingCartItem.isSkippedDuringShopping {
//                    existingCartItem.isSkippedDuringShopping = false
//                    existingCartItem.quantity = 1
//                } else {
//                    // Already active, just update quantity
//                    existingCartItem.quantity += 1
//                }
//                vaultService.updateCartTotals(cart: cart)
//            } else {
//                // This shouldn't happen, but fallback
//                vaultService.addShoppingItemToCart(
//                    name: item.name,
//                    store: store,
//                    price: price,
//                    unit: unit,
//                    cart: cart,
//                    quantity: 1
//                )
//            }
//            
//        } else {
//            // Handle regular Vault item
//            guard let priceOption = item.priceOptions.first else { return }
//            
//            if cart.isShopping {
//                vaultService.addShoppingItemToCart(
//                    name: item.name,
//                    store: priceOption.store,
//                    price: priceOption.pricePerUnit.priceValue,
//                    unit: priceOption.pricePerUnit.unit,
//                    cart: cart,
//                    quantity: 1
//                )
//                print("🛍️ Selected vault item for shopping: \(item.name)")
//            } else {
//                vaultService.addVaultItemToCart(
//                    item: item,
//                    cart: cart,
//                    quantity: 1,
//                    selectedStore: priceOption.store
//                )
//                print("📋 Selected vault item for planning: \(item.name)")
//            }
//        }
//        
//        onItemAdded?()
//        resetAndClose()
//    }
//    
//    private func addNewItemToVaultAndCart(name: String, category: GroceryCategory, store: String, unit: String, price: Double) -> Bool {
//        let success = vaultService.addItem(
//            name: name,
//            to: category,
//            store: store,
//            price: price,
//            unit: unit
//        )
//        
//        if success {
//            let newItems = vaultService.findItemsByName(name)
//            if let newItem = newItems.first(where: { item in
//                item.priceOptions.contains { $0.store == store }
//            }) {
//                vaultService.addVaultItemToCart(
//                    item: newItem,
//                    cart: cart,
//                    quantity: 1,
//                    selectedStore: store
//                )
//                return true
//            }
//        }
//        return false
//    }
//    
//    private func resetAndClose() {
//        formViewModel.resetForm()
//        currentPage = .addNew
//        isPresented = false
//    }
//}
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
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                currentPage = .addNew
                            }
                        },
                        onAddNewItem: {
                            showAddItemPopoverInVault = true
                        }
                    )
                    .offset(x: currentPage == .browseVault ? 0 : UIScreen.main.bounds.width)
                    .opacity(currentPage == .browseVault ? 1 : 0)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            resetAndClose()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.black)
                        }
                    }
                            
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
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        if currentPage == .addNew {
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    currentPage = .browseVault
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Text("vault")
                                        .fuzzyBubblesFont(13, weight: .bold)
                                    Image(systemName: "shippingbox")
                                        .resizable()
                                        .frame(width: 15, height: 15)
                                        .symbolRenderingMode(.monochrome)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .foregroundColor(.black)
                                .background(
                                    ZStack {
                                        Color(.systemGray6)
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.2),
                                                .clear,
                                                .black.opacity(0.1),
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    }
                                )
                                .clipShape(Capsule())
                                .shadow(
                                    color: .black.opacity(0.4),
                                    radius: 1,
                                    x: 0,
                                    y: 0.5
                                )
                            }
                            
                        } else {
                            // Back button when on browse vault page
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                    currentPage = .addNew
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 12))
                                    Text("Back")
                                        .lexendFont(14, weight: .medium)
                                }
                                .foregroundColor(.blue)
                            }
                        }
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
    }
    
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
            // Handle regular Vault item
            guard let priceOption = item.priceOptions.first else { return }
            
            if cart.isShopping {
                vaultService.addShoppingItemToCart(
                    name: item.name,
                    store: priceOption.store,
                    price: priceOption.pricePerUnit.priceValue,
                    unit: priceOption.pricePerUnit.unit,
                    cart: cart,
                    quantity: 1
                )
                print("🛍️ Selected vault item for shopping: \(item.name)")
            } else {
                vaultService.addVaultItemToCart(
                    item: item,
                    cart: cart,
                    quantity: 1,
                    selectedStore: priceOption.store
                )
                print("📋 Selected vault item for planning: \(item.name)")
            }
        }
        
        onItemAdded?()
        resetAndClose()
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

// MARK: - Browse Vault View (Page 2) - Optimized for Automatic Updates
struct BrowseVaultView: View {
    let cart: Cart
    @Binding var selectedCategory: GroceryCategory?
    let onItemSelected: (Item) -> Void
    let onBack: () -> Void
    let onAddNewItem: () -> Void
    
    @Environment(VaultService.self) private var vaultService
    @State private var searchText = ""
    
    private var itemsByStore: [(store: String, items: [StoreItem])] {
        print("🔄 Computing itemsByStore for cart: \(cart.name)")
        guard let vault = vaultService.vault else { return [] }
        
        // Get all items from all categories
        var allStoreItems: [StoreItem] = []
        var seenItemStoreCombinations = Set<String>()
        
        // 1. Add Vault items - ONE PER STORE
        for category in vault.categories {
            for item in category.items {
                // For each price option, create a StoreItem
                for priceOption in item.priceOptions {
                    let combinationKey = "\(item.id)-\(priceOption.store)"
                    if !seenItemStoreCombinations.contains(combinationKey) {
                        let storeItem = StoreItem(
                            item: item,
                            categoryName: category.name,
                            priceOption: priceOption,
                            isShoppingOnlyItem: false
                        )
                        allStoreItems.append(storeItem)
                        seenItemStoreCombinations.insert(combinationKey)
                    }
                }
            }
        }
        
        // 2. Add shopping-only items from the current cart
        // But only if they don't already exist as vault items with the same name and store
        for cartItem in cart.cartItems where cartItem.isShoppingOnlyItem {
            if let name = cartItem.shoppingOnlyName,
               let price = cartItem.shoppingOnlyPrice,
               let store = cartItem.shoppingOnlyStore,
               let unit = cartItem.shoppingOnlyUnit,
               !cartItem.isSkippedDuringShopping,
               cartItem.getQuantity(cart: cart) > 0 {
                
                // Check if this shopping-only item already exists as a vault item
                let alreadyExistsAsVaultItem = allStoreItems.contains { storeItem in
                    storeItem.item.name.lowercased() == name.lowercased() &&
                    storeItem.priceOption.store.lowercased() == store.lowercased() &&
                    !storeItem.isShoppingOnlyItem
                }
                
                // Only add shopping-only item if there's no matching vault item
                if !alreadyExistsAsVaultItem {
                    // Create a temporary Item for shopping-only
                    let tempItem = Item(
                        id: cartItem.itemId,
                        name: name,
                        priceOptions: [
                            PriceOption(
                                store: store,
                                pricePerUnit: PricePerUnit(priceValue: price, unit: unit)
                            )
                        ]
                    )
                    
                    let priceOption = PriceOption(
                        store: store,
                        pricePerUnit: PricePerUnit(priceValue: price, unit: unit)
                    )
                    
                    let storeItem = StoreItem(
                        item: tempItem,
                        categoryName: "Shopping Items",
                        priceOption: priceOption,
                        isShoppingOnlyItem: true
                    )
                    
                    allStoreItems.append(storeItem)
                }
            }
        }
        
        // Filter by search text if applicable
        let filteredItems = searchText.isEmpty ? allStoreItems : allStoreItems.filter { storeItem in
            storeItem.item.name.localizedCaseInsensitiveContains(searchText)
        }
        
        // Group by store
        var storeDict: [String: [StoreItem]] = [:]
        
        for storeItem in filteredItems {
            let store = storeItem.priceOption.store
            if storeDict[store] == nil {
                storeDict[store] = []
            }
            storeDict[store]?.append(storeItem)
        }
        
        // Sort stores alphabetically
        let sortedStores = storeDict.keys.sorted()
        
        // Sort items within each store alphabetically by name
        return sortedStores.compactMap { store in
            guard let items = storeDict[store], !items.isEmpty else { return nil }
            let sortedItems = items.sorted {
                $0.item.name.localizedCaseInsensitiveCompare($1.item.name) == .orderedAscending
            }
            return (store: store, items: sortedItems)
        }
    }
    
    private var availableStores: [String] {
        itemsByStore.map { $0.store }
    }
    
    private var showEndIndicator: Bool {
        itemsByStore.reduce(0) { $0 + $1.items.count } >= 6
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Looking for something in your Vault", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.top)
            
            // Items List organized by store
            if itemsByStore.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: searchText.isEmpty ? "archivebox" : "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(searchText.isEmpty ? "Your vault is empty" : "No items found")
                        .foregroundColor(.gray)
                    
                    if searchText.isEmpty {
                        Button(action: onAddNewItem) {
                            Label("Add New Item", systemImage: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(availableStores, id: \.self) { store in
                        if let storeGroup = itemsByStore.first(where: { $0.store == store }) {
                            BrowseVaultStoreSection(
                                storeName: store,
                                items: storeGroup.items,
                                cart: cart,
                                onItemSelected: onItemSelected,
                                isLastStore: store == availableStores.last
                            )
                        }
                    }
                    
                    if showEndIndicator {
                        HStack {
                            Spacer()
                            Text("You've reached the end.")
                                .fuzzyBubblesFont(14, weight: .regular)
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.vertical, 32)
                            Spacer()
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                    
                    if !availableStores.isEmpty {
                        Color.clear
                            .frame(height: 100)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                .listSectionSpacing(16)
                .scrollContentBackground(.hidden)
                .safeAreaInset(edge: .bottom) {
                    if !availableStores.isEmpty {
                        Color.clear.frame(height: 20)
                    }
                }
            }
        }
        // Optional: Listen for cart changes at the view level
        .onChange(of: cart.cartItems) { oldItems, newItems in
            print("🛒 Cart items changed in BrowseVaultView: \(newItems.count) items")
        }
    }
}

struct BrowseVaultStoreSection: View {
    let storeName: String
    let items: [StoreItem]
    let cart: Cart
    let onItemSelected: (Item) -> Void
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
                        cart: cart, // ADD THIS: Pass the cart
                        action: {
                            onItemSelected(tuple.storeItem.item)
                        }
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

// MARK: - Supporting Types
// MARK: - Supporting Types
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

//struct BrowseVaultItemRow: View {
//    let storeItem: StoreItem
//    let cart: Cart
//    let action: () -> Void
//    
//    @State private var appearScale: CGFloat = 0.9
//    @State private var appearOpacity: Double = 0
//    @State private var isNewlyAdded: Bool = true
//    
//    @Environment(VaultService.self) private var vaultService
//    
//    @State private var textValue: String = ""
//    @FocusState private var isFocused: Bool
//    
//    @State private var associatedCartItem: CartItem?
//    @State private var currentQuantity: Double = 0
//    
//    // Keyboard state
//    @State private var keyboardResponder = KeyboardResponder()
//    
//    private var itemType: ItemType {
//        // Check shopping-only first using the storeItem property
//        if storeItem.isShoppingOnlyItem {
//            return .shoppingOnly
//        }
//        
//        // Check if it's a planned cart item (vault item in cart)
//        let isInCartAsPlanned = cart.cartItems.contains(where: {
//            $0.itemId == storeItem.item.id && !$0.isShoppingOnlyItem
//        })
//        
//        if isInCartAsPlanned {
//            return .plannedCart
//        }
//        
//        // Check if it's a shopping-only item (added during shopping)
//        // This only applies to items that don't exist in vault
//        let isInCartAsShopping = cart.cartItems.contains(where: {
//            $0.isShoppingOnlyItem &&
//            $0.shoppingOnlyName?.lowercased() == storeItem.item.name.lowercased() &&
//            $0.shoppingOnlyStore?.lowercased() == storeItem.priceOption.store.lowercased()
//        })
//        
//        if isInCartAsShopping {
//            return .shoppingOnly
//        }
//        
//        // Otherwise, it's vault-only
//        return .vaultOnly
//    }
//    
//    // Helper to check if this is a true shopping-only item (created via add form, not from vault)
//    private var isTrueShoppingOnlyItem: Bool {
//        // Check if storeItem is marked as shopping-only
//        if storeItem.isShoppingOnlyItem {
//            return true
//        }
//        
//        // Check if there's a shopping-only cart item but no vault item with same ID
//        let hasShoppingOnlyCartItem = cart.cartItems.contains(where: {
//            $0.isShoppingOnlyItem &&
//            $0.shoppingOnlyName?.lowercased() == storeItem.item.name.lowercased() &&
//            $0.shoppingOnlyStore?.lowercased() == storeItem.priceOption.store.lowercased()
//        })
//        
//        let hasVaultItemInCart = cart.cartItems.contains(where: {
//            $0.itemId == storeItem.item.id && !$0.isShoppingOnlyItem
//        })
//        
//        return hasShoppingOnlyCartItem && !hasVaultItemInCart
//    }
//    
//    var body: some View {
//        HStack(alignment: .bottom, spacing: 4) {
//            // State indicator based on item type
//            VStack {
//                Circle()
//                    .fill(indicatorColor)
//                    .frame(width: 9, height: 9)
//                    .scaleEffect(shouldShowIndicator ? 1 : 0)
//                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: shouldShowIndicator)
//                    .padding(.top, 8)
//                Spacer()
//            }
//            
//            // Item details
//            VStack(alignment: .leading, spacing: 2) {
//                HStack(spacing: 4) {
//                    Text(storeItem.item.name)
//                        .lexendFont(17)
//                        .foregroundColor(textColor)
//                        .opacity(contentOpacity)
//                    
//                    // State label - ONLY for true shopping-only items when active
//                    if let badgeText = badgeText {
//                        Text(badgeText)
//                            .lexendFont(11, weight: .medium)
//                            .foregroundColor(badgeTextColor)
//                            .padding(.horizontal, 6)
//                            .padding(.vertical, 2)
//                            .background(badgeBackground)
//                            .cornerRadius(4)
//                            .transition(.scale.combined(with: .opacity))
//                    }
//                }
//                
//                HStack(spacing: 0) {
//                    Text("₱\(storeItem.priceOption.pricePerUnit.priceValue, specifier: "%g")")
//                        .foregroundColor(priceColor)
//                        .opacity(contentOpacity)
//                    
//                    Text("/\(storeItem.priceOption.pricePerUnit.unit)")
//                        .foregroundColor(priceColor)
//                        .opacity(contentOpacity)
//                    
//                    Text(" • \(storeItem.categoryName)")
//                        .font(.caption)
//                        .foregroundColor(priceColor.opacity(0.7))
//                        .opacity(contentOpacity)
//                    
//                    Spacer()
//                }
//                .lexendFont(12)
//            }
//            
//            Spacer()
//            
//            // MARK: - Quantity Controls
//            HStack(spacing: 8) {
//                switch itemType {
//                case .vaultOnly:
//                    // Vault-only items: only show plus button
//                    plusButton
//                        .transition(.scale.combined(with: .opacity))
//                    
//                case .plannedCart:
//                    // Planned cart items: show controls based on quantity
//                    if currentQuantity > 0 {
//                        minusButton
//                            .transition(.scale.combined(with: .opacity))
//                        quantityTextField
//                            .transition(.scale.combined(with: .opacity))
//                        plusButton
//                            .transition(.scale.combined(with: .opacity))
//                    } else {
//                        // Quantity is 0 - show only plus button (reactivate)
//                        plusButton
//                            .transition(.scale.combined(with: .opacity))
//                    }
//                    
//                case .shoppingOnly:
//                    // Shopping-only items: show controls if active, remove button if skipped
//                    if currentQuantity > 0 {
//                        minusButton
//                            .transition(.scale.combined(with: .opacity))
//                        quantityTextField
//                            .transition(.scale.combined(with: .opacity))
//                        plusButton
//                            .transition(.scale.combined(with: .opacity))
//                    } else {
//                        // Show remove button for skipped/empty shopping-only items
//                        removeButton
//                            .transition(.scale.combined(with: .opacity))
//                    }
//                }
//            }
//            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentQuantity)
//            .padding(.top, 6)
//        }
//        .padding(.bottom, 4)
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//        .background(.white)
//        .scaleEffect(appearScale)
//        .opacity(appearOpacity)
//        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentQuantity)
//        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemType)
//        .onTapGesture {
//            if isFocused {
//                // Commit and dismiss keyboard when tapping outside
//                isFocused = false
//                commitTextField()
//            }
//        }
//        // REMOVED: .allowsHitTesting(!isFocused) - This was preventing button taps
//        .overlay(
//            Group {
//                if isFocused && keyboardResponder.isVisible {
//                    KeyboardDoneButton(
//                        keyboardHeight: keyboardResponder.currentHeight,
//                        onDone: {
//                            isFocused = false
//                            commitTextField()
//                        }
//                    )
//                }
//            }
//        )
//        .onAppear {
//            updateState()
//            
//            if isNewlyAdded {
//                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
//                    appearScale = 1.0
//                    appearOpacity = 1.0
//                }
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                    isNewlyAdded = false
//                }
//            } else {
//                appearScale = 1.0
//                appearOpacity = 1.0
//            }
//            
//            if textValue.isEmpty || textValue != formatValue(currentQuantity) {
//                textValue = formatValue(currentQuantity)
//            }
//        }
//        .onChange(of: cart.cartItems) { oldItems, newItems in
//            updateState()
//        }
//        .onChange(of: currentQuantity) { oldValue, newValue in
//            if !isFocused {
//                textValue = formatValue(newValue)
//            }
//        }
//        .onChange(of: textValue) { oldValue, newValue in
//            if isFocused && newValue.isEmpty {
//                return
//            }
//        }
//        .onDisappear {
//            isNewlyAdded = true
//        }
//    }
//    
//    // MARK: - UI Properties based on item type and quantity
//    
//    private var shouldShowIndicator: Bool {
//        switch itemType {
//        case .vaultOnly:
//            return false
//        case .plannedCart, .shoppingOnly:
//            return currentQuantity > 0
//        }
//    }
//    
//    private var indicatorColor: Color {
//        switch itemType {
//        case .vaultOnly:
//            return .clear
//        case .plannedCart:
//            return .blue
//        case .shoppingOnly:
//            return .orange
//        }
//    }
//    
//    private var textColor: Color {
//        switch itemType {
//        case .vaultOnly:
//            return Color(hex: "333").opacity(0.7)
//        case .plannedCart:
//            return currentQuantity > 0 ? .black : Color(hex: "333").opacity(0.7)
//        case .shoppingOnly:
//            return currentQuantity > 0 ? .black : Color(hex: "333").opacity(0.7)
//        }
//    }
//    
//    private var priceColor: Color {
//        switch itemType {
//        case .vaultOnly:
//            return Color(hex: "666").opacity(0.7)
//        case .plannedCart:
//            return currentQuantity > 0 ? .gray : Color(hex: "888").opacity(0.7)
//        case .shoppingOnly:
//            return currentQuantity > 0 ? .gray : Color(hex: "888").opacity(0.7)
//        }
//    }
//    
//    private var contentOpacity: Double {
//        switch itemType {
//        case .vaultOnly:
//            return 0.7
//        case .plannedCart:
//            return currentQuantity > 0 ? 1.0 : 0.7
//        case .shoppingOnly:
//            return currentQuantity > 0 ? 1.0 : 0.7
//        }
//    }
//    
//    private var badgeText: String? {
//        // Only show "New" badge for TRUE shopping-only items when active
//        // TRUE shopping-only items are those created via add form, not vault items
//        if isTrueShoppingOnlyItem && currentQuantity > 0 {
//            return "New"
//        }
//        return nil
//    }
//    
//    private var badgeTextColor: Color {
//        return .white
//    }
//    
//    private var badgeBackground: Color {
//        return .orange
//    }
//    
//    // MARK: - Buttons
//    
//    private var minusButton: some View {
//        Button {
//            handleMinus()
//        } label: {
//            Image(systemName: "minus")
//                .font(.footnote).bold()
//                .foregroundColor(Color(hex: "1E2A36"))
//                .frame(width: 24, height: 24)
//                .background(.white)
//                .clipShape(Circle())
//        }
//        .buttonStyle(.plain)
//        .contentShape(Rectangle())
//        .disabled(currentQuantity <= 0)
//        .opacity(currentQuantity <= 0 ? 0.5 : 1)
//    }
//    
//    private var removeButton: some View {
//        Button {
//            handleRemove()
//        } label: {
//            Image(systemName: "trash")
//                .font(.footnote)
//                .foregroundColor(.red)
//                .frame(width: 24, height: 24)
//                .background(.white)
//                .clipShape(Circle())
//                .overlay(
//                    Circle()
//                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
//                )
//        }
//        .buttonStyle(.plain)
//    }
//    
//    private var plusButton: some View {
//        Button(action: handlePlus) {
//            Image(systemName: "plus")
//                .font(.footnote)
//                .bold()
//                .foregroundColor(plusButtonColor)
//        }
//        .frame(width: 24, height: 24)
//        .background(.white)
//        .clipShape(Circle())
//        .overlay(
//            Circle()
//                .stroke(plusButtonStrokeColor, lineWidth: 1)
//        )
//        .contentShape(Circle())
//        .buttonStyle(.plain)
//    }
//    
//    private var plusButtonColor: Color {
//        switch itemType {
//        case .vaultOnly:
//            return Color(hex: "888888").opacity(0.7)
//        case .plannedCart:
//            return currentQuantity > 0 ? Color(hex: "1E2A36") : .blue.opacity(0.7)
//        case .shoppingOnly:
//            return currentQuantity > 0 ? Color(hex: "1E2A36") : .orange.opacity(0.7)
//        }
//    }
//    
//    private var plusButtonStrokeColor: Color {
//        switch itemType {
//        case .vaultOnly:
//            return Color(hex: "F2F2F2").darker(by: 0.1)
//        case .plannedCart:
//            return currentQuantity > 0 ? .clear : .blue.opacity(0.3)
//        case .shoppingOnly:
//            return currentQuantity > 0 ? .clear : .orange.opacity(0.3)
//        }
//    }
//    
//    private var quantityTextField: some View {
//        ZStack {
//            Text(textValue)
//                .font(.system(size: 15, weight: .bold))
//                .foregroundColor(Color(hex: "2C3E50"))
//                .multilineTextAlignment(.center)
//                .contentTransition(.numericText())
//                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: textValue)
//                .fixedSize()
//
//            TextField("", text: $textValue)
//                .keyboardType(.decimalPad)
//                .font(.system(size: 15, weight: .bold))
//                .foregroundColor(.clear)
//                .multilineTextAlignment(.center)
//                .focused($isFocused)
//                .normalizedNumber($textValue, allowDecimal: true, maxDecimalPlaces: 2)
//                .onChange(of: isFocused) { _, focused in
//                    if !focused {
//                        commitTextField()
//                    }
//                }
//                .onChange(of: textValue) { _, newText in
//                    if let number = Double(newText), number > 100 {
//                        textValue = "100"
//                    }
//                }
//        }
//        .padding(.horizontal, 6)
//        .background(
//            RoundedRectangle(cornerRadius: 6)
//                .stroke(Color(hex: "F2F2F2").darker(by: 0.1), lineWidth: 1)
//        )
//        .frame(minWidth: 40)
//        .frame(maxWidth: 80)
//        .fixedSize(horizontal: true, vertical: false)
//    }
//    
//    // MARK: - State Management
//    
//    private func updateState() {
//        let foundCartItem = findCartItem()
//        self.associatedCartItem = foundCartItem
//        
//        // Get quantity from cart item
//        let quantity = foundCartItem?.getQuantity(cart: cart) ?? 0
//        self.currentQuantity = quantity
//        
//        // Update text value if it doesn't match
//        if !isFocused && textValue != formatValue(quantity) {
//            textValue = formatValue(quantity)
//        }
//    }
//    
//    private func findCartItem() -> CartItem? {
//        // First check for shopping-only items by name and store
//        let shoppingCartItem = cart.cartItems.first(where: {
//            $0.isShoppingOnlyItem &&
//            $0.shoppingOnlyName?.lowercased() == storeItem.item.name.lowercased() &&
//            $0.shoppingOnlyStore?.lowercased() == storeItem.priceOption.store.lowercased()
//        })
//        
//        if shoppingCartItem != nil {
//            return shoppingCartItem
//        }
//        
//        // Then check for planned cart items by itemId
//        let plannedCartItem = cart.cartItems.first(where: {
//            $0.itemId == storeItem.item.id && !$0.isShoppingOnlyItem
//        })
//        
//        return plannedCartItem
//    }
//    
//    // MARK: - Quantity Handlers
//    
//    private func handlePlus() {
//        switch itemType {
//        case .vaultOnly:
//            // Add vault-only item to cart
//            // IMPORTANT: For vault items, always add as planned items (not shopping-only)
//            // even during shopping mode, because they exist in the vault
//            vaultService.addVaultItemToCart(
//                item: storeItem.item,
//                cart: cart,
//                quantity: 1,
//                selectedStore: storeItem.priceOption.store
//            )
//            
//            updateState()
//            
//        case .plannedCart:
//            if let cartItem = associatedCartItem {
//                let newQuantity = cartItem.getQuantity(cart: cart) + 1
//                cartItem.quantity = newQuantity
//                cartItem.isSkippedDuringShopping = false
//                vaultService.updateCartTotals(cart: cart)
//                currentQuantity = newQuantity
//                textValue = formatValue(newQuantity)
//            } else {
//                vaultService.addVaultItemToCart(
//                    item: storeItem.item,
//                    cart: cart,
//                    quantity: 1,
//                    selectedStore: storeItem.priceOption.store
//                )
//                updateState()
//            }
//            
//        case .shoppingOnly:
//            if let cartItem = associatedCartItem {
//                let newQuantity = cartItem.getQuantity(cart: cart) + 1
//                cartItem.quantity = newQuantity
//                cartItem.isSkippedDuringShopping = false
//                vaultService.updateCartTotals(cart: cart)
//                currentQuantity = newQuantity
//                textValue = formatValue(newQuantity)
//            } else {
//                vaultService.addShoppingItemToCart(
//                    name: storeItem.item.name,
//                    store: storeItem.priceOption.store,
//                    price: storeItem.priceOption.pricePerUnit.priceValue,
//                    unit: storeItem.priceOption.pricePerUnit.unit,
//                    cart: cart,
//                    quantity: 1
//                )
//                updateState()
//            }
//        }
//        
//        let generator = UIImpactFeedbackGenerator(style: .light)
//        generator.impactOccurred()
//    }
//    
//    private func handleMinus() {
//        guard currentQuantity > 0 else { return }
//        
//        let newQuantity = max(currentQuantity - 1, 0)
//        
//        if newQuantity <= 0 {
//            handleZeroQuantity()
//        } else {
//            updateCartItemQuantity(quantity: newQuantity)
//            textValue = formatValue(newQuantity)
//        }
//        
//        let generator = UIImpactFeedbackGenerator(style: .light)
//        generator.impactOccurred()
//    }
//    
//    private func handleRemove() {
//        if let cartItem = associatedCartItem, itemType == .shoppingOnly {
//            if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
//                cart.cartItems.remove(at: index)
//                vaultService.updateCartTotals(cart: cart)
//            }
//        }
//    }
//    
//    private func commitTextField() {
//        guard !textValue.isEmpty else {
//            handleZeroQuantity()
//            return
//        }
//        
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//
//        if let number = formatter.number(from: textValue) {
//            let doubleValue = number.doubleValue
//            
//            if doubleValue <= 0 {
//                handleZeroQuantity()
//            } else {
//                let clamped = min(max(doubleValue, 0.01), 100)
//                updateCartItemQuantity(quantity: clamped)
//                
//                if doubleValue != clamped {
//                    textValue = formatValue(clamped)
//                }
//            }
//        } else {
//            textValue = formatValue(currentQuantity)
//        }
//    }
//
//    private func handleZeroQuantity() {
//        guard let cartItem = associatedCartItem else {
//            textValue = ""
//            updateState()
//            return
//        }
//        
//        switch itemType {
//        case .plannedCart:
//            cartItem.quantity = 0
//            cartItem.isSkippedDuringShopping = false
//            vaultService.updateCartTotals(cart: cart)
//            
//            currentQuantity = 0
//            textValue = ""
//            
//        case .shoppingOnly:
//            handleRemove()
//            
//        case .vaultOnly:
//            break
//        }
//    }
//    
//    private func formatValue(_ val: Double) -> String {
//        guard !val.isNaN && val.isFinite else {
//            return "1"
//        }
//        
//        if val <= 0 {
//            return "1"
//        }
//        
//        if val.truncatingRemainder(dividingBy: 1) == 0 {
//            return String(format: "%.0f", val)
//        } else {
//            var result = String(format: "%.2f", val)
//            while result.last == "0" { result.removeLast() }
//            if result.last == "." { result.removeLast() }
//            return result
//        }
//    }
//    
//    // MARK: - Cart Operations
//    
//    private func updateCartItemQuantity(quantity: Double) {
//        guard let cartItem = associatedCartItem else { return }
//        
//        cartItem.quantity = quantity
//        cartItem.isSkippedDuringShopping = false
//        vaultService.updateCartTotals(cart: cart)
//        
//        currentQuantity = quantity
//    }
//}

struct BrowseVaultItemRow: View {
    let storeItem: StoreItem
    let cart: Cart
    let action: () -> Void
    
    @State private var appearScale: CGFloat = 0.9
    @State private var appearOpacity: Double = 0
    @State private var isNewlyAdded: Bool = true
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    @State private var associatedCartItem: CartItem?
    @State private var currentQuantity: Double = 0
    
    private var itemType: ItemType {
        // Check shopping-only first using the storeItem property
        if storeItem.isShoppingOnlyItem {
            return .shoppingOnly
        }
        
        // Check if it's a planned cart item (vault item in cart)
        let isInCartAsPlanned = cart.cartItems.contains(where: {
            $0.itemId == storeItem.item.id && !$0.isShoppingOnlyItem
        })
        
        if isInCartAsPlanned {
            return .plannedCart
        }
        
        // Check if it's a shopping-only item (added during shopping)
        // This only applies to items that don't exist in vault
        let isInCartAsShopping = cart.cartItems.contains(where: {
            $0.isShoppingOnlyItem &&
            $0.shoppingOnlyName?.lowercased() == storeItem.item.name.lowercased() &&
            $0.shoppingOnlyStore?.lowercased() == storeItem.priceOption.store.lowercased()
        })
        
        if isInCartAsShopping {
            return .shoppingOnly
        }
        
        // Otherwise, it's vault-only
        return .vaultOnly
    }
    
    // Helper to check if this is a true shopping-only item (created via add form, not from vault)
    private var isTrueShoppingOnlyItem: Bool {
        // Check if storeItem is marked as shopping-only
        if storeItem.isShoppingOnlyItem {
            return true
        }
        
        // Check if there's a shopping-only cart item but no vault item with same ID
        let hasShoppingOnlyCartItem = cart.cartItems.contains(where: {
            $0.isShoppingOnlyItem &&
            $0.shoppingOnlyName?.lowercased() == storeItem.item.name.lowercased() &&
            $0.shoppingOnlyStore?.lowercased() == storeItem.priceOption.store.lowercased()
        })
        
        let hasVaultItemInCart = cart.cartItems.contains(where: {
            $0.itemId == storeItem.item.id && !$0.isShoppingOnlyItem
        })
        
        return hasShoppingOnlyCartItem && !hasVaultItemInCart
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
                HStack(spacing: 4) {
                    Text(storeItem.item.name)
                        .lexendFont(17)
                        .foregroundColor(textColor)
                        .opacity(contentOpacity)
                    
                    // State label - ONLY for true shopping-only items when active
                    if let badgeText = badgeText {
                        Text(badgeText)
                            .lexendFont(11, weight: .medium)
                            .foregroundColor(badgeTextColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badgeBackground)
                            .cornerRadius(4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                HStack(spacing: 0) {
                    Text("₱\(storeItem.priceOption.pricePerUnit.priceValue, specifier: "%g")")
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
        .scaleEffect(appearScale)
        .opacity(appearOpacity)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentQuantity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemType)
        .onTapGesture {
            if isFocused {
                isFocused = false
                commitTextField()
            }
        }
        // Send focus preference to parent
        .preference(key: TextFieldFocusPreferenceKey.self, value: isFocused ? storeItem.id : nil)
        .onAppear {
            updateState()
            
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
            
            if textValue.isEmpty || textValue != formatValue(currentQuantity) {
                textValue = formatValue(currentQuantity)
            }
        }
        .onChange(of: cart.cartItems) { oldItems, newItems in
            updateState()
        }
        .onChange(of: currentQuantity) { oldValue, newValue in
            if !isFocused {
                textValue = formatValue(newValue)
            }
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
        }
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
    
    private var badgeText: String? {
        // Only show "New" badge for TRUE shopping-only items when active
        // TRUE shopping-only items are those created via add form, not vault items
        if isTrueShoppingOnlyItem && currentQuantity > 0 {
            return "New"
        }
        return nil
    }
    
    private var badgeTextColor: Color {
        return .white
    }
    
    private var badgeBackground: Color {
        return .orange
    }
    
    // MARK: - Buttons
    
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
    
    // MARK: - State Management
    
    private func updateState() {
        let foundCartItem = findCartItem()
        self.associatedCartItem = foundCartItem
        
        // Get quantity from cart item
        let quantity = foundCartItem?.getQuantity(cart: cart) ?? 0
        self.currentQuantity = quantity
        
        // Update text value if it doesn't match
        if !isFocused && textValue != formatValue(quantity) {
            textValue = formatValue(quantity)
        }
    }
    
    private func findCartItem() -> CartItem? {
        // First check for shopping-only items by name and store
        let shoppingCartItem = cart.cartItems.first(where: {
            $0.isShoppingOnlyItem &&
            $0.shoppingOnlyName?.lowercased() == storeItem.item.name.lowercased() &&
            $0.shoppingOnlyStore?.lowercased() == storeItem.priceOption.store.lowercased()
        })
        
        if shoppingCartItem != nil {
            return shoppingCartItem
        }
        
        // Then check for planned cart items by itemId
        let plannedCartItem = cart.cartItems.first(where: {
            $0.itemId == storeItem.item.id && !$0.isShoppingOnlyItem
        })
        
        return plannedCartItem
    }
    
    // MARK: - Quantity Handlers
    
    private func handlePlus() {
        switch itemType {
        case .vaultOnly:
            // Add vault-only item to cart
            // IMPORTANT: For vault items, always add as planned items (not shopping-only)
            // even during shopping mode, because they exist in the vault
            vaultService.addVaultItemToCart(
                item: storeItem.item,
                cart: cart,
                quantity: 1,
                selectedStore: storeItem.priceOption.store
            )
            
            updateState()
            
        case .plannedCart:
            if let cartItem = associatedCartItem {
                let newQuantity = cartItem.getQuantity(cart: cart) + 1
                cartItem.quantity = newQuantity
                cartItem.isSkippedDuringShopping = false
                vaultService.updateCartTotals(cart: cart)
                currentQuantity = newQuantity
                textValue = formatValue(newQuantity)
            } else {
                vaultService.addVaultItemToCart(
                    item: storeItem.item,
                    cart: cart,
                    quantity: 1,
                    selectedStore: storeItem.priceOption.store
                )
                updateState()
            }
            
        case .shoppingOnly:
            if let cartItem = associatedCartItem {
                let newQuantity = cartItem.getQuantity(cart: cart) + 1
                cartItem.quantity = newQuantity
                cartItem.isSkippedDuringShopping = false
                vaultService.updateCartTotals(cart: cart)
                currentQuantity = newQuantity
                textValue = formatValue(newQuantity)
            } else {
                vaultService.addShoppingItemToCart(
                    name: storeItem.item.name,
                    store: storeItem.priceOption.store,
                    price: storeItem.priceOption.pricePerUnit.priceValue,
                    unit: storeItem.priceOption.pricePerUnit.unit,
                    cart: cart,
                    quantity: 1
                )
                updateState()
            }
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func handleMinus() {
        guard currentQuantity > 0 else { return }
        
        let newQuantity = max(currentQuantity - 1, 0)
        
        if newQuantity <= 0 {
            handleZeroQuantity()
        } else {
            updateCartItemQuantity(quantity: newQuantity)
            textValue = formatValue(newQuantity)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func handleRemove() {
        if let cartItem = associatedCartItem, itemType == .shoppingOnly {
            if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                cart.cartItems.remove(at: index)
                vaultService.updateCartTotals(cart: cart)
            }
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
            } else {
                let clamped = min(max(doubleValue, 0.01), 100)
                updateCartItemQuantity(quantity: clamped)
                
                if doubleValue != clamped {
                    textValue = formatValue(clamped)
                }
            }
        } else {
            textValue = formatValue(currentQuantity)
        }
    }

    private func handleZeroQuantity() {
        guard let cartItem = associatedCartItem else {
            textValue = ""
            updateState()
            return
        }
        
        switch itemType {
        case .plannedCart:
            cartItem.quantity = 0
            cartItem.isSkippedDuringShopping = false
            vaultService.updateCartTotals(cart: cart)
            
            currentQuantity = 0
            textValue = ""
            
        case .shoppingOnly:
            handleRemove()
            
        case .vaultOnly:
            break
        }
    }
    
    private func formatValue(_ val: Double) -> String {
        guard !val.isNaN && val.isFinite else {
            return "1"
        }
        
        if val <= 0 {
            return "1"
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
    
    // MARK: - Cart Operations
    
    private func updateCartItemQuantity(quantity: Double) {
        guard let cartItem = associatedCartItem else { return }
        
        cartItem.quantity = quantity
        cartItem.isSkippedDuringShopping = false
        vaultService.updateCartTotals(cart: cart)
        
        currentQuantity = quantity
    }
}

// MARK: - Supporting Types

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

// MARK: - Item State Enum
//enum ItemState {
//    case active
//    case skipped
//    case inactive
//    
//    var indicatorColor: Color {
//        switch self {
//        case .active: return storeBadgeColor
//        case .skipped: return .orange.opacity(0.6)
//        case .inactive: return .clear
//        }
//    }
//    
//    var textColor: Color {
//        switch self {
//        case .active: return .black
//        case .skipped: return Color(hex: "666")
//        case .inactive: return Color(hex: "333")
//        }
//    }
//    
//    var priceColor: Color {
//        switch self {
//        case .active: return .gray
//        case .skipped: return Color(hex: "888")
//        case .inactive: return Color(hex: "666")
//        }
//    }
//    
//    var contentOpacity: Double {
//        switch self {
//        case .active: return 1.0
//        case .skipped: return 0.75  // 75% opacity for skipped items
//        case .inactive: return 1.0
//        }
//    }
//    
//    var labelText: String {
//        switch self {
//        case .active: return "In cart"
//        case .skipped: return "Skipped today"
//        case .inactive: return ""
//        }
//    }
//    
//    var labelColor: Color {
//        switch self {
//        case .active: return .white
//        case .skipped: return .orange
//        case .inactive: return .clear
//        }
//    }
//    
//    var labelBackground: Color {
//        switch self {
//        case .active: return storeBadgeColor
//        case .skipped: return .orange.opacity(0.1)
//        case .inactive: return .clear
//        }
//    }
//    
//    // Helper for store badge color (used in indicator)
//    private var storeBadgeColor: Color {
//        // This would need access to storeItem, but we'll use a placeholder
//        Color(hex: "4A90E2") // Default blue
//    }
//}



// MARK: - Supporting Views

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

