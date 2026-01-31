import SwiftUI

// MARK: - Custom Popover Modifier
struct CustomPopoverModifier<PopoverContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let content: () -> PopoverContent
    
    @State private var scale: CGFloat = 0.3
    @State private var opacity: CGFloat = 0
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                // Full screen dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .opacity(opacity)
                    .onTapGesture {
                        dismissPopover()
                    }
                
                // Popover content (centered)
                self.content()
                    .scaleEffect(scale, anchor: .bottom)
                    .opacity(opacity)
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue {
                presentPopover()
            } else {
                // Reset state if dismissed externally
                scale = 0.3
                opacity = 0
            }
        }
    }
    
    private func presentPopover() {
        // Reset to initial state
        scale = 0.3
        opacity = 0
        
        // Animate popover appearance with smooth spring
        withAnimation(.interpolatingSpring(mass: 0.6, stiffness: 170, damping: 12)) {
            scale = 1.0
            opacity = 1.0
        }
    }
    
    private func dismissPopover() {
        withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 200, damping: 15)) {
            scale = 0.3
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
            onDismiss?()
        }
    }
}

extension View {
    func customPopover<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(
            CustomPopoverModifier(
                isPresented: isPresented,
                onDismiss: onDismiss,
                content: content
            )
        )
    }
}

struct CreateCartPopover: View {
    let onConfirm: (String, Double) -> Void
    let onCancel: () -> Void
    
    @Binding var isPresented: Bool
    @State private var cartTitle: String = ""
    @State private var budget: String = ""
    @FocusState private var focusedField: Field?
    @State private var validationError: String?
    @State private var hasAttemptedSubmission = false
    
    @State private var titleShakeOffset: CGFloat = 0
    
    private enum Field {
        case title, budget
    }
    
    private var budgetValue: Double {
        Double(budget) ?? 0.0
    }
    
    private var canConfirm: Bool {
        !cartTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var shouldShowError: Bool {
        hasAttemptedSubmission && validationError != nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                titleSection
                budgetSection
                buttonsSection
            }
            .frame(width: UIScreen.main.bounds.width * 0.92)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .onAppear {
            // Reset state
            validationError = nil
            hasAttemptedSubmission = false
            cartTitle = ""
            budget = ""
            
            focusedField = .title
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                focusedField = nil
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: hasAttemptedSubmission)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: validationError)
    }
    
    // MARK: - Sections
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("My Monday Shopping Trip...", text: $cartTitle)
                .fuzzyBubblesFont(20, weight: .bold)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit { focusedField = .budget }
                .normalizedText($cartTitle)
                .onChange(of: cartTitle) { _, newValue in
                    if hasAttemptedSubmission { validateCartTitle(newValue) }
                }
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .offset(x: titleShakeOffset)
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .offset(y: 10)
            
            if shouldShowError, let error = validationError {
                validationError(error).offset(y: 10)
            }
        }
        .padding(20)
        .onChange(of: cartTitle) { _, newValue in
            if !newValue.isEmpty { validationError = nil }
        }
        .onChange(of: hasAttemptedSubmission) { _, newValue in
            if newValue && validationError != nil { triggerTitleShake() }
        }
    }
    
    private var budgetSection: some View {
        VStack(spacing: 0) { budgetRow.padding(.bottom) }
            .padding(.horizontal, 20)
    }
    
    private var buttonsSection: some View {
        HStack(spacing: 12) {
            cancelButton
            confirmButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Buttons
    private var cancelButton: some View {
        Button {
            focusedField = nil
            onCancel()
        } label: {
            Text("Cancel")
                .fuzzyBubblesFont(16, weight: .bold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(.white)
                .cornerRadius(10)
        }
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
    }
    
    private var confirmButton: some View {
        FormCompletionButton.createEmptyCartButton(
            isEnabled: canConfirm,
            cornerRadius: 10,
            verticalPadding: 12,
            maxWidth: true
        ) {
            hasAttemptedSubmission = true
            
            if validateCartTitle(cartTitle) {
                focusedField = nil
                DispatchQueue.main.async { onConfirm(cartTitle, budgetValue) }
            } else {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                if cartTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    focusedField = .title
                }
            }
        }
    }
    
    // MARK: - Budget row
    private var budgetRow: some View {
        HStack {
            HStack(spacing: 6) {
                Text("Budget")
                Text("(Optional) :").foregroundStyle(Color(.systemGray))
            }
            .lexendFont(16)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(CurrencyManager.shared.selectedCurrency.symbol)
                    .lexendFont(18, weight: .medium)
                    .foregroundStyle(budget.isEmpty ? .gray : .black)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: CurrencyManager.shared.selectedCurrency.symbol)
                
                Text(budget.isEmpty ? "0" : budget)
                    .foregroundStyle(budget.isEmpty ? .gray : .black)
                    .lexendFont(18, weight: .medium)
                    .multilineTextAlignment(.trailing)
                    .overlay(
                        TextField("0", text: $budget)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .fixedSize(horizontal: true, vertical: false)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .numbersOnly($budget, includeDecimal: true)
                            .lexendFont(18, weight: .medium)
                            .focused($focusedField, equals: .budget)
                            .opacity(focusedField == .budget ? 1 : 0)
                    )
            }
            .contentShape(Rectangle())
            .onTapGesture { focusedField = .budget }
        }
        .padding(.bottom)
    }
    
    // MARK: - Animations
    private func triggerTitleShake() {
        let shakeSequence = [0, -8, 8, -6, 6, -4, 4, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) { self.titleShakeOffset = CGFloat(offset) }
            }
        }
    }
    
    private func validationError(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(Color(hex: "#FA003F"))
            .padding(.bottom, 4)
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9, anchor: .center).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.55)),
                removal: .scale(scale: 0.9, anchor: .center).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.75))
            ))
    }
    
    @discardableResult
    private func validateCartTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            validationError = "Cart name cannot be empty"
            return false
        }
        validationError = nil
        return true
    }
}
