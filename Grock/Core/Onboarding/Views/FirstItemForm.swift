import SwiftUI

// ONBOARDING -> it asks with item portion
struct FirstItemForm: View {
    @Bindable var viewModel: OnboardingViewModel
    var itemNameFieldIsFocused: FocusState<Bool>.Binding
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        VStack {
            Spacer().frame(height: 12)
            QuestionTitle(text: viewModel.questionText)
            Spacer().frame(height: 32)
            
            ItemFormContent(
                formViewModel: viewModel.formViewModel,
                itemNameFieldIsFocused: itemNameFieldIsFocused,
                showCategoryTooltip: viewModel.showCategoryTooltip,
                duplicateError: viewModel.duplicateError,
                isCheckingDuplicate: viewModel.isCheckingDuplicate,
                onStoreChange: {
                    viewModel.checkForDuplicateItemName(viewModel.formViewModel.itemName, vaultService: vaultService)
                }
            )
            
            Spacer().frame(height: 80)
        }
        .padding()
        .onChange(of: viewModel.formViewModel.itemName) { oldValue, newValue in
            viewModel.checkForDuplicateItemName(newValue, vaultService: vaultService)
        }
        .onChange(of: viewModel.formViewModel.storeName) { oldValue, newValue in
            viewModel.checkForDuplicateItemName(viewModel.formViewModel.itemName, vaultService: vaultService)
        }
        .onChange(of: viewModel.formViewModel.selectedCategory) { oldValue, newValue in
            if newValue != nil {
                viewModel.formViewModel.resetValidation()
            }
        }
    }
}

//#Preview {
//    FirstItemForm()
//}
