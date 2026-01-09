//
//  MenuView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/7/25.
//

import SwiftUI
import SwiftData

struct MenuView: View {
    @Environment(VaultService.self) private var vaultService
    
    // Store Renaming State
    @State private var storeToRename: String?
    @State private var newStoreName: String = ""
    @State private var showRenameAlert = false
    @State private var showManageStoresSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .bottom) {
                    HStack {
                        Image("grock_logo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                        
                        Text("Grock")
                            .font(.headline)
                            .bold()
                    }
                    
                    Spacer()
                }
                .frame(height: 100, alignment: .bottom)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Currency Selection Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Currency")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "999"))
                            
                            Menu {
                                // Default/Local Section
                                if let localCurrency = CurrencyManager.shared.localCurrency {
                                    Section(header: Text("Default Local")) {
                                        Button {
                                            withAnimation {
                                                CurrencyManager.shared.setCurrency(localCurrency)
                                            }
                                        } label: {
                                            HStack {
                                                Text("\(localCurrency.symbol) \(localCurrency.name) (\(localCurrency.code))")
                                                if CurrencyManager.shared.selectedCurrency.code == localCurrency.code {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                // All Currencies Section
                                Section(header: Text("All Currencies")) {
                                    ForEach(CurrencyManager.shared.availableCurrencies, id: \.code) { currency in
                                        Button {
                                            withAnimation {
                                                CurrencyManager.shared.setCurrency(currency)
                                            }
                                        } label: {
                                            HStack {
                                                Text("\(currency.symbol) \(currency.name) (\(currency.code))")
                                                if CurrencyManager.shared.selectedCurrency.code == currency.code {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(CurrencyManager.shared.selectedCurrency.symbol)
                                        .fontWeight(.bold)
                                    Text(CurrencyManager.shared.selectedCurrency.code)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.black)
                        }
                        .padding(.bottom, 8)
                        
                        // Manage Stores Button
                        Button {
                            showManageStoresSheet = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "building.2")
                                    .foregroundColor(Color(hex: "999"))
                                    .frame(width: 24, height: 24, alignment: .leading)
                                
                                Text("Manage Stores")
                                    .font(.system(size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.black)
                                    .frame(alignment: .leading)
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        
                        ForEach(MenuItem.userSettingsMenuItems) { item in
                            MenuRow(item: item)
                        }
                        
                        Spacer()
                            .frame(height: 8)
                        
                        ForEach(MenuItem.feedbackMenuItems) { item in
                            MenuRow(item: item)
                        }
                        
                        Spacer()
                            .frame(height: 8)
                        
                        ForEach(MenuItem.infoMenuItems) { item in
                            MenuRow(item: item)
                        }
                    }
                    .padding(24)
                }
                .frame(width: 300, alignment: .leading)
            }
            .frame(width: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showManageStoresSheet) {
            ManageStoresView(
                vaultService: vaultService,
                storeToRename: $storeToRename,
                newStoreName: $newStoreName,
                showRenameAlert: $showRenameAlert
            )
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(24)
        }
        .alert("Rename Store", isPresented: $showRenameAlert) {
            TextField("New Name", text: $newStoreName)
            Button("Cancel", role: .cancel) {
                storeToRename = nil
                newStoreName = ""
            }
            Button("Save") {
                if let oldName = storeToRename {
                    vaultService.renameStore(oldName: oldName, newName: newStoreName)
                }
                storeToRename = nil
                newStoreName = ""
            }
        } message: {
            Text("Enter a new name for this store. This will update all items associated with it.")
        }
    }
}

struct ManageStoresView: View {
    let vaultService: VaultService
    @Binding var storeToRename: String?
    @Binding var newStoreName: String
    @Binding var showRenameAlert: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    let stores = vaultService.getAllStores()
                    
                    if stores.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "building.2.crop.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No stores yet")
                                .foregroundColor(.secondary)
                                .font(.headline)
                            Text("Stores will appear here once you add items to your list.")
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    } else {
                        ForEach(stores, id: \.self) { store in
                            HStack {
                                Image(systemName: "building.2")
                                    .foregroundColor(Color(hex: "999"))
                                    .frame(width: 24, height: 24)
                                
                                Text(store)
                                    .font(.system(size: 16))
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Button {
                                    storeToRename = store
                                    newStoreName = store
                                    showRenameAlert = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)
                                        .padding(8)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 8)
                            
                            Divider()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Manage Stores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MenuRow: View {
    let item: MenuItem
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.iconName)
                .foregroundColor(Color(hex: "999"))
                .frame(width: 24, height: 24, alignment: .leading)
            
            Text(item.title)
                .font(.system(size: 16))
                .fontWeight(.medium)
                .foregroundColor(Color.black)
                .frame(alignment: .leading)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .onTapGesture {
        }
    }
}


#Preview {
    MenuView()
}
