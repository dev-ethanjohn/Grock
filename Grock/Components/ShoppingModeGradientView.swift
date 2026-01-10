import SwiftUI


struct ShoppingModeGradientView: View {
    let cornerRadius: CGFloat
    let hasBackgroundImage: Bool
    
    init(cornerRadius: CGFloat = 24, hasBackgroundImage: Bool = false) {
        self.cornerRadius = cornerRadius
        self.hasBackgroundImage = hasBackgroundImage
    }
    
    private var colors: [Color] {
        hasBackgroundImage ? [
            Color(hex: "FFFFFF"),
            Color(hex: "A8C0D8"),
            Color(hex: "C4D4E4"),
            Color(hex: "FFFFFF"),
            Color(hex: "7C8BA0"),
            Color(hex: "FFFFFF"),
        ] : [
            Color(hex: "FFFFFF"),
            Color(hex: "E0E8F0"),
            Color(hex: "FFFFFF"),
            Color(hex: "D0D8E0"),
            Color(hex: "FFFFFF"),
        ]
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.016)) { context in
            let time = context.date.timeIntervalSince1970
            
            let rotation = Angle(degrees: (time * 240).truncatingRemainder(dividingBy: 360))
            
            AngularGradient(
                gradient: Gradient(colors: colors),
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
    }
}
