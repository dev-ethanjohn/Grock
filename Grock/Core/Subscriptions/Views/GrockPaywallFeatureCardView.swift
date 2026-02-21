import SwiftUI

struct GrockPaywallFeatureCardView: View {
    let feature: GrockPaywallFeature

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                featureTextBlock(feature)
                    .id(feature.id)
                    .transition(.paywallFeatureTextSwap)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.spring(response: 0.36, dampingFraction: 0.84), value: feature.id)

            if let videoResourceName = feature.videoResourceName {
                LoopingVideoView(resourceName: videoResourceName)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .id(videoResourceName)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 320, alignment: .topLeading)
    }

    private func featureTextBlock(_ feature: GrockPaywallFeature) -> some View {
        VStack(alignment: .center, spacing: 10) {
                Text("Free: \(feature.subtitle)")
                    .lexend(.footnote, weight: .regular)
                    .foregroundColor(.black.opacity(0.5))

                Text("Pro: \(feature.body)")
                    .foregroundColor(.black)
                    .lexend(.subheadline, weight: .regular)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FFE08A"), Color(hex: "FFC94A")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "E3AD2B"), lineWidth: 1)
                    )

        }
        .frame(maxWidth: .infinity)
    }
}

private struct PaywallFeatureTextTransitionModifier: ViewModifier {
    let opacity: Double
    let scale: CGFloat
    let blur: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .scaleEffect(scale)
            .blur(radius: blur)
    }
}

private extension AnyTransition {
    static var paywallFeatureTextSwap: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: PaywallFeatureTextTransitionModifier(opacity: 0, scale: 0.96, blur: 10),
                identity: PaywallFeatureTextTransitionModifier(opacity: 1, scale: 1, blur: 0)
            ),
            removal: .modifier(
                active: PaywallFeatureTextTransitionModifier(opacity: 0, scale: 1.03, blur: 11),
                identity: PaywallFeatureTextTransitionModifier(opacity: 1, scale: 1, blur: 0)
            )
        )
    }
}

#Preview {
    GrockPaywallFeatureCardView(feature: GrockPaywallPreviewFixtures.features[0])
        .padding()
        .background(Color.Grock.surfaceMuted)
}
