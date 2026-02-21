import SwiftUI

struct GrockPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var viewModel = GrockPaywallViewModel()
    @State private var selectedFeatureIndex = 0
    @State private var purchaseTapGate = false

    private let onUnlocked: (() -> Void)?

    init(onUnlocked: (() -> Void)? = nil) {
        self.onUnlocked = onUnlocked
    }

    private var selectedPlanBinding: Binding<GrockPaywallPlanCardModel.Plan> {
        Binding(
            get: { viewModel.selectedPlan },
            set: { viewModel.selectedPlan = $0 }
        )
    }

    private var showAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showAlert },
            set: { viewModel.showAlert = $0 }
        )
    }

    private var dismissHeaderBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.7),
                        .init(color: .white.opacity(0.8), location: 0.8),
                        .init(color: .white.opacity(0.4), location: 0.9),
                        .init(color: .white.opacity(0), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(hex: "FFFFFF"), location: 0.0),
                    .init(color: Color(hex: "FFFFFF"), location: 0.2),
                    .init(color: Color(hex: "FFFBEA"), location: 0.4),
                    .init(color: Color(hex: "FFF2C8"), location: 0.55),
                    .init(color: Color(hex: "FFE79A"), location: 0.68),
                    .init(color: Color(hex: "FFD966"), location: 0.82),
                    .init(color: Color(hex: "FFC94A"), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                Image("sub_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 18) {
                    GrockPaywallTopHeaderView()

                    GrockPaywallFeatureCarouselSectionView(
                        features: viewModel.features,
                        selectedIndex: $selectedFeatureIndex,
                        onManualInteraction: {}
                    )
                    .padding(.horizontal, 20)

                    GrockPaywallTrialTimelineView(
                        items: viewModel.trialTimelineItems,
                        summaryText: viewModel.selectedPlanSummaryText
                    )
                    .padding(.horizontal, 20)
                }
                .padding(.top, 32)
                .padding(.bottom, 390)
            }
        }
        .overlay(alignment: .top) {
            GeometryReader { geo in
                let topSafeAreaInset = geo.safeAreaInsets.top

                ZStack(alignment: .topLeading) {
                    dismissHeaderBackground
                        .frame(height: topSafeAreaInset + 40)
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .top)

                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
//                        .padding(.top)
                        .padding(.leading, 16)
                        .onTapGesture {
                            dismiss()
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .overlay(alignment: .bottom) {
            GrockPaywallStickyBottomPanelView(
                planCards: viewModel.planCards,
                selectedPlan: selectedPlanBinding,
                isProcessingAction: viewModel.isProcessingAction || purchaseTapGate,
                isPrimaryActionEnabled: viewModel.isPrimaryActionEnabled && !purchaseTapGate,
                primaryButtonTitle: viewModel.primaryButtonTitle,
                onPrimaryAction: handlePrimaryAction,
                onRestore: handleRestore,
                onTerms: openTerms,
                onPrivacy: openPrivacy
            )
        }
        .task {
            await viewModel.refreshAll()
        }
        .alert("Subscription", isPresented: showAlertBinding) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    private func handlePrimaryAction() {
        guard !purchaseTapGate else { return }
        purchaseTapGate = true

        Task { @MainActor in
            defer { purchaseTapGate = false }
            let unlocked = await viewModel.purchaseSelectedPlan()
            if unlocked {
                onUnlocked?()
                dismiss()
            }
        }
    }
    
    private func handleRestore() {
        Task {
            let restored = await viewModel.restorePurchases()
            if restored {
                onUnlocked?()
                dismiss()
            }
        }
    }

    private func openTerms() {
        openURL(viewModel.termsURL)
    }

    private func openPrivacy() {
        openURL(viewModel.privacyURL)
    }
}

#Preview("Paywall Full") {
    GrockPaywallView()
}
