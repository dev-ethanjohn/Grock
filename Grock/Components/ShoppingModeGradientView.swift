import SwiftUI

/// A Siri-like animated glowing border that indicates a cart is in active shopping mode
struct ShoppingModeGradientView: View {
    let cornerRadius: CGFloat
    let hasBackgroundImage: Bool
    
    init(cornerRadius: CGFloat = 24, hasBackgroundImage: Bool = false) {
        self.cornerRadius = cornerRadius
        self.hasBackgroundImage = hasBackgroundImage
    }
    
    // For background images - high contrast titanium
    private let imageGlowColors: [Color] = [
        Color(hex: "FFFFFF"),  // Pure white flash
        Color(hex: "6B7B8C"),  // Dark steel
        Color(hex: "A8C0D8"),  // Ice blue titanium
        Color(hex: "4A5568"),  // Gunmetal
        Color(hex: "E2E8F0"),  // Bright silver
        Color(hex: "7C8BA0"),  // Medium steel
        Color(hex: "C4D4E4"),  // Light ice
        Color(hex: "5A6A7A"),  // Dark titanium
        Color(hex: "FFFFFF"),  // Pure white flash
    ]
    
    // For plain colors - light silver gradient
    private let plainGlowColors: [Color] = [
        Color(hex: "FFFFFF"),  // Pure white
        Color(hex: "E8ECF0"),  // Light silver
        Color(hex: "D0D8E0"),  // Soft steel
        Color(hex: "FFFFFF"),  // Pure white
        Color(hex: "C8D4E0"),  // Ice silver
        Color(hex: "E0E8F0"),  // Bright silver
        Color(hex: "FFFFFF"),  // Pure white
    ]
    
    private var glowColors: [Color] {
        hasBackgroundImage ? imageGlowColors : plainGlowColors
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016)) { context in
            let time = context.date.timeIntervalSince1970
            let rotation = Angle(degrees: time.truncatingRemainder(dividingBy: 3.0) / 3.0 * 360)
            
            GeometryReader { geometry in
                ZStack {
                    // Very subtle outer halo
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
                    
                    // Medium glow
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
                    
                    // Inner sharp edge (visible border)
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
        }
    }
}

/// Alternative cooler gradient option (blue/purple tones) - Siri style
struct ShoppingModeGradientViewCool: View {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 24) {
        self.cornerRadius = cornerRadius
    }
    
    private let glowColors: [Color] = [
        Color(hex: "5E5CE6"),  // Purple
        Color(hex: "64D2FF"),  // Blue
        Color(hex: "30D158"),  // Green
        Color(hex: "5E5CE6"),  // Purple
        Color(hex: "BF5AF2"),  // Magenta
        Color(hex: "FF375F"),  // Pink
        Color(hex: "64D2FF"),  // Blue
        Color(hex: "5E5CE6"),  // Purple
    ]
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016)) { context in
            let time = context.date.timeIntervalSince1970
            let rotation = Angle(degrees: time.truncatingRemainder(dividingBy: 3.0) / 3.0 * 360)
            
            GeometryReader { geometry in
                ZStack {
                    // Outer glow layer (tighter diffuse)
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
                    
                    // Middle glow layer
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
                    
                    // Inner sharp border
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
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Warm version
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.white)
            .frame(height: 120)
            .overlay(ShoppingModeGradientView(cornerRadius: 24))
            .padding()
        
        // Cool version
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.white)
            .frame(height: 120)
            .overlay(ShoppingModeGradientViewCool(cornerRadius: 24))
            .padding()
    }
    .background(Color(hex: "f7f7f7"))
}
