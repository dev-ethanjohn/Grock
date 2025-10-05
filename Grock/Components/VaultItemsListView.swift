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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Show all stores with their items
                ForEach(availableStores, id: \.self) { store in
                    StoreSection(storeName: store, items: itemsForStore(store))
                }
            }
            .padding()
        }
    }
    
    // Get items for a specific store
    private func itemsForStore(_ store: String) -> [Item] {
        items.filter { item in
            item.priceOptions.contains { $0.store == store }
        }
    }
}

// Store Section Component
struct StoreSection: View {
    let storeName: String
    let items: [Item]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(storeName)
                    .font(.fuzzyBold_11)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Spacer()
            }
            
            LazyVStack(spacing: 0) {
                ForEach(items) { item in
                    MarketPriceListView(item: item)
                    
                    if item.id != items.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }
}

#Preview {
    // Create sample items for SaveMore (5 items)
    let saveMoreItems = [
        createPreviewItem(name: "Monterey Beef Tapa 250g", store: "SaveMore", price: 112.20, unit: "pc"),
        createPreviewItem(name: "ground beef", store: "SaveMore", price: 358.0, unit: "kg"),
        createPreviewItem(name: "Purefoods corned beef 120g", store: "SaveMore", price: 87.25, unit: "can"),
        createPreviewItem(name: "whole chicken", store: "SaveMore", price: 198.0, unit: "kg"),
        createPreviewItem(name: "chicken breast", store: "SaveMore", price: 234.0, unit: "kg")
    ]
    
    // Create sample items for Public Market (1 item)
    let publicMarketItems = [
        createPreviewItem(name: "chicken breast", store: "Public Market", price: 210.0, unit: "kg")
    ]
    
    // Combine all items
    let allItems = saveMoreItems + publicMarketItems
    let allStores = ["SaveMore", "Public Market"]
    
    return VaultItemsListView(
        items: allItems,
        availableStores: allStores,
        selectedStore: .constant(nil)
    )
}

// Helper function for previews
private func createPreviewItem(name: String, store: String, price: Double, unit: String) -> Item {
    let item = Item(name: name)
    let pricePerUnit = PricePerUnit(priceValue: price, unit: unit)
    let priceOption = PriceOption(store: store, pricePerUnit: pricePerUnit)
    item.priceOptions = [priceOption]
    return item
}
