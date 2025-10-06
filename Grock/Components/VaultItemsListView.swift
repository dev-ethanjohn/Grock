//
//  VaultItemsListView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/3/25.
//

import SwiftUI

struct VaultItemsListView: View {
    let items: [Item]
    let availableStores: [String]
    @Binding var selectedStore: String?
    let category: GroceryCategory?
    var onDeleteItem: ((Item) -> Void)?
    
    @State private var swipedItemId: String? = nil // Changed to String
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Show all stores with their items
                ForEach(availableStores, id: \.self) { store in
                    StoreSection(
                        storeName: store,
                        items: itemsForStore(store),
                        category: category,
                        swipedItemId: $swipedItemId,
                        onDeleteItem: onDeleteItem
                    )
                }
            }
            .padding(.vertical)
        }
        .onTapGesture {
            // Close any swiped item when tapping on empty space
            swipedItemId = nil
        }
    }
    
    private func itemsForStore(_ store: String) -> [Item] {
        items.filter { item in
            item.priceOptions.contains { $0.store == store }
        }
    }
}

struct StoreSection: View {
    let storeName: String
    let items: [Item]
    let category: GroceryCategory?
    @Binding var swipedItemId: String? // Changed to String
    var onDeleteItem: ((Item) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(storeName)
                    .font(.fuzzyBold_11)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(category?.pastelColor.saturated(by: 0.3).darker(by: 0.5) ?? Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 4)
            
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    ForEach(items) { item in
                        VaultItemRow(
                            item: item,
                            category: category,
                            isSwiped: Binding(
                                get: { swipedItemId == item.id },
                                set: { isSwiped in
                                    if isSwiped {
                                        swipedItemId = item.id
                                    } else if swipedItemId == item.id {
                                        swipedItemId = nil
                                    }
                                }
                            ),
                            onDelete: {
                                onDeleteItem?(item)
                            }
                        )
                        
                        if item.id != items.last?.id {
                            DashedLine()
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                                .frame(height: 1)
                                .foregroundColor(Color(hex: "ddd"))
                                .padding(.horizontal)
                                .padding(.leading)
                        }
                    }
                }
            }
        }
    }
}
