import SwiftUI
import Lottie

struct GrockPaywallStickyBottomPanelView: View {
    let planCards: [GrockPaywallPlanCardModel]
    @Binding var selectedPlan: GrockPaywallPlanCardModel.Plan
    let isProcessingAction: Bool
    let isPrimaryActionEnabled: Bool
    let primaryButtonTitle: String
    let onPrimaryAction: () -> Void
    let onRestore: () -> Void
    let onTerms: () -> Void
    let onPrivacy: () -> Void
    private let valueEmoji = "✨"

    private var selectedPlanContextPrimaryLine: String {
        guard let selectedCard = planCards.first(where: { $0.id == selectedPlan }) else {
            return ""
        }

        switch selectedPlan {
        case .yearly:
            if let monthlyEquivalent = normalizedMonthlyEquivalent(from: selectedCard.detail) {
                return "Just \(monthlyEquivalent) \(valueEmoji)"
            }
            return "Just \(selectedCard.price)/yr \(valueEmoji)"
        case .monthly:
            if let weeklyEquivalent = normalizedWeeklyEquivalent(from: selectedCard.detail) {
                return "About \(weeklyEquivalent) \(valueEmoji)"
            }
            return "Just \(selectedCard.price)/mo \(valueEmoji)"
        }
    }

    private var selectedPlanContextSecondaryLine: String {
        switch selectedPlan {
        case .yearly:
            return "Save more on every grocery trip."
        case .monthly:
            return "Start saving more on groceries every week."
        }
    }

    private func normalizedMonthlyEquivalent(from detail: String) -> String? {
        guard detail.contains("/mo") else { return nil }
        return detail
            .replacingOccurrences(of: "Only ", with: "")
    }

    private func normalizedWeeklyEquivalent(from detail: String) -> String? {
        guard detail.contains("/week") else { return nil }
        return detail.replacingOccurrences(of: "About ", with: "")
    }

    private var panelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 28,
                bottomLeading: 0,
                bottomTrailing: 0,
                topTrailing: 28
            ),
            style: .continuous
        )
    }

    private var panelBackground: some View {
        panelShape
            .fill(Color.white)
            .overlay {
                panelShape
                    .stroke(Color.gray.opacity(0.32), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
            .ignoresSafeArea(edges: .bottom)
    }

    private func planArrow(flippedHorizontally: Bool) -> some View {
        LottieView(animation: .named("Arrow"))
            .playing(.fromProgress(0, toProgress: 0.5, loopMode: .playOnce))
            .frame(width: 32, height: 24    )
            .rotationEffect(.degrees(120))
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            .scaleEffect(x: flippedHorizontally ? -1 : 1, y: 1)
            .scaleEffect(1.2)
            .allowsHitTesting(false)
    }

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                
                VStack(spacing: 2) {
                    ZStack {
                        Text(selectedPlanContextPrimaryLine)
                            .lexend(.title3, weight: .medium)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .id(selectedPlanContextPrimaryLine)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .animation(.spring(response: 0.32, dampingFraction: 0.8), value: selectedPlanContextPrimaryLine)

                    CharacterRevealView(
                        text: selectedPlanContextSecondaryLine,
                        delay: 0.15,
                        animateOnChange: false,
                        animateOnAppear: true,
                        showsUnderline: false
                    )
                    .lexend(.footnote)
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .id(selectedPlanContextSecondaryLine)
                }
                .padding(.top, 8)

                ZStack {
                    if selectedPlan == .yearly {
                        planArrow(flippedHorizontally: true)
                            .id("plan-arrow-yearly")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 14)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    } else {
                        planArrow(flippedHorizontally: false)
                            .id("plan-arrow-monthly")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 14)
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .offset(y: 4)
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: selectedPlan)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding(.vertical, 4)

            HStack(alignment: .top, spacing: 10) {
                ForEach(planCards) { plan in
                    GrockPaywallStickyPlanCardView(
                        model: plan,
                        isSelected: selectedPlan == plan.id
                    )
                    .onTapGesture {
                        guard plan.isEnabled else { return }
                        selectedPlan = plan.id
                    }
                }
            }
            
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5))
                .padding(.horizontal)
//
//            Text("Cancel anytime :)")
//                .lexend(.footnote, weight: .medium)
//                .foregroundColor(Color.Grock.budgetSafe.darker(by: 0.24))
//                .frame(maxWidth: .infinity, alignment: .center)

            Button(action: onPrimaryAction) {
                HStack(spacing: 8) {
                    if isProcessingAction {
                        ProgressView()
                            .tint(.black)
                    }

                    Text(primaryButtonTitle)
                        .fuzzyBubblesFont(18, weight: .bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 100, style: .continuous)
//                        .fill(Color.Grock.budgetSafe)
                        .fill(.black)
                )
            }
            .disabled(!isPrimaryActionEnabled)
            .opacity(isPrimaryActionEnabled ? 1 : 0.6)

            ZStack {
                HStack(spacing: 0) {
                    Button("Terms", action: onTerms)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 32)

                    Button("Privacy", action: onPrivacy)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 32)
                }

                Button("Restore Purchases", action: onRestore)
                    .lineLimit(1)
                    .minimumScaleFactor(0.92)
                    .fixedSize(horizontal: true, vertical: false)
                    .disabled(isProcessingAction)
            }
            .buttonStyle(.plain)
            .lexend(.caption)
            .foregroundColor(Color(.systemGray))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .background {
            panelBackground
        }
    }
}

private struct GrockPaywallStickyBottomPanelPreview: View {
    @State private var selectedPlan: GrockPaywallPlanCardModel.Plan = .yearly

    var body: some View {
        GrockPaywallStickyBottomPanelView(
            planCards: [GrockPaywallPreviewFixtures.yearlyPlan, GrockPaywallPreviewFixtures.monthlyPlan],
            selectedPlan: $selectedPlan,
            isProcessingAction: false,
            isPrimaryActionEnabled: true,
            primaryButtonTitle: "Start 7-Day Free Trial",
            onPrimaryAction: {},
            onRestore: {},
            onTerms: {},
            onPrivacy: {}
        )
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.Grock.surfaceMuted.ignoresSafeArea()
        GrockPaywallStickyBottomPanelPreview()
    }
}
