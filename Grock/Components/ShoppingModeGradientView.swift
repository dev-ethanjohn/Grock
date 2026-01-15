import SwiftUI

struct ShoppingModeGradientView: View {
    let cornerRadius: CGFloat
    let hasBackgroundImage: Bool
    
    init(cornerRadius: CGFloat = 24, hasBackgroundImage: Bool = false) {
        self.cornerRadius = cornerRadius
        self.hasBackgroundImage = hasBackgroundImage
    }
    
    var body: some View {
        // ONLY show gradient if hasBackgroundImage is true
        if hasBackgroundImage {
            TimelineView(.animation(minimumInterval: 0.016)) { context in
                let time = context.date.timeIntervalSince1970
                
                let rotation = Angle(degrees: (time * 240).truncatingRemainder(dividingBy: 360))
                
                AngularGradient(
                    gradient: Gradient(colors: titaniumColors),
                    center: .center,
                    angle: rotation
                )
                .mask(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(lineWidth: 6)
                        .blur(radius: 3)
                )
                .blendMode(.plusLighter)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
            .allowsHitTesting(false)
        }
        // If hasBackgroundImage is false, don't show anything
    }
    
    private var titaniumColors: [Color] {
        [
            Color(hex: "FFFFFF"),
            Color(hex: "A8C0D8"),
            Color(hex: "C4D4E4"),
            Color(hex: "FFFFFF"),
            Color(hex: "7C8BA0"),
            Color(hex: "FFFFFF"),
        ]
    }
}
