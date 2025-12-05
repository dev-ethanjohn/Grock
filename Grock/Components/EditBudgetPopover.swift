import SwiftUI

struct EditBudgetPopover: View {
    @Binding var isPresented: Bool
    let cart: Cart
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
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4 * overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissPopover() }
            
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 8) {
                        Text("Edit Budget")
                            .lexendFont(15, weight: .medium)
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Spacer()
                    
                    Button(action: { dismissPopover() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.bottom, 4)
                
                // Current budget display
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Budget")
                        .lexendFont(12, weight: .medium)
                        .foregroundColor(.gray)
                    
                    Text(cart.budget.formattedCurrency)
                        .lexendFont(20, weight: .bold)
                        .foregroundColor(.black)
                        .strikethrough()
                        .opacity(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
                // New budget input
                VStack(alignment: .leading, spacing: 6) {
                    Text("New Budget")
                        .lexendFont(12, weight: .medium)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 8) {
                        Text("₱")
                            .lexendFont(18, weight: .medium)
                            .foregroundColor(.black)
                        
                        TextField("Enter amount", text: $budgetString)
                            .lexendFont(18, weight: .semibold)
                            .foregroundColor(.black)
                            .keyboardType(.decimalPad)
                            .focused($budgetFieldIsFocused)
                            .onChange(of: budgetString) { oldValue, newValue in
                                validateBudget(newValue)
                            }
                            .onSubmit {
                                if isValidBudget {
                                    saveBudget()
                                }
                            }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isInvalidAmount ? Color.red : Color.clear, lineWidth: 1)
                    )
                }
                
                if isInvalidAmount {
                    Text(errorMessage)
                        .lexendFont(11, weight: .medium)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                }
                
                Spacer()
                    .frame(height: 8)
                
                // Save button
                Button(action: saveBudget) {
                    Text("Update Budget")
                        .lexendFont(14, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isValidBudget ? Color.black : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!isValidBudget)
                .animation(.easeInOut(duration: 0.2), value: isValidBudget)
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width * 0.85)
            .background(Color.white)
            .cornerRadius(20)
            .scaleEffect(contentScale)
            .offset(y: keyboardVisible ? -UIScreen.main.bounds.height * 0.12 : 0) // Changed to negative for upward movement
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            // Store original budget
            originalBudget = cart.budget
            
            // Pre-populate with current budget
            budgetString = String(format: "%.2f", cart.budget)
            
            // Animate in
            withAnimation(.easeOut(duration: 0.2)) {
                overlayOpacity = 1
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                contentScale = 1
            }
            
                budgetFieldIsFocused = true
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
            isInvalidAmount = true
            errorMessage = "Please enter a valid amount"
            return
        }
        
        if amount <= 0 {
            isInvalidAmount = true
            errorMessage = "Budget must be greater than 0"
        } else if amount == originalBudget {
            isInvalidAmount = true
            errorMessage = "Enter a different amount"
        } else if amount > 1000000 { // Arbitrary limit
            isInvalidAmount = true
            errorMessage = "Budget is too large"
        } else {
            isInvalidAmount = false
            errorMessage = ""
        }
    }
    
    private func saveBudget() {
        guard let newBudget = Double(budgetString), newBudget > 0 else { return }
        
        // Update cart budget
        cart.budget = newBudget
        
        // Update totals
        vaultService.updateCartTotals(cart: cart)
        
        // Callback
        onSave(newBudget)
        
        // Dismiss
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



