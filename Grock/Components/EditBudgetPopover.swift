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
                        .lexendFont(20, weight: .medium)
                        .foregroundColor(.black)
                    
                    Image("budget")
                        .resizable()
                        .frame(width: 24, height: 24)
                        
                }
                .padding(.bottom, 32)
 
                HStack(alignment: .center, spacing: 8) {
                    VStack(spacing: 6) {
                        Text("Current Budget")
                            .lexendFont(12)
                            .foregroundColor(Color(hex: "777"))
                        
//                        Text(cart.budget.formattedCurrency)
                        Text(currentBudget.formattedCurrency)
                            .lexendFont(16, weight: .semibold)
                            .foregroundColor(.black)
                            .padding(.vertical, 10)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(spacing: 6) {
                        Text("New Budget")
                            .lexendFont(12)
                            .foregroundColor(Color(hex: "777"))
                        
                        HStack(spacing: 4) {
                            Text(CurrencyManager.shared.selectedCurrency.symbol)
                                .lexendFont(16, weight: .semibold)
                                .foregroundStyle(budgetString.isEmpty ? .gray : .black)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: CurrencyManager.shared.selectedCurrency.symbol)
                            
                            Text(budgetString.isEmpty ? "0" : budgetString)
                                .lexendFont(16, weight: .semibold)
                                .foregroundStyle(budgetString.isEmpty ? .gray : .black)
                                .multilineTextAlignment(.center)
                                .overlay(
                                    TextField("0", text: $budgetString, onCommit: {
                                        if isValidBudget { saveBudget() }
                                    })
                                    .lexendFont(16, weight: .medium)
                                    .keyboardType(.decimalPad)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .focused($budgetFieldIsFocused)
                                    .opacity(budgetFieldIsFocused ? 1 : 0)
                                    .multilineTextAlignment(.center)
                                    .onChange(of: budgetString) {_, newValue in
                                        validateBudget(newValue)
                                    }
                                    
                                )
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                        .background(Color(hex: "F9F9F9"))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "999"), lineWidth: 0.5)
                        )
                        .offset(x: budgetShakeOffset)
                    }
                    .frame(maxWidth: .infinity)
                }
                
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
                  budgetString = String(format: "%.0f", currentBudget) // Use currentBudget
                  
                  withAnimation(.easeOut(duration: 0.2)) {
                      overlayOpacity = 1
                  }
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                      contentScale = 1
                  }
                  
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                      budgetFieldIsFocused = true
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
}


extension Notification.Name {
    static let cartBudgetUpdated = Notification.Name("cartBudgetUpdated")
}
