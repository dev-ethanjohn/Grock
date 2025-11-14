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
    
    // Form Data
    var storeName: String = ""
    var itemName: String = ""
    var itemPrice: String = ""
    var unit: String = "g"
    var categoryName: String = ""
    var portion: Double?
    
    // UI State
    var currentStep: OnboardingStep = .welcome
    var storeFieldAnimated = false
    var hasShownInfoDropdown = false
    var showPageIndicator = false
    var showUnitPicker = false
    var showCategoryTooltip = false
    
    // Selected Category (UI State)
    var selectedCategory: GroceryCategory? = nil {
        didSet {
            if let category = selectedCategory {
                categoryName = category.title
                showCategoryTooltip = false
            }
        }
    }
    
    // Focus State
    var itemNameFieldIsFocused = false
    var storeFieldIsFocused = false
    
    // Animation States
    var showTextField = false
    var showNextButton = false
    var showInfoDropdown = false
    var showError = false
    var shakeOffset: CGFloat = 0
    
    // Computed Properties
    var isValidStoreName: Bool {
        let trimmed = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1
    }
    
    var isItemFormValid: Bool {
        !itemName.isEmpty &&
        isValidStoreName &&
        Double(itemPrice) != nil &&
        portion != nil &&
        !unit.isEmpty &&
        selectedCategory != nil
    }
    
    var calculatedTotal: Double {
        let portionValue = portion ?? 0
        let priceValue = Double(itemPrice) ?? 0
        return portionValue * priceValue
    }
    
    var selectedCategoryEmoji: String {
        selectedCategory?.emoji ?? "plus.circle.fill"
    }
    
    var questionText: String {
        if storeName.isEmpty {
            return "One item you usually buy for grocery"
        } else {
            return "One item you bought from \(storeName)"
        }
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
    //MARK: TODO: put in a universal viewmodel method for all text inputs includng store name input
    func normalizeSpaces(_ text: String) -> String {
        return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    func processStoreNameInput(_ newValue: String) -> String {
        var processedValue = newValue
        
        if processedValue.hasPrefix(" ") {
            processedValue = String(processedValue.dropFirst())
        }
        
        processedValue = normalizeSpaces(processedValue)
        return processedValue
    }
    
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
            storeFieldIsFocused = true
            storeFieldAnimated = true
        } else {
            showTextField = true
            showNextButton = true
            storeFieldIsFocused = true
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
    func saveInitialData(vaultService: VaultService) {
        guard let category = GroceryCategory.allCases.first(where: { $0.title == categoryName }),
              let price = Double(itemPrice) else { return }
        
        vaultService.addItem(
            name: itemName,
            to: category,
            store: storeName,
            price: price,
            unit: unit
        )
    }
    
    func saveOnboardingItemData() {
        UserDefaults.standard.set([
            "itemName": itemName,
            "categoryName": categoryName,
            "portion": portion ?? 1.0 //NOTE: check logic where 1 active item quantity on first appear vault view
        ] as [String: Any], forKey: "onboardingItemData")
        
        UserDefaults.standard.hasCompletedOnboarding = true
    }
    
    func resetForSkip() {
        storeName = ""
    }
}
