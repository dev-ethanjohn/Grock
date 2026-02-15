import SwiftUI

struct HistoryCartRowView: View {
    let cart: Cart
    let onDelete: () -> Void

    @State private var backgroundImage: UIImage? = nil
    @State private var hasBackgroundImage = false

    init(cart: Cart, onDelete: @escaping () -> Void) {
        self.cart = cart
        self.onDelete = onDelete

        let cartId = cart.id
        let cached = ImageCacheManager.shared.getImage(forCartId: cartId)
        let loaded = cached ?? CartBackgroundImageManager.shared.loadImage(forCartId: cartId)

        _backgroundImage = State(initialValue: loaded)
        _hasBackgroundImage = State(initialValue: loaded != nil || CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cartId))

        if let loaded {
            ImageCacheManager.shared.saveImage(loaded, forCartId: cartId)
        }
    }

    private var completedItemsCount: Int {
        cart.cartItems.filter { cartItem in
            cartItem.quantity > 0 && cartItem.isFulfilled && !cartItem.isSkippedDuringShopping
        }.count
    }

    private var completedDateText: String {
        let date = cart.completedAt ?? cart.startedAt ?? cart.createdAt
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private var completedSummaryText: String {
        if completedItemsCount == 1 {
            return "Totalling \(fulfilledSpentTotal.formattedCurrency)"
        }
        return "Bought \(completedItemsCount) items totalling \(fulfilledSpentTotal.formattedCurrency)"
    }

    private var backgroundColor: Color {
        if hasBackgroundImage {
            return Color.clear
        }
        return ColorOption.getBackgroundColor(for: cart.id, isRow: true)
    }

    private var fulfilledSpentTotal: Double {
        cart.cartItems
            .filter { cartItem in
                cartItem.quantity > 0 && cartItem.isFulfilled && !cartItem.isSkippedDuringShopping
            }
            .reduce(0.0) { total, cartItem in
                let price: Double
                let quantity: Double

                if cartItem.isShoppingOnlyItem {
                    price = cartItem.shoppingOnlyPrice ?? 0
                    quantity = cartItem.quantity
                } else {
                    price = cartItem.actualPrice ?? cartItem.plannedPrice ?? 0
                    quantity = cartItem.quantity
                }

                return total + (price * quantity)
            }
    }

    private var cardBackground: some View {
        Group {
            if hasBackgroundImage, let backgroundImage {
                ZStack {
                    Image(uiImage: backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .blur(radius: 4)
                        .overlay(Color.black.opacity(0.4))

                    VisibleNoiseView(
                        grainSize: 0.0001,
                        density: 0.3,
                        opacity: 0.20
                    )
                }
            } else {
                backgroundColor
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(cart.name)
                    .fuzzyBubblesFont(18, weight: .bold)
                    .foregroundStyle(hasBackgroundImage ? .white : .black)

                Spacer()

                Text(completedDateText)
                    .lexendFont(12)
                    .foregroundStyle(hasBackgroundImage ? .white.opacity(0.72) : .black.opacity(0.45))
            }

            VStack(alignment: .leading, spacing: 4) {
                let summaryColor = hasBackgroundImage ? Color.white.opacity(0.82) : Color(hex: "717171")
                CharacterRevealView(
                    text: completedSummaryText,
                    delay: 0.15,
                    animateOnChange: true,
                    animateOnAppear: false,
                    showsUnderline: false,
                    underlineColor: summaryColor
                )
                .id("spent-\(completedItemsCount)-\(fulfilledSpentTotal.formattedCurrency)")
                .fuzzyBubblesFont(13, weight: .bold)
                .foregroundColor(summaryColor)
                .padding(.leading, 4)

                FluidBudgetPillView(
                    cart: cart,
                    animatedBudget: cart.budget,
                    onBudgetTap: nil,
                    hasBackgroundImage: hasBackgroundImage,
                    isHeader: false
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.gray.opacity(1), lineWidth: 0.3)
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Trip", systemImage: "trash")
            }
        }
        .onAppear {
            loadBackgroundImageAsync()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CartBackgroundImageChanged"))) { notification in
            if let cartId = notification.userInfo?["cartId"] as? String,
               cartId == cart.id {
                loadBackgroundImageAsync()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CartColorChanged"))) { notification in
            if let cartId = notification.userInfo?["cartId"] as? String,
               cartId == cart.id {
                loadBackgroundImageAsync()
            }
        }
    }

    private func loadBackgroundImageAsync() {
        let cartId = cart.id

        let hasImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cartId)
        hasBackgroundImage = hasImage

        guard hasImage else {
            backgroundImage = nil
            return
        }

        if let cached = ImageCacheManager.shared.getImage(forCartId: cartId) {
            backgroundImage = cached
            return
        }

        let image = CartBackgroundImageManager.shared.loadImage(forCartId: cartId)
        backgroundImage = image

        if let image {
            ImageCacheManager.shared.saveImage(image, forCartId: cartId)
        }
    }
}

#Preview("HistoryCartRowView") {
    let preview = HistoryPreviewFactory.makePreviewData()
    let fallbackCart = Cart(name: "Sample Trip", budget: 1000, status: .completed)
    let cart = preview.completedCarts.first ?? fallbackCart

    return VStack {
        HistoryCartRowView(cart: cart, onDelete: {})
            .environment(preview.vaultService)
            .environment(preview.cartViewModel)
    }
    .padding()
    .background(Color(hex: "#F9F9F9"))
}
