import SwiftUI
import SwiftData

//struct StoreSectionListView: View {
//    let store: String
//    let items: [(cartItem: CartItem, item: Item?)]
//    let cart: Cart
//    let onFulfillItem: (CartItem) -> Void  // Changed
//    let onEditItem: (CartItem) -> Void
//    let onDeleteItem: (CartItem) -> Void
//    let isLastStore: Bool
//    
//    @Environment(VaultService.self) private var vaultService
//    
//    // FIXED: Only filter items if we're in shopping mode
//    private var displayItems: [(cartItem: CartItem, item: Item?)] {
//        if cart.isShopping {
//            // In shopping mode, we only get unfulfilled, non-skipped items from parent
//            return items
//        } else {
//            // In planning mode, show all items
//            return items
//        }
//    }
//    
//    private func handleSkipItem(_ cartItem: CartItem) {
//        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//            cartItem.isSkippedDuringShopping = true
//            cartItem.isFulfilled = false
//            vaultService.updateCartTotals(cart: cart)
//        }
//    }
//    
//    var body: some View {
//        // Only show section if there are items to display
//        if !displayItems.isEmpty {
//            Section(
//                header: VStack(spacing: 0) {
//                    HStack {
//                        HStack(spacing: 2) {
//                            Image("store")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 10, height: 10)
//                                .foregroundColor(.white)
//                            
//                            Text(store)
//                                .lexendFont(11, weight: .bold)
//                        }
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 4)
//                        .background(Color.black)
//                        .cornerRadius(6)
//                        Spacer()
//                    }
//                    .padding(.leading)
//                }
//                .listRowInsets(EdgeInsets())
//                .textCase(nil)
//                
//            ) {
//                ForEach(Array(displayItems.enumerated()), id: \.element.cartItem.itemId) { index, tuple in
//                    VStack(spacing: 0) {
//                        CartItemRowListView(
//                            cartItem: tuple.cartItem,
//                            item: tuple.item,
//                            cart: cart,
//                            onFulfillItem: { onFulfillItem(tuple.cartItem) },
//                            onEditItem: { onEditItem(tuple.cartItem) },
//                            onDeleteItem: { onDeleteItem(tuple.cartItem) },
//                            isLastItem: index == displayItems.count - 1
//                        )
//                        .id(tuple.cartItem.itemId + (tuple.cartItem.actualPrice?.description ?? ""))
//                        .listRowInsets(EdgeInsets())
//                        .listRowSeparator(.hidden)
////                        .background(Color(hex: "F7F2ED"))
//                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                            if cart.isShopping {
//                                // Shopping mode: Skip action
//                                Button(role: .destructive) {
//                                    handleSkipItem(tuple.cartItem)
//                                } label: {
//                                    Label("Skip", systemImage: "minus.circle")
//                                }
//                                .tint(.orange)
//                            } else {
//                                // Planning mode: Delete action
//                                Button(role: .destructive) {
//                                    onDeleteItem(tuple.cartItem)
//                                } label: {
//                                    Label("Delete", systemImage: "trash")
//                                }
//                            }
//                            
//                            Button {
//                                onEditItem(tuple.cartItem)
//                            } label: {
//                                Label("Edit", systemImage: "pencil")
//                            }
//                            
//                            // FIXED: Only show "Mark Unfulfilled" for already fulfilled items
//                            if cart.isShopping && tuple.cartItem.isFulfilled {
//                                Button {
//                                    // Direct toggle for unfulfilling (no popover needed)
//                                    tuple.cartItem.isFulfilled = false
//                                    vaultService.updateCartTotals(cart: cart)
//                                } label: {
//                                    Label("Mark Unfulfilled", systemImage: "circle")
//                                }
//                                .tint(.orange)
//                            }
//                        }
//                        
//                        if index < displayItems.count - 1 {
//                            DashedLine()
//                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
//                                .frame(height: 0.5)
//                                .foregroundColor(Color(hex: "999").opacity(0.5))
//                                .padding(.horizontal, 12)
//                        }
//                    }
//                    .listRowInsets(EdgeInsets())
//                    .listRowSeparator(.hidden)
//                    .listRowBackground(Color(hex: "F7F2ED"))
//                }
//            }
//            .listSectionSpacing(isLastStore ? 0 : 20)
//        }
//    }
//}
//import SwiftUI
//import SwiftData
//
//struct StoreSectionListView: View {
//    let store: String
//    let items: [(cartItem: CartItem, item: Item?)]
//    let cart: Cart
//    let onFulfillItem: (CartItem) -> Void  // Changed
//    let onEditItem: (CartItem) -> Void
//    let onDeleteItem: (CartItem) -> Void
//    let isLastStore: Bool
//    
//    @Environment(VaultService.self) private var vaultService
//    
//    // FIXED: Updated filtering logic for shopping mode
//    private var displayItems: [(cartItem: CartItem, item: Item?)] {
//        if cart.isShopping {
//            // In shopping mode: show only unfulfilled AND non-skipped items
//            return items.filter { cartItem, _ in
//                !cartItem.isFulfilled && !cartItem.isSkippedDuringShopping
//            }
//        } else {
//            // In planning mode, show all items
//            return items
//        }
//    }
//    
//    private func handleSkipItem(_ cartItem: CartItem) {
//        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//            cartItem.isSkippedDuringShopping = true
//            cartItem.isFulfilled = false
//            vaultService.updateCartTotals(cart: cart)
//        }
//    }
//    
//    var body: some View {
//        // Only show section if there are items to display
//        if !displayItems.isEmpty {
//            Section(
//                header: VStack(spacing: 0) {
//                    HStack {
//                        HStack(spacing: 2) {
//                            Image("store")
//                                .resizable()
//                                .scaledToFit()
//                                .frame(width: 10, height: 10)
//                                .foregroundColor(.white)
//                            
//                            Text(store)
//                                .lexendFont(11, weight: .bold)
//                        }
//                        .foregroundColor(.white)
//                        .padding(.horizontal, 8)
//                        .padding(.vertical, 4)
//                        .background(Color.black)
//                        .cornerRadius(6)
//                        Spacer()
//                    }
//                    .padding(.leading)
//                }
//                .listRowInsets(EdgeInsets())
//                .textCase(nil)
//                
//            ) {
//                ForEach(Array(displayItems.enumerated()), id: \.element.cartItem.itemId) { index, tuple in
//                    VStack(spacing: 0) {
//                        CartItemRowListView(
//                            cartItem: tuple.cartItem,
//                            item: tuple.item,
//                            cart: cart,
//                            onFulfillItem: { onFulfillItem(tuple.cartItem) },
//                            onEditItem: { onEditItem(tuple.cartItem) },
//                            onDeleteItem: { onDeleteItem(tuple.cartItem) },
//                            isLastItem: index == displayItems.count - 1
//                        )
//                        .id(tuple.cartItem.itemId + (tuple.cartItem.actualPrice?.description ?? ""))
//                        .listRowInsets(EdgeInsets())
//                        .listRowSeparator(.hidden)
//                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                            if cart.isShopping {
//                                // Shopping mode: Skip action
//                                Button(role: .destructive) {
//                                    handleSkipItem(tuple.cartItem)
//                                } label: {
//                                    Label("Skip", systemImage: "minus.circle")
//                                }
//                                .tint(.orange)
//                            } else {
//                                // Planning mode: Delete action
//                                Button(role: .destructive) {
//                                    onDeleteItem(tuple.cartItem)
//                                } label: {
//                                    Label("Delete", systemImage: "trash")
//                                }
//                            }
//                            
//                            Button {
//                                onEditItem(tuple.cartItem)
//                            } label: {
//                                Label("Edit", systemImage: "pencil")
//                            }
//                            
//                            // FIXED: Only show "Mark Unfulfilled" for already fulfilled items
//                            if cart.isShopping && tuple.cartItem.isFulfilled {
//                                Button {
//                                    // Direct toggle for unfulfilling (no popover needed)
//                                    tuple.cartItem.isFulfilled = false
//                                    vaultService.updateCartTotals(cart: cart)
//                                } label: {
//                                    Label("Mark Unfulfilled", systemImage: "circle")
//                                }
//                                .tint(.orange)
//                            }
//                        }
//                        
//                        if index < displayItems.count - 1 {
//                            DashedLine()
//                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
//                                .frame(height: 0.5)
//                                .foregroundColor(Color(hex: "999").opacity(0.5))
//                                .padding(.horizontal, 12)
//                        }
//                    }
//                    .listRowInsets(EdgeInsets())
//                    .listRowSeparator(.hidden)
//                    .listRowBackground(Color(hex: "F7F2ED"))
//                }
//            }
//            .listSectionSpacing(isLastStore ? 0 : 20)
//        }
//    }
//}
//
//
//struct CompletedItemRow: View {
//    let cartItem: CartItem
//    let item: Item?
//    let cart: Cart
//    let onUnfulfill: () -> Void
//    
//    @Environment(VaultService.self) private var vaultService
//    
//    private var displayPrice: Double {
//        if cart.isShopping {
//            return (cartItem.actualPrice ?? cartItem.plannedPrice) ?? 0
//        }
//        return cartItem.plannedPrice ?? 0
//    }
//    
//    private var displayQuantity: Double {
//        if cart.isShopping {
//            return cartItem.actualQuantity ?? cartItem.quantity
//        }
//        return cartItem.quantity
//    }
//    
//    var body: some View {
//        HStack(alignment: .center, spacing: 12) {
//            
//            Button(action: onUnfulfill) {
//                Image(systemName: "checkmark.circle.fill")
//                    .font(.system(size: 22))
//                    .foregroundColor(.green)
//            }
//            .buttonStyle(.plain)
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text(item?.name ?? "Unknown Item")
//                    .lexendFont(15, weight: .medium)
//                    .foregroundColor(Color(hex: "333"))
//                    .strikethrough(true, color: Color(hex: "999"))
//                
//                HStack(spacing: 8) {
//                    Text("\(displayQuantity.formatQuantity()) × \(displayPrice.formattedCurrency)")
//                        .lexendFont(13)
//                        .foregroundColor(Color(hex: "666"))
//                    
////                    if let storeName = item?.store {
////                        Text("• \(storeName)")
////                            .lexendFont(12)
////                            .foregroundColor(Color(hex: "999"))
////                    }
//                }
//            }
//            
//            Spacer()
//            
//            Text((displayPrice * displayQuantity).formattedCurrency)
//                .lexendFont(15, weight: .bold)
//                .foregroundColor(Color(hex: "333"))
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 12)
//        .background(Color.white.opacity(0.5))
//    }
//}
//extension Double {
//    func formatQuantity() -> String {
//        self == floor(self) ? String(Int(self)) : String(self)
//    }
//}
//
//

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
        if cart.isShopping {
            // In shopping mode: show only unfulfilled AND non-skipped items
            return items.filter { cartItem, _ in
                !cartItem.isFulfilled && !cartItem.isSkippedDuringShopping
            }
        } else {
            // In planning mode, show all items
            return items
        }
    }
    
    // ADD THIS: Track item count changes for animation
    @State private var previousDisplayCount: Int = 0
    
    var body: some View {
        // Only show section if there are items to display
        if !displayItems.isEmpty {
            Section(
                header: VStack(spacing: 0) {
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
                
            ) {
                ForEach(Array(displayItems.enumerated()), id: \.element.cartItem.itemId) { index, tuple in
                    VStack(spacing: 0) {
                        CartItemRowListView(
                            cartItem: tuple.cartItem,
                            item: tuple.item,
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
                            if cart.isShopping {
                                // Shopping mode: Skip action
                                Button(role: .destructive) {
                                    handleSkipItem(tuple.cartItem)
                                } label: {
                                    Label("Skip", systemImage: "minus.circle")
                                }
                                .tint(.orange)
                            } else {
                                // Planning mode: Delete action
                                Button(role: .destructive) {
                                    onDeleteItem(tuple.cartItem)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            
                            Button {
                                onEditItem(tuple.cartItem)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            // Only show "Mark Unfulfilled" for already fulfilled items
                            if cart.isShopping && tuple.cartItem.isFulfilled {
                                Button {
                                    // Direct toggle for unfulfilling (no popover needed)
                                    tuple.cartItem.isFulfilled = false
                                    vaultService.updateCartTotals(cart: cart)
                                } label: {
                                    Label("Mark Unfulfilled", systemImage: "circle")
                                }
                                .tint(.orange)
                            }
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
                    // ADD THIS: Animate item removal
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
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
