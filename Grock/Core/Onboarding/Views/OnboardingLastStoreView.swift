import SwiftUI

struct OnboardingLastStoreView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var storeFieldIsFocused: Bool
    
    var body: some View {
        VStack {
            skipButton
            
            Spacer().frame(height: 60)
            
            QuestionTitle(text: "Where was your last grocery trip?")
            
            storeNameField
            
            errorMessage
            
            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            bottomButtons
        }
        .onAppear {
            viewModel.animateStoreFieldAppearance()
            viewModel.showInfoDropdownWithDelay()
            storeFieldIsFocused = true
        }
        .onChange(of: viewModel.formViewModel.storeName) { oldValue, newValue in
            if viewModel.formViewModel.isValidStoreName {
                viewModel.showError = false
            }
        }
    }
    
    private var skipButton: some View {
        HStack {
            Spacer()
            Button("Skip") {
                viewModel.resetForSkip()
                viewModel.navigateToFirstItemDataScreen()
            }
            .fuzzyBubblesFont(16, weight: .bold)
            .foregroundColor(.secondary)
        }
        .padding(.top)
        .padding(.horizontal)
    }
    
    private var storeNameField: some View {
        TextField("e.g. Public Market...", text: $viewModel.formViewModel.storeName)
            .normalizedText($viewModel.formViewModel.storeName)
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
            .scaleEffect(viewModel.showTextField ? 1.0 : 0.0)
            .opacity(viewModel.showTextField ? 1.0 : 0.0)
            .padding(.horizontal, 60)
            .padding(.top, 28)
    }
    
    private var errorMessage: some View {
        Group {
            if viewModel.showError {
                Text("Store name needs at least 1 valid character")
                    .font(.caption)
                    .foregroundColor(Color(hex: "FF6F71"))
                    .padding(.top, 8)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8, anchor: .center)
                            .animation(.spring(response: 0.2, dampingFraction: 0.7)),
                        removal: .scale(scale: 0.8, anchor: .center)
                            .combined(with: .opacity)
                            .animation(.spring(response: 0.2, dampingFraction: 0.75))
                    ))
            }
        }
    }
    
    private var bottomButtons: some View {
        HStack {
            infoButton
            Spacer()
            nextButton
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
    
    private var infoButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.showInfoDropdown = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.showInfoDropdown = false
                }
            }
        }) {
            Image(systemName: "info.circle")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .overlay(alignment: .topLeading) {
            if viewModel.showInfoDropdown {
                infoDropdown
            }
        }
    }
    
    private var infoDropdown: some View {
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
                .combined(with: .opacity)
                .animation(.spring(response: 0.3, dampingFraction: 0.5)),
            removal: .scale(scale: 0.95, anchor: .topLeading)
                .combined(with: .opacity)
                .animation(.spring(response: 0.15, dampingFraction: 0.75))
        ))
    }
    
    private var nextButton: some View {
        FormCompletionButton.nextButton(
            isEnabled: viewModel.formViewModel.isValidStoreName,
            cornerRadius: 50,
            appearanceScale: viewModel.showNextButton ? 1.0 : 0.0,
            shakeOffset: viewModel.shakeOffset
        ) {
            guard viewModel.formViewModel.isValidStoreName else {
                viewModel.triggerStoreNameError()
                return
            }
            
            viewModel.navigateToFirstItemDataScreen()
        }
    }
}
