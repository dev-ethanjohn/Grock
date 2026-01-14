import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#f7f7f7").ignoresSafeArea()

                if cartViewModel.completedCarts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cart.badge.minus")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No completed trips yet")
                            .lexendFont(16)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(cartViewModel.completedCarts.sorted(by: { $0.completedAt ?? Date() > $1.completedAt ?? Date() })) { cart in
                                HomeCartRowView(cart: cart, vaultService: vaultService)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .lexendFont(16, weight: .semibold)
                }
            }
        }
    }
}
