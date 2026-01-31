import SwiftUI

struct EditBudgetPopover: View {
    @Binding var isPresented: Bool
    let currentBudget: Double
//    let cart: Cart
    let onSave: (Double) -> Void
    let onDismiss: (() -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var budgetString: String = ""
    @State private var originalBudget: Double = 0
    
    @FocusState private var budgetFieldIsFocused: Bool
    
    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.8
    @State private var keyboardVisible: Bool = false
    
    // Form validation
    @State private var isInvalidAmount = false
    @State private var errorMessage: String = ""
    @State private var budgetShakeOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4 * overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissPopover() }
            
            VStack(spacing: 0) {
                
                HStack(alignment: .center) {
                    Text("Edit Budget")
                        .fuzzyBubblesFont(16, weight: .bold)
                    
                    Image("budget")
                        .resizable()
                        .frame(width: 18, height: 18)
                        
                }
                .padding(.top, 6)
                .padding(.bottom, 32)
 
                // Single centered text field with underline
                HStack(spacing: 0) {
                    HStack(spacing: 2) {
                        Text(CurrencyManager.shared.selectedCurrency.symbol)
                            .lexendFont(26, weight: .semibold)
                            .foregroundColor(budgetString.isEmpty ? Color(hex: "999").opacity(0.5) : .black)
                            .contentTransition(.numericText())
                            .animation(.snappy, value: CurrencyManager.shared.selectedCurrency.symbol)
                        
                        // Use overlay approach like PricePerUnitField
                        Text(budgetString.isEmpty ? "0" : budgetString)
                            .lexendFont(26, weight: .semibold)
                            .foregroundColor(budgetString.isEmpty ? Color(hex: "999").opacity(0.5) : .black)
                            .overlay(
                                TextField("", text: $budgetString, onCommit: {
                                    if isValidBudget { saveBudget() }
                                })
                                .lexendFont(26, weight: .semibold)
                                .foregroundColor(.clear) // Text is handled by the underlying Text view
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .numbersOnly($budgetString, includeDecimal: true)
                                .focused($budgetFieldIsFocused)
                            )
                    }
                    .onTapGesture {
                        budgetFieldIsFocused = true
                    }
                    
                    // Clear button (X) - Removed per request

                }
                .padding(.vertical, 12)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.top, 16)
                    , alignment: .bottom
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: !budgetString.isEmpty)
                
                if isInvalidAmount {
                    Text(errorMessage)
                        .lexendFont(11, weight: .medium)
                        .foregroundColor(Color(hex: "FA003F"))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.9, anchor: .center)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.55)),
                                removal: .scale(scale: 0.9, anchor: .center)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.75))
                            )
                        )
                }
                
                Spacer()
                    .frame(height: isInvalidAmount ? 20 : 30)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isInvalidAmount)
                
                VStack(spacing: 6) {
                    
                    FormCompletionButton(
                        title: "Update Budget",
                        isEnabled: isValidBudget,
                        cornerRadius: 100,
                        verticalPadding: 12,
                        maxRadius: 1000,
                        bounceScale: (0.98, 1.05, 1.0),
                        bounceTiming: (0.1, 0.3, 0.3),
                        maxWidth: true,
                        action: saveBudget
                    )
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        dismissPopover()
                    }, label: {
                        Text("Cancel")
                            .fuzzyBubblesFont(14, weight: .bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .cornerRadius(100)
                            .overlay {
                                Capsule()
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            }
                        
                    })
                }
                .padding(.top, 4)
                
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width * 0.9)
            .background(Color.white)
            .cornerRadius(24)
            .scaleEffect(contentScale)
            .offset(y: keyboardVisible ? -UIScreen.main.bounds.height * 0.12 : 0)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isInvalidAmount)
        }
        .onAppear {
                  originalBudget = currentBudget // Use currentBudget
                  
                  if currentBudget > 0 {
                      let formatted = String(format: "%.2f", currentBudget)
                      if formatted.hasSuffix(".00") {
                          budgetString = String(format: "%.0f", currentBudget)
                      } else {
                          budgetString = formatted
                      }
                  } else {
                      budgetString = ""
                  }
                  
                  withAnimation(.easeOut(duration: 0.2)) {
                      overlayOpacity = 1
                  }
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                      contentScale = 1
                  }
                  
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                      budgetFieldIsFocused = true
                      
                      // Select all text
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                           if let keyWindow = getKeyWindow(),
                             let textField = keyWindow.findTextField() {
                              textField.selectAll(nil)
                          }
                      }
                  }
              }
              .onDisappear {
                  budgetFieldIsFocused = false
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
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var isValidBudget: Bool {
        guard let amount = Double(budgetString) else { return false }
        return amount > 0 && amount != originalBudget
    }
    
    private func validateBudget(_ text: String) {
        guard let amount = Double(text) else {
            triggerBudgetShake()
            isInvalidAmount = true
            errorMessage = "Please enter a valid amount"
            return
        }
        
        if amount <= 0 {
            triggerBudgetShake()
            isInvalidAmount = true
            errorMessage = "Budget must be greater than 0"
        } else if amount == originalBudget {
            triggerBudgetShake()
            isInvalidAmount = true
            errorMessage = "Enter a different amount"
        } else if amount > 1000000 {
            triggerBudgetShake()
            isInvalidAmount = true
            errorMessage = "Budget is too large"
        } else {
            isInvalidAmount = false
            errorMessage = ""
        }
    }
    
    private func triggerBudgetShake() {
        let shakeSequence = [0, -8, 8, -6, 6, -4, 4, 0]
        
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    self.budgetShakeOffset = CGFloat(offset)
                }
            }
        }
    }
    
//    private func saveBudget() {
//        guard let newBudget = Double(budgetString), newBudget > 0 else { return }
//        
//        cart.budget = newBudget
//        vaultService.updateCartTotals(cart: cart)
//        onSave(newBudget)
//        dismissPopover()
//    }
//    private func saveBudget() {
//        guard let newBudget = Double(budgetString), newBudget > 0 else { return }
//        
//        onSave(newBudget) // Let the parent handle the update with delay
//        dismissPopover()
//    }
//
    
    private func saveBudget() {
        guard let newBudget = Double(budgetString), newBudget > 0 else { return }
        
        onSave(newBudget) // Let the parent handle the update with delay
        dismissPopover()
    }
    private func dismissPopover() {
        withAnimation(.easeOut(duration: 0.2)) {
            overlayOpacity = 0
            contentScale = 0.8
        }
        
        isPresented = false
        onDismiss?()
    }
    
    private func getKeyWindow() -> UIWindow? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return nil
        }
        
        if let keyWindow = windowScene.keyWindow {
            return keyWindow
        }
        
        return windowScene.windows.first
    }
}


extension Notification.Name {
    static let cartBudgetUpdated = Notification.Name("cartBudgetUpdated")
}
