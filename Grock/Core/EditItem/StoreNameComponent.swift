import SwiftUI

struct StoreNameComponent: View {
    @Binding var storeName: String
    @Environment(VaultService.self) private var vaultService
    @FocusState private var isFocused: Bool
    @State private var showAddStoreSheet = false
    @State private var newStoreName = ""
    @State private var showDropdown = false
    let hasError: Bool
    
    var onStoreChange: (() -> Void)? //to notify parent when store changes
    
    private var availableStores: [String] {
        vaultService.getAllStores()
    }
    
    var body: some View {
        HStack {
            Text("Store")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Spacer()
           
            if availableStores.isEmpty || !showDropdown {
                // Text field (stores = 0)
                TextField("Enter store name", text: $storeName)
                    .normalizedText($storeName)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.black)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
            } else {
                // Dropdown (stores >0)
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
                            //Notify parent that store changed
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
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showDropdown = true
                    }
                }
            )
        }
        .onAppear {
            if storeName.isEmpty, let firstStore = availableStores.first {
                storeName = firstStore
            }
            if !availableStores.isEmpty {
                showDropdown = true
            } else {
                showDropdown = false
            }
        }
        .onChange(of: availableStores) { oldValue, newValue in
            if oldValue.isEmpty && !newValue.isEmpty {
                showDropdown = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showDropdown = true
                }
            } else if !newValue.isEmpty {
                showDropdown = true
            } else {
                showDropdown = false
            }
        }
        .onChange(of: storeName) { oldValue, newValue in
            onStoreChange?()
        }
    }
}
