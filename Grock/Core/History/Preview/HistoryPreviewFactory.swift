import Foundation
import SwiftData

@MainActor
enum HistoryPreviewFactory {
    static func makePreviewData() -> (vaultService: VaultService, cartViewModel: CartViewModel, completedCarts: [Cart]) {
        let container = try! ModelContainer(
            for: User.self,
            Vault.self,
            Category.self,
            Item.self,
            PriceOption.self,
            PricePerUnit.self,
            Cart.self,
            CartItem.self,
            DeletedCartItemSnapshot.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let context = ModelContext(container)
        let vaultService = VaultService(modelContext: context)
        let cartViewModel = CartViewModel(vaultService: vaultService)

        seedCompletedTrips(into: vaultService)
        cartViewModel.loadCarts()

        let completed = cartViewModel.completedCarts.sorted {
            ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt)
        }

        return (vaultService, cartViewModel, completed)
    }

    private static func seedCompletedTrips(into vaultService: VaultService) {
        guard let vault = vaultService.vault else { return }

        let now = Date()

        let recentTrip = makeCompletedCart(
            name: "Weekend Run",
            budget: 1500,
            completedAt: now.addingTimeInterval(-86_400),
            items: [
                ("Milk", "Market One", 88, "L", 2),
                ("Bread", "Market One", 55, "pc", 1),
                ("Eggs", "Market One", 120, "tray", 1)
            ]
        )

        let olderTrip = makeCompletedCart(
            name: "Midweek Top-up",
            budget: 900,
            completedAt: now.addingTimeInterval(-86_400 * 4),
            items: [
                ("Bananas", "Fresh Mart", 65, "kg", 1),
                ("Coffee", "Fresh Mart", 210, "pack", 1)
            ]
        )

        vault.carts.append(recentTrip)
        vault.carts.append(olderTrip)
    }

    private static func makeCompletedCart(
        name: String,
        budget: Double,
        completedAt: Date,
        items: [(name: String, store: String, price: Double, unit: String, quantity: Double)]
    ) -> Cart {
        let createdAt = completedAt.addingTimeInterval(-7_200)
        let startedAt = completedAt.addingTimeInterval(-3_600)

        let cart = Cart(
            name: name,
            budget: budget,
            createdAt: createdAt,
            startedAt: startedAt,
            completedAt: completedAt,
            status: .completed
        )

        cart.cartItems = items.map { item in
            let cartItem = CartItem.createShoppingOnlyItem(
                name: item.name,
                store: item.store,
                price: item.price,
                unit: item.unit,
                quantity: item.quantity,
                category: .pantry
            )
            cartItem.isFulfilled = true
            cartItem.actualPrice = item.price
            cartItem.actualQuantity = item.quantity
            cartItem.actualUnit = item.unit
            cartItem.actualStore = item.store
            return cartItem
        }

        return cart
    }
}
