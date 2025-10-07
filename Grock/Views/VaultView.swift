//
//  VaultView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import SwiftUI
import SwiftData

struct VaultView: View {
    @Query var vaults: [Vault]
    @State private var selectedCategory: GroceryCategory?
    @State private var selectedStore: String? = nil
    @State private var toolbarAppeared = false
    @State private var showAddItemPopover = false
    @State private var createCartButtonVisible = true
    
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
                
                itemsListView
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
    
    // Save new item to vault
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
    
    // Get current category items
    private var currentCategoryItems: [Item] {
        guard let category = selectedCategory,
              let vault = vaults.first,
              let foundCategory = vault.categories.first(where: { $0.name == category.title })
        else { return [] }
        return foundCategory.items
    }
    
    // Get all unique stores from price options in current category
    private var availableStores: [String] {
        let allStores = currentCategoryItems.flatMap { item in
            item.priceOptions.map { $0.store }
        }
        return Array(Set(allStores)).sorted()
    }
    
    // Get items filtered by selected store (if any)
    private var filteredItems: [Item] {
        guard let store = selectedStore else { return currentCategoryItems }
        
        return currentCategoryItems.filter { item in
            item.priceOptions.contains { $0.store == store }
        }
    }

    private var categoryScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    // Sliding selection indicator
                    if let selectedCategory = selectedCategory,
                       let selectedIndex = GroceryCategory.allCases.firstIndex(of: selectedCategory) {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.black, lineWidth: 2)
                            .frame(width: 50, height: 50)
                            .offset(x: CGFloat(selectedIndex) * 51) // 50 width + 1 spacing
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCategory)
                    }
                    
                    // Category icons
                    HStack(spacing: 1) {
                        ForEach(GroceryCategory.allCases) { category in
                            VaultCategoryIcon(
                                category: category,
                                isSelected: selectedCategory == category,
                                itemCount: getItemCount(for: category),
                                hasItems: hasItems(in: category),
                                action: {
                                    // Only update if different category is selected
                                    guard selectedCategory != category else { return }
                                    
                                    selectedStore = nil
                                    
                                    // Use a single animation context
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedCategory = category
                                        proxy.scrollTo(category.id, anchor: .center)
                                    }
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
    
    private var itemsListView: some View {
        Group {
            if selectedCategory == nil {
                noCategorySelectedView
            } else if let vault = vaults.first {
                categoryItemsList(vault: vault)
            } else {
                emptyVaultView
            }
        }
    }

    private func categoryItemsList(vault: Vault) -> some View {
        ZStack {
            if let category = selectedCategory,
               let foundCategory = vault.categories.first(where: { $0.name == category.title }) {
                if foundCategory.items.isEmpty {
                    emptyCategoryView
                } else {
                    VaultItemsListView(
                        items: filteredItems,
                        availableStores: availableStores,
                        selectedStore: $selectedStore,
                        category: selectedCategory,
                        onDeleteItem: { item in
                            deleteItem(item)
                        }
                    )
                }
            } else {
                emptyCategoryView
            }
        }
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

    
    private var noCategorySelectedView: some View {
        VStack {
            Spacer()
            Text("Please select a category")
                .foregroundColor(.gray)
            Spacer()
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
    
    private var emptyVaultView: some View {
        VStack {
            Spacer()
            Text("No vault yet.")
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

struct CategoryFramePreference: PreferenceKey {
    static var defaultValue: [GroceryCategory.ID: CGRect] = [:]
    
    static func reduce(value: inout [GroceryCategory.ID: CGRect], nextValue: () -> [GroceryCategory.ID: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

#Preview {
    NavigationStack {
        VaultView()
            .modelContainer(for: [Vault.self, Item.self])
    }
}
