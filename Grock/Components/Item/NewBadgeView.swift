import SwiftUI

struct NewBadgeView: View {
    let scale: CGFloat
    let rotation: Double
    
    var body: some View {
        Text("NEW")
            .shantellSansFont(8)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(4)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .animation(.interpolatingSpring(mass: 1.0, stiffness: 50, damping: 7), value: rotation)
            .shadow(color: Color(hex: "FF6B6B").opacity(0.3), radius: 3, x: 0, y: 2)
    }
}

//#Preview {
//    NewBadgeView()
//}
