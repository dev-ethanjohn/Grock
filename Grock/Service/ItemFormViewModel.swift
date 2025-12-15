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
    var isEditingActualData: Bool = false
    var shouldUpdateVault: Bool = true
    var modeDescription: String = ""
    
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
                   !unit.isEmpty
        
        // Category is only required for vault/planning edits
        if shouldUpdateVault || context == .vault {
            valid = valid && selectedCategory != nil
        }
        
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
    
    var isShoppingModeEditing: Bool {
        context == .cart && !shouldUpdateVault
    }
    
    // MARK: - Validation Methods
    func validateAndGetFirstMissingField() -> String? {
        if itemName.isEmpty {
            return "Item Name"
        }
        
        // Category validation depends on mode
        if shouldUpdateVault && selectedCategory == nil {
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
    
    // In ItemFormViewModel.swift
    func populateFromItem(_ item: Item, vaultService: VaultService, cart: Cart? = nil, cartItem: CartItem? = nil) {
        let priceOption = item.priceOptions.first
        
        // ALWAYS use item.name from Vault (not editable in shopping)
        itemName = item.name
        
        // For store: in shopping mode, use actualStore if exists
        if let cart = cart, cart.status == .shopping, let cartItem = cartItem {
            storeName = cartItem.actualStore ?? cartItem.plannedStore
        } else {
            storeName = priceOption?.store ?? ""
        }
        
        // For price: in shopping mode, use actualPrice if exists
        if let cart = cart, cart.status == .shopping, let cartItem = cartItem {
            if let actualPrice = cartItem.actualPrice {
                itemPrice = String(actualPrice)
            } else if let plannedPrice = cartItem.plannedPrice {
                itemPrice = String(plannedPrice)
            } else {
                itemPrice = String(priceOption?.pricePerUnit.priceValue ?? 0)
            }
        } else {
            itemPrice = String(priceOption?.pricePerUnit.priceValue ?? 0)
        }
        
        unit = priceOption?.pricePerUnit.unit ?? "g"
        
        // Determine mode
        determineMode(cart: cart, cartItem: cartItem)
        
        // Handle portion
        if requiresPortion, let cart = cart, let cartItem = cartItem {
            if cart.status == .shopping {
                portion = cartItem.actualQuantity ?? cartItem.quantity
            } else {
                portion = cartItem.quantity
            }
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
        
        print("✅ populateFromItem - itemName always from vault: \(item.name)")
    }
    
    func populateFromCartItem(_ item: Item, cartItem: CartItem, isActualData: Bool) {
        itemName = item.name
        
        if isActualData {
            // Load actual shopping data
            self.itemPrice = String(cartItem.actualPrice ?? cartItem.plannedPrice ?? 0)
            self.unit = cartItem.actualUnit ?? cartItem.plannedUnit ?? "piece"
            self.storeName = cartItem.actualStore ?? cartItem.plannedStore
            self.portion = cartItem.actualQuantity ?? cartItem.quantity
            self.isEditingActualData = true
            self.shouldUpdateVault = false
            self.modeDescription = "Editing actual shopping data"
        } else {
            // Load planned data
            self.itemPrice = String(cartItem.plannedPrice ?? 0)
            self.unit = cartItem.plannedUnit ?? "piece"
            self.storeName = cartItem.plannedStore
            self.portion = cartItem.quantity
            self.isEditingActualData = false
            self.shouldUpdateVault = true
            self.modeDescription = "Editing planned data"
        }
        
        // Category might be nil in cart context
        self.selectedCategory = nil
    }
    
    private func determineMode(cart: Cart?, cartItem: CartItem?) {
        guard let cart = cart, let cartItem = cartItem else {
            // Vault editing
            isEditingActualData = false
            shouldUpdateVault = true
            modeDescription = "Editing vault item"
            return
        }
        
        switch cart.status {
        case .planning:
            isEditingActualData = false
            shouldUpdateVault = true
            modeDescription = "Planning mode - edits update vault"
            
        case .shopping:
            if cartItem.isFulfilled {
                isEditingActualData = true
                shouldUpdateVault = false
                modeDescription = "Shopping mode - editing actual data"
            } else {
                isEditingActualData = false
                shouldUpdateVault = false
                modeDescription = "Item not fulfilled - can only edit after marking fulfilled"
            }
            
        case .completed:
            isEditingActualData = false
            shouldUpdateVault = false
            modeDescription = "Cart completed - read only"
        }
        
        print("🔧 Mode determined: \(modeDescription)")
    }
    
    func resetForm() {
        itemName = ""
        storeName = ""
        itemPrice = ""
        unit = "g"
        selectedCategory = nil
        portion = nil
        isEditingActualData = false
        shouldUpdateVault = true
        modeDescription = ""
        resetValidation()
    }
    
    // MARK: - Helper Methods
    
    func shouldShowCategoryField() -> Bool {
        // Show category field when editing vault or in planning mode
        return context == .vault || shouldUpdateVault
    }
    
    func getSaveButtonTitle() -> String {
        if isShoppingModeEditing {
            return "Update Shopping Data"
        } else if shouldUpdateVault {
            return "Save to Vault"
        } else {
            return "Save"
        }
    }
    
    func getSaveButtonColor() -> Color {
        if isShoppingModeEditing {
            return .orange
        } else if shouldUpdateVault {
            return .blue
        } else {
            return .green
        }
    }
}

enum EditContext {
    case vault
    case cart 
}
