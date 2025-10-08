import SwiftUI
import SwiftData

struct VaultView: View {
    @Query var vaults: [Vault]
    @State private var selectedCategory: GroceryCategory?
    @State private var toolbarAppeared = false
    @State private var showAddItemPopover = false
    @State private var createCartButtonVisible = true
    @State private var scrollProxy: ScrollViewProxy?
    
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    var onCreateCart: (() -> Void)?
    
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
                
                VaultCategorySectionView(selectedCategory: selectedCategory) {
                    categoryScrollView
                }
                
                categoryContentScrollView
            }
            
            Button(action: {
                onCreateCart?()
            }) {
                Text("Create cart")
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
            
            if showAddItemPopover {
                AddItemPopover(
                    isPresented: $showAddItemPopover,
                    onSave: { itemName, category, store, unit, price in
                        saveNewItem(
                            name: itemName,
                            category: category,
                            store: store,
                            unit: unit,
                            price: price
                        )
                    },
                    onDismiss: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            showCreateCartButton()
                        }
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
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                toolbarAppeared = true
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
        }
    }

    private var categoryContentScrollView: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(GroceryCategory.allCases, id: \.self) { category in
                        CategoryItemsView(
                            category: category,
                            vaults: vaults,
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
            .onAppear {
                if selectedCategory == nil {
                    selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
                }
            }
        }
    }

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
    
    struct CategoryItemsView: View {
        let category: GroceryCategory
        let vaults: [Vault]
        let onDeleteItem: (Item) -> Void
        
        private var categoryItems: [Item] {
            guard let vault = vaults.first,
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
    
    // Rest of your existing methods remain the same...
    private func saveNewItem(name: String, category: GroceryCategory, store: String, unit: String, price: Double) {
        guard let vault = vaults.first else { return }
        
        // Find or create the category
        var targetCategory = vault.categories.first(where: { $0.name == category.title })
        
        if targetCategory == nil {
            // Create new category if it doesn't exist
            let newCategory = Category(name: category.title)
            vault.categories.append(newCategory)
            targetCategory = newCategory
        }
        
        // Create new item
        let newItem = Item(name: name)
        
        // Create price per unit
        let pricePerUnit = PricePerUnit(priceValue: price, unit: unit)
        
        // Create price option with store and pricePerUnit
        let priceOption = PriceOption(store: store, pricePerUnit: pricePerUnit)
        newItem.priceOptions.append(priceOption)
        
        // Add item to category
        targetCategory?.items.append(newItem)
        
        // Save context
        try? modelContext.save()
        
        // Switch to the newly added item's category
        selectedCategory = category
    }
    
    private func showCreateCartButton() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)) {
            createCartButtonVisible = true
        }
    }
    
    // Find the first category that has items from onboarding
    private var firstCategoryWithItems: GroceryCategory? {
        guard let vault = vaults.first else { return nil }
        
        // Find the first category that has items
        for category in vault.categories {
            if !category.items.isEmpty {
                // Convert category name to GroceryCategory
                return GroceryCategory.allCases.first { $0.title == category.name }
            }
        }
        
        return nil
    }
    
    private func getItemCount(for category: GroceryCategory) -> Int {
        guard let vault = vaults.first else { return 0 }
        guard let foundCategory = vault.categories.first(where: { $0.name == category.title }) else { return 0 }
        
        // Count only active items (items that are in the current cart)
        let activeItemsCount = foundCategory.items.reduce(0) { count, item in
            let isActive = (cartViewModel.activeCartItems[item.id] ?? 0) > 0
            return count + (isActive ? 1 : 0)
        }
        
        return activeItemsCount
    }
    
    private func hasItems(in category: GroceryCategory) -> Bool {
        getItemCount(for: category) > 0
    }
    
    private func deleteItem(_ item: Item) {
        guard let vault = vaults.first else { return }
        
        // Find the category that contains this item
        for category in vault.categories {
            if let index = category.items.firstIndex(where: { $0.id == item.id }) {
                category.items.remove(at: index)
                try? modelContext.save()
                break
            }
        }
    }
}

#Preview {
    NavigationStack {
        VaultView()
            .modelContainer(for: [Vault.self, Item.self])
    }
}
