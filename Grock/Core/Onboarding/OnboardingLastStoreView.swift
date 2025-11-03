import SwiftUI

struct OnboardingLastStoreView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var storeFieldAnimated: Bool
    @Binding var hasShownInfoDropdown: Bool
    var onNext: () -> Void
    var onSkip: () -> Void
    
    @FocusState private var storeFieldIsFocused: Bool
    @State private var showTextField = false
    @State private var showNextButton = false
    @State private var fillAnimation: CGFloat = 0.0
    @State private var showInfoDropdown = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var shakeOffset: CGFloat = 0
    @State private var showError = false
    
    private var isValidStoreName: Bool {
        let trimmed = viewModel.storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2
    }
    
    private func normalizeSpaces(_ text: String) -> String {
        return text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    var body: some View {
        VStack {
            
            HStack {
                Spacer()
                Button("Skip") {
                    viewModel.storeName = ""
                    onSkip()
                }
                .font(.fuzzyBold_16)
                .foregroundColor(.secondary)
            }
            .padding(.top)
            .padding(.horizontal)
            
            Spacer()
                .frame(height: 60)
            
            Text("Where was your last grocery trip?")
                .font(.fuzzyBold_24)
                .multilineTextAlignment(.center)

            
            TextField("e.g. Walmart, SM, Costco", text: $viewModel.storeName)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.words)
                .padding(.vertical, 8)
                .overlay(
                    VStack {
                        Spacer()
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                )
                .focused($storeFieldIsFocused)
                .scaleEffect(showTextField ? 1.0 : 0.0)
                .opacity(showTextField ? 1.0 : 0.0)
                .padding(.horizontal, 60)
                .padding(.top, 28)
                .onChange(of: viewModel.storeName) { oldValue, newValue in
                    var processedValue = newValue
                    
                    if processedValue.hasPrefix(" ") {
                        processedValue = String(processedValue.dropFirst())
                    }
                    
                    processedValue = normalizeSpaces(processedValue)
                    
                    if processedValue != newValue {
                        viewModel.storeName = processedValue
                        return
                    }
                    
                    if isValidStoreName {
                        if !wasValidStoreName(oldValue) {
                            withAnimation(.spring(duration: 0.4)) {
                                fillAnimation = 1.0
                            }
                            startButtonBounce()
                        }
                        showError = false
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            fillAnimation = 0.0
                            buttonScale = 1.0
                        }
                    }
                }
            
            if showError {
                Text("Store name needs at least 2 characters")
                    .font(.caption)
                    .foregroundColor(Color(hex: "FF6F71"))
                    .padding(.top, 8)
                    .scaleEffect(showError ? 1.0 : 0)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.25), value: showError)
            }
            
            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showInfoDropdown = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showInfoDropdown = false
                        }
                    }
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .overlay(alignment: .topLeading) {
                    if showInfoDropdown {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Add store so prices match where you shop — not just estimates.")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(12)
                                .multilineTextAlignment(.leading)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Material.ultraThick)
                                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 4)
                        )
                        .frame(width: 240)
                        .frame(height: 200)
                        .offset(x: 12, y: -120)
                        .transition(.asymmetric(
                               insertion: .scale(scale: 0.85, anchor: .topLeading)
                                   .animation(.spring(response: 0.35, dampingFraction: 0.65)),
                               removal: .scale(scale: 0.95, anchor: .topLeading)
                                   .combined(with: .opacity)
                                   .animation(.spring(response: 0.25, dampingFraction: 0.75))
                           ))
                    }
                }
                
                Spacer()
                
                Button {
                    guard isValidStoreName else {
                        triggerError()
                        return
                    }
                    
                    viewModel.storeName = viewModel.storeName.trimmingCharacters(in: .whitespacesAndNewlines)
                    onNext()
                } label: {
                    Text("Next")
                        .font(.fuzzyBold_16)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 24)
                        .background(
                            Capsule()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.black, Color.gray.opacity(0.3)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: fillAnimation * 80
                                    )
                                )
                        )
                        .scaleEffect(showNextButton ? buttonScale : 0.0)
                        .offset(x: shakeOffset)
                }

            }
            .padding(.vertical, 8)
            .padding(.horizontal)
        }
        .onAppear {
            if !storeFieldAnimated {
                showTextField = false
                showNextButton = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                    showTextField = true
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
                    showNextButton = true
                }
                storeFieldIsFocused = true
                storeFieldAnimated = true
            } else {
                showTextField = true
                showNextButton = true
                storeFieldIsFocused = true
            }
            
            if isValidStoreName {
                fillAnimation = 1.0
                startButtonBounce()
            }
            
            if !hasShownInfoDropdown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showInfoDropdown = true
                    }
                    hasShownInfoDropdown = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showInfoDropdown = false
                        }
                    }
                }
            }
        }
    }
    
    private func wasValidStoreName(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2
    }
    
    private func startButtonBounce() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            buttonScale = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                buttonScale = 1.1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                buttonScale = 1.0
            }
        }
    }
    
    private func triggerError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        showError = true
        
        let shakeSequence = [0, -8, 8, -6, 6, -4, 4, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    shakeOffset = CGFloat(offset)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showError = false
            }
        }
    }
}

#Preview {
    OnboardingLastStoreView(
        viewModel: OnboardingViewModel(),
        storeFieldAnimated: .constant(false),
        hasShownInfoDropdown: .constant(false),
        onNext: {},
        onSkip: {}
    )
}
