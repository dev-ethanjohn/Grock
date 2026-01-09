//
//  MenuView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/7/25.
//

import SwiftUI

struct MenuView: View {
    
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
                        
                        // Currency Selection Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Currency")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "999"))
                                .padding(.horizontal, 4)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(CurrencyManager.shared.availableCurrencies, id: \.code) { currency in
                                        CurrencySelectionPill(
                                            currency: currency,
                                            isSelected: CurrencyManager.shared.selectedCurrency.code == currency.code,
                                            action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    CurrencyManager.shared.setCurrency(currency)
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4) // Add space for shadow
                            }
                        }
                        .padding(.bottom, 8)
                        
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
    }
}

struct CurrencySelectionPill: View {
    let currency: Currency
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(currency.symbol)
                    .font(.system(size: 16, weight: .bold))
                Text(currency.code)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.black : Color.white)
            .foregroundColor(isSelected ? .white : .black)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
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
