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
    
    enum AddItemPage {
        case addNew
        case browseVault
    }
    
    var body: some View {
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

// MARK: - Browse Vault View (Page 2)
struct BrowseVaultView: View {
    let cart: Cart
    @Binding var selectedCategory: GroceryCategory?
    let onItemSelected: (Item) -> Void
    let onBack: () -> Void
    let onAddNewItem: () -> Void
    
    @Environment(VaultService.self) private var vaultService
    @State private var searchText = ""
    
    private var itemsByStore: [(store: String, items: [StoreItem])] {
        guard let vault = vaultService.vault else { return [] }
        
        // Get all items from all categories
        var allStoreItems: [StoreItem] = []
        
        // 1. Add Vault items
        for category in vault.categories {
            for item in category.items {
                // Create a StoreItem for each price option
                for priceOption in item.priceOptions {
                    let storeItem = StoreItem(
                        item: item,
                        categoryName: category.name,
                        priceOption: priceOption,
                        isShoppingOnlyItem: false // VAULT ITEMS ARE NOT SHOPPING-ONLY
                    )
                    allStoreItems.append(storeItem)
                }
            }
        }
        
        // 2. Add shopping-only items from the current cart
        let shoppingOnlyItems = cart.cartItems.filter { $0.isShoppingOnlyItem }
        for cartItem in shoppingOnlyItems {
            if let name = cartItem.shoppingOnlyName,
               let price = cartItem.shoppingOnlyPrice,
               let store = cartItem.shoppingOnlyStore,
               let unit = cartItem.shoppingOnlyUnit {
                
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
                    isShoppingOnlyItem: true // SHOPPING-ONLY ITEMS
                )
                
                allStoreItems.append(storeItem)
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

// MARK: - BrowseVaultItemRow (With Quantity Controls - UPDATED FOR SYNC AND ZERO HANDLING)
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
//    // Alert state for zero quantity confirmation
//    @State private var showingZeroQuantityAlert = false
//    @State private var pendingZeroQuantityUpdate = false
//    
//    private var currentQuantity: Double {
//        if let cartItem = cart.cartItems.first(where: { $0.itemId == storeItem.item.id }) {
//            return cartItem.getQuantity(cart: cart)
//        }
//        return 0
//    }
//    
//    private var isActive: Bool {
//        currentQuantity > 0
//    }
//    
//    var body: some View {
//        HStack(alignment: .bottom, spacing: 4) {
//            // Indicator circle
//            VStack {
//                Circle()
//                    .fill(isActive ? storeBadgeColor : .clear)
//                    .frame(width: 9, height: 9)
//                    .scaleEffect(isActive ? 1 : 0)
//                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)
//                    .padding(.top, 8)
//                Spacer()
//            }
//            
//            // Item details
//            VStack(alignment: .leading, spacing: 1) {
//                Text(storeItem.item.name)
//                    .foregroundColor(isActive ? .black : Color(hex: "999"))
//                    .lexendFont(17)
//                
//                HStack(spacing: 0) {
//                    Text("₱\(storeItem.priceOption.pricePerUnit.priceValue, specifier: "%g")")
//                    Text("/\(storeItem.priceOption.pricePerUnit.unit)")
//                    Text(" • \(storeItem.categoryName)")
//                        .font(.caption)
//                        .foregroundColor(isActive ? .gray : Color(hex: "999"))
//                    Spacer()
//                }
//                .lexendFont(12)
//                .foregroundColor(isActive ? .gray : Color(hex: "999"))
//            }
//            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
//            
//            Spacer()
//            
//            // Quantity controls
//            HStack(spacing: 8) {
//                if isActive {
//                    minusButton
//                        .transition(.scale.combined(with: .opacity))
//                    quantityTextField
//                        .transition(.scale.combined(with: .opacity))
//                }
//                plusButton
//            }
//            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isActive)
//            .padding(.top, 6)
//        }
//        .padding(.bottom, 4)
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//        .background(.white)
//        .scaleEffect(appearScale)
//        .opacity(appearOpacity)
//        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
//        .onTapGesture {
//            if isFocused {
//                isFocused = false
//            }
//        }
//        .allowsHitTesting(!isFocused)
//        .onChange(of: currentQuantity) { _, newValue in
//            if !isFocused {
//                textValue = formatValue(newValue)
//            }
//        }
//        .onAppear {
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
//        .onDisappear {
//            isNewlyAdded = true
//        }
//        .alert("Remove Item?", isPresented: $showingZeroQuantityAlert) {
//            Button("Cancel", role: .cancel) {
//                // Reset to previous quantity
//                if pendingZeroQuantityUpdate {
//                    // Keep at 1 instead of going to 0
//                    textValue = "1"
//                    updateCartItemQuantity(quantity: 1)
//                }
//            }
//            Button("Remove", role: .destructive) {
//                // Actually remove item from cart
//                updateCartItemQuantity(quantity: 0)
//            }
//        } message: {
//            Text("Setting quantity to 0 will remove '\(storeItem.item.name)' from your cart. Are you sure?")
//        }
//    }
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
//        .disabled(currentQuantity <= 0 || isFocused)
//        .opacity(currentQuantity <= 0 ? 0.5 : 1)
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
//                    // Check if user typed "0"
//                    if newText == "0" || newText == "0.0" || newText == "0.00" {
//                        pendingZeroQuantityUpdate = true
//                        showingZeroQuantityAlert = true
//                    } else if let number = Double(newText), number > 100 {
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
//    private var plusButton: some View {
//        Button(action: {
//            if isActive {
//                handlePlus()
//            } else {
//                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                    addItemToCart(quantity: 1)
//                }
//            }
//        }) {
//            Image(systemName: "plus")
//                .font(.footnote)
//                .bold()
//                .foregroundColor(isActive ? Color(hex: "1E2A36") : Color(hex: "888888"))
//        }
//        .frame(width: 24, height: 24)
//        .background(.white)
//        .clipShape(Circle())
//        .contentShape(Circle())
//        .buttonStyle(.plain)
//        .disabled(isFocused)
//    }
//    
//    private func handlePlus() {
//        let newValue: Double
//        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
//            newValue = ceil(currentQuantity)
//        } else {
//            newValue = currentQuantity + 1
//        }
//
//        let clamped = min(newValue, 100)
//        updateCartItemQuantity(quantity: clamped)
//        textValue = formatValue(clamped)
//        
//        let generator = UIImpactFeedbackGenerator(style: .light)
//        generator.impactOccurred()
//    }
//
//    private func handleMinus() {
//        // Check if going from 1 to 0
//        if currentQuantity <= 1 {
//            showingZeroQuantityAlert = true
//            pendingZeroQuantityUpdate = true
//            return
//        }
//        
//        let newValue: Double
//        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
//            newValue = floor(currentQuantity)
//        } else {
//            newValue = currentQuantity - 1
//        }
//
//        let clamped = max(newValue, 0)
//        updateCartItemQuantity(quantity: clamped)
//        textValue = formatValue(clamped)
//        
//        let generator = UIImpactFeedbackGenerator(style: .light)
//        generator.impactOccurred()
//    }
//    
//    private func commitTextField() {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//
//        if let number = formatter.number(from: textValue) {
//            let doubleValue = number.doubleValue
//            
//            // Check if value is 0
//            if doubleValue == 0 {
//                pendingZeroQuantityUpdate = true
//                showingZeroQuantityAlert = true
//                return
//            }
//            
//            let clamped = min(max(doubleValue, 0.01), 100) // Minimum 0.01
//            updateCartItemQuantity(quantity: clamped)
//
//            if doubleValue != clamped {
//                textValue = formatValue(clamped)
//            } else {
//                textValue = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
//            }
//        } else {
//            textValue = formatValue(currentQuantity)
//        }
//        isFocused = false
//    }
//    
//    private func formatValue(_ val: Double) -> String {
//        guard !val.isNaN && val.isFinite else {
//            return "0"
//        }
//        
//        if val <= 0 {
//            return "1" // Default to 1 instead of 0
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
//    private func addItemToCart(quantity: Double) {
//        if cart.isShopping {
//            vaultService.addShoppingItemToCart(
//                name: storeItem.item.name,
//                store: storeItem.priceOption.store,
//                price: storeItem.priceOption.pricePerUnit.priceValue,
//                unit: storeItem.priceOption.pricePerUnit.unit,
//                cart: cart,
//                quantity: quantity
//            )
//        } else {
//            vaultService.addVaultItemToCart(
//                item: storeItem.item,
//                cart: cart,
//                quantity: quantity,
//                selectedStore: storeItem.priceOption.store
//            )
//        }
//    }
//    
//    private func updateCartItemQuantity(quantity: Double) {
//        if quantity <= 0 {
//            // Remove item from cart
//            vaultService.removeItemFromCart(cart: cart, itemId: storeItem.item.id)
//        } else {
//            // Check if item already exists in cart
//            if let cartItem = cart.cartItems.first(where: { $0.itemId == storeItem.item.id }) {
//                // Update quantity of existing item
//                if cart.isShopping && cartItem.isFulfilled {
//                    cartItem.actualQuantity = quantity
//                } else {
//                    cartItem.quantity = quantity
//                }
//                vaultService.updateCartTotals(cart: cart)
//            } else {
//                // Add new item with specified quantity
//                addItemToCart(quantity: quantity)
//            }
//        }
//    }
//    
//    private var storeBadgeColor: Color {
//        let colors: [Color] = [
//            Color(hex: "4A90E2"),
//            Color(hex: "50E3C2"),
//            Color(hex: "B8E986"),
//            Color(hex: "F5A623"),
//            Color(hex: "D0021B"),
//            Color(hex: "9013FE"),
//            Color(hex: "8B572A"),
//        ]
//        
//        let hash = storeItem.priceOption.store.hash
//        let index = abs(hash) % colors.count
//        return colors[index]
//    }
//}

// MARK: - BrowseVaultItemRow (With Three-State Shopping Context)
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
    
    // Track if this is a shopping-only item
    private var isShoppingOnlyItem: Bool {
        storeItem.isShoppingOnlyItem
    }
    
    private var cartItem: CartItem? {
        cart.cartItems.first(where: {
            if isShoppingOnlyItem {
                // For shopping-only items, match by name and store
                return $0.isShoppingOnlyItem &&
                       $0.shoppingOnlyName?.lowercased() == storeItem.item.name.lowercased() &&
                       $0.shoppingOnlyStore?.lowercased() == storeItem.priceOption.store.lowercased()
            } else {
                // For Vault items, match by ID
                return $0.itemId == storeItem.item.id
            }
        })
    }
    
    // Determine the item's current state
    private var itemState: ItemState {
        guard let cartItem = cartItem else {
            return .inactive
        }
        
        if cartItem.isSkippedDuringShopping {
            return .skipped
        }
        
        // Check if it's actually in the cart (has quantity > 0)
        let quantity = cartItem.getQuantity(cart: cart)
        if quantity > 0 {
            return .active
        }
        
        // If it has a cartItem but quantity is 0, treat as skipped
        return .skipped
    }
    
    private var currentQuantity: Double {
        cartItem?.getQuantity(cart: cart) ?? 0
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            // State indicator (only for Active and Skipped states)
            if itemState != .inactive || !isShoppingOnlyItem {
                VStack {
                    Circle()
                        .fill(itemState == .active ? .green : .clear)
                        .frame(width: 9, height: 9)
                        .scaleEffect(itemState == .active  ? 1 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: itemState == .active)
                        .padding(.top, 8)
                    Spacer()
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Item details
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(storeItem.item.name)
                        .lexendFont(17)
                        .foregroundColor(itemState.textColor)
                        .opacity(itemState.contentOpacity)
                    
                    // State label (only for Active and Skipped)
                    if itemState != .inactive {
                        Text(itemState.labelText)
                            .lexendFont(11, weight: .medium)
                            .foregroundColor(itemState.labelColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(itemState.labelBackground)
                            .cornerRadius(4)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Shopping-only badge
                    if isShoppingOnlyItem {
                        Text("Temp")
                            .lexendFont(9, weight: .medium)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(3)
                    }
                }
                
                HStack(spacing: 0) {
                    Text("₱\(storeItem.priceOption.pricePerUnit.priceValue, specifier: "%g")")
                        .foregroundColor(itemState.priceColor)
                        .opacity(itemState.contentOpacity)
                    
                    Text("/\(storeItem.priceOption.pricePerUnit.unit)")
                        .foregroundColor(itemState.priceColor)
                        .opacity(itemState.contentOpacity)
                    
                    Text(" • \(storeItem.categoryName)")
                        .font(.caption)
                        .foregroundColor(itemState.priceColor.opacity(0.7))
                        .opacity(itemState.contentOpacity)
                    
                    Spacer()
                }
                .lexendFont(12)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemState)
            
            Spacer()
            
            // Quantity controls based on state
            HStack(spacing: 8) {
                switch itemState {
                case .active:
                    // Active: Show minus button and quantity field
                    minusButton
                        .transition(.scale.combined(with: .opacity))
                    quantityTextField
                        .transition(.scale.combined(with: .opacity))
                    plusButton
                    
                case .skipped:
                    // Skipped: Show only plus button to re-activate
                    if isShoppingOnlyItem {
                        // For shopping-only items, show remove button instead
                        removeButton
                    } else {
                        plusButton
                    }
//                        .transition(.scale.combined(with: .opacity))
                    
                case .inactive:
                    // Inactive: Show plus button to add
                    plusButton
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: itemState)
            .padding(.top, 6)
        }
        .padding(.bottom, 4)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.white)
        .scaleEffect(appearScale)
        .opacity(appearOpacity)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: itemState)
        .onTapGesture {
            if isFocused {
                isFocused = false
            }
        }
        .allowsHitTesting(!isFocused)
        .onChange(of: currentQuantity) { _, newValue in
            if !isFocused {
                textValue = formatValue(newValue)
            }
        }
        .onAppear {
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
        .onDisappear {
            isNewlyAdded = true
        }
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
        .disabled(currentQuantity <= 0 || isFocused)
        .opacity(currentQuantity <= 0 ? 0.5 : 1)
    }
    
    private var removeButton: some View {
        Button {
            // COMPLETELY REMOVE shopping-only item when inactive
            if let cartItem = cartItem, isShoppingOnlyItem {
                if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                    cart.cartItems.remove(at: index)
                    vaultService.updateCartTotals(cart: cart)
                    // Send notification to refresh BrowseVaultView
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShoppingDataUpdated"),
                        object: nil,
                        userInfo: ["cartItemId": cart.id]
                    )
                }
            }
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
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        commitTextField()
                    }
                }
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
        .disabled(isFocused)
    }
    
    private var plusButtonColor: Color {
        switch itemState {
        case .active:
            return Color(hex: "1E2A36")
        case .skipped:
            return .orange
        case .inactive:
            return Color(hex: "888888")
        }
    }
    
    private var plusButtonStrokeColor: Color {
        switch itemState {
        case .skipped:
            return .orange.opacity(0.3)
        case .inactive:
            return Color(hex: "F2F2F2").darker(by: 0.1)
        default:
            return .clear
        }
    }
    
    // MARK: - Quantity Handlers
    private func handlePlus() {
        switch itemState {
        case .active:
            // Increment quantity for active items
            let newValue: Double
            if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
                newValue = ceil(currentQuantity)
            } else {
                newValue = currentQuantity + 1
            }
            
            let clamped = min(newValue, 100)
            updateCartItemQuantity(quantity: clamped)
            textValue = formatValue(clamped)
            
        case .skipped:
            // Re-activate skipped item with quantity 1
            if let cartItem = cartItem {
                // Unskip the item
                cartItem.isSkippedDuringShopping = false
                cartItem.quantity = 1
                vaultService.updateCartTotals(cart: cart)
                textValue = "1"
            }
            
        case .inactive:
            // Add new item with quantity 1
            addItemToCart(quantity: 1)
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func handleMinus() {
        // For active items only
        guard itemState == .active else { return }
        
        let newValue: Double
        if currentQuantity <= 1 {
            // When reducing from 1 to 0
            if isShoppingOnlyItem {
                // For shopping-only items: COMPLETELY REMOVE
                if let cartItem = cartItem {
                    if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                        cart.cartItems.remove(at: index)
                        vaultService.updateCartTotals(cart: cart)
                        // Send notification to refresh BrowseVaultView
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ShoppingDataUpdated"),
                            object: nil,
                            userInfo: ["cartItemId": cart.id]
                        )
                    }
                }
            } else {
                // For Vault items: mark as skipped
                if let cartItem = cartItem {
                    cartItem.isSkippedDuringShopping = true
                    cartItem.quantity = 0
                    vaultService.updateCartTotals(cart: cart)
                    textValue = ""
                }
            }
            return
        } else if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
            newValue = floor(currentQuantity)
        } else {
            newValue = currentQuantity - 1
        }

        let clamped = max(newValue, 0)
        updateCartItemQuantity(quantity: clamped)
        textValue = formatValue(clamped)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func commitTextField() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        if let number = formatter.number(from: textValue) {
            let doubleValue = number.doubleValue
            
            // Handle zero quantity
            if doubleValue == 0 && itemState == .active {
                if isShoppingOnlyItem {
                    // For shopping-only items: COMPLETELY REMOVE
                    if let cartItem = cartItem {
                        if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                            cart.cartItems.remove(at: index)
                            vaultService.updateCartTotals(cart: cart)
                            // Send notification to refresh BrowseVaultView
                            NotificationCenter.default.post(
                                name: NSNotification.Name("ShoppingDataUpdated"),
                                object: nil,
                                userInfo: ["cartItemId": cart.id]
                            )
                        }
                    }
                } else {
                    // For Vault items: mark as skipped
                    if let cartItem = cartItem {
                        cartItem.isSkippedDuringShopping = true
                        cartItem.quantity = 0
                        vaultService.updateCartTotals(cart: cart)
                        textValue = ""
                    }
                }
                return
            }
            
            let clamped = min(max(doubleValue, 0.01), 100)
            updateCartItemQuantity(quantity: clamped)

            if doubleValue != clamped {
                textValue = formatValue(clamped)
            } else {
                textValue = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            textValue = formatValue(currentQuantity)
        }
        isFocused = false
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
    private func addItemToCart(quantity: Double) {
        if cart.isShopping {
            // Check if there's already a shopping-only item with same name and store
            let existingItem = cart.cartItems.first(where: {
                $0.isShoppingOnlyItem &&
                $0.shoppingOnlyName?.lowercased() == storeItem.item.name.lowercased() &&
                $0.shoppingOnlyStore?.lowercased() == storeItem.priceOption.store.lowercased()
            })
            
            if let existingItem = existingItem {
                // Reactivate existing shopping-only item
                existingItem.isSkippedDuringShopping = false
                existingItem.quantity = quantity
            } else {
                // Create new shopping-only item
                vaultService.addShoppingItemToCart(
                    name: storeItem.item.name,
                    store: storeItem.priceOption.store,
                    price: storeItem.priceOption.pricePerUnit.priceValue,
                    unit: storeItem.priceOption.pricePerUnit.unit,
                    cart: cart,
                    quantity: quantity
                )
            }
        } else {
            // Planning mode: add as Vault item
            vaultService.addVaultItemToCart(
                item: storeItem.item,
                cart: cart,
                quantity: quantity,
                selectedStore: storeItem.priceOption.store
            )
        }
    }
    
    private func updateCartItemQuantity(quantity: Double) {
        guard let cartItem = cartItem else { return }
        
        if quantity <= 0 {
            if isShoppingOnlyItem {
                // For shopping-only items: COMPLETELY REMOVE
                if let index = cart.cartItems.firstIndex(where: { $0.id == cartItem.id }) {
                    cart.cartItems.remove(at: index)
                    vaultService.updateCartTotals(cart: cart)
                    // Send notification to refresh BrowseVaultView
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShoppingDataUpdated"),
                        object: nil,
                        userInfo: ["cartItemId": cart.id]
                    )
                }
            } else {
                // For Vault items: mark as skipped
                cartItem.isSkippedDuringShopping = true
                cartItem.quantity = 0
                vaultService.updateCartTotals(cart: cart)
            }
        } else {
            // Update quantity of existing item
            cartItem.quantity = quantity
            cartItem.isSkippedDuringShopping = false
            vaultService.updateCartTotals(cart: cart)
        }
    }
}

// MARK: - Item State Enum
enum ItemState {
    case active
    case skipped
    case inactive
    
    var indicatorColor: Color {
        switch self {
        case .active: return storeBadgeColor
        case .skipped: return .orange.opacity(0.6)
        case .inactive: return .clear
        }
    }
    
    var textColor: Color {
        switch self {
        case .active: return .black
        case .skipped: return Color(hex: "666")
        case .inactive: return Color(hex: "333")
        }
    }
    
    var priceColor: Color {
        switch self {
        case .active: return .gray
        case .skipped: return Color(hex: "888")
        case .inactive: return Color(hex: "666")
        }
    }
    
    var contentOpacity: Double {
        switch self {
        case .active: return 1.0
        case .skipped: return 0.75  // 75% opacity for skipped items
        case .inactive: return 1.0
        }
    }
    
    var labelText: String {
        switch self {
        case .active: return "In cart"
        case .skipped: return "Skipped today"
        case .inactive: return ""
        }
    }
    
    var labelColor: Color {
        switch self {
        case .active: return .white
        case .skipped: return .orange
        case .inactive: return .clear
        }
    }
    
    var labelBackground: Color {
        switch self {
        case .active: return storeBadgeColor
        case .skipped: return .orange.opacity(0.1)
        case .inactive: return .clear
        }
    }
    
    // Helper for store badge color (used in indicator)
    private var storeBadgeColor: Color {
        // This would need access to storeItem, but we'll use a placeholder
        Color(hex: "4A90E2") // Default blue
    }
}



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

