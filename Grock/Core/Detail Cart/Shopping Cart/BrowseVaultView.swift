import SwiftUI

extension Notification.Name {
    static let shoppingItemQuantityChanged = Notification.Name("ShoppingItemQuantityChanged")
    static let shoppingDataUpdated = Notification.Name("ShoppingDataUpdated")
}

struct BrowseVaultView: View {
    let cart: Cart
    @Binding var selectedCategoryName: String?
    let focusSearchToken: Int
    let onItemSelected: (Item) -> Void
    let onBack: () -> Void
    let onAddNewItem: () -> Void
    @Binding var hasUnsavedChanges: Bool
    
    @Environment(VaultService.self) private var vaultService
    @Environment(\.cartStateManager) private var stateManager
    @State private var searchText = ""
    
    @State private var debouncedSearchText = ""
    @State private var debounceTask: Task<Void, Never>?
    @State private var cachedStoreGroups: [StoreGroup] = []
    @FocusState private var searchFieldIsFocused: Bool
    
    // MARK: - StoreGroup Struct (Equatable)
    
    struct StoreGroup: Equatable {
        let store: String
        let items: [StoreItem]
        
        static func == (lhs: StoreGroup, rhs: StoreGroup) -> Bool {
            lhs.store == rhs.store &&
            lhs.items.count == rhs.items.count &&
            lhs.items.map { $0.item.id } == rhs.items.map { $0.item.id }
        }
    }
    
    // MARK: - Computed Properties
    
    private var availableStores: [String] {
        cachedStoreGroups.map { $0.store }
    }
    
    private var showEndIndicator: Bool {
        let totalItems = cachedStoreGroups.reduce(0) { $0 + $1.items.count }
        return totalItems >= 6
    }
    
    private var isEmptyState: Bool {
        cachedStoreGroups.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBarView(searchText: $searchText, focusBinding: $searchFieldIsFocused)
            
            // Items List organized by store
            if isEmptyState {
                EmptyStateView(
                    searchText: debouncedSearchText,
                    onAddNewItem: onAddNewItem
                )
                .frame(maxHeight: .infinity)
            } else {
                StoreItemsListView(
                    itemsByStore: cachedStoreGroups,
                    availableStores: availableStores,
                    showEndIndicator: showEndIndicator,
                    hasBackgroundImage: stateManager.hasBackgroundImage,
                    cart: cart,
                    onItemSelected: { item in
                        onItemSelected(item)
                        hasUnsavedChanges = true
                    },
                    onQuantityChange: {
                        hasUnsavedChanges = true
                    }
                )
                .padding(.top, 16)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: cachedStoreGroups)
        .onAppear {
            recomputeStoreGroups()
        }
        .onChange(of: focusSearchToken) { _, _ in
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000)
                searchFieldIsFocused = true
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    debouncedSearchText = newValue
                }
            }
        }
        .onChange(of: debouncedSearchText) { _, _ in
            recomputeStoreGroups()
        }
        .onChange(of: cart.cartItems) { oldItems, newItems in
            // Add a guard to prevent unnecessary updates
            let oldIds = oldItems.map { $0.id }
            let newIds = newItems.map { $0.id }
            let oldQuantities = oldItems.map { $0.quantity }
            let newQuantities = newItems.map { $0.quantity }
            
            if oldIds != newIds || oldQuantities != newQuantities {
                hasUnsavedChanges = true
                recomputeStoreGroups()
            }
        }
        .onDisappear {
            debounceTask?.cancel()
        }
    }
    
    private func recomputeStoreGroups() {
        let itemManager = ItemManager(
            vault: vaultService.vault,
            cart: cart,
            searchText: debouncedSearchText
        )
        cachedStoreGroups = itemManager.storeGroups
    }
}

// MARK: - Item Manager Struct

struct ItemManager {
    let vault: Vault?
    let cart: Cart
    let searchText: String
    
    // MARK: - Computed Properties
    
    var vaultStoreItems: [StoreItem] {
        guard let vault = vault else { return [] }
        
        var allStoreItems: [StoreItem] = []
        var seenItemStoreCombinations = Set<String>()
        
        for category in vault.categories {
            for item in category.items {
                // ALWAYS include vault items in the browse list
                // The UI (BrowseVaultItemRow) will handle showing them as active/inactive
                for priceOption in item.priceOptions {
                    let combinationKey = "\(item.id)-\(priceOption.store)"
                    if !seenItemStoreCombinations.contains(combinationKey) {
                        let storeItem = StoreItem(
                            item: item,
                            categoryName: category.name,
                            priceOption: priceOption,
                            isShoppingOnlyItem: false
                        )
                        allStoreItems.append(storeItem)
                        seenItemStoreCombinations.insert(combinationKey)
                    }
                }
            }
        }
        
        return allStoreItems
    }

    var shoppingOnlyStoreItems: [StoreItem] {
        var shoppingOnlyItems: [StoreItem] = []
        
        for cartItem in cart.cartItems where cartItem.isShoppingOnlyItem {
            if let name = cartItem.shoppingOnlyName,
               let price = cartItem.shoppingOnlyPrice,
               let store = cartItem.shoppingOnlyStore,
               let unit = cartItem.shoppingOnlyUnit,
               !cartItem.isSkippedDuringShopping,
               // CHANGE: Check if cartItem still exists AND has quantity > 0
               cartItem.quantity > 0 {
                
                // Check if this shopping-only item already exists as a vault item
                let alreadyExistsAsVaultItem = vaultStoreItems.contains { storeItem in
                    let nameMatches = storeItem.item.name.lowercased() == name.lowercased()
                    let storeMatches = storeItem.priceOption.store.lowercased() == store.lowercased()
                    let isNotShoppingOnly = !storeItem.isShoppingOnlyItem
                    return nameMatches && storeMatches && isNotShoppingOnly
                }
                
                // Only add shopping-only item if there's no matching vault item
                if !alreadyExistsAsVaultItem {
                    let tempItem = Item(
                        id: cartItem.itemId,
                        name: name,
                        priceOptions: [
                            PriceOption(
                                store: store,
                                pricePerUnit: PricePerUnit(priceValue: price, unit: unit)
                            )
                        ]
                    )
                    
                    let priceOption = PriceOption(
                        store: store,
                        pricePerUnit: PricePerUnit(priceValue: price, unit: unit)
                    )
                    
                    let storeItem = StoreItem(
                        item: tempItem,
                        categoryName: "Shopping Items",
                        priceOption: priceOption,
                        isShoppingOnlyItem: true
                    )
                    
                    shoppingOnlyItems.append(storeItem)
                }
            }
        }
        
        return shoppingOnlyItems
    }
    
    var allStoreItems: [StoreItem] {
        vaultStoreItems + shoppingOnlyStoreItems
    }
    
    var filteredStoreItems: [StoreItem] {
        if searchText.isEmpty {
            return allStoreItems
        } else {
            return allStoreItems.filter { storeItem in
                storeItem.item.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var groupedStoreItems: [String: [StoreItem]] {
        var storeDict: [String: [StoreItem]] = [:]
        
        for storeItem in filteredStoreItems {
            let store = storeItem.priceOption.store
            if storeDict[store] == nil {
                storeDict[store] = []
            }
            storeDict[store]?.append(storeItem)
        }
        
        return storeDict
    }
    
    var storeGroups: [BrowseVaultView.StoreGroup] {
        let storeDict = groupedStoreItems
        let sortedStores = storeDict.keys.sorted()
        var result: [BrowseVaultView.StoreGroup] = []
        
        for store in sortedStores {
            guard let items = storeDict[store], !items.isEmpty else { continue }
            
            // Sort items within each store alphabetically by name
            let sortedItems = items.sorted { item1, item2 in
                item1.item.name.localizedCaseInsensitiveCompare(item2.item.name) == .orderedAscending
            }
            
            result.append(BrowseVaultView.StoreGroup(store: store, items: sortedItems))
        }
        
        return result
    }
}

// MARK: - Supporting Views

private struct SearchBarView: View {
    @Binding var searchText: String
    let focusBinding: FocusState<Bool>.Binding
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search vault items...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused(focusBinding)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
        .padding(.horizontal)
        .padding(.top)
    }
}

private struct EmptyStateView: View {
    let searchText: String
    let onAddNewItem: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "archivebox" : "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text(searchText.isEmpty ? "Your vault is empty" : "No items found")
                .foregroundColor(.gray)
            
            if searchText.isEmpty {
                Button(action: onAddNewItem) {
                    Label("Add New Item", systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

private struct StoreItemsListView: View {
    let itemsByStore: [BrowseVaultView.StoreGroup]
    let availableStores: [String]
    let showEndIndicator: Bool
    let hasBackgroundImage: Bool
    let cart: Cart
    let onItemSelected: (Item) -> Void
    let onQuantityChange: (() -> Void)?  // This is already here
    
    var body: some View {
        List {
            ForEach(availableStores, id: \.self) { store in
                if let storeGroup = itemsByStore.first(where: { $0.store == store }) {
                    BrowseVaultStoreSection(
                        storeName: store,
                        items: storeGroup.items,
                        hasBackgroundImage: hasBackgroundImage,
                        cart: cart,
                        onItemSelected: onItemSelected,
                        onQuantityChange: onQuantityChange,  // PASS IT HERE
                        isLastStore: store == availableStores.last
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
            
            if showEndIndicator {
                EndIndicatorView()
            }
            
            if !availableStores.isEmpty {
                BottomSpacerView()
            }
        }
        .listStyle(PlainListStyle())
        .listSectionSpacing(16)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            if !availableStores.isEmpty {
                Color.clear.frame(height: 20)
            }
        }
    }
}

private struct EndIndicatorView: View {
    var body: some View {
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
}

private struct BottomSpacerView: View {
    var body: some View {
        Color.clear
            .frame(height: 100)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
}
