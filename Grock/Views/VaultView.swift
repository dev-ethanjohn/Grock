import SwiftUI
import SwiftData
import Lottie

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
    
    // Properties for different modes
    var onCreateCart: ((Cart) -> Void)?
    var existingCart: Cart?
    var onAddItemsToCart: (([String: Double]) -> Void)?
    var shouldTriggerCelebration: Bool = false
    
    @State private var hasInitializedFromExistingCart = false
    
    // Celebration States with Lottie
    @State private var showCelebration = false
    @State private var debugCelebrationCount = 0
    @State private var buttonScale: CGFloat = 1.0
    
    // NEW: Loading state to prevent animation issues
    @State private var vaultReady = false
    
    private var hasActiveItems: Bool {
        !cartViewModel.activeCartItems.isEmpty
    }
    
    // guide
    @State private var showFirstItemTooltip = false
    @State private var firstItemId: String? = nil
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if vaultReady {
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
            } else {
                ProgressView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            vaultReady = true
                        }
                    }
            }
            
            if vaultService.vault != nil && !showCelebration && vaultReady {
                ZStack(alignment: .topLeading) {
                    Button(action: {
                        if existingCart != nil {
                            onAddItemsToCart?(cartViewModel.activeCartItems)
                            dismiss()
                        } else {
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
                    .scaleEffect(createCartButtonVisible ? buttonScale : 0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: createCartButtonVisible)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
                    .disabled(!hasActiveItems)
                    .onChange(of: createCartButtonVisible) { oldValue, newValue in
                        if newValue && hasActiveItems {
                            startButtonBounce()
                        }
                    }
                    .onChange(of: hasActiveItems) { oldValue, newValue in
                        if newValue && createCartButtonVisible {
                            startButtonBounce()
                        }
                    }
                    
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
                                .spring(response: 0.6, dampingFraction: 0.6),
                                value: cartBadgeVisible
                            )
                    }
                }
                .onChange(of: createCartButtonVisible) { oldValue, newValue in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
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
        .fullScreenCover(isPresented: $showCelebration) {
            CelebrationView(
                isPresented: $showCelebration,
                title: "Welcome to Your Vault!",
                subtitle: nil
            )
            .presentationBackground(.clear)
        }
        .onChange(of: showCelebration) { oldValue, newValue in
            if newValue {
                // Celebration starting - hide button
                withAnimation(.easeOut(duration: 0.2)) {
                    createCartButtonVisible = false
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    createCartButtonVisible = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if hasActiveItems {
                        startButtonBounce()
                    }
                }
                
                    findAndHighlightFirstItem()
            }
        }
        .fullScreenCover(isPresented: $showCartConfirmation) {
            CartConfirmationPopover(
                isPresented: $showCartConfirmation,
                activeCartItems: cartViewModel.activeCartItems,
                vaultService: vaultService,
                onConfirm: { title, budget in
                    print("🛒 Creating cart...")
                    
                    if let newCart = cartViewModel.createCartWithActiveItems(name: title, budget: budget) {
                        print("✅ Cart created: \(newCart.name)")
                        cartViewModel.activeCartItems.removeAll()
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
            initializeActiveItemsFromExistingCart()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if selectedCategory == nil {
                    selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
                }
            }
            
            print("🎉 VaultView onAppear - Checking celebration conditions:")
            print("🎉 shouldTriggerCelebration parameter: \(shouldTriggerCelebration)")
            
            let hasSeenCelebration = UserDefaults.standard.bool(forKey: "hasSeenVaultCelebration")
            print("🎉 hasSeenCelebration: \(hasSeenCelebration)")
            
            if let vault = vaultService.vault {
                let totalItems = vault.categories.reduce(0) { $0 + $1.items.count }
                print("🎉 Total items in vault: \(totalItems)")
                print("🎉 Categories with items: \(vault.categories.filter { !$0.items.isEmpty }.count)")
            }
            
            if shouldTriggerCelebration {
                print("🎉 Celebration triggered by parent view!")
                showCelebration = true
                UserDefaults.standard.set(true, forKey: "hasSeenVaultCelebration")
            } else {
                checkAndStartCelebration()
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
        .overlay {
            if showFirstItemTooltip, let firstItemId = firstItemId {
                FirstItemTooltip(itemId: firstItemId, isPresented: $showFirstItemTooltip)
            }
        }
    }
    
    private func checkAndStartCelebration() {
        let hasSeenCelebration = UserDefaults.standard.bool(forKey: "hasSeenVaultCelebration")
        
        guard !hasSeenCelebration else {
            print("⏭️ Skipping celebration - already seen")
            return
        }
        
        guard let vault = vaultService.vault else {
            print("⏭️ Skipping celebration - no vault")
            return
        }
        
        let totalItems = vault.categories.reduce(0) { $0 + $1.items.count }
        print("🎉 Total items in vault: \(totalItems)")
        
        guard totalItems > 0 else {
            print("⏭️ Skipping celebration - vault is empty")
            return
        }
        
        print("🎉 ✅ CONDITIONS MET - Starting celebration!")
        showCelebration = true
        UserDefaults.standard.set(true, forKey: "hasSeenVaultCelebration")
    }
    
    private func initializeActiveItemsFromExistingCart() {
        guard let existingCart = existingCart, !hasInitializedFromExistingCart else { return }
        
        print("🔄 VaultView: Initializing active items from existing cart '\(existingCart.name)'")
        
        cartViewModel.activeCartItems.removeAll()
        
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
        guard let vault = vaultService.vault else {
            print("❌ No vault found in VaultService!")
            return
        }
        
        print("🏷️ Vault ID: \(vault.uid)")
        print("📂 Number of categories in vault: \(vault.categories.count)")
        
        let sortedCategories = vault.categories.sorted { $0.sortOrder < $1.sortOrder }
        
        for (categoryIndex, category) in sortedCategories.enumerated() {
            print("\n  📁 Category \(categoryIndex + 1): '\(category.name)'")
            print("     Number of items: \(category.items.count)")
            
            for (itemIndex, item) in category.items.enumerated() {
                print("     🛒 Item \(itemIndex + 1): '\(item.name)'")
            }
        }
        
        print("===== END VAULT DEBUG INFO =====")
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
    
    private func findAndHighlightFirstItem() {
        guard let vault = vaultService.vault else { return }
        
        for category in vault.categories {
            if let firstItem = category.items.first {
                firstItemId = firstItem.id
                showFirstItemTooltip = true
                break
            }
        }
    }
}



