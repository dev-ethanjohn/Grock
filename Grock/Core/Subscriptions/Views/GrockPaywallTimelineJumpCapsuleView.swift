import SwiftUI

struct GrockPaywallTimelineJumpCapsuleView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("How your free trial works")
                .lexend(.caption2, weight: .bold)
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.black.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.16), radius: 4, x: 0, y: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.Grock.surfaceMuted.ignoresSafeArea()
        GrockPaywallTimelineJumpCapsuleView(action: {})
    }
}
