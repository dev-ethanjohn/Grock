import SwiftUI
import SwiftData

struct TrashView: View {
    @Environment(VaultService.self) private var vaultService
    
    @State private var pendingRestoreItemId: String?
    @State private var pendingRestoreItemName: String = ""
    @State private var showingRestoreAlert = false
    
    @State private var pendingPermanentDeleteItemId: String?
    @State private var pendingPermanentDeleteItemName: String = ""
    @State private var showingPermanentDeleteAlert = false
    
    @State private var pendingRestoreCartId: String?
    @State private var pendingRestoreCartName: String = ""
    @State private var showingRestoreCartAlert = false
    
    @State private var pendingPermanentDeleteCartId: String?
    @State private var pendingPermanentDeleteCartName: String = ""
    @State private var showingPermanentDeleteCartAlert = false
    
    private var deletedItems: [Item] {
        guard let vault = vaultService.vault else { return [] }
        return vault.deletedItems.sorted {
            ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast)
        }
    }
    
    private var deletedCarts: [Cart] {
        guard let vault = vaultService.vault else { return [] }
        return vault.deletedCarts.sorted {
            ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast)
        }
    }
    
    private var deletedItemsGrouped: [(categoryName: String, items: [Item])] {
        let grouped = Dictionary(grouping: deletedItems) { item in
            item.deletedFromCategoryName ?? "Unknown"
        }
        return grouped
            .map { (key: $0.key, value: $0.value) }
            .sorted { $0.key.localizedCaseInsensitiveCompare($1.key) == .orderedAscending }
            .map { ($0.key, $0.value) }
    }
    
    var body: some View {
        List {
            if deletedItems.isEmpty && deletedCarts.isEmpty {
                ContentUnavailableView(
                    "Trash is empty",
                    systemImage: "trash",
                    description: Text("Deleted items will appear here.")
                )
            } else {
                if !deletedCarts.isEmpty {
                    Section("Trips") {
                        ForEach(deletedCarts, id: \.id) { cart in
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.gray)
                                Text(cart.name)
                                    .lexend(.body)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button {
                                    confirmRestore(cart)
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.backward")
                                }
                                
                                Button(role: .destructive) {
                                    confirmPermanentDelete(cart)
                                } label: {
                                    Label("Delete Permanently", systemImage: "trash.slash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    confirmPermanentDelete(cart)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    confirmRestore(cart)
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
                
                ForEach(deletedItemsGrouped, id: \.categoryName) { group in
                    Section(group.categoryName) {
                        ForEach(group.items, id: \.id) { item in
                            HStack(spacing: 12) {
                                Image(systemName: "trash")
                                    .foregroundColor(.gray)
                                Text(item.name)
                                    .lexend(.body)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .contextMenu {
                                Button {
                                    confirmRestore(item)
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.backward")
                                }
                                
                                Button(role: .destructive) {
                                    confirmPermanentDelete(item)
                                } label: {
                                    Label("Delete Permanently", systemImage: "trash.slash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    confirmPermanentDelete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                                Button {
                                    confirmRestore(item)
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Trash")
        .alert("Restore Item", isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore") {
                if let itemId = pendingRestoreItemId {
                    withAnimation {
                        vaultService.restoreDeletedItem(itemId: itemId)
                    }
                }
                pendingRestoreItemId = nil
            }
        } message: {
            Text("Restore '\(pendingRestoreItemName)' back to your vault?")
        }
        .alert("Delete Permanently", isPresented: $showingPermanentDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let itemId = pendingPermanentDeleteItemId {
                    withAnimation {
                        vaultService.permanentlyDeleteItemFromTrash(itemId: itemId)
                    }
                }
                pendingPermanentDeleteItemId = nil
            }
        } message: {
            Text("Permanently delete '\(pendingPermanentDeleteItemName)'? This cannot be undone.")
        }
        .alert("Restore Trip", isPresented: $showingRestoreCartAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Restore") {
                if let cartId = pendingRestoreCartId {
                    withAnimation {
                        vaultService.restoreDeletedCart(cartId: cartId)
                    }
                }
                pendingRestoreCartId = nil
            }
        } message: {
            Text("Restore '\(pendingRestoreCartName)' back to History?")
        }
        .alert("Delete Trip Permanently", isPresented: $showingPermanentDeleteCartAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let cartId = pendingPermanentDeleteCartId {
                    withAnimation {
                        vaultService.permanentlyDeleteCartFromTrash(cartId: cartId)
                    }
                }
                pendingPermanentDeleteCartId = nil
            }
        } message: {
            Text("Permanently delete '\(pendingPermanentDeleteCartName)'? This cannot be undone.")
        }
    }
    
    private func confirmRestore(_ item: Item) {
        pendingRestoreItemId = item.id
        pendingRestoreItemName = item.name
        showingRestoreAlert = true
    }
    
    private func confirmPermanentDelete(_ item: Item) {
        pendingPermanentDeleteItemId = item.id
        pendingPermanentDeleteItemName = item.name
        showingPermanentDeleteAlert = true
    }
    
    private func confirmRestore(_ cart: Cart) {
        pendingRestoreCartId = cart.id
        pendingRestoreCartName = cart.name
        showingRestoreCartAlert = true
    }
    
    private func confirmPermanentDelete(_ cart: Cart) {
        pendingPermanentDeleteCartId = cart.id
        pendingPermanentDeleteCartName = cart.name
        showingPermanentDeleteCartAlert = true
    }
}
