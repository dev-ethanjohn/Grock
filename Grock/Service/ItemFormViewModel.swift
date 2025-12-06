//
//  ItemFormViewModel.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/18/25.
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class ItemFormViewModel {
    // Form Data
    var itemName: String = ""
    var storeName: String = ""
    var itemPrice: String = ""
    var unit: String = "g"
    var selectedCategory: GroceryCategory?
    var portion: Double?
    
    // Validation State
    var attemptedSubmission = false
    var firstMissingField: String? = nil
    var invalidSubmissionCount = 0
    
    // Configuration
    let requiresPortion: Bool
    let requiresStore: Bool
    
    init(requiresPortion: Bool = false, requiresStore: Bool = true) {
        self.requiresPortion = requiresPortion
        self.requiresStore = requiresStore
    }
    
    // Computed Properties
    var isValidStoreName: Bool {
        let trimmed = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1
    }
    
    var isFormValid: Bool {
        var valid = !itemName.isEmpty &&
                   Double(itemPrice) != nil &&
                   Double(itemPrice) ?? 0 > 0 &&
                   !unit.isEmpty &&
                   selectedCategory != nil
        
        if requiresStore {
            valid = valid && isValidStoreName
        }
        
        if requiresPortion {
            valid = valid && (portion != nil && portion ?? 0 > 0)
        }
        
        return valid
    }
    
    var selectedCategoryEmoji: String {
        selectedCategory?.emoji ?? "plus.circle.fill"
    }
    
    // Validation Methods
    func validateAndGetFirstMissingField() -> String? {
        if itemName.isEmpty {
            return "Item Name"
        }
        if selectedCategory == nil {
            return "Category"
        }
        if requiresStore && !isValidStoreName {
            return "Store Name"
        }
        if requiresPortion && (portion == nil || portion == 0) {
            return "Portion"
        }
        if unit.isEmpty {
            return "Unit"
        }
        if Double(itemPrice) == nil || Double(itemPrice) == 0 {
            return "Price"
        }
        return nil
    }
    
    func attemptSubmission() -> Bool {
        attemptedSubmission = true
        firstMissingField = validateAndGetFirstMissingField()
        
        if firstMissingField != nil {
            invalidSubmissionCount += 1
        } else {
            invalidSubmissionCount = 0
        }
        
        return firstMissingField == nil
    }
    
    func clearErrorForField(_ field: String) {
        if firstMissingField == field {
            firstMissingField = nil
        }
    }
    
    func resetValidation() {
        attemptedSubmission = false
        firstMissingField = nil
        invalidSubmissionCount = 0
    }
    
    // Data Methods
//    func populateFromItem(_ item: Item, vaultService: VaultService) {
//        let priceOption = item.priceOptions.first
//        
//        itemName = item.name
//        storeName = priceOption?.store ?? ""
//        itemPrice = String(priceOption?.pricePerUnit.priceValue ?? 0)
//        unit = priceOption?.pricePerUnit.unit ?? "g"
//        
//        // Find the current category
//        if let categoryName = vaultService.vault?.categories.first(where: {
//            $0.items.contains(where: { $0.id == item.id })
//        })?.name,
//        let groceryCategory = GroceryCategory.allCases.first(where: {
//            $0.title == categoryName
//        }) {
//            selectedCategory = groceryCategory
//        }
//    }
    // In ItemFormViewModel.swift, update the populateFromItem method:
    // In ItemFormViewModel.swift
    func populateFromItem(_ item: Item, vaultService: VaultService, isCartContext: Bool = false, cart: Cart? = nil, cartItem: CartItem? = nil) {
        let priceOption = item.priceOptions.first
        
        itemName = item.name
        storeName = priceOption?.store ?? ""
        itemPrice = String(priceOption?.pricePerUnit.priceValue ?? 0)
        unit = priceOption?.pricePerUnit.unit ?? "g"
        
        // Handle portion based on context
        if isCartContext, let cart = cart, let cartItem = cartItem {
            // In cart context: use cart item quantity
            portion = cartItem.getQuantity(cart: cart)
        } else {
            // In vault context: set portion to nil (or don't set it at all)
            portion = nil
        }
        
        // Find the current category
        if let categoryName = vaultService.vault?.categories.first(where: {
            $0.items.contains(where: { $0.id == item.id })
        })?.name,
        let groceryCategory = GroceryCategory.allCases.first(where: {
            $0.title == categoryName
        }) {
            selectedCategory = groceryCategory
        }
    }
    func resetForm() {
        itemName = ""
        storeName = ""
        itemPrice = ""
        unit = "g"
        selectedCategory = nil
        portion = nil
        resetValidation()
    }
}
