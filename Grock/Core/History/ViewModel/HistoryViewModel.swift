import Foundation
import Observation

@MainActor
@Observable
final class HistoryViewModel {
    var pendingDeleteCartId: String?
    var pendingDeleteCartName: String = ""
    var showingDeleteAlert = false

    func sortedCompletedCarts(from carts: [Cart]) -> [Cart] {
        carts.sorted {
            ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt)
        }
    }

    func confirmDelete(_ cart: Cart) {
        pendingDeleteCartId = cart.id
        pendingDeleteCartName = cart.name
        showingDeleteAlert = true
    }

    func pendingCart(in carts: [Cart]) -> Cart? {
        guard let pendingDeleteCartId else { return nil }
        return carts.first(where: { $0.id == pendingDeleteCartId })
    }

    func clearPendingDelete() {
        pendingDeleteCartId = nil
    }
}
