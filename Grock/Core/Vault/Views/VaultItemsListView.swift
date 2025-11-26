import SwiftUI

struct VaultItemsListView: View {
    
    let items: [Item]
    let availableStores: [String]
    @Binding var selectedStore: String?
    let category: GroceryCategory?
    var onDeleteItem: ((Item) -> Void)?
    
    var body: some View {
        List {
            ForEach(availableStores.indices, id: \.self) { index in
                let store = availableStores[index]
                
                VStack(spacing: 0) {
                    StoreSection(
                        storeName: store,
                        items: itemsForStore(store),
                        category: category,
                        onDeleteItem: onDeleteItem,
                        isLastStore: store == availableStores.last
                    )
                }
                .padding(.top, index == 0 ? 20 : 0)
                .padding(.bottom, store == availableStores.last ? 0 : 20)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
        .listSectionSpacing(16)
        .safeAreaInset(edge: .bottom) {
            if !availableStores.isEmpty {
                Color.clear.frame(height: 80)
            }
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
    var onDeleteItem: ((Item) -> Void)?
    let isLastStore: Bool
    
    private var itemsWithStableIdentifiers: [(id: String, item: Item)] {
        items.map { ($0.id, $0) }
    }
    
    var body: some View {
        Section(
            header: HStack {
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
            ForEach(itemsWithStableIdentifiers, id: \.id) { tuple in
                VStack(spacing: 0) {
                    VaultItemRow(
                        item: tuple.item,
                        category: category,
                        onDelete: {
                            onDeleteItem?(tuple.item)
                        }
                    )
                    
                    if tuple.id != itemsWithStableIdentifiers.last?.id {
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
