import SwiftUI

struct HistoryEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .lexendFont(48)
                .foregroundColor(.gray.opacity(0.5))

            Text("No completed trips yet")
                .lexendFont(18, weight: .medium)
                .foregroundColor(.gray)

            Text("Finish a shopping trip to see it here.")
                .lexendFont(14)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview("HistoryEmptyStateView") {
    HistoryEmptyStateView()
        .padding()
        .background(Color(hex: "#F9F9F9"))
}
