import SwiftUI
import SwiftData
import Lottie

struct TrashView: View {
    private enum RestoreBlockReason {
        case categoryLocked
        case storeLocked
        case categoryAndStore

        func alertMessage(for itemName: String) -> String {
            switch self {
            case .categoryLocked:
                return "'\(itemName)' uses a custom category, which is locked on Free."
            case .storeLocked:
                return "'\(itemName)' uses a store that isn't your active Main Store on Free."
            case .categoryAndStore:
                return "'\(itemName)' uses a custom category and a locked store on Free."
            }
        }
    }

    @Environment(VaultService.self) private var vaultService
    
    @State private var pendingRestoreItemId: String?
    @State private var pendingRestoreItemName: String = ""
    @State private var showingRestoreAlert = false
    
    @State private var pendingPermanentDeleteItemId: String?
    @State private var pendingPermanentDeleteItemName: String = ""
    @State private var showingPermanentDeleteAlert = false

    @State private var blockedRestoreItemName: String = ""
    @State private var blockedRestoreReason: RestoreBlockReason?
    @State private var showingBlockedRestoreAlert = false
    
    @State private var pendingRestoreCartId: String?
    @State private var pendingRestoreCartName: String = ""
    @State private var showingRestoreCartAlert = false
    
    @State private var pendingPermanentDeleteCartId: String?
    @State private var pendingPermanentDeleteCartName: String = ""
    @State private var showingPermanentDeleteCartAlert = false
    @State private var showingFreeStoreSelection = false
    @State private var showPaywall = false
    
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
                ContentUnavailableView {
                    Label {
                        Text("Trash is empty")
                            .fuzzyBubblesFont(28, weight: .bold)
                    } icon: {
                        LottieView(animation: .named("Trash"))
                            .playing(.fromProgress(0, toProgress: 1, loopMode: .loop))
                            .allowsHitTesting(false)
                            .frame(width: 96, height: 96)
                    }
                } description: {
                    Text("Deleted items will appear here.")
                }
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
                            let restoreBlockReason = restoreBlockReason(for: item)
                            let canRestore = restoreBlockReason == nil

                            HStack(spacing: 12) {
                                Text(item.name)
                                    .lexend(.body)
                                    .foregroundStyle(canRestore ? .black : .gray)

                                Spacer()

                                Button {
                                    attemptRestore(item, blockReason: restoreBlockReason)
                                } label: {
                                    if canRestore {
                                        Image(systemName: "arrow.uturn.backward.circle.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundStyle(.green)
                                    } else {
                                        Text("💎")
                                            .font(.system(size: 18))
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(canRestore ? "Restore item" : "Restore unavailable")
                            }
                            .opacity(canRestore ? 1 : 0.68)
                            .contentShape(Rectangle())
                            .contextMenu {
                                if canRestore {
                                    Button {
                                        confirmRestore(item)
                                    } label: {
                                        Label("Restore", systemImage: "arrow.uturn.backward")
                                    }
                                } else {
                                    Button {
                                        attemptRestore(item, blockReason: restoreBlockReason)
                                    } label: {
                                        Text("💎 Restore Unavailable")
                                    }
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
                                    attemptRestore(item, blockReason: restoreBlockReason)
                                } label: {
                                    if canRestore {
                                        Label("Restore", systemImage: "arrow.uturn.backward")
                                    } else {
                                        Text("💎 Pro")
                                    }
                                }
                                .tint(canRestore ? .green : .gray)
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
        .alert("Restore Unavailable on Free", isPresented: $showingBlockedRestoreAlert) {
            Button("Choose Main Store") {
                showingFreeStoreSelection = true
            }
            Button("Unlock unlimited stores") {
                showPaywall = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let blockedRestoreReason {
                Text(blockedRestoreReason.alertMessage(for: blockedRestoreItemName))
            } else {
                Text("This item can't be restored on your current plan.")
            }
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
        .sheet(isPresented: $showingFreeStoreSelection) {
            FreeStoreSelectionSheet(isPresented: $showingFreeStoreSelection)
                .environment(vaultService)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            GrockPaywallView(initialFeatureFocus: .stores) {
                showPaywall = false
            }
        }
    }
    
    private func confirmRestore(_ item: Item) {
        pendingRestoreItemId = item.id
        pendingRestoreItemName = item.name
        showingRestoreAlert = true
    }

    private func attemptRestore(_ item: Item, blockReason: RestoreBlockReason?) {
        if let blockReason {
            blockedRestoreItemName = item.name
            blockedRestoreReason = blockReason
            showingBlockedRestoreAlert = true
            return
        }
        confirmRestore(item)
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

    private func restoreBlockReason(for item: Item) -> RestoreBlockReason? {
        guard !UserDefaults.standard.isPro else { return nil }

        let deletedCategory = item.deletedFromCategoryName?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isCategoryLocked = !deletedCategory.isEmpty && vaultService.isCategoryLockedByPlan(named: deletedCategory)

        let stores = item.priceOptions
            .map { $0.store.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let hasStores = !stores.isEmpty
        let isStoreLocked = hasStores && stores.allSatisfy { vaultService.isStoreLockedByPlan(named: $0) }

        if isCategoryLocked && isStoreLocked {
            return .categoryAndStore
        }
        if isCategoryLocked {
            return .categoryLocked
        }
        if isStoreLocked {
            return .storeLocked
        }
        return nil
    }
}
