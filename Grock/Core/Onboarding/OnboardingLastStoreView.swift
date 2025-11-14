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
        .onChange(of: viewModel.storeName) { oldValue, newValue in
            processStoreNameChange(newValue)
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
                    .scaleEffect(viewModel.showError ? 1.0 : 0)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.25), value: viewModel.showError)
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
                .animation(.spring(response: 0.35, dampingFraction: 0.65)),
            removal: .scale(scale: 0.95, anchor: .topLeading)
                .combined(with: .opacity)
                .animation(.spring(response: 0.25, dampingFraction: 0.75))
        ))
    }
    
    private var nextButton: some View {
        FormCompletionButton.nextButton(
            isEnabled: viewModel.isValidStoreName,
            appearanceScale: viewModel.showNextButton ? 1.0 : 0.0,
            shakeOffset: viewModel.shakeOffset
        ) {
            guard viewModel.isValidStoreName else {
                viewModel.triggerStoreNameError()
                return
            }
            
            viewModel.storeName = viewModel.storeName.trimmingCharacters(in: .whitespacesAndNewlines)
            viewModel.navigateToFirstItemDataScreen()
        }
    }
    
    private func processStoreNameChange(_ newValue: String) {
        let processedValue = viewModel.processStoreNameInput(newValue)
        
        if processedValue != newValue {
            viewModel.storeName = processedValue
            return
        }
        
        if viewModel.isValidStoreName {
            viewModel.showError = false
        }
    }
}
