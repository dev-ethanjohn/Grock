import SwiftUI

struct HistoryContentView: View {
    let completedCarts: [Cart]
    let onDeleteTrip: (Cart) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your completed shopping trips.")
                .lexendFont(14)
                .foregroundStyle(.black.opacity(0.6))
                .padding(.horizontal)

            if completedCarts.isEmpty {
                HistoryEmptyStateView()
                    .padding(.top, 40)
            } else {
                VStack(spacing: 14) {
                    ForEach(completedCarts, id: \.id) { cart in
                        HistoryCartRowView(cart: cart) {
                            onDeleteTrip(cart)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Color.clear
                .frame(height: 80)
        }
        .padding(.top, 8)
        .blurScroll(scale: 1.8)
        .background(Color(hex: "#F9F9F9"))
    }
}

#Preview("HistoryContentView") {
    let preview = HistoryPreviewFactory.makePreviewData()

    return HistoryContentView(
        completedCarts: preview.completedCarts,
        onDeleteTrip: { _ in }
    )
    .environment(preview.vaultService)
    .environment(preview.cartViewModel)
}
