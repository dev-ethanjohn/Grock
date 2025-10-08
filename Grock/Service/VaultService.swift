//
//  VaultService.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/8/25.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
class VaultService {
    private let modelContext: ModelContext
    
    // Current state
    var vault: Vault?
    var isLoading = false
    var error: Error?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadVault()
    }
    
    // In VaultService, add this computed property
    var sortedCategories: [Category] {
        vault?.categories.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }
    
    func loadVault() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let descriptor = FetchDescriptor<Vault>()
            let vaults = try modelContext.fetch(descriptor)
            
            if let existingVault = vaults.first {
                self.vault = existingVault
                
                // Ensure all categories exist in existing vault
                ensureAllCategoriesExist(in: existingVault)
            } else {
                // Create new vault for user
                let newVault = Vault()
                modelContext.insert(newVault)
                
                // Pre-populate with all categories
                prePopulateCategories(in: newVault)
                
                try modelContext.save()
                self.vault = newVault
            }
        } catch {
            self.error = error
            print("❌ Failed to load vault: \(error)")
        }
    }

    private func ensureAllCategoriesExist(in vault: Vault) {
        // Create a dictionary of existing categories for quick lookup
        let existingCategoriesDict = Dictionary(uniqueKeysWithValues: vault.categories.map { ($0.name, $0) })
        
        // Create new array in the correct order WITH SORT ORDER
        var orderedCategories: [Category] = []
        var needsSave = false
        
        for (index, groceryCategory) in GroceryCategory.allCases.enumerated() {
            let categoryName = groceryCategory.title
            
            if let existingCategory = existingCategoriesDict[categoryName] {
                // Update sort order if needed
                if existingCategory.sortOrder != index {
                    existingCategory.sortOrder = index
                    needsSave = true
                }
                orderedCategories.append(existingCategory)
            } else {
                // Create new category with correct sort order
                let newCategory = Category(name: categoryName)
                newCategory.sortOrder = index
                orderedCategories.append(newCategory)
                needsSave = true
                print("➕ Created missing category: \(categoryName) with order \(index)")
            }
        }
        
        // Sort by sortOrder to ensure correct order
        vault.categories = orderedCategories.sorted { $0.sortOrder < $1.sortOrder }
        
        if needsSave {
            saveContext()
            print("✅ Categories ordered with sort indexes")
        }
    }
    
//    func migrateCategoriesWithSortOrder() {
//        guard let vault = vault else { return }
//        
//        for (index, category) in vault.categories.enumerated() {
//            category.sortOrder = index
//        }
//        
//        saveContext()
//        print("✅ Migrated categories with sort order")
//    }

    private func prePopulateCategories(in vault: Vault) {
        // Clear any existing categories
        vault.categories.removeAll()
        
        // Add categories with proper sort order
        for (index, groceryCategory) in GroceryCategory.allCases.enumerated() {
            let category = Category(name: groceryCategory.title)
            category.sortOrder = index
            vault.categories.append(category)
        }
    }
    
    // MARK: - Category Operations
    func addCategory(_ category: GroceryCategory) {
        guard let vault = vault else { return }
        
        let newCategory = Category(name: category.title)
        vault.categories.append(newCategory)
        
        saveContext()
    }
    
    func getCategory(_ groceryCategory: GroceryCategory) -> Category? {
        vault?.categories.first { $0.name == groceryCategory.title }
    }
    
    // MARK: - Item Operations
    func addItem(
        name: String,
        to category: GroceryCategory,
        store: String,
        price: Double,
        unit: String
    ) {
        guard let vault = vault else { return }
        
        // Find or create category
        let targetCategory: Category
        if let existingCategory = getCategory(category) {
            targetCategory = existingCategory
        } else {
            targetCategory = Category(name: category.title)
            vault.categories.append(targetCategory)
        }
        
        // Create item with price option
        let pricePerUnit = PricePerUnit(priceValue: price, unit: unit)
        let priceOption = PriceOption(store: store, pricePerUnit: pricePerUnit)
        let newItem = Item(name: name)
        newItem.priceOptions = [priceOption]
        
        targetCategory.items.append(newItem)
        saveContext()
    }
    
    func deleteItem(_ item: Item) {
        guard let vault = vault else { return }
        
        for category in vault.categories {
            if let index = category.items.firstIndex(where: { $0.id == item.id }) {
                category.items.remove(at: index)
                saveContext()
                break
            }
        }
    }
    
    // MARK: - Store Operations
    func getAllStores() -> [String] {
        guard let vault = vault else { return [] }
        
        let allStores = vault.categories.flatMap { category in
            category.items.flatMap { item in
                item.priceOptions.map { $0.store }
            }
        }
        
        return Array(Set(allStores)).sorted()
    }
    
    // MARK: - Cart Operations
    func createCart(name: String, budget: Double) -> Cart {
        let newCart = Cart(name: name, budget: budget)
        vault?.carts.append(newCart)
        saveContext()
        return newCart
    }
    
    // MARK: - Helper
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            self.error = error
            print("❌ Failed to save vault: \(error)")
        }
    }
}
