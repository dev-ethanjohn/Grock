import SwiftUI

struct GrockPaywallTimelineJumpCapsuleView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("How your free trial works")
                .lexend(.caption, weight: .semibold)
                .foregroundColor(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.white)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.black.opacity(0.5), lineWidth: 1)
                        )
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
