import SwiftUI

struct GrockPaywallTimelineJumpCapsuleView: View {
    let action: () -> Void

    private var headerBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .fill(.black.opacity(0.04))
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(1), location: 0),
                            .init(color: .black.opacity(0.7), location: 0.4),
                            .init(color: .black.opacity(0.5), location: 0.55),
                            .init(color: .black.opacity(0.3), location: 0.7),
                            .init(color: .black.opacity(0), location: 1.0)
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
        }
    }

    var body: some View {
//        ZStack {
//            headerBackground
//                .offset(y: 24)

            Button(action: action) {
                Text("How your free trial works")
                    .lexend(.caption, weight: .semibold)
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.white)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color.black.opacity(0.07), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .offset(y: 40)
        .frame(maxWidth: .infinity)
        .frame(height: 72)
    }
}

#Preview {
    ZStack {
        Color.Grock.surfaceMuted.ignoresSafeArea()
        GrockPaywallTimelineJumpCapsuleView(action: {})
    }
}
