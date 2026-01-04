//
//  ItemsListView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 1/4/26.
//

import SwiftUI

struct ItemsListView: View {
    let cart: Cart
    let totalItemCount: Int
    let sortedStoresWithRefresh: [String]
    let storeItemsWithRefresh: (String) -> [(cartItem: CartItem, item: Item?)]
    @Binding var fulfilledCount: Int
//    @Binding var selectedColor: ColorOption
    let backgroundColor: Color
    let rowBackgroundColor: Color
    let onFulfillItem: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    
    @Environment(VaultService.self) private var vaultService
    
    
    // Calculate available width based on screen width minus total padding
    private var availableWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        let cartDetailPadding: CGFloat = 17
        let itemRowPadding: CGFloat = cart.isShopping ? 36 : 28
        let internalSpacing: CGFloat = 4
        let safetyBuffer: CGFloat = 3
        
        let totalPadding = cartDetailPadding + itemRowPadding + internalSpacing + safetyBuffer
        
        let calculatedWidth = screenWidth - totalPadding
        
        return max(min(calculatedWidth, 250), 150)
    }
    
    private func estimateRowHeight(for itemName: String, isFirstInSection: Bool = true) -> CGFloat {
        let averageCharWidth: CGFloat = 8.0
        
        let estimatedTextWidth = CGFloat(itemName.count) * averageCharWidth
        let numberOfLines = ceil(estimatedTextWidth / availableWidth)
        
        let singleLineTextHeight: CGFloat = 22
        let verticalPadding: CGFloat = 24
        let internalSpacing: CGFloat = 10
        
        let baseHeight = singleLineTextHeight + verticalPadding + internalSpacing
        
        let additionalLineHeight: CGFloat = 24
        
        let itemHeight = baseHeight + (max(0, numberOfLines - 1) * additionalLineHeight)
        
        let dividerHeight: CGFloat = isFirstInSection ? 0 : 12.0
        
        return itemHeight + dividerHeight
    }
    
    private var estimatedHeight: CGFloat {
        let sectionHeaderHeight: CGFloat = 34
        let sectionSpacing: CGFloat = 8
        let listPadding: CGFloat = 24
        
        var totalHeight: CGFloat = listPadding
        
        for store in sortedStoresWithRefresh {
            let displayItems = getDisplayItems(for: store)
            
            if !displayItems.isEmpty {
                totalHeight += sectionHeaderHeight
                
                for (index, (_, item)) in displayItems.enumerated() {
                    let itemName = item?.name ?? "Unknown"
                    let isFirstInStore = index == 0
                    totalHeight += estimateRowHeight(for: itemName, isFirstInSection: isFirstInStore)
                }
                
                if store != sortedStoresWithRefresh.last {
                    totalHeight += sectionSpacing
                }
            }
        }
        
        return totalHeight
    }
    
    private var allItemsCompleted: Bool {
        guard cart.isShopping else { return false }
        
        // Get all items across all stores
        let allItems = sortedStoresWithRefresh.flatMap { storeItemsWithRefresh($0) }
        
        // Check if all non-skipped items are fulfilled
        let allUnfulfilledItems = allItems.filter {
            !$0.cartItem.isFulfilled &&
            !$0.cartItem.isSkippedDuringShopping
        }
        
        return allUnfulfilledItems.isEmpty && totalItemCount > 0
    }
    
    // FIXED: Check if ALL stores have no display items
    private var hasDisplayItems: Bool {
        for store in sortedStoresWithRefresh {
            if !getDisplayItems(for: store).isEmpty {
                return true
            }
        }
        return false
    }
    
    // FIXED: Helper function to get display items
    private func getDisplayItems(for store: String) -> [(cartItem: CartItem, item: Item?)] {
        // Call the function with the store name
        let allItems = storeItemsWithRefresh(store)
        
        let filteredItems = allItems.filter { cartItem, _ in
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
        
        // Sort items by addedAt (newest first)
        return filteredItems.sorted {
            $0.cartItem.addedAt > $1.cartItem.addedAt
        }
    }
    
    // FIX: Sort stores by the newest item in each store
    private var sortedStoresByNewestItem: [String] {
        var storeTimestamps: [String: Date] = [:]
        
        for store in sortedStoresWithRefresh {
            let displayItems = getDisplayItems(for: store)
            // Find the newest item in this store
            let newestDate = displayItems
                .map { $0.cartItem.addedAt }
                .max() ?? Date.distantPast
            
            storeTimestamps[store] = newestDate
        }
        
        // Sort stores by newest item (descending)
        return storeTimestamps.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let calculatedHeight = estimatedHeight
            let maxAllowedHeight = geometry.size.height * 0.8
            
            VStack(spacing: 0) {
                // FIXED: Only show "Shopping Trip Complete" when in shopping mode AND all items are done
                if cart.isShopping && allItemsCompleted {
                    // Celebration message for completed shopping
                    VStack(spacing: 16) {
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "FF6B6B"))
                        
                        Text("Shopping Trip Complete! 🎉")
                            .lexendFont(18, weight: .bold)
                            .foregroundColor(Color(hex: "333"))
                            .multilineTextAlignment(.center)
                        
                        Text("Congratulations! You've checked off all items.")
                            .lexendFont(14)
                            .foregroundColor(Color(hex: "666"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("Ready to finish your trip?")
                            .lexendFont(12)
                            .foregroundColor(Color(hex: "999"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                    .frame(height: min(200, maxAllowedHeight))
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [
                                backgroundColor,
                                rowBackgroundColor
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "FF6B6B").opacity(0.3), lineWidth: 2)
                    )
                    .transition(.opacity.combined(with: .scale))
                } else if !hasDisplayItems && cart.isPlanning {
                    EmptyCartView()
                        .transition(.scale)
                        .offset(y: UIScreen.main.bounds.height * 0.4)
                } else {
                    List {
                        // Use sortedStoresByNewestItem instead of sortedStoresWithRefresh
                        ForEach(Array(sortedStoresByNewestItem.enumerated()), id: \.offset) { (index, store) in
                            let displayItems = getDisplayItems(for: store)
                            
                            if !displayItems.isEmpty {
                                StoreSectionListView(
                                    store: store,
                                    items: displayItems,
                                    cart: cart,
                                    onFulfillItem: { cartItem in
                                        onFulfillItem(cartItem)
                                    },
                                    onEditItem: onEditItem,
                                    onDeleteItem: onDeleteItem,
                                    isLastStore: index == sortedStoresByNewestItem.count - 1,
                                    backgroundColor: backgroundColor,
                                                           rowBackgroundColor: rowBackgroundColor
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(rowBackgroundColor)
                            }
                        }
                    }                    .frame(height: min(calculatedHeight, maxAllowedHeight))
                    .listStyle(PlainListStyle())
                    .listSectionSpacing(0)
                    .background(backgroundColor)
                    .cornerRadius(16)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: calculatedHeight)
                    
                    if cart.isShopping {
                        ShoppingProgressSummary(cart: cart)
                            .presentationCornerRadius(24)
                            .environment(vaultService)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
        }
        .onChange(of: cart.cartItems) { oldItems, newItems in
            // Update the fulfilled count when cart items change
            let newFulfilledCount = newItems.filter { $0.isFulfilled }.count
            if fulfilledCount != newFulfilledCount {
                fulfilledCount = newFulfilledCount
            }
        }
        .onChange(of: cart.status) { oldStatus, newStatus in
            print("🔄 Cart status changed in ItemsListView: \(oldStatus) → \(newStatus)")
            print("   Display items will now: \(newStatus == .planning ? "Show ALL items" : "Show only unfulfilled, non-skipped")")
        }
    }
}

