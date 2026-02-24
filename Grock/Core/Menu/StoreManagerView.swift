import SwiftUI
import SwiftData

struct StoreManagerView: View {
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var stores: [String] = []
    @State private var showingAddStore = false
    @State private var newStoreName = ""
    @State private var storeToRename: String?
    @State private var showPaywall = false
    @State private var paywallFeatureFocus: GrockPaywallFeatureFocus?
    
    var body: some View {
        ZStack {
            List {
                if stores.isEmpty {
                    ContentUnavailableView("No Stores", systemImage: "storefront", description: Text("Add a store to get started."))
                } else {
                    ForEach(stores, id: \.self) { store in
                        let isLockedStore = vaultService.isStoreLockedByPlan(named: store)
                        HStack {
                            Text(store)
                                .lexend(.body)
                                .foregroundStyle(isLockedStore ? .gray : .black)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isLockedStore else {
                                    presentPaywall(for: .stores)
                                    return
                                }
                                prepareRename(store)
                            }
                            
                            Spacer()
                            
                            Button {
                                if isLockedStore {
                                    presentPaywall(for: .stores)
                                } else {
                                    deleteStore(store)
                                }
                            } label: {
                                Text(isLockedStore ? "💎" : "🗑️")
                                    .font(.footnote)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 8)
                        }
                        .contentShape(Rectangle())
                        .opacity(isLockedStore ? 0.58 : 1)
                    }
                }
            }
            
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
                    currentName: storeToRename,
                    onSave: { newName in
                        vaultService.renameStore(oldName: storeToRename, newName: newName)
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
        .toolbar {
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
        .onAppear {
            loadStores()
        }
    }
    
    private func prepareRename(_ store: String) {
        storeToRename = store
    }
    
    private func loadStores() {
        stores = vaultService.getAllStores()
    }
    
    private func deleteStore(_ name: String) {
        withAnimation {
            vaultService.deleteStore(name)
            loadStores()
        }
    }

    private func presentPaywall(for featureFocus: GrockPaywallFeatureFocus) {
        paywallFeatureFocus = featureFocus
        showPaywall = true
    }
}
