import SwiftUI
import SwiftData

struct OnboardingFirstItemView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(VaultService.self) private var vaultService
    @FocusState private var itemNameFieldIsFocused: Bool
    
    @State private var finishButtonShakeOffset: CGFloat = 0
    
    private var formViewModel: ItemFormViewModel {
        viewModel.formViewModel
    }
    
    var body: some View {
        VStack {
            FirstItemBackHeader(onBack: viewModel.navigateBack)
            
            ScrollView {
                FirstItemForm(viewModel: viewModel, itemNameFieldIsFocused: $itemNameFieldIsFocused)
            }
            .safeAreaInset(edge: .bottom) {
                bottomButtons
            }
        }
        .onAppear {
            itemNameFieldIsFocused = true
            if formViewModel.unit.isEmpty {
                formViewModel.unit = "g"
            }
            viewModel.showCategoryTooltipWithDelay()
        }
        .onChange(of: formViewModel.selectedCategory) { _, newValue in
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
        FinishButton(isFormValid: formViewModel.isFormValid) {
            if formViewModel.attemptSubmission() {
                saveItemAndComplete()
            } else {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                
                triggerFinishButtonShake()
            }
        }
        .offset(x: finishButtonShakeOffset)
    }
    
    private func triggerFinishButtonShake() {
        let shakeSequence = [0, -8, 8, -6, 6, -4, 4, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    self.finishButtonShakeOffset = CGFloat(offset)
                }
            }
        }
    }
    
    private func saveItemAndComplete() {
        
        UserDefaults.standard.set(false, forKey: "hasSeenVaultCelebration")
        print("🎉 OnboardingFirstItemView: Reset celebration flag")
        
        saveInitialData()
    }
    
    private func saveInitialData() {
        guard let category = formViewModel.selectedCategory,
              let price = Double(formViewModel.itemPrice) else {
            print("❌ Failed to save item - invalid data")
            return
        }
        
        print("💾 Saving item to vault:")
        print("   Name: \(formViewModel.itemName)")
        print("   Category: \(category.title)")
        print("   Store: \(formViewModel.storeName)")
        print("   Price: ₱\(price)")
        print("   Unit: \(formViewModel.unit)")
        
        vaultService.addItem(
            name: formViewModel.itemName,
            to: category,
            store: formViewModel.storeName,
            price: price,
            unit: formViewModel.unit
        )
        
        print("✅ Item saved successfully!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("💾 Vault processing complete - proceeding to finish")
            viewModel.saveOnboardingItemData()
            viewModel.navigateToDone()
        }
    }
}
