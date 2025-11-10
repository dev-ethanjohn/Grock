import SwiftUI

struct VaultItemsListView: View {
    let items: [Item]
    let availableStores: [String]
    @Binding var selectedStore: String?
    let category: GroceryCategory?
    var onDeleteItem: ((Item) -> Void)?
    
    var body: some View {
        List {
            ForEach(availableStores, id: \.self) { store in
                StoreSection(
                    storeName: store,
                    items: itemsForStore(store),
                    category: category,
                    onDeleteItem: onDeleteItem
                )
            }
        }
        .listStyle(PlainListStyle())
        .listSectionSpacing(16)
        
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
    var onDeleteItem: ((Item) -> Void)?
    
    var body: some View {
        Section(
            header:
                HStack {
                    Text(storeName)
                        .fuzzyBubblesFont(11, weight: .bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(category?.pastelColor.saturated(by: 0.3).darker(by: 0.5) ?? Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Spacer()
                }
                .padding(.leading)
                .listRowInsets(EdgeInsets())
            
        ) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                VStack(spacing: 0) {
                    VaultItemRow(
                        item: item,
                        category: category,
                        onDelete: {
                            onDeleteItem?(item)
                        }
                    )
                    
                    if index < items.count - 1 {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "ddd"))
                            .padding(.horizontal, 16)
                            .padding(.leading, 14)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
    }
}
