import SwiftUI
import SwiftData

struct EditItemSheet: View {
    let item: Item
    var onSave: ((Item) -> Void)?
    var context: EditContext = .vault
    
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    
    @State private var formViewModel = ItemFormViewModel(requiresPortion: false, requiresStore: true)
    @State private var showUnitPicker = false
    
    @FocusState private var itemNameFieldIsFocused: Bool
    
    @State private var duplicateError: String?
    @State private var validationTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack {
                        ItemFormContent(
                            formViewModel: formViewModel,
                            itemNameFieldIsFocused: $itemNameFieldIsFocused,
                            showCategoryTooltip: false,
                            duplicateError: duplicateError,
                            onStoreChange: {
                                  triggerRealTimeValidation() // Call your existing validation method
                              }
                        )
                        
                        if context == .cart {
                            HStack(spacing: 0) {
                                Text("Remove from Cart")
                                    .lexendFont(14, weight: .medium)
                                    .foregroundStyle(.red)
                                    .padding(.vertical)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text("|")
                                    .lexendFont(16, weight: .thin)
                                
                                Text("Remove from Vault")
                                    .lexendFont(14, weight: .medium)
                                    .foregroundStyle(.red)
                                    .padding(.vertical)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .foregroundStyle(.black)
                        } else {
                            HStack(spacing: 8) {
                                Text("Remove from Vault")
                                    .lexendFont(14, weight: .medium)
                                
                                Image(systemName: "trash")
                                    .lexendFont(12, weight: .bold)
                            }
                            .foregroundStyle(.red)
                            .padding(.vertical)
                        }
                        
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            initializeFormValues()
        }
        .onChange(of: formViewModel.itemName) { oldValue, newValue in
                  triggerRealTimeValidation()
              }
              .onChange(of: formViewModel.storeName) { oldValue, newValue in
                  triggerRealTimeValidation()
              }
     
        .safeAreaInset(edge: .bottom) {
            HStack {
                if context == .cart {
                    Text("Editing this item will update prices from vault and in all active carts")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                EditItemSaveButton(isEditFormValid: formViewModel.isFormValid && duplicateError == nil) {
                    if formViewModel.attemptSubmission() {
                        saveChanges()
                    } else {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: formViewModel.firstMissingField)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: duplicateError)
    }
    
    private func initializeFormValues() {
        formViewModel.populateFromItem(item, vaultService: vaultService)
    }
    
    private func saveChanges() {
        guard let priceValue = Double(formViewModel.itemPrice),
              let selectedCategory = formViewModel.selectedCategory else { return }
        
        // Validate for duplicates (excluding current item)
        let validation = vaultService.validateItemName(formViewModel.itemName, store: formViewModel.storeName, excluding: item.id)
        if !validation.isValid {
            duplicateError = validation.errorMessage
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        // Store the old category for comparison
        let oldCategoryName = vaultService.vault?.categories.first(where: { $0.items.contains(where: { $0.id == item.id }) })?.name
        
        // Update the item in the vault
        let success = vaultService.updateItem(
            item: item,
            newName: formViewModel.itemName.trimmingCharacters(in: .whitespacesAndNewlines),
            newCategory: selectedCategory,
            newStore: formViewModel.storeName.trimmingCharacters(in: .whitespacesAndNewlines),
            newPrice: priceValue,
            newUnit: formViewModel.unit
        )
        
        if success {
            onSave?(item)
            dismiss()
            
            // Notify about category change if needed
            if oldCategoryName != selectedCategory.title {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ItemCategoryChanged"),
                    object: nil,
                    userInfo: [
                        "newCategory": selectedCategory,
                        "itemId": item.id
                    ]
                )
            }
        } else {
            duplicateError = "Failed to update item. Please try again."
        }
    }
    
    private func triggerRealTimeValidation() {
        validationTask?.cancel()
        
        let itemName = formViewModel.itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let storeName = formViewModel.storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !itemName.isEmpty && !storeName.isEmpty else {
            duplicateError = nil
            return
        }
        
        validationTask = Task {
            // Debounce the validation
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            if !Task.isCancelled {
                let validation = vaultService.validateItemName(itemName, store: storeName, excluding: item.id)
                await MainActor.run {
                    if !validation.isValid {
                        duplicateError = validation.errorMessage
                    } else {
                        duplicateError = nil
                    }
                }
            }
        }
    }
    
}
