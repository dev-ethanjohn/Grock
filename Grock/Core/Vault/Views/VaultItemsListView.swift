import SwiftUI

struct VaultItemsListView: View {
    let items: [Item]
    let availableStores: [String]
    @Binding var selectedStore: String?
    let categoryColor: Color
    var onDeleteItem: ((Item) -> Void)?
    
    private var showEndIndicator: Bool {
        items.count >= 6
    }
    
    var body: some View {
        List {
            ForEach(availableStores, id: \.self) { store in
                let storeItems = itemsForStore(store)
                StoreSection(
                    storeName: store,
                    items: storeItems,
                    categoryColor: categoryColor,
                    onDeleteItem: onDeleteItem,
                    isLastStore: store == availableStores.last
                )
            }
            
            if showEndIndicator {
                HStack {
                    Spacer()
                    Text("You've reached the end.")
                        .fuzzyBubblesFont(14, weight: .regular)
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.vertical, 32)
                    Spacer()
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            
            if !availableStores.isEmpty {
                Color.clear
                    .frame(height: 100)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(PlainListStyle())
        .listSectionSpacing(16)
        .listSectionSeparator(.hidden, edges: .all)
        .listRowSeparatorTint(.clear)
        .safeAreaInset(edge: .bottom) {
            if !availableStores.isEmpty {
                Color.clear.frame(height: 20)
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
    let categoryColor: Color
    var hasBackgroundImage: Bool = false
    var onDeleteItem: ((Item) -> Void)?
    let isLastStore: Bool
    
    private var itemsWithStableIdentifiers: [(id: String, item: Item)] {
        items.map { ($0.id, $0) }
    }
    
    private var headerForegroundColor: Color {
        hasBackgroundImage ? .black : .white
    }
    
    private var headerBackgroundColor: Color {
        hasBackgroundImage ? .white : categoryColor.saturated(by: 0.3).darker(by: 0.5)
    }
    
    var body: some View {
        Section(
            header: HStack {
            HStack(spacing: 2) {
                Image(systemName: "storefront")
                    .lexendFont(10)
                    .foregroundStyle(headerForegroundColor)
                
                Text(storeName)
                    .lexendFont(11, weight: .bold)
                    .foregroundStyle(headerForegroundColor)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(headerBackgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Spacer()
        }
        .padding(.leading)
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets())
        ) {
            ForEach(itemsWithStableIdentifiers, id: \.id) { tuple in
                VStack(spacing: 0) {
                    VaultItemRow(
                        item: tuple.item,
                        categoryColor: categoryColor
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            onDeleteItem?(tuple.item)
                        } label: {
                            Label("Remove from Vault", systemImage: "trash")
                        }
                    }
                    
                    if tuple.id != itemsWithStableIdentifiers.last?.id {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "ddd"))
                            .padding(.horizontal, 16)
                            .padding(.leading, 14)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button {
                        onDeleteItem?(tuple.item)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                    .tint(.red)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden, edges: .all)
                .listRowSeparatorTint(.clear, edges: .all)
                .listRowBackground(Color.clear)
                .transition(.asymmetric(
                    insertion: .move(edge: .top)
                        .combined(with: .opacity)
                        .combined(with: .scale(scale: 0.95, anchor: .top)),
                    removal: .move(edge: .leading)
                        .combined(with: .opacity)
                ))
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: itemsWithStableIdentifiers.map { $0.id })
            }
        }
        .listSectionSeparator(.hidden, edges: .all)
    }
}
