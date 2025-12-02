import SwiftUI
import SwiftData

struct ManageCartOverlay: View {
    let cart: Cart
    let namespace: Namespace.ID
    @Binding var isShowing: Bool
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    
    // Copy properties from ManageCartSheet
    @State private var selectedCategory: GroceryCategory?
    @State private var showAddItemPopover = false
    @State private var createCartButtonVisible = true
    @State private var localActiveItems: [String: Double] = [:]
    @State private var duplicateError: String?
    @State private var vaultUpdateTrigger = 0
    @State private var navigationDirection: NavigationDirection = .none
    
    // Animation states - EXACT FROM SAMPLE
    @State private var contentVisible = false
    @State private var isLoading = true
    
    // --- Animation Properties --- EXACT FROM SAMPLE
    private let initialPopScale: CGFloat = 0.98
    private let initialPopOffset: CGFloat = 10.0
    private let minLoadingDuration: Double = 0.5
    private let contentPopInDuration: Double = 0.35
    private let loaderFadeDuration: Double = 0.1
    
    private var contentScale: CGFloat { contentVisible ? 1.0 : initialPopScale }
    private var contentOffset: CGFloat { contentVisible ? 0 : initialPopOffset }
    
    enum NavigationDirection {
        case left, right, none
    }
    
    private var hasActiveItems: Bool {
        !localActiveItems.isEmpty
    }
    
    private var currentVault: Vault? {
        vaultService.vault
    }
    
    var body: some View {
        ZStack {
            // Full-screen dark background layer (for dimming) - EXACT FROM SAMPLE
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                        isShowing = false
                    }
                }
            
            // Content container (The white box that animates) - EXACT FROM SAMPLE
            VStack(spacing: 0) {
                
                // 1. --- Content Header --- EXACT FROM SAMPLE
                HStack {
                    Text("Manage Cart")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .fixedSize()
                        .minimumScaleFactor(1)
                        .matchedGeometryEffect(id: "headerText", in: namespace)
                    
                    Spacer()
                    
                    // Close button - EXACT FROM SAMPLE
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            isShowing = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.gray)
                    }
                    .opacity(contentVisible ? 1 : 0)
                    .scaleEffect(contentScale)
                    .offset(y: contentOffset)
                    .animation(.spring(response: contentPopInDuration, dampingFraction: 0.9), value: contentVisible)
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                
                Divider().padding(.vertical, 10).padding(.horizontal, 20)
                
                // 2. --- Toolbar with Add Button ---
                HStack {
                    if let category = selectedCategory {
                        Text(category.title)
                            .lexendFont(13, weight: .bold)
                            .contentTransition(.identity)
                            .animation(.spring(duration: 0.3), value: selectedCategory?.id)
                    } else {
                        Text("Select Category")
                            .fuzzyBubblesFont(13, weight: .bold)
                    }
                    
                    Spacer()
                    
                    // Add button - same as in original ManageCartSheet
                    Button(action: {
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
                    .opacity(contentVisible ? 1 : 0)
                    .scaleEffect(contentScale)
                    .offset(y: contentOffset)
                    .animation(.spring(response: contentPopInDuration, dampingFraction: 0.9), value: contentVisible)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                
                // 3. --- Content Area (Loading or Loaded) --- EXACT FROM SAMPLE
                
                // A. Progress View
                if isLoading {
                    VStack {
                        ProgressView("Loading Cart...")
                            .progressViewStyle(.circular)
                            .padding(50)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.animation(.easeOut(duration: loaderFadeDuration)))
                }
                
                // B. Main Content
                if !isLoading {
                    VStack(spacing: 0) {
                        if let vault = currentVault, !vault.categories.isEmpty {
                            // Category scroll view
                            categoryScrollView
                                .padding(.top, 8)
                                .padding(.bottom, 10)
                            
                            // Category content
                            categoryContentScrollView
                        } else {
                            emptyVaultView
                        }
                    }
                    // *** IMMEDIATE POP-IN EFFECT APPLIED HERE *** EXACT FROM SAMPLE
                    .opacity(contentVisible ? 1 : 0)
                    .scaleEffect(contentScale)
                    .offset(y: contentOffset)
                    // Animation is triggered by contentVisible = true
                    .animation(.spring(response: contentPopInDuration, dampingFraction: 0.9), value: contentVisible)
                    
                    // Transition is quick to bridge the gap between loader removal and pop-in
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.easeIn(duration: loaderFadeDuration)),
                            removal: .opacity.animation(.easeOut(duration: loaderFadeDuration))
                        )
                    )
                }
                
                // 4. --- Save Button ---
                if contentVisible {
                    doneButton
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white)
                    .matchedGeometryEffect(id: "buttonBackground", in: namespace)
            )
            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            .matchedGeometryEffect(id: "buttonContainer", in: namespace)
            .onAppear {
                // 1. Initial State - EXACT FROM SAMPLE
                isLoading = true
                contentVisible = false
                
                initializeActiveItemsFromCart()
                if selectedCategory == nil {
                    selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
                }
                
                // 2. Wait for the enforced minimum loading time (0.5s) - EXACT FROM SAMPLE
                DispatchQueue.main.asyncAfter(deadline: .now() + minLoadingDuration) {
                    
                    // 3. Simultaneously: - EXACT FROM SAMPLE
                    //    a) Remove loader (isLoading = false) using fade animation
                    //    b) Start the content pop-in (contentVisible = true) using spring animation
                    
                    withAnimation(.easeOut(duration: loaderFadeDuration)) {
                        isLoading = false
                    }
                    
                    // We trigger the pop-in immediately after the loader removal is initiated
                    // The duration of the pop-in (.35s) will make the content appear fluidly
                    withAnimation(.spring(response: contentPopInDuration, dampingFraction: 0.5)) {
                        contentVisible = true
                    }
                }
            }
            .onDisappear {
                // Reset states
                contentVisible = false
                isLoading = true
                
                // Save changes if any
                if hasActiveItems {
                    updateCartWithSelectedItems()
                    vaultService.updateCartTotals(cart: cart)
                }
            }
            .onTapGesture { /* Empty or handle dismissal */ }
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .overlay {
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
                        let success = vaultService.addItem(
                            name: itemName,
                            to: category,
                            store: store,
                            price: price,
                            unit: unit
                        )
                        
                        if success {
                            vaultUpdateTrigger += 1
                            
                            // Auto-scroll to the category where the item was added
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedCategory = category
                                }
                            }
                        } else {
                            duplicateError = "An item with this name already exists at \(store)"
                        }
                    },
                    onDismiss: {
                        duplicateError = nil
                    }
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
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
                                    UIApplication.shared.endEditing()
                                    
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
        }
    }
    
    private var categoryContentScrollView: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(GroceryCategory.allCases, id: \.self) { category in
                        AddItemsCategoryView(
                            category: category,
                            localActiveItems: $localActiveItems
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .id(category.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $selectedCategory)
            .scrollTargetBehavior(.paging)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedCategory)
        }
    }
    
    private var doneButton: some View {
        Button(action: {
            updateCartWithSelectedItems()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                isShowing = false
            }
        }) {
            Text("Save")
                .fuzzyBubblesFont(16, weight: .bold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(hasActiveItems ? Color.black : Color.gray)
                .cornerRadius(25)
        }
        .disabled(!hasActiveItems)
    }
    
    // MARK: - Helper Methods
    
    private func initializeActiveItemsFromCart() {
        localActiveItems.removeAll()
        
        for cartItem in cart.cartItems {
            localActiveItems[cartItem.itemId] = cartItem.quantity
        }
    }
    
    private func updateCartWithSelectedItems() {
        let selectedItemIds = Set(localActiveItems.keys)
        let currentCartItemIds = Set(cart.cartItems.map { $0.itemId })
        
        // Remove items that were deselected OR have zero quantity
        let itemsToRemove = currentCartItemIds.subtracting(selectedItemIds)
        for itemId in itemsToRemove {
            vaultService.removeItemFromCart(cart: cart, itemId: itemId)
        }
        
        // Add/Update selected items
        for (itemId, quantity) in localActiveItems {
            if let item = vaultService.findItemById(itemId) {
                if currentCartItemIds.contains(itemId) {
                    // Update existing item quantity
                    if let existingCartItem = cart.cartItems.first(where: { $0.itemId == itemId }) {
                        if quantity > 0 {
                            existingCartItem.quantity = quantity
                        } else {
                            // Remove item if quantity is 0
                            vaultService.removeItemFromCart(cart: cart, itemId: itemId)
                        }
                    }
                } else {
                    // Add new item only if quantity > 0
                    if quantity > 0 {
                        vaultService.addItemToCart(item: item, cart: cart, quantity: quantity)
                    }
                }
            }
        }
        
        vaultService.updateCartTotals(cart: cart)
    }
    
    private func selectCategory(_ category: GroceryCategory, proxy: ScrollViewProxy) {
        if let current = selectedCategory,
           let currentIndex = GroceryCategory.allCases.firstIndex(of: current),
           let newIndex = GroceryCategory.allCases.firstIndex(of: category) {
            navigationDirection = newIndex > currentIndex ? .right : .left
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedCategory = category
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
}
