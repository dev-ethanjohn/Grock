import SwiftUI

struct HistoryView: View {
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = HistoryViewModel()

    private var completedCarts: [Cart] {
        viewModel.sortedCompletedCarts(from: cartViewModel.completedCarts)
    }

    var body: some View {
        NavigationStack {
            HistoryContentView(
                completedCarts: completedCarts,
                onDeleteTrip: { cart in
                    viewModel.confirmDelete(cart)
                }
            )
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("History")
                        .fuzzyBubblesFont(20, weight: .bold)
                        .foregroundStyle(.black)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .lexendFont(16, weight: .semibold)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                HistoryInsightsTeaserCardView()
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
                    .ignoresSafeArea(edges: .bottom)
            }
            .alert("Delete Trip", isPresented: Binding(
                get: { viewModel.showingDeleteAlert },
                set: { viewModel.showingDeleteAlert = $0 }
            )) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    handleDeleteConfirmation()
                }
            } message: {
                Text("Move '\(viewModel.pendingDeleteCartName)' to Trash? Insights and history for this trip will be removed until you restore it.")
            }
        }
    }

    private func handleDeleteConfirmation() {
        if let cart = viewModel.pendingCart(in: cartViewModel.carts) {
            withAnimation {
                cartViewModel.deleteCart(cart)
            }
        }
        viewModel.clearPendingDelete()
    }
}

#Preview("HistoryView") {
    let preview = HistoryPreviewFactory.makePreviewData()

    return HistoryView()
        .environment(preview.vaultService)
        .environment(preview.cartViewModel)
}
