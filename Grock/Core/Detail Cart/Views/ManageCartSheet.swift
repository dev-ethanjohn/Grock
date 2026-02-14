import SwiftUI
import SwiftData

struct ManageCartSheet: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategoryName: String?
    @State private var toolbarAppeared = false
    @State private var showAddItemPopover = false
    @State private var createCartButtonVisible = true
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @Namespace private var searchNamespace
    @Namespace private var categoryManagerNamespace
    
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
    @State private var buttonScale: CGFloat = 0
    
    // Track keyboard state
    @FocusState private var isAnyFieldFocused: Bool
    
    // Keyboard responder
    @State private var keyboardResponder = KeyboardResponder()
    @State private var focusedItemId: String?
    
    private var activeItemCount: Int {
        localActiveItems.values.reduce(0) { count, quantity in
            count + (quantity > 0 ? 1 : 0)
        }
    }
    
    private var hasActiveItems: Bool {
        activeItemCount > 0
    }
    
    // Computed property that reacts to vault changes
    private var currentVault: Vault? {
        vaultService.vault
    }
    
    private var totalVaultItemsCount: Int {
        guard let vault = vaultService.vault else { return 0 }
        return vault.categories.reduce(0) { $0 + $1.items.count }
    }
    
    private var defaultCategoryNames: [String] {
        GroceryCategory.allCases.map(\.title)
    }
    
    private var customCategoryNames: [String] {
        guard let vault = vaultService.vault else { return [] }
        let defaultSet = Set(defaultCategoryNames)
        return vault.categories
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.name)
            .filter { !defaultSet.contains($0) }
    }
    
    private var allCategoryNames: [String] {
        var seen = Set<String>()
        var results: [String] = []
        
        for name in defaultCategoryNames + customCategoryNames {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard !seen.contains(trimmed.lowercased()) else { continue }
            seen.insert(trimmed.lowercased())
            results.append(trimmed)
        }
        
        return results
    }
    
    private var visibleCategories: [String] {
        let decoded = (try? JSONDecoder().decode([String].self, from: visibleCategoryNamesData))
            .map {
                $0.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
        let configured = (decoded?.isEmpty == false) ? decoded! : defaultCategoryNames

        let canonicalByKey = Dictionary(uniqueKeysWithValues: allCategoryNames.map { ($0.lowercased(), $0) })
        var seen = Set<String>()
        var result: [String] = []

        for name in configured {
            let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard let canonical = canonicalByKey[key], !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(canonical)
        }

        return result.isEmpty ? defaultCategoryNames : result
    }
    
    private var visibleCategoriesBinding: Binding<[String]> {
        Binding(
            get: { visibleCategories },
            set: { newValue in
                let normalized = newValue
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                visibleCategoryNamesData = (try? JSONEncoder().encode(normalized)) ?? Data()
            }
        )
    }

    private func openCategoryManager() {
        showCategoryPickerSheet = true
    }

    private func closeCategoryManager() {
        showCategoryPickerSheet = false
        categoryManagerStartOnHidden = false
    }
    
    //switching category transition
    @State private var navigationDirection: NavigationDirection = .none
    @State private var showCategoryPickerSheet = false
    @State private var categoryManagerStartOnHidden = false
    
    @AppStorage("visibleCategoryNames") private var visibleCategoryNamesData: Data = Data()
    
    enum NavigationDirection {
        case left, right, none
    }
    
    var body: some View {
        baseContent
            .navigationBarHidden(true) // Hide native navigation bar
            .background(.white)
            .ignoresSafeArea(.keyboard)
            .onPreferenceChange(TextFieldFocusPreferenceKey.self) { itemId in
                focusedItemId = itemId
            }
            .onAppear {
                initializeActiveItemsFromCart()
                if selectedCategoryName == nil {
                    selectedCategoryName = firstVisibleCategoryWithItems ?? visibleCategories.first
                }
                updateChevronVisibility()
            }
            .onChange(of: vaultService.vault) { oldValue, newValue in
                print("🔄 ManageCartSheet: Vault updated, refreshing view")
                vaultUpdateTrigger += 1
                
                // Update selected category if the current one no longer has items
                if let currentCategoryName = selectedCategoryName,
                   !hasItems(inCategoryNamed: currentCategoryName) {
                    selectedCategoryName = firstVisibleCategoryWithItems ?? visibleCategories.first
                }
            }
            .onChange(of: vaultUpdateTrigger) { oldValue, newValue in
                // This forces the view to refresh when vault changes
                print("🔄 ManageCartSheet: Refreshing view due to vault changes")
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemCategoryChanged"))) { notification in
                if let newCategoryName = notification.userInfo?["newCategoryName"] as? String {
                    print("🔄 ManageCartSheet: Received category change notification - switching to \(newCategoryName)")
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedCategoryName = newCategoryName
                    }
                } else if let newCategory = notification.userInfo?["newCategory"] as? GroceryCategory {
                    print("🔄 ManageCartSheet: Received category change notification - switching to \(newCategory.title)")
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedCategoryName = newCategory.title
                    }
                }
            }
            .onChange(of: selectedCategoryName) { oldValue, newValue in
                updateChevronVisibility()
            }
            .onChange(of: searchText) { oldValue, newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty, let vault = vaultService.vault else { return }
                if let matched = matchCategoryForSearch(trimmed, vault: vault) {
                    if let current = selectedCategoryName,
                       let currentIndex = visibleCategories.firstIndex(of: current),
                       let newIndex = visibleCategories.firstIndex(of: matched) {
                        navigationDirection = newIndex > currentIndex ? .right : .left
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedCategoryName = matched
                    }
                }
            }
            .onChange(of: visibleCategoryNamesData) { _, _ in
                if let selectedCategoryName,
                   !visibleCategories.contains(selectedCategoryName) {
                    self.selectedCategoryName = visibleCategories.first
                }
                updateChevronVisibility()
            }
            .onChange(of: hasActiveItems) { oldValue, newValue in
                if newValue {
                    if !oldValue {
                        withAnimation(.spring(duration: 0.4)) {
                            fillAnimation = 1.0
                        }
                        startButtonBounce()
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        fillAnimation = 0.0
                        buttonScale = 0
                    }
                }
            }
            .onAppear {
                if hasActiveItems {
                    fillAnimation = 1.0
                    buttonScale = 1.0
                } else {
                    buttonScale = 0
                }
            }
            .fullScreenCover(isPresented: $showCategoryPickerSheet) {
                NavigationStack {
                    categoriesManagerDestination
                }
            }
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(24)
            .onChange(of: showCategoryPickerSheet) { _, isPresented in
                if !isPresented {
                    categoryManagerStartOnHidden = false
                }
            }
    }

    private var categoriesManagerDestination: some View {
        CategoriesManagerSheet(
            title: "Manage Categories",
            startOnHiddenTab: categoryManagerStartOnHidden,
            selectedCategoryName: $selectedCategoryName,
            visibleCategoryNames: visibleCategoriesBinding,
            activeItemCount: { getActiveItemCount(forCategoryNamed: $0) },
            hasItems: { hasItems(inCategoryNamed: $0) },
            onClose: closeCategoryManager
        )
    }

    private var baseContent: some View {
        ZStack(alignment: .bottom) {
            // Main content
            VStack(spacing: 0) {
                // Custom Header
                CustomHeaderView(
                    showAddItemPopover: $showAddItemPopover,
                    duplicateError: $duplicateError,
                    searchText: $searchText,
                    isSearching: $isSearching,
                    matchedNamespace: searchNamespace
                )
                
                // Use currentVault instead of vaultService.vault directly
                if let vault = currentVault, !vault.categories.isEmpty {
                    ZStack(alignment: .top) {
                        categoryContentScrollView
                            .frame(maxHeight: .infinity)
                            .padding(.top, 40)
                            .zIndex(0)
                        
                        VaultCategorySectionView(selectedCategoryTitle: selectedCategoryName) {
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
                    onSave: { itemName, categoryName, store, unit, price in
                        if let newItem = vaultService.addItem(
                            name: itemName,
                            toCategoryName: categoryName,
                            store: store,
                            price: price,
                            unit: unit
                        ) {
                            localActiveItems[newItem.id] = 1
                        }
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
    }
    
    private var categoryScrollView: some View {
        ScrollViewReader { proxy in
            let iconSize: CGFloat = 50
            let iconSpacing: CGFloat = 0
            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .leading) {
                        if let selectedCategoryName,
                           let selectedIndex = visibleCategories.firstIndex(of: selectedCategoryName) {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.black, lineWidth: 2)
                                .frame(width: iconSize, height: iconSize)
                                .offset(x: CGFloat(selectedIndex) * (iconSize + iconSpacing))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCategoryName)
                        }
                        
                        HStack(spacing: iconSpacing) {
                            ForEach(visibleCategories, id: \.self) { categoryName in
                                VaultCategoryNameIcon(
                                    name: categoryName,
                                    isSelected: selectedCategoryName == categoryName,
                                    itemCount: getActiveItemCount(forCategoryNamed: categoryName),
                                    hasItems: hasItems(inCategoryNamed: categoryName),
                                    iconText: vaultService.displayEmoji(forCategoryName: categoryName),
                                    action: {
                                        // Dismiss keyboard immediately when tapping category
                                        UIApplication.shared.endEditing()
                                        
                                        // Set navigation direction
                                        if let current = selectedCategoryName,
                                           let currentIndex = visibleCategories.firstIndex(of: current),
                                           let newIndex = visibleCategories.firstIndex(of: categoryName) {
                                            navigationDirection = newIndex > currentIndex ? .right : .left
                                        }
                                        selectCategory(named: categoryName)
                                    }
                                )
                                .frame(width: iconSize, height: iconSize)
                                .id(categoryName)
                            }

                            Image(systemName: "plus.square.dashed")
                                .font(.system(size: 46, weight: .light))
                                .foregroundStyle(Color(.systemGray3))
                                .offset(x: -2)
                                .onTapGesture {
                                    categoryManagerStartOnHidden = true
                                    openCategoryManager()
                                }
                        }
                        .padding(.trailing, 80)
                    }
                    .padding(.vertical, 1)
                    .padding(.leading)
                    .padding(.trailing, 4)
                }
                .overlay(alignment: .trailing) {
                    GroceryCategoryScrollRightOverlay(
                        backgroundColor: .white,
                        namespace: categoryManagerNamespace,
                        isExpanded: showCategoryPickerSheet
                    ) {
                        UIApplication.shared.endEditing()
                        categoryManagerStartOnHidden = false
                        openCategoryManager()
                    }
                }
            }
            .onChange(of: selectedCategoryName) { _, newValue in
                if let newName = newValue {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                        proxy.scrollTo(newName, anchor: .center)
                    }
                }
            }
            .onAppear {
                if let initialCategory = selectedCategoryName ?? firstVisibleCategoryWithItems ?? visibleCategories.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            proxy.scrollTo(initialCategory, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private var categoryContentScrollView: some View {
        Group {
            if let selectedCategoryName {
                CategoryItemsListView(
                    categoryName: selectedCategoryName,
                    localActiveItems: $localActiveItems,
                    searchText: searchText,
                    navigationDirection: navigationDirection
                )
            }
        }
        .frame(maxHeight: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedCategoryName)
    }
    
    private var bottomActionBar: some View {
        VStack {
            Spacer()
            
            HStack {
                if showLeftChevron {
                    Button(action: navigateToPreviousCategory) {
                        Image(systemName: "chevron.left")
                            .lexendFont(16, weight: .bold)
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
                        .frame(height: 44)
                        .background(saveButtonBackground)
                        .cornerRadius(25)
                }
                .overlay(alignment: .topLeading) {
                    if hasActiveItems {
                        saveBadge
                    }
                }
                .buttonStyle(.solid)
                .scaleEffect(createCartButtonVisible ? buttonScale : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: createCartButtonVisible)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
                .disabled(!hasActiveItems)
                
                Spacer()
                
                if showRightChevron {
                    Button(action: navigateToNextCategory) {
                        Image(systemName: "chevron.right")
                            .lexendFont(16, weight: .bold)
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

    private var saveButtonBackground: some View {
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
    }

    private var saveBadge: some View {
        Text("\(activeItemCount)")
            .fuzzyBubblesFont(16, weight: .bold)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeItemCount)
            .foregroundColor(.black)
            .frame(width: 25, height: 25)
            .background(Color.white)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.black, lineWidth: 2)
            )
            .offset(x: -8, y: -4)
            .scaleEffect(createCartButtonVisible ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: createCartButtonVisible)
    }
    
    private var emptyVaultView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "shippingbox")
                .lexendFont(60)
                .foregroundColor(.gray)
            
            Text("Your vault is empty")
                .lexend(.title2)
                .foregroundColor(.gray)
            
            Text("No items available to add")
                .lexend(.body)
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
        var changedQuantities: [(itemId: String, newQuantity: Double)] = []
        
        // Remove items that were deselected OR have zero quantity
        let itemsToRemove = currentCartItemIds.subtracting(selectedItemIds)
        for itemId in itemsToRemove {
            if let item = vaultService.findItemById(itemId) {
                print("   🗑️ Removing: \(item.name)")
                vaultService.removeItemFromCart(cart: cart, itemId: itemId)
                changedQuantities.append((itemId: itemId, newQuantity: 0))
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
                            changedQuantities.append((itemId: itemId, newQuantity: quantity))
                        } else {
                            // Remove item if quantity is 0
                            print("   🗑️ Removing (zero quantity): \(item.name)")
                            vaultService.removeItemFromCart(cart: cart, itemId: itemId)
                            changedQuantities.append((itemId: itemId, newQuantity: 0))
                        }
                    }
                } else {
                    // Add new item only if quantity > 0
                    if quantity > 0 {
                        print("   ➕ Adding: \(item.name) × \(quantity)")
                        // CHANGED: Use addVaultItemToCart instead of addItemToCart
                        vaultService.addVaultItemToCart(item: item, cart: cart, quantity: quantity)
                        changedQuantities.append((itemId: itemId, newQuantity: quantity))
                    }
                }
            }
        }
        
        vaultService.updateCartTotals(cart: cart)
        print("   ✅ Final cart items: \(cart.cartItems.count)")
        
        // Broadcast detailed quantity changes for row/UI refresh
        for change in changedQuantities {
            NotificationCenter.default.post(
                name: .shoppingItemQuantityChanged,
                object: nil,
                userInfo: [
                    "cartId": cart.id,
                    "itemId": change.itemId,
                    "newQuantity": change.newQuantity
                ]
            )
        }
        
        NotificationCenter.default.post(
            name: .shoppingItemQuantityChanged,
            object: nil,
            userInfo: [
                "cartId": cart.id
            ]
        )
        
        NotificationCenter.default.post(
            name: .shoppingDataUpdated,
            object: nil,
            userInfo: ["cartItemId": cart.id]
        )
    }
    
    private func selectCategory(named categoryName: String) {
        // Set navigation direction
        if let current = selectedCategoryName,
           let currentIndex = visibleCategories.firstIndex(of: current),
           let newIndex = visibleCategories.firstIndex(of: categoryName) {
            navigationDirection = newIndex > currentIndex ? .right : .left
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedCategoryName = categoryName
        }
    }
    
    private func updateChevronVisibility() {
        guard let currentCategory = selectedCategoryName,
              let currentIndex = visibleCategories.firstIndex(of: currentCategory) else {
            showLeftChevron = false
            showRightChevron = false
            return
        }
        
        showLeftChevron = currentIndex > 0
        showRightChevron = currentIndex < visibleCategories.count - 1
    }
    
    private func navigateToPreviousCategory() {
        // Dismiss keyboard immediately
        UIApplication.shared.endEditing()
        
        guard let currentCategory = selectedCategoryName,
              let currentIndex = visibleCategories.firstIndex(of: currentCategory),
              currentIndex > 0 else { return }
        
        let previousCategory = visibleCategories[currentIndex - 1]
        navigationDirection = .left
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedCategoryName = previousCategory
        }
    }
    
    private func navigateToNextCategory() {
        // Dismiss keyboard immediately
        UIApplication.shared.endEditing()
        
        guard let currentCategory = selectedCategoryName,
              let currentIndex = visibleCategories.firstIndex(of: currentCategory),
              currentIndex < visibleCategories.count - 1 else { return }
        
        let nextCategory = visibleCategories[currentIndex + 1]
        navigationDirection = .right
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedCategoryName = nextCategory
        }
    }
    
    private func matchCategoryForSearch(_ text: String, vault: Vault) -> String? {
        for name in visibleCategories {
            if let vaultCategory = vaultCategory(named: name, in: vault) {
                let hasMatch = vaultCategory.items.contains { $0.name.localizedCaseInsensitiveContains(text) }
                if hasMatch { return name }
            }
        }
        return nil
    }
    
    private var firstVisibleCategoryWithItems: String? {
        guard let vault = vaultService.vault else { return nil }
        
        for name in visibleCategories {
            if let vaultCategory = vaultCategory(named: name, in: vault),
               !vaultCategory.items.isEmpty {
                return name
            }
        }
        return nil
    }
    
    private func vaultCategory(named name: String, in vault: Vault?) -> Category? {
        guard let vault else { return nil }
        let target = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return vault.categories.first { category in
            category.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == target
        }
    }
    
    private func getActiveItemCount(forCategoryNamed name: String) -> Int {
        guard let foundCategory = vaultCategory(named: name, in: vaultService.vault) else { return 0 }
        
        let activeItemsCount = foundCategory.items.reduce(0) { count, item in
            let isActive = (localActiveItems[item.id] ?? 0) > 0
            return count + (isActive ? 1 : 0)
        }
        
        return activeItemsCount
    }
    
    private func getTotalItemCount(forCategoryNamed name: String) -> Int {
        guard let foundCategory = vaultCategory(named: name, in: vaultService.vault) else { return 0 }
        
        return foundCategory.items.count
    }
    
    private func hasItems(inCategoryNamed name: String) -> Bool {
        return getTotalItemCount(forCategoryNamed: name) > 0
    }

    private func startButtonBounce() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            buttonScale = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                buttonScale = 1.1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                buttonScale = 1.0
            }
        }
    }
}

// MARK: - Custom Header View
private struct CustomHeaderView: View {
    @Binding var showAddItemPopover: Bool
    @Binding var duplicateError: String?
    @Binding var searchText: String
    @Binding var isSearching: Bool
    var matchedNamespace: Namespace.ID
    @FocusState private var searchFieldIsFocused: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Centered title
            HStack {
                Spacer()
                Text("Manage Cart")
                    .lexend(.headline)
                    .foregroundColor(.black)
                Spacer()
            }
            .frame(height: 44)
            .padding(.top, 18)
            
            // Trailing Add button
            HStack {
                Spacer()
                Button(action: {
                    UIApplication.shared.endEditing()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAddItemPopover = true
                        duplicateError = nil
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
                .padding(.trailing, 20)
            }
            .frame(height: 44)
            .padding(.top, 18)
            
            // Search stack overlay
            if isSearching {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .lexend(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .matchedGeometryEffect(id: "searchIcon", in: matchedNamespace, isSource: false)
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Search items in Manage Cart")
                                .lexendFont(16)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        TextField("", text: $searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($searchFieldIsFocused)
                    }
                    Button(action: {
                        isSearching = false
                        searchText = ""
                        searchFieldIsFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                        .matchedGeometryEffect(id: "searchCapsule", in: matchedNamespace, isSource: false)
                )
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.scale.combined(with: .opacity))
            } else {
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSearching = true
                        }
                        searchFieldIsFocused = true
                    }) {
                        ZStack {
                            Capsule()
                                .fill(Color.white)
                                .matchedGeometryEffect(id: "searchCapsule", in: matchedNamespace, isSource: true)
                                .frame(height: 28)
                                .frame(width: 36, alignment: .leading)
                            Image(systemName: "magnifyingglass")
                                .lexend(.headline)
                                .fontWeight(.medium)
                                .foregroundStyle(.black)
                                .matchedGeometryEffect(id: "searchIcon", in: matchedNamespace, isSource: true)
                        }
                    }
                }
                .padding(.leading, 16)
                .padding(.top, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.white)
        .padding(.bottom, 8)
    }
}

struct CategoryItemsListView: View {
    let categoryName: String
    @Binding var localActiveItems: [String: Double]
    let searchText: String
    let navigationDirection: ManageCartSheet.NavigationDirection
    
    @Environment(VaultService.self) private var vaultService
    
    // Store availableStores as @State
    @State private var currentStores: [String] = []
    
    private var groceryCategory: GroceryCategory? {
        GroceryCategory.allCases.first(where: { $0.title == categoryName })
    }
    
    private var categoryColor: Color {
        groceryCategory?.pastelColor ?? categoryName.generatedPastelColor
    }
    
    private var categoryEmoji: String {
        vaultService.displayEmoji(forCategoryName: categoryName)
    }
    
    private var categoryItems: [Item] {
        guard let vault = vaultService.vault,
              let foundCategory = vault.categories.first(where: {
                  $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                  == categoryName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
              })
        else { return [] }
        
        // Filter out deleted items
        let items = foundCategory.items
            .filter { !$0.isDeleted }
            .sorted { $0.createdAt > $1.createdAt }
        
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return items
        } else {
            return items.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }
    }
    
    var body: some View {
        Group {
            if categoryItems.isEmpty {
                emptyCategoryView
            } else {
                ManageCartItemsListView(
                    items: categoryItems,
                    availableStores: currentStores,
                    categoryName: categoryName,
                    categoryColor: categoryColor,
                    localActiveItems: $localActiveItems,
                    onDeleteVaultItem: { item in
                        let itemId = item.id
                        localActiveItems.removeValue(forKey: itemId)
                        vaultService.deleteItem(itemId: itemId)
                    }
                )
                .id(categoryName)
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
        .onChange(of: searchText) { _, _ in
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
            Text(emptyMessage)
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }
    
    private var emptyMessage: String {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
        ? "No items yet in \(categoryName) \(categoryEmoji)"
        : "No items found"
    }
}


// MARK: - Items List View for Manage Cart (with native swipe gestures)
struct ManageCartItemsListView: View {
    let items: [Item]
    let availableStores: [String]
    let categoryName: String
    let categoryColor: Color
    @Binding var localActiveItems: [String: Double]
    let onDeleteVaultItem: (Item) -> Void
    
    @Environment(VaultService.self) private var vaultService
    @Environment(\.cartStateManager) private var stateManager
    @State private var focusedItemId: String?
    @State private var previousStores: [String] = []
    
    // Alert state
    @State private var itemToDelete: Item?
    @State private var showDeleteConfirmation = false
    
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
                    categoryName: categoryName,
                    categoryColor: categoryColor,
                    hasBackgroundImage: stateManager.hasBackgroundImage,
                    localActiveItems: $localActiveItems,
                    onDeleteVaultItem: { item in
                        itemToDelete = item
                        showDeleteConfirmation = true
                    }
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
        .onAppear {
            previousStores = availableStores
        }
        .onChange(of: availableStores) { oldStores, newStores in
            // Update previous stores
            previousStores = oldStores
        }
        .alert("Remove Item", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { itemToDelete = nil }
            Button("Remove", role: .destructive) {
                if let item = itemToDelete {
                    onDeleteVaultItem(item)
                }
                itemToDelete = nil
            }
        } message: {
            Text("Are you sure you want to remove this item from your vault? This will also remove it from all carts.")
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
    let categoryName: String
    let categoryColor: Color
    let hasBackgroundImage: Bool
    @Binding var localActiveItems: [String: Double]
    let onDeleteVaultItem: (Item) -> Void
    
    private var itemsWithStableIdentifiers: [(id: String, item: Item)] {
        items.map { ($0.id, $0) }
    }
    
    private var headerForegroundColor: Color {
        hasBackgroundImage ? .black : .white
    }
    
    private var headerBackgroundColor: Color {
        hasBackgroundImage ? .white : categoryColor.saturated(by: 0.3).darker(by: 0.5)
    }
    
    var body: some View {
        Section(
            header: HStack {
                HStack(spacing: 2) {
                    Image(systemName: "storefront")
                        .lexendFont(10)
                        .foregroundStyle(headerForegroundColor)
                    
                    Text(storeName)
                        .fuzzyBubblesFont(11, weight: .bold)
                        .foregroundStyle(headerForegroundColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(headerBackgroundColor)
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
                        categoryName: categoryName,
                        categoryColor: categoryColor,
                        localActiveItems: $localActiveItems,
                        onDeleteVaultItem: onDeleteVaultItem
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

// MARK: - Item Row for Manage Cart (clean version without custom swipe)
struct ManageCartItemRow: View {
    let item: Item
    let categoryName: String
    let categoryColor: Color
    @Binding var localActiveItems: [String: Double]
    let onDeleteVaultItem: (Item) -> Void
    
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
                    .fill(isActive ? categoryColor.saturated(by: 0.3).darker(by: 0.5) : .clear)
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
                        Text("\(CurrencyManager.shared.selectedCurrency.symbol)\(priceOption.pricePerUnit.priceValue.formattedPricePerUnitValue)")
                            .contentTransition(.numericText())
                            .animation(.snappy, value: CurrencyManager.shared.selectedCurrency.symbol)
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
            .presentationBackground(.white)
        }
        .contextMenu {
            Button(role: .destructive) {
                localActiveItems.removeValue(forKey: item.id)
            } label: {
                Label("Remove from Cart", systemImage: "trash")
            }
            
            Button(role: .destructive) {
                onDeleteVaultItem(item)
            } label: {
                Label("Remove from Vault", systemImage: "trash.slash")
            }
            
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDeleteVaultItem(item)
            } label: {
                Label("Vault", systemImage: "trash.slash")
            }
            .tint(.red)
        }
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
        .preference(key: TextFieldFocusPreferenceKey.self, value: isFocused ? item.id : nil)
    }
    
    private var minusButton: some View {
        Button {
            handleMinus()
        } label: {
            Image(systemName: "minus")
                .lexend(.footnote).bold()
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
                .lexendFont(15, weight: .bold)
                .foregroundColor(Color(hex: "2C3E50"))
                .multilineTextAlignment(.center)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: textValue)
                .fixedSize()
            
            TextField("", text: $textValue)
                .keyboardType(.decimalPad)
                .lexendFont(15, weight: .bold)
                .foregroundColor(.clear)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .focused($isFocused)
                .numbersOnly($textValue, includeDecimal: true)
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
                .lexend(.footnote)
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
