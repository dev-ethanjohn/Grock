import SwiftUI

struct VaultItemsListView: View {
    let items: [Item]
    let availableStores: [String]
    let categoryName: String
    @Binding var selectedStore: String?
    let categoryColor: Color
    var onDeleteItem: ((Item) -> Void)?
    var isEditingLocked: Bool = false
    var onLockedEditAttempt: (() -> Void)? = nil

    @Environment(VaultService.self) private var vaultService
    
    private var showEndIndicator: Bool {
        items.count >= 6
    }

    private var lockedRowsOpacity: Double {
        isEditingLocked ? 0.82 : 1
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
                    isEditingLocked: isEditingLocked,
                    onLockedEditAttempt: onLockedEditAttempt,
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

            if isEditingLocked {
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 0) {
                        Text("Bring back “\(categoryName)” \(vaultService.displayEmoji(forCategoryName: categoryName)) for complete planning, shopping, and budget tracking.")
                            .fuzzyBubblesFont(14, weight: .bold)
                            .foregroundStyle(Color.black.opacity(0.9))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    if let onLockedEditAttempt {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .foregroundColor(Color.black.opacity(0.2))
                            .frame(height: 1)
                            .padding(.horizontal, 16)

                        Button(action: onLockedEditAttempt) {
                            Text("Unlock with Pro")
                                .fuzzyBubblesFont(20, weight: .bold)
                                .foregroundColor(.black.opacity(0.9))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                        }
                        .buttonStyle(.plain)
                        .background(categoryColor.brightness(0.10))
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(categoryColor.opacity(0.32))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.7), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 12)
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
    var isEditingLocked: Bool = false
    var onLockedEditAttempt: (() -> Void)? = nil
    let isLastStore: Bool
    
    private var itemsWithStableIdentifiers: [(id: String, item: Item)] {
        items.map { (ActiveItemSelectionKey.make(itemId: $0.id, store: storeName), $0) }
    }
    
    private var headerForegroundColor: Color {
        hasBackgroundImage ? .black : .white
    }
    
    private var headerBackgroundColor: Color {
        hasBackgroundImage ? .white : categoryColor.saturated(by: 0.3).darker(by: 0.5)
    }

    private var lockedRowsOpacity: Double {
        isEditingLocked ? 0.82 : 1
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
            .saturation(isEditingLocked ? 0 : 1)
            .opacity(lockedRowsOpacity)
        ) {
            ForEach(itemsWithStableIdentifiers, id: \.id) { tuple in
                VStack(spacing: 0) {
                    VaultItemRow(
                        item: tuple.item,
                        storeName: storeName,
                        categoryColor: categoryColor,
                        isEditingLocked: isEditingLocked,
                        onLockedEditAttempt: onLockedEditAttempt
                    )
                    .contextMenu {
                        if isEditingLocked {
                            Button {
                                onLockedEditAttempt?()
                            } label: {
                                Label("Unlock Pro to Edit", systemImage: "lock.fill")
                            }
                        } else {
                            Button(role: .destructive) {
                                onDeleteItem?(tuple.item)
                            } label: {
                                Label("Remove from Vault", systemImage: "trash")
                            }
                        }
                    }
                    
                    if tuple.id != itemsWithStableIdentifiers.last?.id {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 1)
                            .foregroundColor(Color.Grock.neutral300)
                            .padding(.horizontal, 16)
                            .padding(.leading, 14)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if isEditingLocked {
                        Button {
                            onLockedEditAttempt?()
                        } label: {
                            Label("Pro", systemImage: "lock.fill")
                        }
                        .tint(.orange)
                    } else {
                        Button {
                            onDeleteItem?(tuple.item)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                        .tint(.red)
                    }
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
                .saturation(isEditingLocked ? 0 : 1)
                .opacity(lockedRowsOpacity)
            }
        }
        .listSectionSeparator(.hidden, edges: .all)
    }
}
