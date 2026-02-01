import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class ItemFormViewModel {
    // MARK: - Form Data
    var itemName: String = ""
    var storeName: String = ""
    var itemPrice: String = ""
    var unit: String = "g"
    var selectedCategory: GroceryCategory?
    var portion: Double?
    
    // MARK: - Mode-Aware Properties
    var shouldUpdateVault: Bool = true
    
    // MARK: - Validation State
    var attemptedSubmission = false
    var firstMissingField: String? = nil
    var invalidSubmissionCount = 0
    
    // MARK: - Configuration
    let requiresPortion: Bool
    let requiresStore: Bool
    let context: EditContext
    
    init(requiresPortion: Bool = false, requiresStore: Bool = true, context: EditContext = .vault) {
        self.requiresPortion = requiresPortion
        self.requiresStore = requiresStore
        self.context = context
    }
    
    // MARK: - Computed Properties
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
    
    // MARK: - Validation Methods
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
    
    // MARK: - Data Population Methods
    
    func populateFromItem(_ item: Item, vaultService: VaultService, cart: Cart? = nil, cartItem: CartItem? = nil) {
        let priceOption = item.priceOptions.first
        
        // ALWAYS use item.name from Vault
        itemName = item.name
        
        // For store: use plannedStore if in cart context
        if let cart = cart, let cartItem = cartItem, cart.status == .planning {
            storeName = cartItem.plannedStore
        } else {
            storeName = priceOption?.store ?? ""
        }
        
        // For price: use plannedPrice if in cart context
        if let cart = cart, let cartItem = cartItem, cart.status == .planning {
            if let plannedPrice = cartItem.plannedPrice {
                itemPrice = String(plannedPrice)
            } else {
                itemPrice = String(priceOption?.pricePerUnit.priceValue ?? 0)
            }
        } else {
            itemPrice = String(priceOption?.pricePerUnit.priceValue ?? 0)
        }
        
        unit = priceOption?.pricePerUnit.unit ?? "g"
        
        // Handle portion
        if requiresPortion, let cart = cart, let cartItem = cartItem, cart.status == .planning {
            portion = cartItem.quantity
        }
        
        // Load category from vault
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
        shouldUpdateVault = true
        resetValidation()
    }
    
    // MARK: - Helper Methods
    
    func shouldShowCategoryField() -> Bool {
        // Show category field always (no shopping mode editing)
        return true
    }
    
    func getSaveButtonTitle() -> String {
        // Always show "Update" regardless of context
        return "Update"
    }
    
    func getSaveButtonColor() -> Color {
        // Always use black background
        return .black
    }
}

enum EditContext {
    case vault
    case cart
}
