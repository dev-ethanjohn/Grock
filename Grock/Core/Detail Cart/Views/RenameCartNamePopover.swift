import SwiftUI
import Lottie

struct RenameCartNamePopover: View {
    @Binding var isPresented: Bool
    let currentName: String
    let onSave: (String) -> Void
    let onDismiss: (() -> Void)?
    
    @State private var cartName: String = ""
    @State private var originalName: String = ""
    
    @FocusState private var nameFieldIsFocused: Bool
    
    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.9
    @State private var keyboardVisible: Bool = false
    
    @State private var isInvalidName = false
    @State private var errorMessage: String = ""
    
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4 * overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissPopover() }
            
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    Text("Rename Cart Name")
                        .fuzzyBubblesFont(16, weight: .bold)
                    
                    Image("edit")
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 18, height: 18)
                        .foregroundColor(.black.opacity(0.8))
                }
                .foregroundColor(.black.opacity(0.8))
                .padding(.top, 6)
                .padding(.bottom)
                
                // Single text field with clean UI (no background, no border)
                HStack(spacing: 0) {
                    ZStack(alignment: .leading) {
                        // Placeholder showing when field is empty
                        if cartName.isEmpty {
                            Text("Enter new name...")
                                .fuzzyBubblesFont(20, weight: .bold)
                                .foregroundColor(Color(hex: "999"))
                        }
                        
                        TextField("", text: $cartName, onCommit: {
                            if isValidName { saveName() }
                        })
                        .fuzzyBubblesFont(20, weight: .bold)
                        .foregroundColor(.black)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .focused($nameFieldIsFocused)
                        .onChange(of: cartName) {_, newValue in
                            validateName(newValue)
                        }
                    }
                    
                    // Clear button (X) - appears only when there's text (no background)
                    if !cartName.isEmpty {
                        Button(action: {
                            cartName = ""
                            isInvalidName = false
                            errorMessage = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .lexendFont(20)
                                .foregroundColor(Color(hex: "999"))
                                .frame(width: 24, height: 24)
                        }
                        .padding(.leading, 8)
                    }
                }
                .padding(.vertical, 12)
                .overlay(
                    // Gray line under text field (same as CreateCartPopover)
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: !cartName.isEmpty)
                
                // Error message
                if isInvalidName {
                    Text(errorMessage)
                        .lexendFont(11, weight: .medium)
                        .foregroundColor(Color(hex: "FA003F"))
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                
                
                // Arrow indicator when form is valid
                if isValidName && !isInvalidName {
                    Image(systemName: "chevron.down.dotted.2")
                        .lexend(.body)
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
                
                // Action buttons
                VStack(spacing: 6) {
                    FormCompletionButton(
                        title: "Update Name",
                        isEnabled: isValidName && !isInvalidName,
                        cornerRadius: 100,
                        verticalPadding: 12,
                        maxRadius: 1000,
                        bounceScale: (0.98, 1.05, 1.0),
                        bounceTiming: (0.1, 0.3, 0.3),
                        maxWidth: true,
                        action: saveName
                    )
                    .frame(maxWidth: .infinity)
                    .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1), value: isValidName)
                    
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
                .padding(.top, isValidName ? 4 : 20)
                .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1), value: isValidName)
                
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(24)
            .scaleEffect(contentScale)
            .offset(y: keyboardVisible ? -UIScreen.main.bounds.height * 0.12 : 0)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.1), value: isValidName)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: keyboardVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isInvalidName)
            .frame(maxHeight: .infinity, alignment: keyboardVisible ? .center : .center)
            .padding(.horizontal, UIScreen.main.bounds.width * 0.038)
        }
        .onAppear {
            originalName = currentName
            // FIXED: Start with current cart name pre-filled
            cartName = currentName
            
            nameFieldIsFocused = true
            
            withAnimation(.easeOut(duration: 0.2)) {
                overlayOpacity = 1
            }
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                contentScale = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                nameFieldIsFocused = true
                
                // Select all text for easy editing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if let keyWindow = getKeyWindow(),
                       let textField = keyWindow.findTextField() {
                        textField.selectAll(nil)
                    }
                }
            }
        }
        .onDisappear {
            nameFieldIsFocused = false
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
    
    private var isValidName: Bool {
        let trimmedName = cartName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName != originalName && !isInvalidName
    }
    
    private func validateName(_ text: String) {
        let trimmedName = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            isInvalidName = false  // Don't show error when empty
            errorMessage = ""
        } else if trimmedName == originalName {
            isInvalidName = true
            errorMessage = "Enter a different name"
        } else if trimmedName.count > 50 {
            isInvalidName = true
            errorMessage = "Name is too long (max 50 characters)"
        } else {
            isInvalidName = false
            errorMessage = ""
        }
    }
    
    private func saveName() {
        let trimmedName = cartName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        onSave(trimmedName)
        dismissPopover()
    }
    
    private func dismissPopover() {
        nameFieldIsFocused = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            overlayOpacity = 0
            contentScale = 0.9
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

// Helper extension to find and select text in TextField
extension UIView {
    func findTextField() -> UITextField? {
        if let textField = self as? UITextField {
            return textField
        }
        for subview in self.subviews {
            if let textField = subview.findTextField() {
                return textField
            }
        }
        return nil
    }
}
