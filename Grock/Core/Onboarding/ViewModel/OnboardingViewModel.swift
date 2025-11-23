import Foundation
import SwiftUI
import SwiftData
import Observation

enum OnboardingStep {
    case welcome
    case lastStore
    case firstItem
    case done
}

@MainActor
@Observable
class OnboardingViewModel {
    
    // Onboarding-specific state
    var currentStep: OnboardingStep = .welcome
    var storeFieldAnimated = false
    var hasShownInfoDropdown = false
    var showPageIndicator = false
    var showCategoryTooltip = false
    
    // Form data using shared ViewModel
    var formViewModel = ItemFormViewModel(requiresPortion: true, requiresStore: true)
    
    // Animation States
    var showTextField = false
    var showNextButton = false
    var showInfoDropdown = false
    var showError = false
    var shakeOffset: CGFloat = 0
    
    // Duplicate Validation States
    var duplicateError: String?
    var isCheckingDuplicate = false
    
    // Computed Properties
    var calculatedTotal: Double {
        let portionValue = formViewModel.portion ?? 0
        let priceValue = Double(formViewModel.itemPrice) ?? 0
        return portionValue * priceValue
    }
    
    var questionText: String {
        if formViewModel.storeName.isEmpty {
            return "One item you usually buy for grocery"
        } else {
            return "One item you bought from \(formViewModel.storeName)"
        }
    }
    
    var isFormValidForCompletion: Bool {
        formViewModel.isFormValid && duplicateError == nil
    }
    
    // Navigation Methods
    func navigateToWelcome() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = .welcome
        }
        hidePageIndicator()
    }
    
    func navigateToLastStore() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = .lastStore
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                self.showPageIndicator = true
            }
        }
    }
    
    func navigateToFirstItemDataScreen() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            currentStep = .firstItem
        }
    }
    
    func navigateToDone() {
        withAnimation(.easeOut(duration: 0.2)) {
            showPageIndicator = false
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentStep = .done
        }
    }
    
    func navigateBack() {
        withAnimation(.spring(response: 0.5, dampingFraction: 1)) {
            currentStep = .lastStore
        }
    }
    
    private func hidePageIndicator() {
        withAnimation(.easeOut(duration: 0.1)) {
            showPageIndicator = false
        }
    }
    
    // Store Name Methods
    func triggerStoreNameError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        showError = true
        
        let shakeSequence = [0, -8, 8, -6, 6, -4, 4, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    self.shakeOffset = CGFloat(offset)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showError = false
            }
        }
    }
    
    // Duplicate Validation Methods
    func checkForDuplicateItemName(_ itemName: String, vaultService: VaultService) {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            duplicateError = nil
            isCheckingDuplicate = false
            return
        }
        
        isCheckingDuplicate = true
        
        // Debounce the duplicate check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // OLD CODE:
            // let validation = vaultService.validateItemName(trimmedName)
            
            // NEW CODE - ADD STORE PARAMETER:
            let validation = vaultService.validateItemName(trimmedName, store: self.formViewModel.storeName)
            
            self.isCheckingDuplicate = false
            if !validation.isValid {
                self.duplicateError = validation.errorMessage
            } else {
                self.duplicateError = nil
            }
        }
    }
    
    func clearDuplicateError() {
        duplicateError = nil
    }
    
    func validateFinalItemName(vaultService: VaultService) -> Bool {      
        let validation = vaultService.validateItemName(formViewModel.itemName, store: formViewModel.storeName)
        
        if !validation.isValid {
            duplicateError = validation.errorMessage
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return false
        }
        return true
    }
    
    // Animation Methods
    func animateStoreFieldAppearance() {
        if !storeFieldAnimated {
            showTextField = false
            showNextButton = false
            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                showTextField = true
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
                showNextButton = true
            }
            storeFieldAnimated = true
        } else {
            showTextField = true
            showNextButton = true
        }
    }
    
    func showInfoDropdownWithDelay() {
        if !hasShownInfoDropdown {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.showInfoDropdown = true
                }
                self.hasShownInfoDropdown = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.showInfoDropdown = false
                    }
                }
            }
        }
    }
    
    func showCategoryTooltipWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.showCategoryTooltip = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.showCategoryTooltip = false
                }
            }
        }
    }
    
    // Data Methods
    func saveInitialData(vaultService: VaultService) -> Bool {
        guard let category = GroceryCategory.allCases.first(where: { $0.title == formViewModel.selectedCategory?.title }),
              let price = Double(formViewModel.itemPrice) else {
            print("❌ Failed to save item - invalid data")
            return false
        }
        
        let success = vaultService.addItem(
            name: formViewModel.itemName,
            to: category,
            store: formViewModel.storeName,
            price: price,
            unit: formViewModel.unit
        )
        
        if success {
            print("✅ Item saved successfully!")
            return true
        } else {
            print("❌ Failed to save item - duplicate name")
            duplicateError = "An item with this name already exists"
            return false
        }
    }
    
    func saveOnboardingItemData() {
        UserDefaults.standard.set([
            "itemName": formViewModel.itemName,
            "categoryName": formViewModel.selectedCategory?.title ?? "",
            "portion": formViewModel.portion ?? 1.0
        ] as [String: Any], forKey: "onboardingItemData")
        
        UserDefaults.standard.hasCompletedOnboarding = true
    }
    
    func resetForSkip() {
        formViewModel.storeName = ""
    }
    
    // Reset method for when starting over
    func resetOnboarding() {
        currentStep = .welcome
        storeFieldAnimated = false
        hasShownInfoDropdown = false
        showPageIndicator = false
        showCategoryTooltip = false
        formViewModel.resetForm()
        showTextField = false
        showNextButton = false
        showInfoDropdown = false
        showError = false
        shakeOffset = 0
        duplicateError = nil
        isCheckingDuplicate = false
    }
}
