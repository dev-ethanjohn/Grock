//
//  StoreNameComponent.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/17/25.
//

import SwiftUI

struct StoreNameComponent: View {
    //TODO: Rearrange + put in a veiw model.
    @Binding var storeName: String
    @Environment(VaultService.self) private var vaultService
    @FocusState private var isFocused: Bool
    @State private var showAddStoreSheet = false
    @State private var newStoreName = ""
    
    private var availableStores: [String] {
        vaultService.getAllStores()
    }
    
    var body: some View {
        HStack {
            Text("Store")
                .font(.footnote)
                .foregroundColor(.gray)
            
            Spacer()
            //TODO: own var view /viewbuilder
            
           
            if availableStores.isEmpty {
                // Text field (stores = 0)
                TextField("Enter store name", text: $storeName)
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
        .sheet(isPresented: $showAddStoreSheet) {
            AddStoreSheet(
                storeName: $newStoreName,
                isPresented: $showAddStoreSheet,
                onSave: { newStore in
                    vaultService.addStore(newStore)
                    storeName = newStore
                    showAddStoreSheet = false
                    print("➕ New store added and persisted: \(newStore)")
                }
            )
        }
        .onAppear {
            if storeName.isEmpty, let firstStore = availableStores.first {
                storeName = firstStore
            }
        }
    }
}


