import SwiftUI

struct StoreNameComponent: View {
    @Binding var storeName: String
    @Environment(VaultService.self) private var vaultService
    @FocusState private var isFocused: Bool
    @State private var showAddStoreSheet = false
    @State private var newStoreName = ""
    let hasError: Bool
    
    //to notify parent when store changes
    var onStoreChange: (() -> Void)?
    
    private var availableStores: [String] {
        vaultService.getAllStores()
    }
    
    var body: some View {
        HStack {
            Text("Store")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Spacer()
           
            if availableStores.isEmpty {
                // Text field (stores = 0)
                TextField("Enter store name", text: $storeName)
                    .normalizedText($storeName)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.black)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
            } else {
                // Dropdown (stores > 0)
                Menu {
                    Button(action: {
                        newStoreName = ""
                        showAddStoreSheet = true
                    }) {
                        Label("Add New Store", systemImage: "plus.circle.fill")
                    }
                    
                    Divider()
                    
                    ForEach(availableStores, id: \.self) { store in
                        Button(action: {
                            storeName = store
                            // ADD THIS: Notify parent that store changed
                            onStoreChange?()
                        }) {
                            HStack {
                                Text(store)
                                if storeName == store {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(storeName.isEmpty ? "Select Store" : storeName)
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(storeName.isEmpty ? .gray : .black)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    Color(hex: "#FA003F"),
                    lineWidth: hasError ? 2.0 : 0
                )
        )
        .sheet(isPresented: $showAddStoreSheet) {
            AddStoreSheet(
                storeName: $newStoreName,
                isPresented: $showAddStoreSheet,
                onSave: { newStore in
                    vaultService.addStore(newStore)
                    storeName = newStore
                    showAddStoreSheet = false
                    print("➕ New store added and persisted: \(newStore)")
                    onStoreChange?()
                }
            )
        }
        .onAppear {
            if storeName.isEmpty, let firstStore = availableStores.first {
                storeName = firstStore
            }
        }
        .onChange(of: storeName) { oldValue, newValue in
            onStoreChange?()
        }
    }
}
