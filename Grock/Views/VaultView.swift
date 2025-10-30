import SwiftUI
import SwiftData

struct VaultView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: GroceryCategory?
    @State private var toolbarAppeared = false
    @State private var showAddItemPopover = false
    
    @State private var createCartButtonVisible = true
    @State private var cartBadgeVisible = false
    
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showCartConfirmation = false
    
    // ✅ COMPLETE: Properties for different modes
    var onCreateCart: ((Cart) -> Void)?
    var existingCart: Cart?
    var onAddItemsToCart: (([String: Double]) -> Void)?
    
    // ✅ NEW: Track if we've initialized from existing cart
    @State private var hasInitializedFromExistingCart = false
    
    private var hasActiveItems: Bool {
        !cartViewModel.activeCartItems.isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                VaultToolbarView(
                    toolbarAppeared: $toolbarAppeared,
                    onAddTapped: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAddItemPopover = true
                        }
                    }
                )
                
                if let vault = vaultService.vault, !vault.categories.isEmpty {
                    VaultCategorySectionView(selectedCategory: selectedCategory) {
                        categoryScrollView
                    }
                    
                    categoryContentScrollView
                } else {
                    emptyVaultView
                }
            }
            
            if vaultService.vault != nil {
                ZStack(alignment: .topLeading) {
                    Button(action: {
                        if existingCart != nil {
                            // ✅ MODE: Adding to existing cart - DON'T clear active items
                            onAddItemsToCart?(cartViewModel.activeCartItems)
                            // Note: We don't clear activeCartItems here so they persist for next use
                            dismiss()
                        } else {
                            // MODE: Creating new cart
                            withAnimation {
                                showCartConfirmation = true
                            }
                        }
                    }) {
                        Text(existingCart != nil ? "Add to Cart" : "Create cart")
                            .font(.fuzzyBold_16)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .cornerRadius(25)
                    }
                    .padding(.bottom, 20)
                    .scaleEffect(createCartButtonVisible ? 1 : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0), value: createCartButtonVisible)
                    .opacity(createCartButtonVisible ? 1 : 0)
                    .opacity(hasActiveItems ? 1 : 0.5)
                    .disabled(!hasActiveItems)
                    
                    if hasActiveItems {
                        Text("\(cartViewModel.activeCartItems.count)")
                            .font(.fuzzyBold_16)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cartViewModel.activeCartItems.count)
                            .foregroundColor(.black)
                            .frame(width: 25, height: 25)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: -8, y: -4)
                            .scaleEffect(cartBadgeVisible ? 1 : 0)
                            .animation(
                                cartBadgeVisible ?
                                    .spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0).delay(0.35) :
                                    .spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0),
                                value: cartBadgeVisible
                            )
                    }
                }
                .onChange(of: createCartButtonVisible) { oldValue, newValue in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        cartBadgeVisible = newValue
                    }
                }
            }
            
            if showAddItemPopover {
                AddItemPopover(
                    isPresented: $showAddItemPopover,
                    onSave: { itemName, category, store, unit, price in
                        vaultService.addItem(
                            name: itemName,
                            to: category,
                            store: store,
                            price: price,
                            unit: unit
                        )
                    },
                    onDismiss: {
                        showCreateCartButton()
                    }
                )
                .transition(.opacity)
                .zIndex(1)
                .onAppear {
                    createCartButtonVisible = false
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .toolbar(.hidden)
        .overlay {
            if showCartConfirmation {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showCartConfirmation)
        .fullScreenCover(isPresented: $showCartConfirmation) {
            CartConfirmationPopover(
                isPresented: $showCartConfirmation,
                activeCartItems: cartViewModel.activeCartItems,
                vaultService: vaultService,
                onConfirm: { title, budget in
                    print("🛒 Creating cart...")
                    
                    // ✅ FIX: Create cart and pass it immediately
                    if let newCart = cartViewModel.createCartWithActiveItems(name: title, budget: budget) {
                        print("✅ Cart created: \(newCart.name)")
                        
                        // ✅ Clear active items ONLY when creating new cart
                        cartViewModel.activeCartItems.removeAll()
                        
                        // ✅ Call onCreateCart immediately with the new cart
                        onCreateCart?(newCart)
                    } else {
                        print("❌ Failed to create cart")
                        showCreateCartButton()
                    }
                },
                onCancel: {
                    showCartConfirmation = false
                    showCreateCartButton()
                }
            )
            .presentationBackground(.clear)
        }
        .onAppear {
            printVaultStructure()
            
            // ✅ NEW: Initialize active items from existing cart
            initializeActiveItemsFromExistingCart()
            
            if selectedCategory == nil {
                selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                toolbarAppeared = true
            }
            
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ItemCategoryChanged"),
                object: nil,
                queue: .main
            ) { notification in
                if let newCategory = notification.userInfo?["newCategory"] as? GroceryCategory {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedCategory = newCategory
                    }
                    print("🔄 Auto-switched to category: \(newCategory.title)")
                }
            }
        }
        
        .onDisappear {
            NotificationCenter.default.removeObserver(self)
        }
        .onChange(of: vaultService.vault) { oldValue, newValue in
            if selectedCategory == nil {
                selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
            }
            
            if newValue != oldValue {
                print("🔄 Vault changed - reprinting structure:")
                printVaultStructure()
            }
        }
        .onChange(of: showAddItemPopover) { oldValue, newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("📝 After adding item - updated vault structure:")
                    printVaultStructure()
                }
            }
        }
    }
    
    // ✅ NEW: Initialize active items from existing cart
    private func initializeActiveItemsFromExistingCart() {
        guard let existingCart = existingCart, !hasInitializedFromExistingCart else { return }
        
        print("🔄 VaultView: Initializing active items from existing cart '\(existingCart.name)'")
        
        // Clear any existing active items
        cartViewModel.activeCartItems.removeAll()
        
        // Add items from the existing cart to activeCartItems
        for cartItem in existingCart.cartItems {
            cartViewModel.activeCartItems[cartItem.itemId] = cartItem.quantity
            if let item = vaultService.findItemById(cartItem.itemId) {
                print("   - Activated: \(item.name) × \(cartItem.quantity)")
            }
        }
        
        print("   Total active items: \(cartViewModel.activeCartItems.count)")
        hasInitializedFromExistingCart = true
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
            
            Text("Add your first item to get started")
                .font(.body)
                .foregroundColor(.gray.opacity(0.8))
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAddItemPopover = true
                }
            }) {
                Text("Add First Item")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(12)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding()
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
                                itemCount: getItemCount(for: category),
                                hasItems: hasItems(in: category),
                                action: {
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
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(GroceryCategory.allCases, id: \.self) { category in
                        CategoryItemsView(
                            category: category,
                            onDeleteItem: deleteItem
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .id(category.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $selectedCategory)
            .scrollTargetBehavior(.paging)
            .animation(.spring(response: 0.35, dampingFraction: 0.9), value: selectedCategory)
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
                }
            }
        }
    }
    
    // MARK: - Category Items View
    struct CategoryItemsView: View {
        let category: GroceryCategory
        let onDeleteItem: (Item) -> Void
        
        @Environment(VaultService.self) private var vaultService
        @Environment(CartViewModel.self) private var cartViewModel
        
        private var categoryItems: [Item] {
            guard let vault = vaultService.vault,
                  let foundCategory = vault.categories.first(where: { $0.name == category.title })
            else { return [] }
            return foundCategory.items
        }
        
        private var availableStores: [String] {
            let allStores = categoryItems.flatMap { item in
                item.priceOptions.map { $0.store }
            }
            return Array(Set(allStores)).sorted()
        }
        
        var body: some View {
            Group {
                if categoryItems.isEmpty {
                    emptyCategoryView
                } else {
                    VaultItemsListView(
                        items: categoryItems,
                        availableStores: availableStores,
                        selectedStore: .constant(nil),
                        category: category,
                        onDeleteItem: onDeleteItem
                    )
                }
            }
            .onAppear {
                print("📱 CategoryItemsView appeared for: '\(category.title)'")
                print("   Items count: \(categoryItems.count)")
                print("   Available stores: \(availableStores)")
                print("   Active items in this category: \(getActiveItemCount(in: categoryItems))")
            }
        }
        
        private func getActiveItemCount(in items: [Item]) -> Int {
            items.reduce(0) { count, item in
                let isActive = (cartViewModel.activeCartItems[item.id] ?? 0) > 0
                return count + (isActive ? 1 : 0)
            }
        }
        
        private var emptyCategoryView: some View {
            VStack {
                Spacer()
                Text("No items yet in this category")
                    .foregroundColor(.gray)
                Spacer()
            }
        }
    }
    
    // MARK: - Methods
    
    private func selectCategory(_ category: GroceryCategory, proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
            selectedCategory = category
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                proxy.scrollTo(category.id, anchor: .center)
            }
        }
        
        print("🎯 Selected category: '\(category.title)'")
        if let vault = vaultService.vault,
           let foundCategory = vault.categories.first(where: { $0.name == category.title }) {
            print("   Items in this category: \(foundCategory.items.count)")
            let activeCount = getActiveItemCount(in: foundCategory.items)
            print("   Active items in this category: \(activeCount)")
        } else {
            print("   No items found in this category")
        }
    }
    
    private func getActiveItemCount(in items: [Item]) -> Int {
        items.reduce(0) { count, item in
            let isActive = (cartViewModel.activeCartItems[item.id] ?? 0) > 0
            return count + (isActive ? 1 : 0)
        }
    }
    
    private func showCreateCartButton() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
            createCartButtonVisible = true
        }
    }
    
    private var firstCategoryWithItems: GroceryCategory? {
        guard let vault = vaultService.vault else { return nil }
        
        for category in vault.categories {
            if !category.items.isEmpty {
                return GroceryCategory.allCases.first { $0.title == category.name }
            }
        }
        
        return nil
    }
    
    private func getItemCount(for category: GroceryCategory) -> Int {
        guard let vault = vaultService.vault else { return 0 }
        guard let foundCategory = vault.categories.first(where: { $0.name == category.title }) else { return 0 }
        
        let activeItemsCount = foundCategory.items.reduce(0) { count, item in
            let isActive = (cartViewModel.activeCartItems[item.id] ?? 0) > 0
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
    
    private func deleteItem(_ item: Item) {
        print("🗑️ Deleting item: '\(item.name)'")
        vaultService.deleteItem(item)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🔄 After deletion - updated vault structure:")
            printVaultStructure()
        }
    }
    
    private func printVaultStructure() {
        print("\n🔍 ===== VAULT STRUCTURE DEBUG INFO =====")
        print("📦 Number of vaults in service: \(vaultService.vault != nil ? 1 : 0)")
        
        guard let vault = vaultService.vault else {
            print("❌ No vault found in VaultService!")
            return
        }
        
        print("🏷️ Vault ID: \(vault.uid)")
        print("📂 Number of categories in vault: \(vault.categories.count)")
        
        if vault.categories.isEmpty {
            print("📭 Vault is empty - no categories found")
        } else {
            print("\n🔍 RAW ARRAY ORDER (as stored in SwiftData):")
            for categoryIndex in 0..<vault.categories.count {
                let category = vault.categories[categoryIndex]
                print("  [\(categoryIndex)]: '\(category.name)' (Sort Order: \(category.sortOrder))")
            }
            
            let sortedCategories = vault.categories.sorted { $0.sortOrder < $1.sortOrder }
            print("\n🔍 SORTED ORDER (by sortOrder property):")
            for (sortedIndex, category) in sortedCategories.enumerated() {
                print("  [\(sortedIndex)]: '\(category.name)' (Sort Order: \(category.sortOrder))")
            }
            
            print("\n📋 DETAILED CATEGORY STRUCTURE (SORTED):")
            for (categoryIndex, category) in sortedCategories.enumerated() {
                print("\n  📁 Category \(categoryIndex + 1) (Sort Order: \(category.sortOrder)):")
                print("     Name: '\(category.name)'")
                print("     ID: \(category.uid)")
                print("     Number of items: \(category.items.count)")
                
                if category.items.isEmpty {
                    print("     📭 No items in this category")
                } else {
                    for (itemIndex, item) in category.items.enumerated() {
                        print("     🛒 Item \(itemIndex + 1):")
                        print("        Name: '\(item.name)'")
                        print("        ID: \(item.id)")
                        print("        Price options: \(item.priceOptions.count)")
                        
                        if item.priceOptions.isEmpty {
                            print("        💰 No price options for this item")
                        } else {
                            for (priceIndex, priceOption) in item.priceOptions.enumerated() {
                                print("        💰 Price option \(priceIndex + 1):")
                                print("           Store: '\(priceOption.store)'")
                                print("           Price: ₱\(priceOption.pricePerUnit.priceValue)")
                                print("           Unit: '\(priceOption.pricePerUnit.unit)'")
                            }
                        }
                        let isActive = (cartViewModel.activeCartItems[item.id] ?? 0) > 0
                        let quantity = cartViewModel.activeCartItems[item.id] ?? 0
                        print("        🛍️ Cart Status: \(isActive ? "ACTIVE (qty: \(quantity))" : "inactive")")
                    }
                }
            }
        }
        let allStores = getAllStores()
        print("\n  🏪 All available stores: \(allStores)")
        
        print("\n  🛒 Cart Summary:")
        print("     Active items: \(cartViewModel.activeCartItems.count)")
        for (itemId, quantity) in cartViewModel.activeCartItems {
            if let item = vaultService.findItemById(itemId) {
                print("     - \(item.name): \(quantity)")
            } else {
                print("     - Unknown item (\(itemId)): \(quantity)")
            }
        }
        
        // ✅ NEW: Show which cart we're adding to (if any)
        if let existingCart = existingCart {
            print("\n  🎯 Vault Mode: Adding to existing cart '\(existingCart.name)'")
            print("     Cart items: \(existingCart.cartItems.count)")
        } else {
            print("\n  🎯 Vault Mode: Creating new cart")
        }
        
        print("===== END VAULT DEBUG INFO =====")
    }
    
    private func getAllStores() -> [String] {
        guard let vault = vaultService.vault else { return [] }
        
        let allStores = vault.categories.flatMap { category in
            category.items.flatMap { item in
                item.priceOptions.map { $0.store }
            }
        }
        
        return Array(Set(allStores)).sorted()
    }
}

struct ClearBackgroundView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
