import SwiftUI

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

struct ItemFormContent: View {
    @Bindable var formViewModel: ItemFormViewModel
    var itemNameFieldIsFocused: FocusState<Bool>.Binding
    var showCategoryTooltip: Bool = false
    var duplicateError: String? = nil
    var isCheckingDuplicate: Bool = false
    var onStoreChange: (() -> Void)? = nil 
    
    @State private var showUnitPicker = false
    
    // Shake states for each field
    @State private var itemNameShakeOffset: CGFloat = 0
    @State private var storeNameShakeOffset: CGFloat = 0
    @State private var portionShakeOffset: CGFloat = 0
    @State private var unitShakeOffset: CGFloat = 0
    @State private var priceShakeOffset: CGFloat = 0
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                if formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Item Name" {
                    validationError("Item name is required")
                        .padding(.leading, 8)
                }
                
                if let duplicateError = duplicateError {
                    validationError(duplicateError)
                        .padding(.leading, 8)
                }
                
                ItemNameInput(
                    selectedCategoryEmoji: formViewModel.selectedCategoryEmoji,
                    showTooltip: showCategoryTooltip,
                    showItemNameError: (formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Item Name") || duplicateError != nil,
                    showCategoryError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Category",
                    invalidAttemptCount: formViewModel.invalidSubmissionCount,
                    isCheckingDuplicate: isCheckingDuplicate, duplicateError: duplicateError,
                    itemNameFieldIsFocused: itemNameFieldIsFocused,
                    itemName: $formViewModel.itemName,
                    selectedCategory: $formViewModel.selectedCategory
                )
                .offset(x: itemNameShakeOffset)
            }
            .onChange(of: formViewModel.itemName) { oldValue, newValue in
                if !newValue.isEmpty {
                    formViewModel.clearErrorForField("Item Name")
                }
            }
            .onChange(of: formViewModel.invalidSubmissionCount) { oldValue, newValue in
                if newValue > oldValue && formViewModel.firstMissingField == "Item Name" {
                    triggerFieldShake(field: "Item Name")
                }
            }
            
            if formViewModel.requiresStore {
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                    .frame(height: 1)
                    .foregroundColor(Color(hex: "ddd"))
                    .padding(.vertical, 2)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 4) {
                    StoreNameComponent(
                          storeName: $formViewModel.storeName,
                          hasError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Store Name",
                          onStoreChange: onStoreChange 
                      )
                    .offset(x: storeNameShakeOffset)
                    
                    if formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Store Name" {
                        validationError("Store name is required")
                    }
                }
                .onChange(of: formViewModel.storeName) { oldValue, newValue in
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.count >= 1 {
                        formViewModel.clearErrorForField("Store Name")
                    }
                }
                .onChange(of: formViewModel.invalidSubmissionCount) { oldValue, newValue in
                    if newValue > oldValue && formViewModel.firstMissingField == "Store Name" {
                        triggerFieldShake(field: "Store Name")
                    }
                }
            }
            
            if formViewModel.requiresPortion {
                VStack(alignment: .leading, spacing: 4) {
                    PortionAndUnitInput(
                        portion: $formViewModel.portion,
                        unit: $formViewModel.unit,
                        showUnitPicker: $showUnitPicker,
                        hasPortionError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Portion",
                        hasUnitError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Unit",
                        portionShakeOffset: portionShakeOffset,
                        unitShakeOffset: unitShakeOffset
                    )
                    
                    if formViewModel.attemptedSubmission {
                        if formViewModel.firstMissingField == "Portion" {
                            HStack {
                                validationError("Portion must be greater than 0")
                                    .padding(.leading, 8)
                                Spacer()
                            }
                        } else if formViewModel.firstMissingField == "Unit" {
                            HStack {
                                Spacer()
                                validationError("Unit selection is required")
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                }
                .onChange(of: formViewModel.portion) { oldValue, newValue in
                    if (newValue ?? 0) > 0 {
                        formViewModel.clearErrorForField("Portion")
                    }
                }
                .onChange(of: formViewModel.unit) { oldValue, newValue in
                    if !newValue.isEmpty {
                        formViewModel.clearErrorForField("Unit")
                    }
                }
                .onChange(of: formViewModel.invalidSubmissionCount) { oldValue, newValue in
                    if newValue > oldValue && formViewModel.firstMissingField == "Portion" {
                        triggerFieldShake(field: "Portion")
                    }
                    if newValue > oldValue && formViewModel.firstMissingField == "Unit" {
                        triggerFieldShake(field: "Unit")
                    }
                }
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                if !formViewModel.requiresPortion {
                    HStack(spacing: 12) {
                        UnitButton(
                            unit: $formViewModel.unit,
                            hasError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Unit"
                        )
                        .offset(x: unitShakeOffset)
                        
                        PricePerUnitField(
                            price: $formViewModel.itemPrice,
                            hasError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Price"
                        )
                        .offset(x: priceShakeOffset)
                    }
                } else {
                    PricePerUnitField(
                        price: $formViewModel.itemPrice,
                        hasError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Price"
                    )
                    .offset(x: priceShakeOffset)
                }
                
                if formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Price" {
                    validationError("Price must be greater than 0")
                }
            }
            .onChange(of: formViewModel.itemPrice) { oldValue, newValue in
                if (Double(newValue) ?? 0) > 0 {
                    formViewModel.clearErrorForField("Price")
                }
            }
            .onChange(of: formViewModel.invalidSubmissionCount) { oldValue, newValue in
                if newValue > oldValue && formViewModel.firstMissingField == "Price" {
                    triggerFieldShake(field: "Price")
                }
                if newValue > oldValue && formViewModel.firstMissingField == "Unit" {
                    triggerFieldShake(field: "Unit")
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: formViewModel.attemptedSubmission)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: formViewModel.firstMissingField)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: duplicateError)
    }
    
    private func triggerFieldShake(field: String) {
        let shakeSequence = [0, -8, 8, -6, 6, -4, 4, 0]
        
        switch field {
        case "Item Name":
            for (index, offset) in shakeSequence.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    withAnimation(.linear(duration: 0.05)) {
                        self.itemNameShakeOffset = CGFloat(offset)
                    }
                }
            }
            
        case "Store Name":
            for (index, offset) in shakeSequence.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    withAnimation(.linear(duration: 0.05)) {
                        self.storeNameShakeOffset = CGFloat(offset)
                    }
                }
            }
            
        case "Portion":
            for (index, offset) in shakeSequence.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    withAnimation(.linear(duration: 0.05)) {
                        self.portionShakeOffset = CGFloat(offset)
                    }
                }
            }
            
        case "Unit":
            for (index, offset) in shakeSequence.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    withAnimation(.linear(duration: 0.05)) {
                        self.unitShakeOffset = CGFloat(offset)
                    }
                }
            }
            
        case "Price":
            for (index, offset) in shakeSequence.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                    withAnimation(.linear(duration: 0.05)) {
                        self.priceShakeOffset = CGFloat(offset)
                    }
                }
            }
            
        default:
            break
        }
    }
    
    private func validationError(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(Color(hex: "#FA003F"))
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9, anchor: .center)
                    .combined(with: .opacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.55)),
                removal: .scale(scale: 0.9, anchor: .center)
                    .combined(with: .opacity)
                    .animation(.spring(response: 0.3, dampingFraction: 0.75))
            ))
    }
}
