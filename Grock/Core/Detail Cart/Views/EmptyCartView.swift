import SwiftUI
import Lottie

struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 8) {
                Text("Add items to your cart")
                    .fuzzyBubblesFont(20, weight: .bold)
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
            
            LottieView(animation: .named("Arrow"))
                .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
                .animationSpeed(0.6)
                .scaleEffect(x: -0.8, y: 0.8)
                .allowsHitTesting(false)
                .frame(height: 100)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.5)
                .rotationEffect(.degrees(-90))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#Preview {
    EmptyCartView()
}
