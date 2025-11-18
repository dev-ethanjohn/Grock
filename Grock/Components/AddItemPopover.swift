import SwiftUI

struct AddItemPopover: View {
    @Binding var isPresented: Bool
    var onSave: ((String, GroceryCategory, String, String, Double) -> Void)?
    var onDismiss: (() -> Void)?
    
    @State private var formViewModel = ItemFormViewModel(requiresPortion: false, requiresStore: true)
    
    @FocusState private var itemNameFieldIsFocused: Bool
    
    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.8
    @State private var keyboardVisible: Bool = false
    
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
                    showCategoryTooltip: false
                )
                
                if formViewModel.isFormValid {
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
                
                FormCompletionButton.doneButton(isEnabled: formViewModel.isFormValid, maxWidth: true) {
                    if formViewModel.attemptSubmission(),
                       let category = formViewModel.selectedCategory,
                       let priceValue = Double(formViewModel.itemPrice) {
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
            .cornerRadius(20)
            .padding(.horizontal, UIScreen.main.bounds.width * 0.038)
            .scaleEffect(contentScale)
            .offset(y: keyboardVisible ? UIScreen.main.bounds.height * 0.12 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1), value: formViewModel.isFormValid)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: keyboardVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: formViewModel.firstMissingField)
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
    
    private func dismissPopover() {
        itemNameFieldIsFocused = false
        isPresented = false
        onDismiss?()
    }
}
