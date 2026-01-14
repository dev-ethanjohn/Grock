//
//  MenuView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/7/25.
//

import SwiftUI

struct MenuView: View {
    @Environment(VaultService.self) private var vaultService
    @State private var currencyManager = CurrencyManager.shared
    
    @State private var isEditingName = false
    @State private var editingName = ""
    
    var body: some View {
        NavigationStack {
            VStack {
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // User Profile
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hello,")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                Text(vaultService.currentUser?.name ?? "User")
                                    .font(.title3)
                                    .bold()
                            }
                            
                            Spacer()
                            
                            Button {
                                let name = vaultService.currentUser?.name ?? ""
                                editingName = name
                                isEditingName = true
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(.gray)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Currency Selector
                        Menu {
                            ForEach(currencyManager.availableCurrencies) { currency in
                                Button {
                                    currencyManager.setCurrency(currency)
                                } label: {
                                    if currency.code == currencyManager.selectedCurrency.code {
                                        Label("\(currency.symbol) \(currency.code) - \(currency.name)", systemImage: "checkmark")
                                    } else {
                                        Text("\(currency.symbol) \(currency.code) - \(currency.name)")
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "banknote")
                                    .foregroundColor(Color(hex: "999"))
                                    .frame(width: 24, height: 24, alignment: .leading)
                                
                                Text("Currency")
                                    .font(.system(size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.black)
                                
                                Spacer()
                                
                                Text(currencyManager.selectedCurrency.code)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                        }
                        
                        // Store Manager
                        NavigationLink {
                            StoreManagerView()
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "storefront")
                                    .foregroundColor(Color(hex: "999"))
                                    .frame(width: 24, height: 24, alignment: .leading)
                                
                                Text("Manage Stores")
                                    .font(.system(size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.black)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                        }
                        
                        // Insights
                        NavigationLink {
                            InsightsView()
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "chart.bar.xaxis")
                                    .foregroundColor(Color(hex: "999"))
                                    .frame(width: 24, height: 24, alignment: .leading)
                                
                                Text("Insights")
                                    .font(.system(size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color.black)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                        }
                        
                        ForEach(MenuItem.userSettingsMenuItems) { item in
                            MenuRow(item: item)
                        }
                        
                        Spacer()
                            .frame(height: 8)
                        
                        ForEach(MenuItem.feedbackMenuItems) { item in
                            MenuRow(item: item)
//                            Divider()
                        }
                        
                        Spacer()
                            .frame(height: 8)
                        
                        ForEach(MenuItem.infoMenuItems) { item in
                            MenuRow(item: item)
//                            Divider()
                        }
                    }
                    .padding(24)
                }
                .frame(width: 300, alignment: .leading)
            }
            .frame(width: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .alert("Change Name", isPresented: $isEditingName) {
            TextField("Name", text: $editingName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    vaultService.updateUserName(editingName)
                }
            }
        } message: {
            Text("Enter your new username")
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
