//import SwiftUI
//import SwiftData
//
//struct ManageCartSheet: View {
//    let cart: Cart
//    @Environment(VaultService.self) private var vaultService
//    @Environment(CartViewModel.self) private var cartViewModel
//    @Environment(\.dismiss) private var dismiss
//    
//    @State private var selectedCategory: GroceryCategory?
//    @State private var toolbarAppeared = false
//    @State private var showAddItemPopover = false
//    @State private var createCartButtonVisible = true
//    
//    // Use LOCAL state for active items in this sheet
//    @State private var localActiveItems: [String: Double] = [:]
//    
//    // Add duplicate error state
//    @State private var duplicateError: String?
//    
//    // Add state to track vault changes and force updates
//    @State private var vaultUpdateTrigger = 0
//    
//    // Chevron navigation
//    @State private var showLeftChevron = false
//    @State private var showRightChevron = false
//    @State private var fillAnimation: CGFloat = 0.0
//    
//    // Track keyboard state
//    @FocusState private var isAnyFieldFocused: Bool
//    
//    // Keyboard responder
//    @State private var keyboardResponder = KeyboardResponder()
//    @State private var focusedItemId: String?
//    
//    private var hasActiveItems: Bool {
//        !localActiveItems.isEmpty
//    }
//    
//    // Computed property that reacts to vault changes
//    private var currentVault: Vault? {
//        vaultService.vault
//    }
//    
//    private var totalVaultItemsCount: Int {
//        guard let vault = vaultService.vault else { return 0 }
//        return vault.categories.reduce(0) { $0 + $1.items.count }
//    }
//    
//    //switching category transition
//    @State private var navigationDirection: NavigationDirection = .none
//    
//    enum NavigationDirection {
//        case left, right, none
//    }
//    
//    var body: some View {
//        NavigationStack {
//            ZStack(alignment: .bottom) {
//                // Main content
//                VStack(spacing: 0) {
//                    // Use currentVault instead of vaultService.vault directly
//                    if let vault = currentVault, !vault.categories.isEmpty {
//                        ZStack(alignment: .top) {
//                            categoryContentScrollView
//                                .frame(maxHeight: .infinity)
//                                .padding(.top, 56) // Height of category section
//                                .zIndex(0)
//                            
//                            VaultCategorySectionView(selectedCategory: selectedCategory) {
//                                categoryScrollView
//                            }
//                            .onTapGesture {
//                                UIApplication.shared.endEditing()
//                            }
//                            .zIndex(1)
//                        }
//                    } else {
//                        emptyVaultView
//                    }
//                }
//                
//                // Bottom action bar with chevrons
//                if currentVault != nil && !showAddItemPopover {
//                    bottomActionBar
//                }
//                
//                if showAddItemPopover {
//                    Color.clear
//                        .contentShape(Rectangle())
//                        .onTapGesture {
//                            withAnimation(.easeInOut(duration: 0.2)) {
//                                showAddItemPopover = false
//                            }
//                        }
//                    
//
//                    AddItemPopover(
//                        isPresented: $showAddItemPopover,
//                        createCartButtonVisible: $createCartButtonVisible,
//                        onSave: { itemName, category, store, unit, price in
//                            _ = vaultService.addItem(
//                                name: itemName,
//                                to: category,
//                                store: store,
//                                price: price,
//                                unit: unit
//                            )
//                            
//                        },
//                        onDismiss: {
//                            duplicateError = nil
//                        }
//                    )
//                    .offset(y: UIScreen.main.bounds.height * -0.04)
//                    .transition(.opacity)
//                    .zIndex(1)
//                }
//                
//                ZStack {
//                    if keyboardResponder.isVisible && focusedItemId != nil {
//                        KeyboardDoneButton(
//                            keyboardHeight: keyboardResponder.currentHeight,
//                            onDone: {
//                                UIApplication.shared.endEditing()
//                            }
//                        )
//                        .transition(.identity)
//                        .zIndex(10)
//                    }
//                }
//                .frame(maxHeight: .infinity)
//            }
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: {}) {
//                        Image("search")
//                            .resizable()
//                            .frame(width: 24, height: 24)
//                    }
//                }
//                
//                ToolbarItem(placement: .principal) {
//                    Text("Manage Cart")
//                        .font(.headline)
//                        .foregroundColor(.black)
//                }
//                
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        UIApplication.shared.endEditing()
//                        withAnimation(.easeInOut(duration: 0.2)) {
//                            showAddItemPopover = true
//                            duplicateError = nil // Clear previous errors
//                        }
//                    }) {
//                        Text("Add")
//                            .fuzzyBubblesFont(13, weight: .bold)
//                            .foregroundColor(.white)
//                            .padding(.horizontal, 10)
//                            .padding(.vertical, 4)
//                            .background(Color.black)
//                            .cornerRadius(20)
//                    }
//                }
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .background(.white)
//            .ignoresSafeArea(.keyboard)
//            .onAppear {
//                initializeActiveItemsFromCart()
//                if selectedCategory == nil {
//                    selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
//                }
//                updateChevronVisibility()
//            }
//            .onChange(of: vaultService.vault) { oldValue, newValue in
//                print("🔄 ManageCartSheet: Vault updated, refreshing view")
//                vaultUpdateTrigger += 1
//                
//                // Update selected category if the current one no longer has items
//                if let currentCategory = selectedCategory,
//                   !hasItems(in: currentCategory) {
//                    selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
//                }
//            }
//            .onChange(of: vaultUpdateTrigger) { oldValue, newValue in
//                // This forces the view to refresh when vault changes
//                print("🔄 ManageCartSheet: Refreshing view due to vault changes")
//            }
//            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemCategoryChanged"))) { notification in
//                if let newCategory = notification.userInfo?["newCategory"] as? GroceryCategory {
//                    print("🔄 ManageCartSheet: Received category change notification - switching to \(newCategory.title)")
//                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
//                        selectedCategory = newCategory
//                    }
//                }
//            }
//            .onChange(of: selectedCategory) { oldValue, newValue in
//                updateChevronVisibility()
//            }
//            .onChange(of: hasActiveItems) { oldValue, newValue in
//                if newValue {
//                    if !oldValue {
//                        withAnimation(.spring(duration: 0.4)) {
//                            fillAnimation = 1.0
//                        }
//                    }
//                } else {
//                    withAnimation(.easeInOut(duration: 0.3)) {
//                        fillAnimation = 0.0
//                    }
//                }
//            }
//            .onAppear {
//                if hasActiveItems {
//                    fillAnimation = 1.0
//                }
//            }
//            .preference(key: TextFieldFocusPreferenceKey.self, value: focusedItemId)
//        }
//        .presentationDragIndicator(.visible)
//        .presentationCornerRadius(24)
//    }
//    
//    private var categoryScrollView: some View {
//        ScrollViewReader { proxy in
//            ScrollView(.horizontal, showsIndicators: false) {
//                ZStack(alignment: .leading) {
//                    if let selectedCategory = selectedCategory,
//                       let selectedIndex = GroceryCategory.allCases.firstIndex(of: selectedCategory) {
//                        RoundedRectangle(cornerRadius: 10)
//                            .strokeBorder(Color.black, lineWidth: 2)
//                            .frame(width: 50, height: 50)
//                            .offset(x: CGFloat(selectedIndex) * 51)
//                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCategory)
//                    }
//                    
//                    HStack(spacing: 1) {
//                        ForEach(GroceryCategory.allCases, id: \.self) { category in  // FIXED: Changed GrocceryCategory to GroceryCategory
//                            VaultCategoryIcon(
//                                category: category,
//                                isSelected: selectedCategory == category,
//                                itemCount: getActiveItemCount(for: category),
//                                hasItems: hasItems(in: category),
//                                action: {
//                                    // Dismiss keyboard immediately when tapping category
//                                    UIApplication.shared.endEditing()
//                                    
//                                    // Set navigation direction
//                                    if let current = selectedCategory,
//                                       let currentIndex = GroceryCategory.allCases.firstIndex(of: current),
//                                       let newIndex = GroceryCategory.allCases.firstIndex(of: category) {
//                                        navigationDirection = newIndex > currentIndex ? .right : .left
//                                    }
//                                    selectCategory(category, proxy: proxy)
//                                }
//                            )                            .frame(width: 50, height: 50)
//                            .id(category.id)
//                        }
//                    }
//                }
//                .padding(.horizontal)
//            }
//            .onChange(of: selectedCategory) { oldValue, newValue in
//                if let newCategory = newValue {
//                    withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
//                        proxy.scrollTo(newCategory.id, anchor: .center)
//                    }
//                }
//            }
//            .onAppear {
//                if let initialCategory = selectedCategory ?? firstCategoryWithItems ?? GroceryCategory.allCases.first {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
//                            proxy.scrollTo(initialCategory.id, anchor: .center)
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
//    private var categoryContentScrollView: some View {
//        Group {
//            if let selectedCategory = selectedCategory {
//                CategoryItemsListView(
//                    category: selectedCategory,
//                    localActiveItems: $localActiveItems
//                )
//                .id(selectedCategory.id)
//                .padding(.top, 8)
//                .transition(.asymmetric(
//                    insertion: navigationDirection == .right ?
//                        .move(edge: .trailing) :
//                        .move(edge: .leading),
//                    removal: navigationDirection == .right ?
//                        .move(edge: .leading) :
//                        .move(edge: .trailing)
//                ))
//            }
//        }
//        .frame(maxHeight: .infinity)
//        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedCategory)
//    }
//    
//    private var bottomActionBar: some View {
//        VStack {
//            Spacer()
//            
//            HStack {
//                if showLeftChevron {
//                    Button(action: navigateToPreviousCategory) {
//                        Image(systemName: "chevron.left")
//                            .font(.system(size: 16, weight: .bold))
//                            .foregroundColor(.black)
//                            .frame(width: 44, height: 44)
//                            .background(
//                                Circle()
//                                    .fill(Material.thin)
//                                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
//                            )
//                    }
//                    .transition(.scale.combined(with: .opacity))
//                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showLeftChevron)
//                } else {
//                    Circle()
//                        .fill(Color.clear)
//                        .frame(width: 44, height: 44)
//                }
//                
//                Spacer()
//                
//                Button(action: {
//                    // Update the cart with selected items
//                    updateCartWithSelectedItems()
//                    dismiss()
//                }) {
//                    Text("Save")
//                        .fuzzyBubblesFont(16, weight: .bold)
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 24)
//                        .padding(.vertical, 12)
//                        .background(
//                            Capsule()
//                                .fill(
//                                    hasActiveItems
//                                    ? RadialGradient(
//                                        colors: [Color.black, Color.gray.opacity(0.3)],
//                                        center: .center,
//                                        startRadius: 0,
//                                        endRadius: fillAnimation * 300
//                                    )
//                                    : RadialGradient(
//                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
//                                        center: .center,
//                                        startRadius: 0,
//                                        endRadius: 0
//                                    )
//                                )
//                        )
//                        .cornerRadius(25)
//                }
//                .overlay(alignment: .topLeading, content: {
//                    if hasActiveItems {
//                        Text("\(localActiveItems.count)")
//                            .fuzzyBubblesFont(16, weight: .bold)
//                            .contentTransition(.numericText())
//                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: localActiveItems.count)
//                            .foregroundColor(.black)
//                            .frame(width: 25, height: 25)
//                            .background(Color.white)
//                            .clipShape(Circle())
//                            .overlay(
//                                Circle()
//                                    .stroke(Color.black, lineWidth: 2)
//                            )
//                            .offset(x: -8, y: -4)
//                    }
//                })
//                .buttonStyle(.solid)
//                .disabled(!hasActiveItems)
//                
//                Spacer()
//                
//                if showRightChevron {
//                    Button(action: navigateToNextCategory) {
//                        Image(systemName: "chevron.right")
//                            .font(.system(size: 16, weight: .bold))
//                            .foregroundColor(.black)
//                            .frame(width: 44, height: 44)
//                            .background(
//                                Circle()
//                                    .fill(Material.thin)
//                                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
//                            )
//                    }
//                    .transition(.scale.combined(with: .opacity))
//                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showRightChevron)
//                } else {
//                    Circle()
//                        .fill(Color.clear)
//                        .frame(width: 44, height: 44)
//                }
//            }
//            .padding(.horizontal, 20)
//            .padding(.bottom, 40)
//        }
//        .ignoresSafeArea(.all, edges: .bottom)
//    }
//    
//    private var emptyVaultView: some View {
//        VStack(spacing: 20) {
//            Spacer()
//            
//            Image(systemName: "shippingbox")
//                .font(.system(size: 60))
//                .foregroundColor(.gray)
//            
//            Text("Your vault is empty")
//                .font(.title2)
//                .foregroundColor(.gray)
//            
//            Text("No items available to add")
//                .font(.body)
//                .foregroundColor(.gray.opacity(0.8))
//            
//            Spacer()
//        }
//        .padding()
//    }
//    
//    // MARK: - Helper Methods
//    
//    private func initializeActiveItemsFromCart() {
//        print("🔄 ManageCartSheet: Initializing from cart '\(cart.name)'")
//        
//        // Clear any existing active items
//        localActiveItems.removeAll()
//        
//        // Add items from the existing cart to localActiveItems
//        for cartItem in cart.cartItems {
//            localActiveItems[cartItem.itemId] = cartItem.quantity
//            if let item = vaultService.findItemById(cartItem.itemId) {
//                print("   - Pre-selected: \(item.name) × \(cartItem.quantity)")
//            }
//        }
//        
//        print("   Total pre-selected items: \(localActiveItems.count)")
//    }
//    
//    private func updateCartWithSelectedItems() {
//        print("🔄 Updating cart with selected items")
//        
//        let selectedItemIds = Set(localActiveItems.keys)
//        let currentCartItemIds = Set(cart.cartItems.map { $0.itemId })
//        
//        // Remove items that were deselected OR have zero quantity
//        let itemsToRemove = currentCartItemIds.subtracting(selectedItemIds)
//        for itemId in itemsToRemove {
//            if let item = vaultService.findItemById(itemId) {
//                print("   🗑️ Removing: \(item.name)")
//                vaultService.removeItemFromCart(cart: cart, itemId: itemId)
//            }
//        }
//        
//        // Add/Update selected items
//        for (itemId, quantity) in localActiveItems {
//            if let item = vaultService.findItemById(itemId) {
//                if currentCartItemIds.contains(itemId) {
//                    // Update existing item quantity
//                    if let existingCartItem = cart.cartItems.first(where: { $0.itemId == itemId }) {
//                        if quantity > 0 {
//                            print("   🔄 Updating: \(item.name) from \(existingCartItem.quantity) to \(quantity)")
//                            existingCartItem.quantity = quantity
//                        } else {
//                            // Remove item if quantity is 0
//                            print("   🗑️ Removing (zero quantity): \(item.name)")
//                            vaultService.removeItemFromCart(cart: cart, itemId: itemId)
//                        }
//                    }
//                } else {
//                    // Add new item only if quantity > 0
//                    if quantity > 0 {
//                        print("   ➕ Adding: \(item.name) × \(quantity)")
//                        // CHANGED: Use addVaultItemToCart instead of addItemToCart
//                        vaultService.addVaultItemToCart(item: item, cart: cart, quantity: quantity)
//                    }
//                }
//            }
//        }
//        
//        vaultService.updateCartTotals(cart: cart)
//        print("   ✅ Final cart items: \(cart.cartItems.count)")
//    }
//    
//    private func selectCategory(_ category: GroceryCategory, proxy: ScrollViewProxy) {
//        // Set navigation direction
//        if let current = selectedCategory,
//           let currentIndex = GroceryCategory.allCases.firstIndex(of: current),
//           let newIndex = GroceryCategory.allCases.firstIndex(of: category) {
//            navigationDirection = newIndex > currentIndex ? .right : .left
//        }
//        
//        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//            selectedCategory = category
//        }
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                proxy.scrollTo(category.id, anchor: .center)
//            }
//        }
//    }
//    
//    private func updateChevronVisibility() {
//        guard let currentCategory = selectedCategory,
//              let currentIndex = GroceryCategory.allCases.firstIndex(of: currentCategory) else {
//            showLeftChevron = false
//            showRightChevron = false
//            return
//        }
//        
//        showLeftChevron = currentIndex > 0
//        showRightChevron = currentIndex < GroceryCategory.allCases.count - 1
//    }
//    
//    private func navigateToPreviousCategory() {
//        // Dismiss keyboard immediately
//        UIApplication.shared.endEditing()
//        
//        guard let currentCategory = selectedCategory,
//              let currentIndex = GroceryCategory.allCases.firstIndex(of: currentCategory),
//              currentIndex > 0 else { return }
//        
//        let previousCategory = GroceryCategory.allCases[currentIndex - 1]
//        navigationDirection = .left
//        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
//            selectedCategory = previousCategory
//        }
//    }
//    
//    private func navigateToNextCategory() {
//        // Dismiss keyboard immediately
//        UIApplication.shared.endEditing()
//        
//        guard let currentCategory = selectedCategory,
//              let currentIndex = GroceryCategory.allCases.firstIndex(of: currentCategory),
//              currentIndex < GroceryCategory.allCases.count - 1 else { return }
//        
//        let nextCategory = GroceryCategory.allCases[currentIndex + 1]
//        navigationDirection = .right
//        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
//            selectedCategory = nextCategory
//        }
//    }
//    
//    private var firstCategoryWithItems: GroceryCategory? {
//        guard let vault = vaultService.vault else { return nil }
//        
//        // Always check in GroceryCategory.allCases order, not vault.categories order
//        for groceryCategory in GroceryCategory.allCases {
//            if let vaultCategory = vault.categories.first(where: { $0.name == groceryCategory.title }),
//               !vaultCategory.items.isEmpty {
//                return groceryCategory
//            }
//        }
//        return nil
//    }
//    
//    private func getActiveItemCount(for category: GroceryCategory) -> Int {
//        guard let vault = vaultService.vault else { return 0 }
//        guard let foundCategory = vault.categories.first(where: { $0.name == category.title }) else { return 0 }
//        
//        let activeItemsCount = foundCategory.items.reduce(0) { count, item in
//            let isActive = (localActiveItems[item.id] ?? 0) > 0
//            return count + (isActive ? 1 : 0)
//        }
//        
//        return activeItemsCount
//    }
//    
//    private func getTotalItemCount(for category: GroceryCategory) -> Int {
//        guard let vault = vaultService.vault else { return 0 }
//        guard let foundCategory = vault.categories.first(where: { $0.name == category.title }) else { return 0 }
//        
//        return foundCategory.items.count
//    }
//    
//    private func hasItems(in category: GroceryCategory) -> Bool {
//        return getTotalItemCount(for: category) > 0
//    }
//}
//
//struct CategoryItemsListView: View {
//    let category: GroceryCategory
//    @Binding var localActiveItems: [String: Double]
//    
//    @Environment(VaultService.self) private var vaultService
//    @State private var focusedItemId: String?
//    
//    // Store availableStores as @State
//    @State private var currentStores: [String] = []
//    
//    private var categoryItems: [Item] {
//        guard let vault = vaultService.vault,
//              let foundCategory = vault.categories.first(where: { $0.name == category.title })
//        else { return [] }
//        
//        return foundCategory.items.sorted { $0.createdAt > $1.createdAt }
//    }
//    
//    var body: some View {
//        Group {
//            if categoryItems.isEmpty {
//                emptyCategoryView
//            } else {
//                ManageCartItemsListView(
//                    items: categoryItems,
//                    availableStores: currentStores,
//                    category: category,
//                    localActiveItems: $localActiveItems
//                )
//            }
//        }
//        .preference(key: TextFieldFocusPreferenceKey.self, value: focusedItemId)
//        .onAppear {
//            updateStores()
//        }
//        .onChange(of: vaultService.vault) { oldValue, newValue in
//            updateStores()
//        }
//        // Also watch for when items count changes
//        .onChange(of: categoryItems.count) { oldCount, newCount in
//            updateStores()
//        }
//    }
//    
//    private func updateStores() {
//        let allStores = categoryItems.flatMap { item in
//            item.priceOptions.map { $0.store }
//        }
//        let newStores = Array(Set(allStores)).sorted()
//        
//        if newStores != currentStores {
//            print("🔄 Stores updated: \(newStores)")
//            currentStores = newStores
//        }
//    }
//    
//    private var emptyCategoryView: some View {
//        VStack {
//            Spacer()
//            Text("No items in this category")
//                .foregroundColor(.gray)
//            Spacer()
//        }
//    }
//}
//
//
//// MARK: - Items List View for Manage Cart (with native swipe gestures)
//struct ManageCartItemsListView: View {
//    let items: [Item]
//    let availableStores: [String]
//    let category: GroceryCategory?
//    @Binding var localActiveItems: [String: Double]
//    
//    @State private var focusedItemId: String?
//    
//    @State private var previousStores: [String] = []
//    
//    var body: some View {
//        List {
//            // Add top padding for the list items
//            Color.clear
//                .frame(height: 8)
//                .listRowInsets(EdgeInsets())
//                .listRowSeparator(.hidden)
//                .listRowBackground(Color.clear)
//            
//            ForEach(availableStores, id: \.self) { store in
//                ManageCartStoreSection(
//                    storeName: store,
//                    items: itemsForStore(store),
//                    category: category,
//                    localActiveItems: $localActiveItems
//                )
//                .animation(
//                                 previousStores.contains(store) ? nil : .spring(response: 0.3, dampingFraction: 0.7),
//                                 value: store
//                             )
//            }
//            
//            // Add bottom padding
//            Color.clear
//                .frame(height: 100)
//                .listRowInsets(EdgeInsets())
//                .listRowSeparator(.hidden)
//                .listRowBackground(Color.clear)
//        }
//        .listStyle(PlainListStyle())
//        .listSectionSpacing(16)
//        .preference(key: TextFieldFocusPreferenceKey.self, value: focusedItemId)
//        .onAppear {
//                   previousStores = availableStores
//               }
//               .onChange(of: availableStores) { oldStores, newStores in
//                   // Update previous stores
//                   previousStores = oldStores
//               }
//    }
//    
//    private func itemsForStore(_ store: String) -> [Item] {
//        items.filter { item in
//            item.priceOptions.contains { $0.store == store }
//        }
//    }
//}
//
//// MARK: - Store Section for Manage Cart
//struct ManageCartStoreSection: View {
//    let storeName: String
//    let items: [Item]
//    let category: GroceryCategory?
//    @Binding var localActiveItems: [String: Double]
//    
//    private var itemsWithStableIdentifiers: [(id: String, item: Item)] {
//        items.map { ($0.id, $0) }
//    }
//    
//    var body: some View {
//        Section(
//            header: HStack {
//                Text(storeName)
//                    .fuzzyBubblesFont(11, weight: .bold)
//                    .foregroundStyle(.white)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 3)
//                    .background(category?.pastelColor.saturated(by: 0.3).darker(by: 0.5) ?? Color.primary)
//                    .clipShape(RoundedRectangle(cornerRadius: 6))
//                Spacer()
//            }
//                .padding(.leading)
//                .listRowInsets(EdgeInsets())
//        ) {
//            ForEach(itemsWithStableIdentifiers, id: \.id) { tuple in
//                VStack(spacing: 0) {
//                    ManageCartItemRow(
//                        item: tuple.item,
//                        category: category,
//                        localActiveItems: $localActiveItems
//                    )
//                    
//                    // Native swipe gesture using .swipeActions modifier
//                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                        Button(role: .destructive) {
//                            // Remove from local active items
//                            localActiveItems.removeValue(forKey: tuple.item.id)
//                        } label: {
//                            Label("Remove", systemImage: "trash")
//                        }
//                    }
//                    
//                    if tuple.id != itemsWithStableIdentifiers.last?.id {
//                        DashedLine()
//                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
//                            .frame(height: 1)
//                            .foregroundColor(Color(hex: "ddd"))
//                            .padding(.horizontal, 16)
//                            .padding(.leading, 14)
//                    }
//                }
//                .listRowInsets(EdgeInsets())
//                .listRowSeparator(.hidden)
//                .transition(.asymmetric(
//                    insertion: .move(edge: .top)
//                        .combined(with: .opacity)
//                        .combined(with: .scale(scale: 0.95, anchor: .top)),
//                    removal: .move(edge: .leading)
//                        .combined(with: .opacity)
//                ))
//                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: itemsWithStableIdentifiers.map { $0.id })
//            }
//        }
//    }
//}
//
//// MARK: - Item Row for Manage Cart (clean version without custom swipe)
//struct ManageCartItemRow: View {
//    let item: Item
//    let category: GroceryCategory?
//    @Binding var localActiveItems: [String: Double]
//    
//    @Environment(VaultService.self) private var vaultService
//    @State private var showEditSheet = false
//    @State private var textValue: String = ""
//    @FocusState private var isFocused: Bool
//    
//    // Animation states
//    @State private var isNewlyAdded = true
//    @State private var appearScale: CGFloat = 0.8
//    @State private var appearOpacity: Double = 0
//    
//    private var currentQuantity: Double {
//        localActiveItems[item.id] ?? 0
//    }
//    
//    private var isActive: Bool {
//        currentQuantity > 0
//    }
//    
//    var body: some View {
//        HStack(alignment: .bottom, spacing: 4) {
//            VStack {
//                Circle()
//                    .fill(isActive ? (category?.pastelColor.saturated(by: 0.3).darker(by: 0.5) ?? Color.primary) : .clear)
//                    .frame(width: 9, height: 9)
//                    .scaleEffect(isActive ? 1 : 0)
//                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)
//                    .padding(.top, 8)
//
//                Spacer()
//            }
//            
//            VStack(alignment: .leading, spacing: 0) {
//                Text(item.name)
//                    .foregroundColor(isActive ? .black : Color(hex: "999"))
//                    .lexendFont(17)
//                
//                if let priceOption = item.priceOptions.first {
//                    HStack(spacing: 0) {
//                        Text("₱\(priceOption.pricePerUnit.priceValue, specifier: "%g")")
//                        Text("/\(priceOption.pricePerUnit.unit)")
//                        Spacer()
//                    }
//                    .lexendFont(12)
//                    .foregroundColor(isActive ? .black : Color(hex: "999"))
//                }
//            }
//            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
//            
//            Spacer()
//            
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
//            if !isFocused {
//                showEditSheet = true
//            }
//        }
//        .sheet(isPresented: $showEditSheet) {
//            EditItemSheet(
//                item: item,
//                onSave: { updatedItem in
//                    print("✅ Updated item: \(updatedItem.name)")
//                }
//            )
//            .environment(vaultService)
//            .presentationDetents([.medium, .fraction(0.75)])
//            .presentationCornerRadius(24)
//        }
//        .contextMenu {
//            Button(role: .destructive) {
//                localActiveItems.removeValue(forKey: item.id)
//            } label: {
//                Label("Remove from Cart", systemImage: "trash")
//            }
//            
//            Button {
//                showEditSheet = true
//            } label: {
//                Label("Edit", systemImage: "pencil")
//            }
//        }
//        .onChange(of: currentQuantity) { oldValue, newValue in
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
//        .preference(key: TextFieldFocusPreferenceKey.self, value: isFocused ? item.id : nil)
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
//        .disabled(currentQuantity <= 0)
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
//                .onChange(of: isFocused) { oldValue, focused in
//                    if !focused {
//                        commitTextField()
//                    }
//                }
//                .onChange(of: textValue) { oldValue, newText in
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
//    private var plusButton: some View {
//        Button(action: {
//            if isActive {
//                handlePlus()
//            } else {
//                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                    localActiveItems[item.id] = 1
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
//        localActiveItems[item.id] = clamped
//        textValue = formatValue(clamped)
//    }
//    
//    private func handleMinus() {
//        let newValue: Double
//        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
//            newValue = floor(currentQuantity)
//        } else {
//            newValue = currentQuantity - 1
//        }
//        
//        let clamped = max(newValue, 0)
//        localActiveItems[item.id] = clamped
//        textValue = formatValue(clamped)
//    }
//    
//    private func commitTextField() {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//        
//        if let number = formatter.number(from: textValue) {
//            let doubleValue = number.doubleValue
//            let clamped = min(max(doubleValue, 0), 100)
//            localActiveItems[item.id] = clamped
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
//        if val.truncatingRemainder(dividingBy: 1) == 0 {
//            return String(format: "%.0f", val)
//        } else {
//            var result = String(format: "%.2f", val)
//            while result.last == "0" { result.removeLast() }
//            if result.last == "." { result.removeLast() }
//            return result
//        }
//    }
//}


import SwiftUI
import SwiftData

struct ManageCartSheet: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: GroceryCategory?
    @State private var toolbarAppeared = false
    @State private var showAddItemPopover = false
    @State private var createCartButtonVisible = true
    
    // Use LOCAL state for active items in this sheet
    @State private var localActiveItems: [String: Double] = [:]
    
    // Add duplicate error state
    @State private var duplicateError: String?
    
    // Add state to track vault changes and force updates
    @State private var vaultUpdateTrigger = 0
    
    // Chevron navigation
    @State private var showLeftChevron = false
    @State private var showRightChevron = false
    @State private var fillAnimation: CGFloat = 0.0
    
    // Track keyboard state
    @FocusState private var isAnyFieldFocused: Bool
    
    // Keyboard responder
    @State private var keyboardResponder = KeyboardResponder()
    @State private var focusedItemId: String?
    
    private var hasActiveItems: Bool {
        !localActiveItems.isEmpty
    }
    
    // Computed property that reacts to vault changes
    private var currentVault: Vault? {
        vaultService.vault
    }
    
    private var totalVaultItemsCount: Int {
        guard let vault = vaultService.vault else { return 0 }
        return vault.categories.reduce(0) { $0 + $1.items.count }
    }
    
    //switching category transition
    @State private var navigationDirection: NavigationDirection = .none
    
    enum NavigationDirection {
        case left, right, none
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            VStack(spacing: 0) {
                // Custom Header
                CustomHeaderView(
                    showAddItemPopover: $showAddItemPopover,
                    duplicateError: $duplicateError
                )
                
                // Use currentVault instead of vaultService.vault directly
                if let vault = currentVault, !vault.categories.isEmpty {
                    ZStack(alignment: .top) {
                        categoryContentScrollView
                            .frame(maxHeight: .infinity)
                            .padding(.top, 56) // Height of category section
                            .zIndex(0)
                        
                        VaultCategorySectionView(selectedCategory: selectedCategory) {
                            categoryScrollView
                        }
                        .onTapGesture {
                            UIApplication.shared.endEditing()
                        }
                        .zIndex(1)
                    }
                } else {
                    emptyVaultView
                }
            }
            
            // Bottom action bar with chevrons
            if currentVault != nil && !showAddItemPopover {
                bottomActionBar
            }
            
            if showAddItemPopover {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAddItemPopover = false
                        }
                    }
                

                AddItemPopover(
                    isPresented: $showAddItemPopover,
                    createCartButtonVisible: $createCartButtonVisible,
                    onSave: { itemName, category, store, unit, price in
                        _ = vaultService.addItem(
                            name: itemName,
                            to: category,
                            store: store,
                            price: price,
                            unit: unit
                        )
                        
                    },
                    onDismiss: {
                        duplicateError = nil
                    }
                )
                .offset(y: UIScreen.main.bounds.height * -0.04)
                .transition(.opacity)
                .zIndex(1)
            }
            
            ZStack {
                if keyboardResponder.isVisible && focusedItemId != nil {
                    KeyboardDoneButton(
                        keyboardHeight: keyboardResponder.currentHeight,
                        onDone: {
                            UIApplication.shared.endEditing()
                        }
                    )
                    .transition(.identity)
                    .zIndex(10)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .navigationBarHidden(true) // Hide native navigation bar
        .background(.white)
        .ignoresSafeArea(.keyboard)
        .onAppear {
            initializeActiveItemsFromCart()
            if selectedCategory == nil {
                selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
            }
            updateChevronVisibility()
        }
        .onChange(of: vaultService.vault) { oldValue, newValue in
            print("🔄 ManageCartSheet: Vault updated, refreshing view")
            vaultUpdateTrigger += 1
            
            // Update selected category if the current one no longer has items
            if let currentCategory = selectedCategory,
               !hasItems(in: currentCategory) {
                selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
            }
        }
        .onChange(of: vaultUpdateTrigger) { oldValue, newValue in
            // This forces the view to refresh when vault changes
            print("🔄 ManageCartSheet: Refreshing view due to vault changes")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemCategoryChanged"))) { notification in
            if let newCategory = notification.userInfo?["newCategory"] as? GroceryCategory {
                print("🔄 ManageCartSheet: Received category change notification - switching to \(newCategory.title)")
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedCategory = newCategory
                }
            }
        }
        .onChange(of: selectedCategory) { oldValue, newValue in
            updateChevronVisibility()
        }
        .onChange(of: hasActiveItems) { oldValue, newValue in
            if newValue {
                if !oldValue {
                    withAnimation(.spring(duration: 0.4)) {
                        fillAnimation = 1.0
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    fillAnimation = 0.0
                }
            }
        }
        .onAppear {
            if hasActiveItems {
                fillAnimation = 1.0
            }
        }
        .preference(key: TextFieldFocusPreferenceKey.self, value: focusedItemId)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
    
    private var categoryScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    if let selectedCategory = selectedCategory,
                       let selectedIndex = GroceryCategory.allCases.firstIndex(of: selectedCategory) {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.black, lineWidth: 2)
                            .frame(width: 50, height: 50)
                            .offset(x: CGFloat(selectedIndex) * 51)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCategory)
                    }
                    
                    HStack(spacing: 1) {
                        ForEach(GroceryCategory.allCases, id: \.self) { category in
                            VaultCategoryIcon(
                                category: category,
                                isSelected: selectedCategory == category,
                                itemCount: getActiveItemCount(for: category),
                                hasItems: hasItems(in: category),
                                action: {
                                    // Dismiss keyboard immediately when tapping category
                                    UIApplication.shared.endEditing()
                                    
                                    // Set navigation direction
                                    if let current = selectedCategory,
                                       let currentIndex = GroceryCategory.allCases.firstIndex(of: current),
                                       let newIndex = GroceryCategory.allCases.firstIndex(of: category) {
                                        navigationDirection = newIndex > currentIndex ? .right : .left
                                    }
                                    selectCategory(category, proxy: proxy)
                                }
                            )
                            .frame(width: 50, height: 50)
                            .id(category.id)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: selectedCategory) { oldValue, newValue in
                if let newCategory = newValue {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                        proxy.scrollTo(newCategory.id, anchor: .center)
                    }
                }
            }
            .onAppear {
                if let initialCategory = selectedCategory ?? firstCategoryWithItems ?? GroceryCategory.allCases.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            proxy.scrollTo(initialCategory.id, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private var categoryContentScrollView: some View {
        Group {
            if let selectedCategory = selectedCategory {
                CategoryItemsListView(
                    category: selectedCategory,
                    localActiveItems: $localActiveItems
                )
                .id(selectedCategory.id)
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: navigationDirection == .right ?
                        .move(edge: .trailing) :
                        .move(edge: .leading),
                    removal: navigationDirection == .right ?
                        .move(edge: .leading) :
                        .move(edge: .trailing)
                ))
            }
        }
        .frame(maxHeight: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedCategory)
    }
    
    private var bottomActionBar: some View {
        VStack {
            Spacer()
            
            HStack {
                if showLeftChevron {
                    Button(action: navigateToPreviousCategory) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Material.thin)
                                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showLeftChevron)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                Button(action: {
                    // Update the cart with selected items
                    updateCartWithSelectedItems()
                    dismiss()
                }) {
                    Text("Save")
                        .fuzzyBubblesFont(16, weight: .bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(
                                    hasActiveItems
                                    ? RadialGradient(
                                        colors: [Color.black, Color.gray.opacity(0.3)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: fillAnimation * 300
                                    )
                                    : RadialGradient(
                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 0
                                    )
                                )
                        )
                        .cornerRadius(25)
                }
                .overlay(alignment: .topLeading, content: {
                    if hasActiveItems {
                        Text("\(localActiveItems.count)")
                            .fuzzyBubblesFont(16, weight: .bold)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: localActiveItems.count)
                            .foregroundColor(.black)
                            .frame(width: 25, height: 25)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: -8, y: -4)
                    }
                })
                .buttonStyle(.solid)
                .disabled(!hasActiveItems)
                
                Spacer()
                
                if showRightChevron {
                    Button(action: navigateToNextCategory) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Material.thin)
                                    .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showRightChevron)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    private var emptyVaultView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "shippingbox")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Your vault is empty")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("No items available to add")
                .font(.body)
                .foregroundColor(.gray.opacity(0.8))
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func initializeActiveItemsFromCart() {
        print("🔄 ManageCartSheet: Initializing from cart '\(cart.name)'")
        
        // Clear any existing active items
        localActiveItems.removeAll()
        
        // Add items from the existing cart to localActiveItems
        for cartItem in cart.cartItems {
            localActiveItems[cartItem.itemId] = cartItem.quantity
            if let item = vaultService.findItemById(cartItem.itemId) {
                print("   - Pre-selected: \(item.name) × \(cartItem.quantity)")
            }
        }
        
        print("   Total pre-selected items: \(localActiveItems.count)")
    }
    
    private func updateCartWithSelectedItems() {
        print("🔄 Updating cart with selected items")
        
        let selectedItemIds = Set(localActiveItems.keys)
        let currentCartItemIds = Set(cart.cartItems.map { $0.itemId })
        
        // Remove items that were deselected OR have zero quantity
        let itemsToRemove = currentCartItemIds.subtracting(selectedItemIds)
        for itemId in itemsToRemove {
            if let item = vaultService.findItemById(itemId) {
                print("   🗑️ Removing: \(item.name)")
                vaultService.removeItemFromCart(cart: cart, itemId: itemId)
            }
        }
        
        // Add/Update selected items
        for (itemId, quantity) in localActiveItems {
            if let item = vaultService.findItemById(itemId) {
                if currentCartItemIds.contains(itemId) {
                    // Update existing item quantity
                    if let existingCartItem = cart.cartItems.first(where: { $0.itemId == itemId }) {
                        if quantity > 0 {
                            print("   🔄 Updating: \(item.name) from \(existingCartItem.quantity) to \(quantity)")
                            existingCartItem.quantity = quantity
                        } else {
                            // Remove item if quantity is 0
                            print("   🗑️ Removing (zero quantity): \(item.name)")
                            vaultService.removeItemFromCart(cart: cart, itemId: itemId)
                        }
                    }
                } else {
                    // Add new item only if quantity > 0
                    if quantity > 0 {
                        print("   ➕ Adding: \(item.name) × \(quantity)")
                        // CHANGED: Use addVaultItemToCart instead of addItemToCart
                        vaultService.addVaultItemToCart(item: item, cart: cart, quantity: quantity)
                    }
                }
            }
        }
        
        vaultService.updateCartTotals(cart: cart)
        print("   ✅ Final cart items: \(cart.cartItems.count)")
    }
    
    private func selectCategory(_ category: GroceryCategory, proxy: ScrollViewProxy) {
        // Set navigation direction
        if let current = selectedCategory,
           let currentIndex = GroceryCategory.allCases.firstIndex(of: current),
           let newIndex = GroceryCategory.allCases.firstIndex(of: category) {
            navigationDirection = newIndex > currentIndex ? .right : .left
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedCategory = category
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                proxy.scrollTo(category.id, anchor: .center)
            }
        }
    }
    
    private func updateChevronVisibility() {
        guard let currentCategory = selectedCategory,
              let currentIndex = GroceryCategory.allCases.firstIndex(of: currentCategory) else {
            showLeftChevron = false
            showRightChevron = false
            return
        }
        
        showLeftChevron = currentIndex > 0
        showRightChevron = currentIndex < GroceryCategory.allCases.count - 1
    }
    
    private func navigateToPreviousCategory() {
        // Dismiss keyboard immediately
        UIApplication.shared.endEditing()
        
        guard let currentCategory = selectedCategory,
              let currentIndex = GroceryCategory.allCases.firstIndex(of: currentCategory),
              currentIndex > 0 else { return }
        
        let previousCategory = GroceryCategory.allCases[currentIndex - 1]
        navigationDirection = .left
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedCategory = previousCategory
        }
    }
    
    private func navigateToNextCategory() {
        // Dismiss keyboard immediately
        UIApplication.shared.endEditing()
        
        guard let currentCategory = selectedCategory,
              let currentIndex = GroceryCategory.allCases.firstIndex(of: currentCategory),
              currentIndex < GroceryCategory.allCases.count - 1 else { return }
        
        let nextCategory = GroceryCategory.allCases[currentIndex + 1]
        navigationDirection = .right
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedCategory = nextCategory
        }
    }
    
    private var firstCategoryWithItems: GroceryCategory? {
        guard let vault = vaultService.vault else { return nil }
        
        // Always check in GroceryCategory.allCases order, not vault.categories order
        for groceryCategory in GroceryCategory.allCases {
            if let vaultCategory = vault.categories.first(where: { $0.name == groceryCategory.title }),
               !vaultCategory.items.isEmpty {
                return groceryCategory
            }
        }
        return nil
    }
    
    private func getActiveItemCount(for category: GroceryCategory) -> Int {
        guard let vault = vaultService.vault else { return 0 }
        guard let foundCategory = vault.categories.first(where: { $0.name == category.title }) else { return 0 }
        
        let activeItemsCount = foundCategory.items.reduce(0) { count, item in
            let isActive = (localActiveItems[item.id] ?? 0) > 0
            return count + (isActive ? 1 : 0)
        }
        
        return activeItemsCount
    }
    
    private func getTotalItemCount(for category: GroceryCategory) -> Int {
        guard let vault = vaultService.vault else { return 0 }
        guard let foundCategory = vault.categories.first(where: { $0.name == category.title }) else { return 0 }
        
        return foundCategory.items.count
    }
    
    private func hasItems(in category: GroceryCategory) -> Bool {
        return getTotalItemCount(for: category) > 0
    }
}

// MARK: - Custom Header View
private struct CustomHeaderView: View {
    @Binding var showAddItemPopover: Bool
    @Binding var duplicateError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Search button
                Button(action: {
                    // Search action
                }) {
                    Image("search")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                // Title
                Text("Manage Cart")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Spacer()
                
                // Add button
                Button(action: {
                    UIApplication.shared.endEditing()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAddItemPopover = true
                        duplicateError = nil // Clear previous errors
                    }
                }) {
                    Text("Add")
                        .fuzzyBubblesFont(13, weight: .bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black)
                        .cornerRadius(20)
                }
                .padding(.trailing, 16)
            }
            .frame(height: 44)
            .padding(.top, 10)
            
        }
        .background(Color.white)
    }
}

struct CategoryItemsListView: View {
    let category: GroceryCategory
    @Binding var localActiveItems: [String: Double]
    
    @Environment(VaultService.self) private var vaultService
    @State private var focusedItemId: String?
    
    // Store availableStores as @State
    @State private var currentStores: [String] = []
    
    private var categoryItems: [Item] {
        guard let vault = vaultService.vault,
              let foundCategory = vault.categories.first(where: { $0.name == category.title })
        else { return [] }
        
        return foundCategory.items.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        Group {
            if categoryItems.isEmpty {
                emptyCategoryView
            } else {
                ManageCartItemsListView(
                    items: categoryItems,
                    availableStores: currentStores,
                    category: category,
                    localActiveItems: $localActiveItems
                )
            }
        }
        .preference(key: TextFieldFocusPreferenceKey.self, value: focusedItemId)
        .onAppear {
            updateStores()
        }
        .onChange(of: vaultService.vault) { oldValue, newValue in
            updateStores()
        }
        // Also watch for when items count changes
        .onChange(of: categoryItems.count) { oldCount, newCount in
            updateStores()
        }
    }
    
    private func updateStores() {
        let allStores = categoryItems.flatMap { item in
            item.priceOptions.map { $0.store }
        }
        let newStores = Array(Set(allStores)).sorted()
        
        if newStores != currentStores {
            print("🔄 Stores updated: \(newStores)")
            currentStores = newStores
        }
    }
    
    private var emptyCategoryView: some View {
        VStack {
            Spacer()
            Text("No items in this category")
                .foregroundColor(.gray)
            Spacer()
        }
    }
}


// MARK: - Items List View for Manage Cart (with native swipe gestures)
struct ManageCartItemsListView: View {
    let items: [Item]
    let availableStores: [String]
    let category: GroceryCategory?
    @Binding var localActiveItems: [String: Double]
    
    @State private var focusedItemId: String?
    
    @State private var previousStores: [String] = []
    
    var body: some View {
        List {
            // Add top padding for the list items
            Color.clear
                .frame(height: 8)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            
            ForEach(availableStores, id: \.self) { store in
                ManageCartStoreSection(
                    storeName: store,
                    items: itemsForStore(store),
                    category: category,
                    localActiveItems: $localActiveItems
                )
                .animation(
                    previousStores.contains(store) ? nil : .spring(response: 0.3, dampingFraction: 0.7),
                    value: store
                )
            }
            
            // Add bottom padding
            Color.clear
                .frame(height: 100)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
        .listStyle(PlainListStyle())
        .listSectionSpacing(16)
        .preference(key: TextFieldFocusPreferenceKey.self, value: focusedItemId)
        .onAppear {
            previousStores = availableStores
        }
        .onChange(of: availableStores) { oldStores, newStores in
            // Update previous stores
            previousStores = oldStores
        }
    }
    
    private func itemsForStore(_ store: String) -> [Item] {
        items.filter { item in
            item.priceOptions.contains { $0.store == store }
        }
    }
}

// MARK: - Store Section for Manage Cart
struct ManageCartStoreSection: View {
    let storeName: String
    let items: [Item]
    let category: GroceryCategory?
    @Binding var localActiveItems: [String: Double]
    
    private var itemsWithStableIdentifiers: [(id: String, item: Item)] {
        items.map { ($0.id, $0) }
    }
    
    var body: some View {
        Section(
            header: HStack {
                Text(storeName)
                    .fuzzyBubblesFont(11, weight: .bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(category?.pastelColor.saturated(by: 0.3).darker(by: 0.5) ?? Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Spacer()
            }
            .padding(.leading)
            .listRowInsets(EdgeInsets())
        ) {
            ForEach(itemsWithStableIdentifiers, id: \.id) { tuple in
                VStack(spacing: 0) {
                    ManageCartItemRow(
                        item: tuple.item,
                        category: category,
                        localActiveItems: $localActiveItems
                    )
                    
                    // Native swipe gesture using .swipeActions modifier
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            // Remove from local active items
                            localActiveItems.removeValue(forKey: tuple.item.id)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                    
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

// MARK: - Item Row for Manage Cart (clean version without custom swipe)
struct ManageCartItemRow: View {
    let item: Item
    let category: GroceryCategory?
    @Binding var localActiveItems: [String: Double]
    
    @Environment(VaultService.self) private var vaultService
    @State private var showEditSheet = false
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    // Animation states
    @State private var isNewlyAdded = true
    @State private var appearScale: CGFloat = 0.8
    @State private var appearOpacity: Double = 0
    
    private var currentQuantity: Double {
        localActiveItems[item.id] ?? 0
    }
    
    private var isActive: Bool {
        currentQuantity > 0
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            VStack {
                Circle()
                    .fill(isActive ? (category?.pastelColor.saturated(by: 0.3).darker(by: 0.5) ?? Color.primary) : .clear)
                    .frame(width: 9, height: 9)
                    .scaleEffect(isActive ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)
                    .padding(.top, 8)

                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .foregroundColor(isActive ? .black : Color(hex: "999"))
                    .lexendFont(17)
                
                if let priceOption = item.priceOptions.first {
                    HStack(spacing: 0) {
                        Text("₱\(priceOption.pricePerUnit.priceValue, specifier: "%g")")
                        Text("/\(priceOption.pricePerUnit.unit)")
                        Spacer()
                    }
                    .lexendFont(12)
                    .foregroundColor(isActive ? .black : Color(hex: "999"))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            
            Spacer()
            
            HStack(spacing: 8) {
                if isActive {
                    minusButton
                        .transition(.scale.combined(with: .opacity))
                    quantityTextField
                        .transition(.scale.combined(with: .opacity))
                }
                plusButton
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isActive)
            .padding(.top, 6)
        }
        .padding(.bottom, 4)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.white)
        .scaleEffect(appearScale)
        .opacity(appearOpacity)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
        .onTapGesture {
            if !isFocused {
                showEditSheet = true
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditItemSheet(
                item: item,
                onSave: { updatedItem in
                    print("✅ Updated item: \(updatedItem.name)")
                }
            )
            .environment(vaultService)
            .presentationDetents([.medium, .fraction(0.75)])
            .presentationCornerRadius(24)
        }
        .contextMenu {
            Button(role: .destructive) {
                localActiveItems.removeValue(forKey: item.id)
            } label: {
                Label("Remove from Cart", systemImage: "trash")
            }
            
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
        .onChange(of: currentQuantity) { oldValue, newValue in
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
        .preference(key: TextFieldFocusPreferenceKey.self, value: isFocused ? item.id : nil)
    }
    
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
                .onChange(of: isFocused) { oldValue, focused in
                    if !focused {
                        commitTextField()
                    }
                }
                .onChange(of: textValue) { oldValue, newText in
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
        Button(action: {
            if isActive {
                handlePlus()
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    localActiveItems[item.id] = 1
                }
            }
        }) {
            Image(systemName: "plus")
                .font(.footnote)
                .bold()
                .foregroundColor(isActive ? Color(hex: "1E2A36") : Color(hex: "888888"))
        }
        .frame(width: 24, height: 24)
        .background(.white)
        .clipShape(Circle())
        .contentShape(Circle())
        .buttonStyle(.plain)
        .disabled(isFocused)
    }
    
    private func handlePlus() {
        let newValue: Double
        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
            newValue = ceil(currentQuantity)
        } else {
            newValue = currentQuantity + 1
        }
        
        let clamped = min(newValue, 100)
        localActiveItems[item.id] = clamped
        textValue = formatValue(clamped)
    }
    
    private func handleMinus() {
        let newValue: Double
        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
            newValue = floor(currentQuantity)
        } else {
            newValue = currentQuantity - 1
        }
        
        let clamped = max(newValue, 0)
        localActiveItems[item.id] = clamped
        textValue = formatValue(clamped)
    }
    
    private func commitTextField() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        if let number = formatter.number(from: textValue) {
            let doubleValue = number.doubleValue
            let clamped = min(max(doubleValue, 0), 100)
            localActiveItems[item.id] = clamped
            
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
}
