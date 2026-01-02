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
    
    // FIXED: Proper filtering for shopping mode
    private var displayItems: [(cartItem: CartItem, item: Item?)] {
        let filteredItems = items.filter { cartItem, _ in
            // Always exclude items with quantity <= 0
            guard cartItem.quantity > 0 else {
                return false
            }
            
            // Filter based on cart status
            switch cart.status {
            case .planning:
                // In planning mode: show all items with quantity > 0
                return true
                
            case .shopping:
                // In shopping mode: show only unfulfilled, non-skipped items
                return !cartItem.isFulfilled && !cartItem.isSkippedDuringShopping
                
            case .completed:
                // In completed mode: show all items
                return true
            }
        }
        
        // Sort items by name for consistent display
        return filteredItems.sorted { ($0.item?.name ?? "") < ($1.item?.name ?? "") }
    }
    
    // ADD THIS: Track item count changes for animation
    @State private var previousDisplayCount: Int = 0
    
    var body: some View {
        // Only show section if there are items to display
        if !displayItems.isEmpty {
            Section(
                header: StoreSectionHeader(store: store),
                content: {
                    ForEach(Array(displayItems.enumerated()), id: \.element.cartItem.itemId) { index, tuple in
                        StoreSectionRow(
                            index: index,
                            tuple: tuple,
                            cart: cart,
                            displayItems: displayItems, // Pass displayItems for comparison
                            onFulfillItem: onFulfillItem,
                            onEditItem: onEditItem,
                            onDeleteItem: onDeleteItem,
                            handleSkipItem: handleSkipItem
                        )
                    }
                }
            )
            .listSectionSpacing(isLastStore ? 0 : 20)
            // ADD THIS: Animate section changes
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: displayItems.count)
            .onAppear {
                previousDisplayCount = displayItems.count
            }
            .onChange(of: displayItems.count) { oldCount, newCount in
                // Trigger animation when count changes
                if oldCount != newCount {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        // Force UI update
                    }
                }
                previousDisplayCount = newCount
            }
        }
    }
    
    private func handleSkipItem(_ cartItem: CartItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            cartItem.isSkippedDuringShopping = true
            cartItem.isFulfilled = false
            vaultService.updateCartTotals(cart: cart)
        }
    }
}

// MARK: - Private Subviews

private struct StoreSectionHeader: View {
    let store: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 2) {
                    Image("store")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
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
    
    // Helper to determine item type
    private var isShoppingOnlyItem: Bool {
        tuple.cartItem.isShoppingOnlyItem
    }
    
    private var isSkipped: Bool {
        tuple.cartItem.isSkippedDuringShopping
    }
    
    private var isFulfilled: Bool {
        tuple.cartItem.isFulfilled
    }
    
    private var hasQuantity: Bool {
        tuple.cartItem.quantity > 0
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CartItemRowListView(
                cartItem: tuple.cartItem,
                cart: cart,
                onFulfillItem: { onFulfillItem(tuple.cartItem) },
                onEditItem: { onEditItem(tuple.cartItem) },
                onDeleteItem: { onDeleteItem(tuple.cartItem) },
                isLastItem: index == displayItems.count - 1
            )
            .id(tuple.cartItem.itemId + (tuple.cartItem.actualPrice?.description ?? ""))
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
        .listRowBackground(Color(hex: "F7F2ED"))
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    @ViewBuilder
    private var swipeActionsContent: some View {
        if cart.isShopping {
            // SHOPPING MODE SWIPE ACTIONS
            if isShoppingOnlyItem {
                // SHOPPING-ONLY ITEMS (added during shopping)
                Button(role: .destructive) {
                    deleteShoppingOnlyItem()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
            } else {
                // VAULT ITEMS (originally planned)
                if isSkipped {
                    // Skipped vault item: "Add Back" action
                    Button {
                        addBackSkippedItem()
                    } label: {
                        Label("Add Back", systemImage: "plus.circle")
                    }
                    .tint(.green)
                } else if isFulfilled {
                    // Fulfilled vault item: "Mark Unfulfilled" action
                    Button {
                        markUnfulfilled()
                    } label: {
                        Label("Unfulfill", systemImage: "circle")
                    }
                    .tint(.orange)
                } else {
                    // Active unfulfilled vault item: "Skip" action
                    Button {
                        handleSkipItem(tuple.cartItem)
                    } label: {
                        Label("Skip", systemImage: "minus.circle")
                    }
                    .tint(.orange)
                }
            }
        } else {
            // PLANNING MODE SWIPE ACTIONS
            Button(role: .destructive) {
                onDeleteItem(tuple.cartItem)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        
        // EDIT ACTION (available for all item types in all modes)
        Button {
            onEditItem(tuple.cartItem)
        } label: {
            Label("Edit", systemImage: "pencil")
        }
        .tint(.blue)
    }
    
    // MARK: - Action Handlers
    
    private func deleteShoppingOnlyItem() {
        print("🗑️ Deleting shopping-only item via swipe: \(tuple.cartItem.shoppingOnlyName ?? "Unknown")")
        
        // Simply call the standard delete handler
        // The parent view will handle the refresh
        onDeleteItem(tuple.cartItem)
    }
    
    private func addBackSkippedItem() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tuple.cartItem.isSkippedDuringShopping = false
            tuple.cartItem.quantity = max(1, tuple.cartItem.originalPlanningQuantity ?? 1)
            vaultService.updateCartTotals(cart: cart)
        }
    }
    
    private func markUnfulfilled() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            tuple.cartItem.isFulfilled = false
            vaultService.updateCartTotals(cart: cart)
        }
    }
}
