import SwiftUI

struct OnboardingLastStoreView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var storeFieldIsFocused: Bool
    @State private var infoPopoverTaskID = UUID()
    
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
            presentInfoPopoverOnFirstAppearance()
            storeFieldIsFocused = true
        }
        .onDisappear {
            infoPopoverTaskID = UUID()
            viewModel.showInfoDropdown = false
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
            .textInputAutocapitalization(.never)
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
            presentInfoPopover()
        }) {
            Image(systemName: "info.circle")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .popover(
            isPresented: $viewModel.showInfoDropdown,
            attachmentAnchor: .point(.center),
            arrowEdge: .bottom
        ) {
            infoPopoverContent
        }
    }
    
    @ViewBuilder
    private var infoPopoverContent: some View {
        if #available(iOS 16.4, *) {
            infoPopoverBody
                .presentationCompactAdaptation(.popover)
                .presentationBackground(Color.white)
        } else {
            infoPopoverBody
        }
    }

    private var infoPopoverBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Add store so prices match where you shop — not just estimates.")
                .lexendFont(13, weight: .regular)
                .foregroundStyle(Color.black)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 248, alignment: .leading)
        }
        .padding(24)
        .background(Color.white)
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

    private func presentInfoPopoverOnFirstAppearance() {
        guard !viewModel.hasShownInfoDropdown else { return }
        viewModel.hasShownInfoDropdown = true

        let taskID = UUID()
        infoPopoverTaskID = taskID

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard infoPopoverTaskID == taskID else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.showInfoDropdown = true
            }
            scheduleInfoPopoverDismiss(taskID: taskID)
        }
    }

    private func presentInfoPopover() {
        let taskID = UUID()
        infoPopoverTaskID = taskID

        if viewModel.showInfoDropdown {
            viewModel.showInfoDropdown = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                guard infoPopoverTaskID == taskID else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.showInfoDropdown = true
                }
                scheduleInfoPopoverDismiss(taskID: taskID)
            }
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.showInfoDropdown = true
        }
        scheduleInfoPopoverDismiss(taskID: taskID)
    }

    private func scheduleInfoPopoverDismiss(taskID: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard infoPopoverTaskID == taskID else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.showInfoDropdown = false
            }
        }
    }
}
