import Foundation
import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
class EditItemViewModel {
    
    // MARK: - Dependencies
    private let vaultService: VaultService
    let item: Item
    let context: EditContext
    
    // MARK: - Form State
    var itemName: String = ""
    var selectedCategory: GroceryCategory?
    var storeName: String = ""
    var price: String = ""
    var unit: String = "g"
    
    // MARK: - UI State
    var showUnitPicker = false
    var showAddStoreSheet = false
    var newStoreName = ""
    var itemNameFieldIsFocused = false
    
    // MARK: - Error State
    var duplicateError: String?
    
    // MARK: - Computed Properties
    var selectedCategoryEmoji: String {
        selectedCategory?.emoji ?? "plus.circle.fill"
    }
    
    var availableStores: [String] {
        vaultService.getAllStores()
    }
    
    var isFormValid: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCategory != nil &&
        !storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(price) != nil
    }
    
    var isFormValidForSave: Bool {
        isFormValid && duplicateError == nil
    }
    
    // MARK: - Initialization
    init(item: Item, context: EditContext, vaultService: VaultService) {
        self.item = item
        self.context = context
        self.vaultService = vaultService
        initializeFormValues()
    }
    
    // MARK: - Form Initialization
    private func initializeFormValues() {
        let priceOption = item.priceOptions.first
        
        // Set initial values
        itemName = item.name
        storeName = priceOption?.store ?? ""
        price = String(priceOption?.pricePerUnit.priceValue ?? 0)
        unit = priceOption?.pricePerUnit.unit ?? "g"
        
        // Find the current category
        if let categoryName = vaultService.vault?.categories.first(where: { $0.items.contains(where: { $0.id == item.id }) })?.name,
           let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == categoryName }) {
            selectedCategory = groceryCategory
        }
    }
    
    // MARK: - Store Management
    func addNewStore() {
        let trimmedStore = newStoreName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStore.isEmpty else { return }
        
        vaultService.addStore(trimmedStore)
        storeName = trimmedStore
        newStoreName = ""
        showAddStoreSheet = false
        print("➕ New store added and persisted: \(trimmedStore)")
    }
    
    // MARK: - Save Operations
    func saveChanges() -> Bool {
        guard let priceValue = Double(price),
              let selectedCategory = selectedCategory else { return false }
        
        // Validate for duplicates (excluding current item)
        let validation = vaultService.validateItemName(itemName, excluding: item.id)
        if !validation.isValid {
            duplicateError = validation.errorMessage
            print("❌ Cannot save item: \(validation.errorMessage ?? "Unknown error")")
            return false
        }
        
        // Store the old category for comparison
        let oldCategoryName = vaultService.vault?.categories.first(where: { $0.items.contains(where: { $0.id == item.id }) })?.name
        
        // Update the item in the vault
        let success = vaultService.updateItem(
            item: item,
            newName: itemName.trimmingCharacters(in: .whitespacesAndNewlines),
            newCategory: selectedCategory,
            newStore: storeName.trimmingCharacters(in: .whitespacesAndNewlines),
            newPrice: priceValue,
            newUnit: unit
        )
        
        if success {
            duplicateError = nil
            
            // Notify about category change if needed
            if oldCategoryName != selectedCategory.title {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ItemCategoryChanged"),
                    object: nil,
                    userInfo: [
                        "newCategory": selectedCategory,
                        "itemId": item.id
                    ]
                )
            }
        } else {
            duplicateError = "Failed to update item. Please try again."
        }
        
        return success
    }
    
    // MARK: - Helper Methods
    func selectStore(_ store: String) {
        storeName = store
    }
    
    func clearDuplicateError() {
        duplicateError = nil
    }
    
    func validateItemName() {
        let validation = vaultService.validateItemName(itemName, excluding: item.id)
        if !validation.isValid {
            duplicateError = validation.errorMessage
        } else {
            duplicateError = nil
        }
    }
}
