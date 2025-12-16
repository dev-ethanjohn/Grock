import SwiftUI

struct AddItemPopover: View {
    @Binding var isPresented: Bool
    @Binding var createCartButtonVisible: Bool
    
    var onSave: ((String, GroceryCategory, String, String, Double) -> Void)?
    var onDismiss: (() -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var formViewModel = ItemFormViewModel(requiresPortion: false, requiresStore: true)
    
    @FocusState private var itemNameFieldIsFocused: Bool
    
    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.8
    @State private var keyboardVisible: Bool = false
    
    // Duplicate validation state
    @State private var duplicateError: String?
    @State private var isCheckingDuplicate = false
    @State private var duplicateCheckTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4 * overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissPopover() }
            
            VStack(spacing: 8) {
                HStack {
                    HStack {
                        Text("Add new item to vault")
                            .lexendFont(13, weight: .medium)
                        Image(systemName: "shippingbox")
                            .resizable()
                            .frame(width: 16.5, height: 16.5)
                    }
                    
                    Spacer()
                    Button(action: { dismissPopover() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.bottom)
                
                ItemFormContent(
                    formViewModel: formViewModel,
                    itemNameFieldIsFocused: $itemNameFieldIsFocused,
                    showCategoryTooltip: false,
                    duplicateError: duplicateError,
                    isCheckingDuplicate: isCheckingDuplicate,
                    onStoreChange: {
                        performRealTimeDuplicateCheck(formViewModel.itemName)
                    }
                )
                
                if formViewModel.isFormValid && duplicateError == nil {
                    Image(systemName: "chevron.down.dotted.2")
                        .font(.body)
                        .symbolEffect(.wiggle.down.byLayer, options: .repeat(.continuous))
                        .scaleEffect(1.0)
                        .padding(.vertical, 8)
                        .padding(.top, 4)
                        .foregroundStyle(Color(.systemGray))
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.8, anchor: .center)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)),
                                removal: .scale(scale: 0.8, anchor: .center)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1))
                            )
                        )
                }
                
                FormCompletionButton.doneButton(
                    isEnabled: formViewModel.isFormValid && duplicateError == nil,
                    verticalPadding: 12,
                    maxWidth: true
                ) {
                    if formViewModel.attemptSubmission(),
                       let category = formViewModel.selectedCategory,
                       let priceValue = Double(formViewModel.itemPrice) {
                        
                        // Final duplicate check before saving
                        let validation = vaultService.validateItemName(formViewModel.itemName, store: formViewModel.storeName)
                        if !validation.isValid {
                            duplicateError = validation.errorMessage
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.error)
                            return
                        }
                        
                        // ENSURE THE STORE exists in vault stores before saving
                        vaultService.ensureStoreExists(formViewModel.storeName)
                        
                        onSave?(formViewModel.itemName, category, formViewModel.storeName, formViewModel.unit, priceValue)
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ItemCategoryChanged"),
                            object: nil,
                            userInfo: ["newCategory": category]
                        )
                        dismissPopover()
                    }
                }
                .padding(.top, formViewModel.isFormValid ? 4 : 20)
                .buttonStyle(.plain)
                
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(24)
            .padding(.horizontal, UIScreen.main.bounds.width * 0.038)
            .scaleEffect(contentScale)
            .offset(y: keyboardVisible ? UIScreen.main.bounds.height * 0.12 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1), value: formViewModel.isFormValid)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: keyboardVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: formViewModel.firstMissingField)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: duplicateError)
            .frame(maxHeight: .infinity, alignment: keyboardVisible ? .top : .center)
        }
        .onAppear {
            itemNameFieldIsFocused = true
            withAnimation(.easeOut(duration: 0.2)) {
                overlayOpacity = 1
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                contentScale = 1
            }
        }
        .onDisappear {
            formViewModel.resetForm()
            duplicateError = nil
            duplicateCheckTask?.cancel()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                createCartButtonVisible = true
            }
        }
        .onChange(of: formViewModel.itemName) { oldValue, newValue in
            performRealTimeDuplicateCheck(newValue)
        }
        .onChange(of: formViewModel.storeName) { oldValue, newValue in
            performRealTimeDuplicateCheck(formViewModel.itemName)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                keyboardVisible = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                keyboardVisible = false
            }
        }
    }
    
    private func performRealTimeDuplicateCheck(_ itemName: String) {
        duplicateCheckTask?.cancel()
        
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let storeName = formViewModel.storeName
        
        guard !trimmedName.isEmpty else {
            duplicateError = nil
            isCheckingDuplicate = false
            return
        }
        
        duplicateCheckTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    isCheckingDuplicate = true
                }
            }
            
            try? await Task.sleep(nanoseconds: 200_000_000)
            
            if !Task.isCancelled {
                let validation = vaultService.validateItemName(trimmedName, store: storeName)
                await MainActor.run {
                    isCheckingDuplicate = false
                    if validation.isValid {
                        duplicateError = nil
                    } else {
                        duplicateError = validation.errorMessage
                    }
                }
            }
        }
    }
    
    private func dismissPopover() {
        duplicateCheckTask?.cancel()
        itemNameFieldIsFocused = false
        isPresented = false
        onDismiss?()
    }
}
