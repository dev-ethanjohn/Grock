import SwiftUI

struct GrockPaywallBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            Image("sub_background")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    GrockPaywallBackgroundView()
        .ignoresSafeArea()
}
