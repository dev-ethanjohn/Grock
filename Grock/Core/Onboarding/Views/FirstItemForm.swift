import SwiftUI

struct FirstItemForm: View {
    @Bindable var viewModel: OnboardingViewModel
    var itemNameFieldIsFocused: FocusState<Bool>.Binding
    
    var body: some View {
        VStack {
            Spacer().frame(height: 12)
            QuestionTitle(text: viewModel.questionText)
            Spacer().frame(height: 32)
            
            ItemFormContent(
                formViewModel: viewModel.formViewModel,
                itemNameFieldIsFocused: itemNameFieldIsFocused,
                showCategoryTooltip: viewModel.showCategoryTooltip
            )
            
            Spacer().frame(height: 80)
        }
        .padding()
        .onChange(of: viewModel.formViewModel.selectedCategory) { oldValue, newValue in
            if newValue != nil {
                viewModel.formViewModel.resetValidation()
            }
        }
    }
}

import SwiftUI

struct ItemFormContent: View {
    @Bindable var formViewModel: ItemFormViewModel
    var itemNameFieldIsFocused: FocusState<Bool>.Binding
    var showCategoryTooltip: Bool = false
    
    @State private var showUnitPicker = false
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 4) {
                if formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Item Name" {
                    validationError("Item name is required")
                        .padding(.leading, 8)
                }
                
                ItemNameInput(
                    selectedCategoryEmoji: formViewModel.selectedCategoryEmoji,
                    showTooltip: showCategoryTooltip,
                    showItemNameError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Item Name",
                    showCategoryError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Category",
                    invalidAttemptCount: formViewModel.invalidSubmissionCount,
                    itemNameFieldIsFocused: itemNameFieldIsFocused,
                    itemName: $formViewModel.itemName,
                    selectedCategory: $formViewModel.selectedCategory
                )
            }
            .onChange(of: formViewModel.itemName) { oldValue, newValue in
                if !newValue.isEmpty {
                    formViewModel.clearErrorForField("Item Name")
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
                        hasError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Store Name"
                    )
                    
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
            }
            
            if formViewModel.requiresPortion {
                VStack(alignment: .leading, spacing: 4) {
                    PortionAndUnitInput(
                        portion: $formViewModel.portion,
                        unit: $formViewModel.unit,
                        showUnitPicker: $showUnitPicker,
                        hasPortionError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Portion",
                        hasUnitError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Unit"
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
            }
            
            VStack(alignment: .trailing, spacing: 4) {
                if !formViewModel.requiresPortion {
                    HStack(spacing: 12) {
                        UnitButton(
                            unit: $formViewModel.unit,
                            hasError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Unit"
                        )
                        PricePerUnitField(
                            price: $formViewModel.itemPrice,
                            hasError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Price"
                        )
                    }
                } else {
                    PricePerUnitField(
                        price: $formViewModel.itemPrice,
                        hasError: formViewModel.attemptedSubmission && formViewModel.firstMissingField == "Price"
                    )
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
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: formViewModel.attemptedSubmission)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: formViewModel.firstMissingField)
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
