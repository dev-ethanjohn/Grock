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
                FirstItemForm(
                    viewModel: viewModel,
                    itemNameFieldIsFocused: $itemNameFieldIsFocused
                )
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
        .onChange(of: formViewModel.selectedCategoryName) { _, newValue in
            if newValue != nil {
                viewModel.showCategoryTooltip = false
            }
        }
        .onChange(of: formViewModel.itemName) { oldValue, newValue in
            // Clear duplicate error when user starts typing
            if viewModel.duplicateError != nil {
                viewModel.clearDuplicateError()
            }
            
            // Real-time duplicate check with debounce
            viewModel.checkForDuplicateItemName(newValue, vaultService: vaultService)
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
        FinishButton(isFormValid: viewModel.isFormValidForCompletion) {
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
        // Final duplicate check before saving
        guard viewModel.validateFinalItemName(vaultService: vaultService) else {
            return
        }
        
        UserDefaults.standard.set(false, forKey: "hasSeenVaultCelebration")
        print("🎉 OnboardingFirstItemView: Reset celebration flag")
        
        saveInitialData()
    }
    
    private func saveInitialData() {
        let success = viewModel.saveInitialData(vaultService: vaultService)
        
        if success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("💾 Vault processing complete - proceeding to finish")
                viewModel.saveOnboardingItemData()
                viewModel.navigateToDone()
            }
        }
    }
}
