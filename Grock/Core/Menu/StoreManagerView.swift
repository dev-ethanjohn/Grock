import SwiftUI
import SwiftData

struct StoreManagerView: View {
    
    @Environment(VaultService.self) private var vaultService
    
    @State private var stores: [String] = []
    @State private var showingAddStore = false
    @State private var newStoreName = ""
    @State private var storeToRename: String?
    
    var body: some View {
        ZStack {
            List {
                if stores.isEmpty {
                    ContentUnavailableView("No Stores", systemImage: "storefront", description: Text("Add a store to get started."))
                } else {
                    ForEach(stores, id: \.self) { store in
                        HStack {
                            HStack(spacing: 4) {
                                Text(store)
                                    .lexend(.body)
                                Text("✏️")
                                    .font(.footnote)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                prepareRename(store)
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                deleteStore(store)
                            } label: {
                                Text("🗑️")
                                    .font(.footnote)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 8)
                        }
                        .contentShape(Rectangle())
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
                    newStoreName = ""
                    showingAddStore = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddStore) {
            AddStoreSheet(storeName: $newStoreName, isPresented: $showingAddStore) { name in
                vaultService.addStore(name)
                loadStores()
                showingAddStore = false
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
}
