//  MarketPriceListView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/3/25.
//


import SwiftUI

struct MarketPriceListView: View {
    let item: Item
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {

            Circle()
                .fill(Color.primary)
                .frame(width: 8, height: 8)
                .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .foregroundColor(.primary)
                + Text(" >")
                    .font(.fuzzyBold_20)
                    .foregroundStyle(Color(hex: "bbb"))
                
                if let priceOption = item.priceOptions.first {
                    HStack(spacing: 4) {
                        Text("₱\(priceOption.pricePerUnit.priceValue, specifier: "%.2f")")
                        
                        Text("/ \(priceOption.pricePerUnit.unit)")
                            .font(.caption)
                        
                        Spacer()
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            Button(action: {
                // TODO: Add to cart functionality
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
                    .font(.footnote)
                    .bold()
                    .padding(6)
                    .background(Color(hex: "fff"))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    // Preview with single store item
    let pricePerUnit = PricePerUnit(priceValue: 358.0, unit: "kg")
    let priceOption = PriceOption(store: "SaveMore", pricePerUnit: pricePerUnit)
    
    let sampleItem = Item(name: "ground beef")
    sampleItem.priceOptions = [priceOption]
    
    return MarketPriceListView(item: sampleItem)
        .padding()
}

#Preview("Multiple Items") {
    VStack(spacing: 0) {
        // Sample items that match the screenshot
        let items = [
            createPreviewItem(name: "Monterey Beef Tapa 250g", price: 112.20, unit: "pc"),
            createPreviewItem(name: "ground beef", price: 358.0, unit: "kg"),
            createPreviewItem(name: "Purefoods corned beef 120g", price: 87.25, unit: "can"),
            createPreviewItem(name: "whole chicken", price: 198.0, unit: "kg"),
            createPreviewItem(name: "chicken breast", price: 234.0, unit: "kg")
        ]
        
        ForEach(items) { item in
            MarketPriceListView(item: item)
            
            if item.id != items.last?.id {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
}

// Helper function for previews
private func createPreviewItem(name: String, price: Double, unit: String) -> Item {
    let pricePerUnit = PricePerUnit(priceValue: price, unit: unit)
    let priceOption = PriceOption(store: "SaveMore", pricePerUnit: pricePerUnit)
    let item = Item(name: name)
    item.priceOptions = [priceOption]
    return item
}
