import SwiftUI
import SwiftData

struct OnboardingFirstItemView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(VaultService.self) private var vaultService
    @FocusState private var itemNameFieldIsFocused: Bool
    
    var body: some View {
        VStack {
            FirstItemBackHeader(onBack: viewModel.navigateBack)
            
            ScrollView {
                FirstItemForm(viewModel: viewModel)
            }
            .safeAreaInset(edge: .bottom) {
                bottomButtons
            }
        }
        .onAppear {
            itemNameFieldIsFocused = true
            if viewModel.unit.isEmpty {
                viewModel.unit = "g"
            }
            if !viewModel.categoryName.isEmpty {
                viewModel.selectedCategory = GroceryCategory.allCases.first { $0.title == viewModel.categoryName }
            }
            
            viewModel.showCategoryTooltipWithDelay()
        }
        .onChange(of: viewModel.selectedCategory) { _, newValue in
            if newValue != nil {
                viewModel.showCategoryTooltip = false
            }
        }
    }
    
    private var bottomButtons: some View {
        HStack {
            TotalDisplay(calculatedTotal: viewModel.calculatedTotal)
            Spacer()
            finishButton
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
    
    private var finishButton: some View {
        FinishButton(isFormValid: viewModel.isItemFormValid) {
            saveItemAndComplete()
        }
    }
    
    private func saveItemAndComplete() {
        guard let category = viewModel.selectedCategory else { return }
        
        viewModel.categoryName = category.title
        UserDefaults.standard.set(false, forKey: "hasSeenVaultCelebration")
        print("🎉 OnboardingFirstItemView: Reset celebration flag")
        
        saveInitialData()
    }
    
    private func saveInitialData() {
        guard let category = viewModel.selectedCategory,
              let price = Double(viewModel.itemPrice) else {
            print("❌ Failed to save item - invalid data")
            return
        }
        
        print("💾 Saving item to vault:")
        print("   Name: \(viewModel.itemName)")
        print("   Category: \(category.title)")
        print("   Store: \(viewModel.storeName)")
        print("   Price: ₱\(price)")
        print("   Unit: \(viewModel.unit)")
        
        vaultService.addItem(
            name: viewModel.itemName,
            to: category,
            store: viewModel.storeName,
            price: price,
            unit: viewModel.unit
        )
        
        print("✅ Item saved successfully!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("💾 Vault processing complete - proceeding to finish")
            viewModel.saveOnboardingItemData()
            viewModel.navigateToDone()
        }
    }
}
