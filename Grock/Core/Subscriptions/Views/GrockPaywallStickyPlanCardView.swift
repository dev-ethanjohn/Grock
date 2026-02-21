import SwiftUI

struct GrockPaywallStickyPlanCardView: View {
    let model: GrockPaywallPlanCardModel
    let isSelected: Bool
    private let badgeClearance: CGFloat = 11
    private let cardCornerRadius: CGFloat = 14
    private let selectedAccent = Color.Grock.budgetSafe
    private let unselectedBorderColor = Color.black.opacity(0.16)
    
    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
    }
    
    @ViewBuilder
    private func badgeLabel(_ badge: String) -> some View {
        let uppercasedBadge = badge.uppercased()
        let components = uppercasedBadge.split(separator: " ", omittingEmptySubsequences: true)
        
        if let percentIndex = components.firstIndex(where: { $0.contains("%") }) {
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                    Text("\(component)\(index < components.count - 1 ? " " : "")")
                        .lexend(.footnote, weight: index == percentIndex ? .bold : .semibold)
                        .tracking(0.3)
                }
            }
        } else {
            Text(uppercasedBadge)
                .lexend(.footnote, weight: .semibold)
                .tracking(0.3)
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            VStack(alignment: .center, spacing: 0) {
                Text(model.title)
                    .lexend(.callout)
                    .foregroundColor(isSelected ? .white.opacity(0.7) : .black.opacity(0.7))
                    .padding(.top, 8)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(model.price)
                        .lexend(.title3, weight: .semibold)
                        .foregroundColor(isSelected ? .white : .black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                    
                    Text(model.cadence)
                        .lexend(.footnote, weight: .medium)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .gray)
                        .lineLimit(1)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 10)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(
            ZStack {
                cardShape
                    .fill(
                        model.isEnabled
                        ? .white
                        : Color.white.opacity(0.85)
                    )
                
                if isSelected {
                    cardShape
                        .fill(Color.clear)
                        .overlay {
                            Image("selected_sub")
                                .resizable()
                                .scaledToFill()
                        }
                        .clipShape(cardShape)
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
                .clipShape(cardShape)
                .clipped()
                .overlay {
                    if !isSelected {
                        cardShape
                            .stroke(
                                unselectedBorderColor,
                                lineWidth: 1
                            )
                    }
                }
                .overlay {
                    if isSelected {
                        ShoppingModeGradientView(
                            cornerRadius: cardCornerRadius,
                            hasBackgroundImage: true
                        )
                        .clipShape(cardShape)
                    }
                }
        )
        .overlay(alignment: .topLeading) {
            if let badge = model.badge {
                badgeLabel(badge)
                    .foregroundColor(.black.opacity(0.86))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        ZStack {
                            if badge.localizedCaseInsensitiveContains("save") {
                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FFE08A"), Color(hex: "FFC94A")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            } else {
                                Capsule(style: .continuous)
                                    .fill(isSelected ? selectedAccent : .white)
                            }
                        }
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? .clear : unselectedBorderColor, lineWidth: 1)
                    )
                    .offset(y: -badgeClearance)
                    .offset(x: 8)
            }
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundStyle(isSelected ? selectedAccent : Color.gray.opacity(0.5))
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
