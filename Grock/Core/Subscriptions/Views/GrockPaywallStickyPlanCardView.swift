import SwiftUI

struct GrockPaywallStickyPlanCardView: View {
    let model: GrockPaywallPlanCardModel
    let isSelected: Bool
    private let badgeClearance: CGFloat = 11
    private let cardCornerRadius: CGFloat = 14
    private let selectedAccent = Color(hex: "6F9F20")
    private let selectedBorderColor = Color(hex: "6F9F20")
    private let unselectedBorderColor = Color.black.opacity(0.16)
    private let selectedFillColor = Color(hex: "EAF4AF")
    
    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
    }

    private var titleColor: Color {
        .black.opacity(0.7)
    }

    private var priceColor: Color {
        if !isSelected {
            return titleColor
        }

        return .black
    }

    @ViewBuilder
    private func badgeLabel(_ badge: String) -> some View {
        let uppercasedBadge = badge.uppercased()
        let components = uppercasedBadge.split(separator: " ", omittingEmptySubsequences: true)
        let isSaveBadge = uppercasedBadge.contains("SAVE")
        let baseTextStyle: Font.TextStyle = isSaveBadge ? .subheadline : .footnote
        let badgeWeight: Font.Weight = isSaveBadge ? .black : .semibold
        let trackingAmount: CGFloat = isSaveBadge ? 0.55 : 0.3
        
        if components.contains(where: { $0.contains("%") }) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                    Text("\(component)\(index < components.count - 1 ? " " : "")")
                        .lexend(baseTextStyle, weight: badgeWeight)
                        .tracking(trackingAmount)
                }
            }
        } else {
            Text(uppercasedBadge)
                .lexend(baseTextStyle, weight: badgeWeight)
                .tracking(trackingAmount)
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            VStack(alignment: .center, spacing: 0) {
                Text(model.title)
                    .lexend(.subheadline)
                    .foregroundColor(titleColor)
                    .padding(.top, 8)
                
                if model.isPriceLoading {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.72)
                            .tint(.black.opacity(0.58))

                        Text("Loading")
                            .lexend(.footnote, weight: .medium)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(model.price)
                            .lexend(.title3, weight: .semibold)
                            .foregroundColor(priceColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .allowsTightening(true)
                        
                        Text(model.cadence)
                            .lexend(.footnote, weight: .medium)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            cardShape
                .fill(
                    model.isEnabled
                    ? (isSelected ? selectedFillColor.opacity(0.24) : .white)
                    : .white
                )
                .clipShape(cardShape)
                .overlay {
                    if isSelected {
                        cardShape
                            .stroke(
                                selectedBorderColor,
                                lineWidth: 1.5
                            )
                    } else {
                        cardShape
                            .stroke(
                                unselectedBorderColor,
                                lineWidth: 1
                            )
                    }
                }
        )
        .overlay(alignment: .topLeading) {
            if let badge = model.badge {
                let isSaveBadge = badge.localizedCaseInsensitiveContains("save")
                badgeLabel(badge)
                    .foregroundColor(isSaveBadge ? .white : .black.opacity(0.86))
                    .padding(.horizontal, isSaveBadge ? 6 : 8)
                    .padding(.vertical, isSaveBadge ? 2 : 2)
                    .background(
                        ZStack {
                            if isSaveBadge {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(
                                        selectedBorderColor
                                    )
                                
                            } else {
                                Capsule(style: .continuous)
                                    .fill(isSelected ? selectedAccent : .white)
                            }
                        }
                    )
                    .overlay(
                        Group {
                            if isSaveBadge {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(selectedBorderColor.opacity(0.55), lineWidth: 0.8)
                            } else {
                                Capsule()
                                    .stroke(isSelected ? .clear : unselectedBorderColor, lineWidth: 1)
                            }
                        }
                    )
                    .offset(y: -badgeClearance)
                    .offset(x: 8)
            }
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(isSelected ? selectedBorderColor : Color.gray.opacity(0.5))
                .scaleEffect(isSelected ? 1.07 : 1.0)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.bounce, value: isSelected)
                .animation(
                    .interactiveSpring(response: 0.24, dampingFraction: 0.64, blendDuration: 0.08),
                    value: isSelected
                )
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
                .padding(.top, 6)
                .padding(.trailing, 6)
        }
        .padding(.top, badgeClearance)
        .opacity(model.isEnabled ? 1 : 0.7)
        .animation(.spring(response: 0.34, dampingFraction: 0.68), value: isSelected)
    }
}

#Preview("Selected") {
    HStack {
        GrockPaywallStickyPlanCardView(
            model: GrockPaywallPreviewFixtures.yearlyPlan,
            isSelected: true
        )
        GrockPaywallStickyPlanCardView(
            model: GrockPaywallPreviewFixtures.monthlyPlan,
            isSelected: false
        )
    }
    .padding(.horizontal)
}
