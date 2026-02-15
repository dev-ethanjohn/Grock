import SwiftUI

struct HistoryInsightsTeaserCardView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("🧠 Coming Soon: Smart Insights")
                .lexendFont(17, weight: .semibold)
                .foregroundStyle(.black.opacity(0.75))

            Text("See patterns across your grocery trips")
                .lexendFont(12, weight: .regular)
                .foregroundStyle(.black.opacity(0.55))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(Color.white)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .allowsHitTesting(false)
    }
}

#Preview("HistoryInsightsTeaserCardView") {
    VStack {
        Spacer()
        HistoryInsightsTeaserCardView()
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "#F9F9F9"))
}
