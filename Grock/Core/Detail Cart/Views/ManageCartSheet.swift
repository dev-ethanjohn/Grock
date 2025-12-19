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
    
    // Add navigation direction for smooth category transitions
    @State private var navigationDirection: NavigationDirection = .none
    
    enum NavigationDirection {
        case left, right, none
    }
    
    private var hasActiveItems: Bool {
        !localActiveItems.isEmpty
    }
    
    // Computed property that reacts to vault changes
    private var currentVault: Vault? {
        vaultService.vault
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    customToolbar
                    
                    // Use currentVault instead of vaultService.vault directly
                    if let vault = currentVault, !vault.categories.isEmpty {
                        VStack(spacing: 0) {
                            categoryScrollView
                                .padding(.top, 8)
                                .padding(.bottom, 10)
                        }
                        .background(
                            Rectangle()
                                .fill(.white)
                                .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 1)
                                .mask(
                                    Rectangle()
                                        .padding(.bottom, -20)
                                )
                        )
                        
                        categoryContentScrollView
                    } else {
                        emptyVaultView
                    }
                }
                
                VStack {
                    Spacer()
                    doneButton
                        .padding(.bottom, 20)
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
                            let success = vaultService.addItem(
                                name: itemName,
                                to: category,
                                store: store,
                                price: price,
                                unit: unit
                            )
                            
                            if success {
                                print("✅ Item added successfully: \(itemName)")
                                // Force view update after adding item
                                vaultUpdateTrigger += 1
                                
                                // Auto-scroll to the category where the item was added
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedCategory = category
                                    }
                                }
                            } else {
                                print("❌ Failed to add item - duplicate name: \(itemName)")
                                duplicateError = "An item with this name already exists at \(store)"
                            }
                        },
                        onDismiss: {
                            // Clear any duplicate error when popover is dismissed
                            duplicateError = nil
                        }
                    )
                    .offset(y: UIScreen.main.bounds.height * -0.04)
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {}) {
                        Image("search")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
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
                }
            }
            .navigationTitle("Manage Cart")
            .navigationBarTitleDisplayMode(.inline)
            .background(.white)
            .ignoresSafeArea(.keyboard)
            .onAppear {
                initializeActiveItemsFromCart()
                if selectedCategory == nil {
                    selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
                }
            }
            // Add onChange to watch for vault updates and category changes
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
            // Listen for category change notifications (from EditItemSheet)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ItemCategoryChanged"))) { notification in
                if let newCategory = notification.userInfo?["newCategory"] as? GroceryCategory {
                    print("🔄 ManageCartSheet: Received category change notification - switching to \(newCategory.title)")
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedCategory = newCategory
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
    }
    
    private var customToolbar: some View {
        HStack {
            if let category = selectedCategory {
                Text(category.title)
                    .lexendFont(13, weight: .bold)
                    .contentTransition(.identity)
                    .animation(.spring(duration: 0.3), value: selectedCategory?.id)
                    .transition(.push(from: .leading))
            } else {
                Text("Select Category")
                    .fuzzyBubblesFont(13, weight: .bold)
            }
            Spacer()
        }
        .padding(.horizontal)
        .background(Color.white)
    }
    
    private var categoryScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    // ✅ ADDED: Responsive black border that follows selected category
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
                                    // Dismiss keyboard immediately when tapping category
                                    UIApplication.shared.endEditing()
                                    
                                    // Set navigation direction for smooth transitions
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
            // ✅ ADDED: Smooth animation with navigation direction
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedCategory)
        }
    }
    
    private var doneButton: some View {
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
                .background(hasActiveItems ? Color.black : Color.gray)
                .cornerRadius(25)
        }
        .padding(.bottom, 20)
        .disabled(!hasActiveItems)
    }
    
    // MARK: - Helper Methods
    
    private func initializeActiveItemsFromCart() {
        print("🔄 AddItemsToCartSheet: Initializing from cart '\(cart.name)'")
        
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
                        vaultService.addItemToCart(item: item, cart: cart, quantity: quantity)
                    }
                }
            }
        }
        
        vaultService.updateCartTotals(cart: cart)
        print("   ✅ Final cart items: \(cart.cartItems.count)")
    }
    
    private func selectCategory(_ category: GroceryCategory, proxy: ScrollViewProxy) {
        // Set navigation direction for smooth animation
        if let current = selectedCategory,
           let currentIndex = GroceryCategory.allCases.firstIndex(of: current),
           let newIndex = GroceryCategory.allCases.firstIndex(of: category) {
            navigationDirection = newIndex > currentIndex ? .right : .left
        }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedCategory = category
        }
        
        print("🎯 Selected category: '\(category.title)'")
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

// MARK: - Category Items View for Add Items Sheet
struct AddItemsCategoryView: View {
    let category: GroceryCategory
    @Binding var localActiveItems: [String: Double]
    
    @Environment(VaultService.self) private var vaultService
    
    // Use computed property that reacts to vault changes
    private var categoryItems: [Item] {
        guard let vault = vaultService.vault,
              let foundCategory = vault.categories.first(where: { $0.name == category.title })
        else { return [] }
        return foundCategory.items.sorted { $0.createdAt > $1.createdAt } // Sort by newest first
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
                AddItemsVaultItemsListView(
                    items: categoryItems,
                    availableStores: availableStores,
                    category: category,
                    localActiveItems: $localActiveItems
                )
            }
        }
        .onAppear {
            print("📱 AddItemsCategoryView appeared for: '\(category.title)'")
            print("   Items count: \(categoryItems.count)")
        }
        // Add animation for smooth updates
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: categoryItems.count)
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

// MARK: - VaultItemsListView for Add Items Sheet (using local state)
struct AddItemsVaultItemsListView: View {
    let items: [Item]
    let availableStores: [String]
    let category: GroceryCategory?
    @Binding var localActiveItems: [String: Double]
    
    var body: some View {
        List {
            ForEach(availableStores, id: \.self) { store in
                AddItemsStoreSection(
                    storeName: store,
                    items: itemsForStore(store),
                    category: category,
                    localActiveItems: $localActiveItems
                )
            }
        }
        .listStyle(PlainListStyle())
        .listSectionSpacing(16)
    }
    
    private func itemsForStore(_ store: String) -> [Item] {
        items.filter { item in
            item.priceOptions.contains { $0.store == store }
        }
    }
}

// MARK: - StoreSection for Add Items Sheet (using local state)
struct AddItemsStoreSection: View {
    let storeName: String
    let items: [Item]
    let category: GroceryCategory?
    @Binding var localActiveItems: [String: Double]
    
    var body: some View {
        Section(
            header:
                HStack {
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
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                VStack(spacing: 0) {
                    AddItemsVaultItemRow(
                        item: item,
                        category: category,
                        localActiveItems: $localActiveItems
                    )
                    
                    if index < items.count - 1 {
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
            }
        }
    }
}

// MARK: - VaultItemRow for Add Items Sheet (using local state)
struct AddItemsVaultItemRow: View {
    let item: Item
    let category: GroceryCategory?
    @Binding var localActiveItems: [String: Double]
    
    @Environment(VaultService.self) private var vaultService
    @State private var showEditSheet = false
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    // Track if this is a newly added item for animation
    @State private var isNewlyAdded = true
    @State private var appearScale: CGFloat = 0.8
    @State private var appearOpacity: Double = 0
    @State private var deleteBackgroundOpacity: Double = 0 // Control delete UI visibility
    
    private var currentQuantity: Double {
        localActiveItems[item.id] ?? 0
    }
    
    private var isActive: Bool {
        currentQuantity > 0
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Swipe to delete background - Only show when swiped or explicitly triggered
            if isSwiped || deleteBackgroundOpacity > 0 {
                deleteBackground
                    .opacity(deleteBackgroundOpacity)
            }
            
            // Main content
            mainContent
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // If swiped open, tap to close
            if isSwiped {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                    isSwiped = false
                    deleteBackgroundOpacity = 0
                }
            } else {
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
                deleteItem()
            } label: {
                Label("Delete from Vault", systemImage: "trash")
            }
        }
        .onChange(of: currentQuantity) { oldValue, newValue in
            if !isFocused {
                textValue = formatValue(newValue)
            }
        }
        .onAppear {
            // Animate new items in
            if isNewlyAdded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    appearScale = 1.0
                    appearOpacity = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isNewlyAdded = false
                }
            }
        }
    }
    
    private var deleteBackground: some View {
        HStack {
            Spacer()
            Button(action: {
                deleteItem()
            }) {
                ZStack {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 80)
                    
                    VStack {
                        Image(systemName: "trash")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("Delete")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 80)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var mainContent: some View {
        HStack(alignment: .top, spacing: 4) {
            Circle()
                .fill(isActive ? (category?.pastelColor.saturated(by: 0.3).darker(by: 0.5) ?? Color.primary) : .clear)
                .frame(width: 9, height: 9)
                .padding(.top, 8)
                .scaleEffect(isActive ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)
            
            VStack(alignment: .leading, spacing: 0) {
                
                Text(item.name)
                    .foregroundColor(isActive ? .black : Color(hex: "999"))
                
                if let priceOption = item.priceOptions.first {
                    HStack(spacing: 0) {
                        Text("₱\(priceOption.pricePerUnit.priceValue, specifier: "%g")")
                        Text("/\(priceOption.pricePerUnit.unit)")
                            .lexendFont(12, weight: .medium)
                        Spacer()
                    }
                    .lexendFont(12, weight: .medium)
                    .foregroundColor(isActive ? .black : Color(hex: "999"))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            
            Spacer()
            
            HStack(spacing: 8) {
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
                .scaleEffect(isActive ? 1 : 0)
                .frame(width: isActive ? 24 : 0)
                
                ZStack {
                    Text(textValue)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "2C3E50"))
                        .multilineTextAlignment(.center)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: textValue)
                    
                    TextField("", text: $textValue)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.clear)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .onChange(of: isFocused) { oldValue, newValue in
                            if !newValue { commitTextField() }
                        }
                        .onChange(of: textValue) { oldValue, newValue in
                            if let number = Double(newValue), number > 100 {
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
                .scaleEffect(isActive ? 1 : 0)
                .frame(width: isActive ? nil : 0)
                .onAppear {
                    textValue = formatValue(currentQuantity)
                }
                .onChange(of: currentQuantity) { oldValue, newValue in
                    if !isFocused {
                        textValue = formatValue(newValue)
                    }
                }
                
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
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActive)
            .padding(.top, 6)
        }
        .padding(.bottom, 4)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.white)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
        .offset(x: offset)
        .scaleEffect(appearScale)
        .opacity(appearOpacity)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Allow swiping for ALL items (active and inactive)
                    if value.translation.width < 0 {
                        offset = value.translation.width
                        // Gradually show delete background as user swipes
                        let progress = min(abs(value.translation.width) / 80, 1.0)
                        deleteBackgroundOpacity = progress
                    }
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if value.translation.width < -100 {
                            offset = -80
                            isSwiped = true
                            deleteBackgroundOpacity = 1.0
                        } else {
                            offset = 0
                            isSwiped = false
                            deleteBackgroundOpacity = 0
                        }
                    }
                }
        )
    }
    
    private func deleteItem() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Remove from local active items (if it was active)
            localActiveItems.removeValue(forKey: item.id)
            // Delete the item from the vault (permanent deletion)
            vaultService.deleteItem(item)
            offset = 0
            isSwiped = false
            deleteBackgroundOpacity = 0
        }
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
    }
    
    private func formatValue(_ val: Double) -> String {
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
