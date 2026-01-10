import SwiftUI
import SwiftData

struct StoreManagerView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    
    @State private var stores: [String] = []
    @State private var showingAddStore = false
    @State private var newStoreName = ""
    
    @State private var storeToRename: String?
    @State private var renameText = ""
    @State private var showingRenameAlert = false
    
    var body: some View {
        List {
            if stores.isEmpty {
                ContentUnavailableView("No Stores", systemImage: "storefront", description: Text("Add a store to get started."))
            } else {
                ForEach(stores, id: \.self) { store in
                    HStack {
                        Image(systemName: "storefront")
                            .foregroundColor(.gray)
                        Text(store)
                            .font(.body)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button {
                            prepareRename(store)
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            deleteStore(store)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteStore(store)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            prepareRename(store)
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
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
        .alert("Rename Store", isPresented: $showingRenameAlert) {
            TextField("Store Name", text: $renameText)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let oldName = storeToRename {
                    vaultService.renameStore(oldName: oldName, newName: renameText)
                    loadStores()
                }
            }
        } message: {
            Text("Enter a new name for this store.")
        }
        .onAppear {
            loadStores()
        }
    }
    
    private func prepareRename(_ store: String) {
        storeToRename = store
        renameText = store
        showingRenameAlert = true
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
