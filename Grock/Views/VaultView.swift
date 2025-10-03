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
    
    @Environment(\.dismiss) private var dismiss
    var onCreateCart: (() -> Void)? // Callback for creating cart
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Category title
                HStack {
                    Text(selectedCategory?.title ?? "Select Category")
                        .font(.fuzzyBold_16)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                categoryScrollView
                    .padding(.bottom, 10)
                    .background(
                        Rectangle()
                            .fill(.white)
                            .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 1)
                            .mask(
                                Rectangle()
                                    .padding(.bottom, -20)
                            )
                    )
                
                itemsListView
            }
            
            // Floating Create Cart Button
            Button(action: {
                onCreateCart?() // Trigger the callback
            }) {
                Text("Create cart")
                    .font(.fuzzyBold_16)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.black)
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(.bottom, 20)
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("vault")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {}) {
                    Image("search")
                        .resizable()
                }
                .scaleEffect(toolbarAppeared ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0).delay(0.15), value: toolbarAppeared)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                 
                    
                    Button(action: {}) {
                        Text("Add")
                            .font(.fuzzyBold_13)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.black)
                            .cornerRadius(20)
                    }
                    .scaleEffect(toolbarAppeared ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0).delay(0.2), value: toolbarAppeared)
            }
        }
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
            }
            
            // Trigger toolbar animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                toolbarAppeared = true
            }
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(GroceryCategory.allCases) { category in
                    VaultCategoryIcon(
                        category: category,
                        isSelected: selectedCategory == category,
                        itemCount: getItemCount(for: category),
                        hasItems: hasItems(in: category)
                    ) {
                        selectedCategory = category
                        selectedStore = nil // Reset store filter when category changes
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func getItemCount(for category: GroceryCategory) -> Int {
        guard let vault = vaults.first else { return 0 }
        guard let foundCategory = vault.categories.first(where: { $0.name == category.title }) else { return 0 }
        return foundCategory.items.count
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
        Group {
            if let category = selectedCategory,
               let foundCategory = vault.categories.first(where: { $0.name == category.title }) {
                if foundCategory.items.isEmpty {
                    emptyCategoryView
                } else {
                    itemsList(items: filteredItems)
                }
            } else {
                emptyCategoryView
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
    
    private func itemsList(items: [Item]) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Store filter buttons
                if !availableStores.isEmpty {
                    storeFilterScrollView
                        .padding(.bottom, 16)
                }
                
                // Items list
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        ItemRowWithMultipleStores(item: item)
                        
                        if item.id != items.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var storeFilterScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All Stores" button
                StoreFilterButton(
                    storeName: "All Stores",
                    isSelected: selectedStore == nil
                ) {
                    selectedStore = nil
                }
                
                // Individual store buttons
                ForEach(availableStores, id: \.self) { store in
                    StoreFilterButton(
                        storeName: store,
                        isSelected: selectedStore == store
                    ) {
                        selectedStore = store
                    }
                }
            }
        }
    }
}

struct StoreFilterButton: View {
    let storeName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(storeName)
                .foregroundColor(isSelected ? .black : .gray)
        }
    }
}

struct ItemRowWithMultipleStores: View {
    let item: Item
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                // Item name
                Text(item.name)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                // Price options from different stores
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(item.priceOptions, id: \.store) { option in
                        HStack(spacing: 8) {
                            Text(option.store)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.gray)
                                .frame(width: 80, alignment: .leading)
                            
                            Text("₱\(option.pricePerUnit.priceValue, specifier: "%.2f")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("/ \(option.pricePerUnit.unit)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                // TODO: Add to cart action
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        VaultView()
            .modelContainer(for: [Vault.self, Store.self, Item.self])
    }
}
