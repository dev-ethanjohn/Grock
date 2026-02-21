import SwiftUI

/// A Siri-like animated glowing border that indicates a cart is in active shopping mode.
struct ShoppingModeGradientView: View {
    let cornerRadius: CGFloat
    let hasBackgroundImage: Bool

    init(cornerRadius: CGFloat = 24, hasBackgroundImage: Bool = false) {
        self.cornerRadius = cornerRadius
        self.hasBackgroundImage = hasBackgroundImage
    }

    // For background images - high contrast titanium.
    private let imageGlowColors: [Color] = [
        Color(hex: "FFFFFF"),
        Color(hex: "6B7B8C"),
        Color(hex: "A8C0D8"),
        Color(hex: "4A5568"),
        Color(hex: "E2E8F0"),
        Color(hex: "7C8BA0"),
        Color(hex: "C4D4E4"),
        Color(hex: "5A6A7A"),
        Color(hex: "FFFFFF")
    ]

    // For plain colors - light silver gradient.
    private let plainGlowColors: [Color] = [
        Color(hex: "FFFFFF"),
        Color(hex: "E8ECF0"),
        Color(hex: "D0D8E0"),
        Color(hex: "FFFFFF"),
        Color(hex: "C8D4E0"),
        Color(hex: "E0E8F0"),
        Color(hex: "FFFFFF")
    ]

    private var glowColors: [Color] {
        hasBackgroundImage ? imageGlowColors : plainGlowColors
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016)) { context in
            let time = context.date.timeIntervalSince1970
            let rotation = Angle(degrees: time.truncatingRemainder(dividingBy: 3.0) / 3.0 * 360)

            ZStack {
                // Very subtle outer halo.
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: glowColors),
                            center: .center,
                            angle: rotation
                        ),
                        lineWidth: 4
                    )
                    .blur(radius: 5)
                    .opacity(0.3)

                // Medium glow.
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: glowColors),
                            center: .center,
                            angle: rotation
                        ),
                        lineWidth: 2.5
                    )
                    .blur(radius: 2)
                    .opacity(0.6)

                // Inner sharp edge (visible border).
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: glowColors),
                            center: .center,
                            angle: rotation
                        ),
                        lineWidth: 2
                    )
                    .opacity(1.0)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Alternative cooler gradient option (blue/purple tones) - Siri style.
struct ShoppingModeGradientViewCool: View {
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 24) {
        self.cornerRadius = cornerRadius
    }

    private let glowColors: [Color] = [
        Color(hex: "5E5CE6"),
        Color(hex: "64D2FF"),
        Color(hex: "30D158"),
        Color(hex: "5E5CE6"),
        Color(hex: "BF5AF2"),
        Color(hex: "FF375F"),
        Color(hex: "64D2FF"),
        Color(hex: "5E5CE6")
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016)) { context in
            let time = context.date.timeIntervalSince1970
            let rotation = Angle(degrees: time.truncatingRemainder(dividingBy: 3.0) / 3.0 * 360)

            ZStack {
                // Outer glow layer (tighter diffuse).
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: glowColors),
                            center: .center,
                            angle: rotation
                        ),
                        lineWidth: 3
                    )
                    .blur(radius: 3)
                    .opacity(0.7)

                // Middle glow layer.
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: glowColors),
                            center: .center,
                            angle: rotation
                        ),
                        lineWidth: 2.5
                    )
                    .blur(radius: 1.5)
                    .opacity(0.85)

                // Inner sharp border.
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: glowColors),
                            center: .center,
                            angle: rotation
                        ),
                        lineWidth: 2
                    )
                    .opacity(1.0)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Warm version.
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.white)
            .frame(height: 120)
            .overlay(ShoppingModeGradientView(cornerRadius: 24))
            .padding()

        // Cool version.
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.white)
            .frame(height: 120)
            .overlay(ShoppingModeGradientViewCool(cornerRadius: 24))
            .padding()
    }
    .background(Color(hex: "F7F7F7"))
}
