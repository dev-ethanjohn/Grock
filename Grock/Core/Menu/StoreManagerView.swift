import SwiftUI
import SwiftData

struct StoreManagerView: View {
    private struct PendingStoreDeletion: Identifiable {
        let id = UUID()
        let name: String
    }
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var stores: [String] = []
    @State private var showingAddStore = false
    @State private var newStoreName = ""
    @State private var storeToRename: String?
    @State private var pendingStoreDeletion: PendingStoreDeletion?
    @State private var showPaywall = false
    @State private var paywallFeatureFocus: GrockPaywallFeatureFocus?
    @State private var listRefreshID = UUID()
    @AppStorage("lastSelectedStore") private var lastSelectedStore: String = ""
    
    var body: some View {
        ZStack {
            List {
                if stores.isEmpty {
                    ContentUnavailableView("No Stores", systemImage: "storefront", description: Text("Add a store to get started."))
                } else {
                    ForEach(stores, id: \.self) { store in
                        let isLockedStore = vaultService.isStoreLockedByPlan(named: store)
                        HStack {
                            HStack(spacing: 4) {
                                Text(store)
                                    .lexend(.body)
                                    .foregroundStyle(isLockedStore ? .gray : .black)

                                if isActiveStore(store) && !isLockedStore {
                                    Text("✏️")
                                        .font(.system(size: 11))
                                }
                            }
                            
                            Spacer()

                            if isLockedStore {
                                Text("💎")
                                    .font(.footnote)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard !isLockedStore else {
                                presentPaywall(for: .stores)
                                return
                            }
                            prepareRename(store)
                        }
                        .opacity(isLockedStore ? 0.58 : 1)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                guard !isLockedStore else {
                                    presentPaywall(for: .stores)
                                    return
                                }
                                prepareRename(store)
                            } label: {
                                Label("Rename", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                pendingStoreDeletion = PendingStoreDeletion(name: store)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .id(listRefreshID)
            
            if let storeToRename {
                RenamePopover(
                    isPresented: Binding(
                        get: { self.storeToRename != nil },
                        set: { if !$0 { self.storeToRename = nil } }
                    ),
                    title: "Rename Store Name",
                    placeholder: "Enter store name...",
                    saveButtonTitle: "Update Store",
                    useLexendInputFont: true,
                    adjustForKeyboard: false,
                    currentName: storeToRename,
                    onSave: { newName in
                        vaultService.renameStore(oldName: storeToRename, newName: newName)
                        if normalizedStoreKey(lastSelectedStore) == normalizedStoreKey(storeToRename) {
                            lastSelectedStore = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        loadStores()
                        self.storeToRename = nil
                    },
                    onDismiss: {
                        self.storeToRename = nil
                    }
                )
                .environment(vaultService)
                .zIndex(2000)
            }
        }
        .navigationTitle("Manage Stores")
        .navigationBarBackButtonHidden(storeToRename != nil)
        .toolbar {
            if storeToRename == nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        guard !vaultService.isStoreLimitReached() else {
                            presentPaywall(for: .stores)
                            return
                        }
                        newStoreName = ""
                        showingAddStore = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddStore) {
            AddStoreSheet(storeName: $newStoreName, isPresented: $showingAddStore) { name in
                guard vaultService.canUseStoreName(name) else {
                    showingAddStore = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        presentPaywall(for: .stores)
                    }
                    return
                }
                vaultService.addStore(name)
                loadStores()
                showingAddStore = false
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            GrockPaywallView(initialFeatureFocus: paywallFeatureFocus) {
                paywallFeatureFocus = nil
                showPaywall = false
            }
        }
        .alert(item: $pendingStoreDeletion) { pending in
            Alert(
                title: Text(deleteAlertTitle(for: pending.name)),
                message: Text(deleteAlertMessage(for: pending.name)),
                primaryButton: .destructive(Text("Delete Store")) {
                    deleteStore(pending.name)
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            loadStores()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DataUpdated"))) { _ in
            loadStores()
        }
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionStatusChanged)) { _ in
            loadStores()
        }
    }
    
    private func prepareRename(_ store: String) {
        storeToRename = store
    }
    
    private func loadStores() {
        stores = vaultService.getAllStores()
        listRefreshID = UUID()
    }
    
    private func deleteStore(_ name: String) {
        withAnimation {
            vaultService.deleteStore(name)
            if normalizedStoreKey(lastSelectedStore) == normalizedStoreKey(name) {
                lastSelectedStore = ""
            }
            loadStores()
        }
    }

    private func isActiveStore(_ storeName: String) -> Bool {
        let storeKey = normalizedStoreKey(storeName)
        guard !storeKey.isEmpty else { return false }

        if UserDefaults.standard.isPro {
            return true
        }

        return storeKey == activeStoreKey
    }

    private var activeStoreKey: String {
        let storedKey = normalizedStoreKey(lastSelectedStore)
        if !storedKey.isEmpty,
           let storedStore = stores.first(where: { normalizedStoreKey($0) == storedKey }),
           !vaultService.isStoreLockedByPlan(named: storedStore) {
            return storedKey
        }

        if let recentStore = vaultService.getMostRecentStore() {
            let recentKey = normalizedStoreKey(recentStore)
            if !recentKey.isEmpty,
               let visibleRecentStore = stores.first(where: { normalizedStoreKey($0) == recentKey }),
               !vaultService.isStoreLockedByPlan(named: visibleRecentStore) {
                return recentKey
            }
        }

        if let firstUnlockedStore = stores.first(where: { !vaultService.isStoreLockedByPlan(named: $0) }) {
            return normalizedStoreKey(firstUnlockedStore)
        }

        return ""
    }

    private func deleteAlertTitle(for storeName: String) -> String {
        isDeletingLastStore(named: storeName) ? "Delete Last Store?" : "Delete Store?"
    }

    private func deleteAlertMessage(for storeName: String) -> String {
        if isDeletingLastStore(named: storeName) {
            return """
Deleting "\(storeName)" will remove every item tied to this store from Vault and Manage Cart, and remove this store from all pickers.

This is your last store, so this may leave your vault with no stores and no items.
"""
        }

        return """
Deleting "\(storeName)" will remove every item tied to this store from Vault and Manage Cart, and remove this store from all pickers.
"""
    }

    private func isDeletingLastStore(named storeName: String) -> Bool {
        let targetKey = normalizedStoreKey(storeName)
        guard !targetKey.isEmpty else { return false }

        let remainingKeys = Set(stores.map(normalizedStoreKey)).subtracting([targetKey])
        return remainingKeys.isEmpty
    }

    private func normalizedStoreKey(_ storeName: String) -> String {
        storeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func presentPaywall(for featureFocus: GrockPaywallFeatureFocus) {
        paywallFeatureFocus = featureFocus
        showPaywall = true
    }
}
