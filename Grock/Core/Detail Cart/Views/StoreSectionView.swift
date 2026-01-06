import SwiftUI
import SwiftData

struct StoreSectionListView: View {
    let store: String
    let items: [(cartItem: CartItem, item: Item?)] // This is a constant, not a function
    let cart: Cart
    let onFulfillItem: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    let isLastStore: Bool
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartStateManager.self) private var stateManager
    
    // FIXED: Proper filtering and sorting for items
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
        
        // DEBUG: Print timestamps to verify
        #if DEBUG
        for (cartItem, item) in filteredItems {
            print("📅 Item: \(item?.name ?? cartItem.shoppingOnlyName ?? "Unknown"), addedAt: \(cartItem.addedAt)")
        }
        #endif
        
        // FIX: Sort items by addedAt (newest first) for consistent display
        return filteredItems.sorted {
            // Sort by addedAt in descending order (newest first)
            $0.cartItem.addedAt > $1.cartItem.addedAt
        }
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

private struct StoreSectionHeader: View {
    let store: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "storefront") // Using SF Symbol instead of custom image
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
        .listRowBackground(stateManager.effectiveRowBackgroundColor)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    // In StoreSectionRow's swipeActionsContent:
    @ViewBuilder
    private var swipeActionsContent: some View {
        if cart.isShopping {
            // SHOPPING MODE SWIPE ACTIONS
            
            if isShoppingOnlyItem {
                // SHOPPING-ONLY ITEMS: Delete action
                Button(role: .destructive) {
                    deleteShoppingOnlyItem()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
                
            } else if tuple.cartItem.addedDuringShopping {
                // VAULT ITEMS ADDED DURING SHOPPING: Deactivate action (not delete)
                Button {
                    deactivateVaultItemAddedDuringShopping()
                } label: {
                    Label("Remove", systemImage: "minus.circle")
                }
                .tint(.orange) // Orange instead of red to indicate deactivation, not deletion
                
            } else {
                // PLANNED VAULT ITEMS (in cart before shopping started)
                if isSkipped {
                    // Skipped planned item: "Add Back" action
                    Button {
                        addBackSkippedItem()
                    } label: {
                        Label("Add Back", systemImage: "plus.circle")
                    }
                    .tint(.green)
                } else if isFulfilled {
                    // Fulfilled planned item: "Mark Unfulfilled" action
                    Button {
                        markUnfulfilled()
                    } label: {
                        Label("Unfulfill", systemImage: "circle")
                    }
                    .tint(.orange)
                } else {
                    // Active unfulfilled planned item: "Skip" action
                    Button {
                        handleSkipItem(tuple.cartItem)
                    } label: {
                        Label("Skip", systemImage: "minus.circle")
                    }
                    .tint(.orange)
                }
            }
        } else {
            // PLANNING MODE SWIPE ACTIONS (same for all)
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

    private func deactivateVaultItemAddedDuringShopping() {
        print("🔄 Deactivating vault item added during shopping: \(tuple.item?.name ?? "Unknown")")
        
        // Set quantity to 0 instead of removing
        tuple.cartItem.quantity = 0
        tuple.cartItem.isSkippedDuringShopping = false // Not skipped, just deactivated
        vaultService.updateCartTotals(cart: cart)
        
        // Send notification
        NotificationCenter.default.post(
            name: NSNotification.Name("ShoppingDataUpdated"),
            object: nil,
            userInfo: ["cartItemId": cart.id]
        )
    }

    private func deleteVaultItemAddedDuringShopping() {
        print("🔄 Deactivating vault item added during shopping: \(tuple.item?.name ?? "Unknown")")
        
        // Instead of deleting, set quantity to 0
        if let cartItem = cart.cartItems.first(where: { $0.itemId == tuple.cartItem.itemId }) {
            cartItem.quantity = 0
            cartItem.isSkippedDuringShopping = false // Not skipped, just deactivated
            vaultService.updateCartTotals(cart: cart)
            
            print("   Deactivated vault item: quantity set to 0")
            
            // Send notification to refresh UI
            NotificationCenter.default.post(
                name: NSNotification.Name("ShoppingDataUpdated"),
                object: nil,
                userInfo: ["cartItemId": cart.id]
            )
        }
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
