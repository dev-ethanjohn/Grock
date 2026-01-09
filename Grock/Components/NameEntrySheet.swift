import SwiftUI

struct NameEntrySheet: View {
    @Binding var isPresented: Bool
    @Binding var createCartButtonVisible: Bool
    
    var onSave: ((String) -> Void)?
    var onDismiss: (() -> Void)?
    
    @State private var userName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var hasAttemptedSubmission = false
    @State private var validationError: String?
    @State private var shakeOffset: CGFloat = 0
    
    private let maxNameLength = 20
    
    private var currentCharacterCount: Int { userName.count }
    private var remainingCharacterCount: Int { max(0, maxNameLength - userName.count) }
    
    private var canSave: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var shouldShowError: Bool {
        hasAttemptedSubmission && validationError != nil
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
                .frame(height: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                TextField("You can call me...", text: $userName)
                    .fuzzyBubblesFont(20, weight: .bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        hasAttemptedSubmission = true
                        if canSave {
                            saveName()
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            isTextFieldFocused = true
                            triggerShake()
                        }
                    }
                    .normalizedText($userName)
                    .onChange(of: userName) { _, newValue in
                        if newValue.count > maxNameLength {
                            userName = String(newValue.prefix(maxNameLength))
                        }
                        
                        if hasAttemptedSubmission { validateName(userName) }
                        if !newValue.isEmpty { validationError = nil }
                    }
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.words)
                    .padding(.vertical, 8)
                    .padding(.trailing, 64)
                    .overlay(
                        VStack {
                            Spacer()
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    )
                    .overlay(alignment: .trailing) {
                        HStack(spacing: 2) {
                            Text("\(currentCharacterCount)")
                                .contentTransition(.numericText())
                                .animation(.spring(response: 0.25, dampingFraction: 0.85), value: currentCharacterCount)
                            
                            Text(" / \(remainingCharacterCount)")
                        }
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                    }
                    .offset(x: shakeOffset)
                    .padding(.horizontal, 40)
                
                if shouldShowError, let error = validationError {
                    validationErrorView(error)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
            .padding(.bottom, 8)
            
            Spacer()
        }
        .padding()
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canSave)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: validationError)
        .onAppear {
            userName = ""
            validationError = nil
            hasAttemptedSubmission = false
            isTextFieldFocused = true
            createCartButtonVisible = false
        }
        .onDisappear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                createCartButtonVisible = true
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if !newValue {
                isTextFieldFocused = false
            }
        }
    }
    
    // MARK: - Actions
    private func saveName() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.userName = trimmedName
        onSave?(trimmedName)
        dismissSheet()
    }
    
    // MARK: - Validation
    @discardableResult
    private func validateName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            validationError = "Name cannot be empty"
            return false
        }
        validationError = nil
        return true
    }
    
    // MARK: - Animations
    private func triggerShake() {
        let shakeSequence = [0, -8, 8, -6, 6, -4, 4, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    self.shakeOffset = CGFloat(offset)
                }
            }
        }
    }
    
    private func validationErrorView(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(Color(hex: "#FA003F"))
            .transition(.asymmetric(
                insertion: .scale(scale: 0.9, anchor: .center).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.55)),
                removal: .scale(scale: 0.9, anchor: .center).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.75))
            ))
    }
    
    private func dismissSheet() {
        isTextFieldFocused = false
        isPresented = false
        onDismiss?()
    }
}
