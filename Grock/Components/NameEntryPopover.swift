import SwiftUI

struct NameEntryPopover: View {
    @Binding var isPresented: Bool
    @Binding var createCartButtonVisible: Bool
    
    var onSave: ((String) -> Void)?
    var onDismiss: (() -> Void)?
    
    @State private var userName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var hasAttemptedSubmission = false
    @State private var validationError: String?
    @State private var shakeOffset: CGFloat = 0
    
    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.8
    @State private var keyboardVisible: Bool = false
    
    private var canSave: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var shouldShowError: Bool {
        hasAttemptedSubmission && validationError != nil
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4 * overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissPopover() }
            
            VStack(spacing: 8) {
                HStack {
                    HStack {
                        Text("What's your name?")
                            .lexendFont(13, weight: .medium)
                        Image(systemName: "person.circle")
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
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Enter your name", text: $userName)
                        .lexendFont(18, weight: .semibold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if canSave {
                                saveName()
                            }
                        }
                        .normalizedText($userName)
                        .onChange(of: userName) { _, newValue in
                            if hasAttemptedSubmission { validateName(newValue) }
                            if !newValue.isEmpty { validationError = nil }
                        }
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.words)
                        .offset(x: shakeOffset)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 1)
                        .padding(.top, 4)
                    
                    if shouldShowError, let error = validationError {
                        validationErrorView(error)
                            .padding(.top, 4)
                    }
                }
                .padding(.bottom, 8)
                
                if canSave {
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
                
                HStack(spacing: 12) {
                    Button {
                        isTextFieldFocused = false
                        dismissPopover()
                    } label: {
                        Text("Skip")
                            .fuzzyBubblesFont(14, weight: .bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(.white)
                            .cornerRadius(10)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.systemGray4), lineWidth: 1))
                    
                    FormCompletionButton.createEmptyCartButton(
                        isEnabled: canSave,
                        cornerRadius: 10,
                        verticalPadding: 10,
                        maxWidth: true
                    ) {
                        hasAttemptedSubmission = true
                        
                        if validateName(userName) {
                            isTextFieldFocused = false
                            saveName()
                        } else {
                            UINotificationFeedbackGenerator().notificationOccurred(.error)
                            isTextFieldFocused = true
                            triggerShake()
                        }
                    }
                }
                .padding(.top, canSave ? 4 : 20)
                .buttonStyle(.plain)
                
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(24)
            .padding(.horizontal, UIScreen.main.bounds.width * 0.038)
            .scaleEffect(contentScale)
            .offset(y: keyboardVisible ? UIScreen.main.bounds.height * 0.12 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1), value: canSave)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: keyboardVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: validationError)
            .frame(maxHeight: .infinity, alignment: keyboardVisible ? .top : .center)
        }
        .onAppear {
            userName = ""
            validationError = nil
            hasAttemptedSubmission = false
            isTextFieldFocused = true
            withAnimation(.easeOut(duration: 0.2)) {
                overlayOpacity = 1
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                contentScale = 1
            }
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
    
    // MARK: - Actions
    private func saveName() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.userName = trimmedName
        onSave?(trimmedName)
        dismissPopover()
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
    
    private func dismissPopover() {
        isTextFieldFocused = false
        isPresented = false
        onDismiss?()
    }
}
