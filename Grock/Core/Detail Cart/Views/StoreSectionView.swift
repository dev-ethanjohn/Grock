import SwiftUI
import SwiftData

struct StoreSectionListView: View {
    let store: String
    let items: [(cartItem: CartItem, item: Item?)]
    let cart: Cart
    let onFulfillItem: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    let isLastStore: Bool
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartStateManager.self) private var stateManager
    
    @State private var animatingOutSkippedItems: Set<String> = []
    
    // FIXED: Remove the old parameters and use stateManager instead
    
    private var displayItems: [(cartItem: CartItem, item: Item?)] {
        let filteredItems = items.filter { cartItem, _ in
            guard cartItem.quantity > 0 else { return false }
            
            switch cart.status {
            case .planning:
                return true
            case .shopping:
                return !cartItem.isFulfilled &&
                       (!cartItem.isSkippedDuringShopping || animatingOutSkippedItems.contains(cartItem.itemId))
            case .completed:
                return true
            }
        }
        
        return filteredItems.sorted { $0.cartItem.addedAt > $1.cartItem.addedAt }
    }
    
    var body: some View {
        if !displayItems.isEmpty {
            Section(
                header: StoreSectionHeader(store: store),
                content: {
                    ForEach(Array(displayItems.enumerated()), id: \.element.cartItem.itemId) { index, tuple in
                        StoreSectionRow(
                            index: index,
                            tuple: tuple,
                            cart: cart,
                            displayItems: displayItems,
                            onFulfillItem: onFulfillItem,
                            onEditItem: onEditItem,
                            onDeleteItem: onDeleteItem,
                            handleSkipItem: handleSkipItem
                        )
                    }
                }
            )
            .listSectionSpacing(isLastStore ? 0 : 20)
            // Use simple animation to prevent lag
            .animation(.easeInOut(duration: 0.25), value: displayItems.count)
        }
    }
    
    private func handleSkipItem(_ cartItem: CartItem) {
        animatingOutSkippedItems.insert(cartItem.itemId)
        
        withAnimation(.easeInOut(duration: 0.25)) {
            cartItem.isSkippedDuringShopping = true
            cartItem.isFulfilled = false
            // DON'T update totals immediately during animation
        }
        
        // Update totals AFTER animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            measurePerformance(name: "SkipItem_UpdateTotals", context: "Item: \(cartItem.itemId)") {
                vaultService.updateCartTotals(cart: cart)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animatingOutSkippedItems.remove(cartItem.itemId)
        }
    }
}

private struct StoreSectionRow: View {
    let index: Int
    let tuple: (cartItem: CartItem, item: Item?)
    let cart: Cart
    let displayItems: [(cartItem: CartItem, item: Item?)]
    let onFulfillItem: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    let handleSkipItem: (CartItem) -> Void
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartStateManager.self) private var stateManager
    
    private var isShoppingOnlyItem: Bool { tuple.cartItem.isShoppingOnlyItem }
    private var isSkipped: Bool { tuple.cartItem.isSkippedDuringShopping }
    private var isFulfilled: Bool { tuple.cartItem.isFulfilled }
    
    var body: some View {
        VStack(spacing: 0) {
            CartItemRowListView(
                cartItem: tuple.cartItem,
                cart: cart,
                onFulfillItem: { onFulfillItem(tuple.cartItem) },
                onEditItem: { onEditItem(tuple.cartItem) },
                onDeleteItem: { onDeleteItem(tuple.cartItem) },
                isLastItem: index == displayItems.count - 1,
                isFirstItem: index == 0
            )
            .id(tuple.cartItem.itemId + (tuple.cartItem.actualPrice?.description ?? "") + "\(isSkipped)")
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                swipeActionsContent
            }
            
            if index < displayItems.count - 1 {
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                    .frame(height: 0.5)
                    .foregroundColor(Color(hex: "999").opacity(0.5))
                    .padding(.horizontal, 12)
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
        .listRowBackground(stateManager.effectiveRowBackgroundColor)
        // Disable animations during scroll for better performance
        .transition(.opacity)
        .animation(nil, value: isSkipped)
    }
    
    @ViewBuilder
    private var swipeActionsContent: some View {
        if cart.isShopping {
            if isShoppingOnlyItem {
                Button(role: .destructive) {
                    deleteShoppingOnlyItem()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
            } else if tuple.cartItem.addedDuringShopping {
                Button {
                    deactivateVaultItemAddedDuringShopping()
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }
                .tint(.orange)
            } else {
                if isSkipped {
                    Button {
                        addBackSkippedItem()
                    } label: {
                        Label("Add Back", systemImage: "plus.circle")
                    }
                    .tint(.green)
                } else if isFulfilled {
                    Button {
                        markUnfulfilled()
                    } label: {
                        Label("Unfulfill", systemImage: "circle")
                    }
                    .tint(.orange)
                } else {
                    Button {
                        handleSkipItem(tuple.cartItem)
                    } label: {
                        Label("Skip", systemImage: "minus.circle")
                    }
                    .tint(.orange)
                }
            }
        } else {
            Button(role: .destructive) {
                onDeleteItem(tuple.cartItem)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        
        Button {
            onEditItem(tuple.cartItem)
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.blue)
    }

    private func deactivateVaultItemAddedDuringShopping() {
        tuple.cartItem.quantity = 0
        tuple.cartItem.isSkippedDuringShopping = false
        vaultService.updateCartTotals(cart: cart)
        
        NotificationCenter.default.post(
            name: NSNotification.Name("ShoppingDataUpdated"),
            object: nil,
            userInfo: ["cartItemId": cart.id]
        )
    }

    private func deleteShoppingOnlyItem() {
        onDeleteItem(tuple.cartItem)
    }
    
    private func addBackSkippedItem() {
        withAnimation(.easeInOut(duration: 0.25)) {
            tuple.cartItem.isSkippedDuringShopping = false
            tuple.cartItem.quantity = max(1, tuple.cartItem.originalPlanningQuantity ?? 1)
            // Don't update totals immediately
        }
        
        // Update totals after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            measurePerformance(name: "AddBackItem_UpdateTotals", context: "Item: \(tuple.cartItem.itemId)") {
                vaultService.updateCartTotals(cart: cart)
            }
        }
    }
    
    private func markUnfulfilled() {
        withAnimation(.easeInOut(duration: 0.25)) {
            tuple.cartItem.isFulfilled = false
            // Don't update totals immediately
        }
        
        // Update totals after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            measurePerformance(name: "MarkUnfulfilled_UpdateTotals", context: "Item: \(tuple.cartItem.itemId)") {
                vaultService.updateCartTotals(cart: cart)
            }
        }
    }
}

private struct StoreSectionHeader: View {
    let store: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "storefront")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    
                    Text(store)
                        .lexendFont(11, weight: .bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black)
                .cornerRadius(6)
                Spacer()
            }
            .padding(.leading)
        }
        .listRowInsets(EdgeInsets())
        .textCase(nil)
    }
}
