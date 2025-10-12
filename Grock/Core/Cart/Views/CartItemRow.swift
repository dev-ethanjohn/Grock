//
//  CartItemRow.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/11/25.
//

import SwiftUI

struct CartItemRow: View {
    let item: Item
    let quantity: Double
    let isLastItem: Bool
    
    private var displayQuantity: String {
        if quantity == Double(Int(quantity)) {
            return "\(Int(quantity))"
        } else {
            return "\(quantity)"
        }
    }
    
    private var displayUnit: String {
        // Extract unit from the first price option if available
        if let firstPrice = item.priceOptions.first {
            return firstPrice.pricePerUnit.unit
        }
        return ""
    }
    
    private var itemPrice: Double {
        item.priceOptions.first?.pricePerUnit.priceValue ?? 0.0
    }
    
    private var itemTotal: Double {
        itemPrice * quantity
    }
    
    private var displayTotal: String {
        if itemTotal == Double(Int(itemTotal)) {
            // Whole number - remove decimals
            return "₱\(Int(itemTotal))"
        } else if itemTotal * 10 == Double(Int(itemTotal * 10)) {
            // Single decimal place (like 12.50 becomes 12.5)
            return String(format: "₱%.1f", itemTotal)
        } else {
            // Two decimal places
            return String(format: "₱%.2f", itemTotal)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                
                Text("\(displayQuantity)\(displayUnit) - \(item.name)")
                    .font(.lexendRegular_15)
                
                
                Spacer()
                
                Text(displayTotal)
                    .lexendFont(16, weight: .light)
            
            }
            .padding(.vertical, 8)
            .padding(.bottom, 2)
            .padding(.trailing, 2)
            
            if !isLastItem {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "ddd"))
                    }
        }
    }
}

//#Preview {
//    VStack {
//        
//        // Preview with price options
//        CartItemRow(
//            item: {
//                let item = Item(name: "Item with price")
//                let pricePerUnit = PricePerUnit(priceValue: 25.50, unit: "kg")
//                let priceOption = PriceOption(store: "Supermarket", pricePerUnit: pricePerUnit)
//                item.priceOptions = [priceOption]
//                return item
//            }(),
//            quantity: 3
//        )
//        
//        // Preview with multiple price options
//        CartItemRow(
//            item: {
//                let item = Item(name: "Item with multiple prices ok done")
//                let pricePerUnit1 = PricePerUnit(priceValue: 12.00, unit: "pack")
//                let pricePerUnit2 = PricePerUnit(priceValue: 45.00, unit: "box")
//                let priceOption1 = PriceOption(store: "Supermarket", pricePerUnit: pricePerUnit1)
//                let priceOption2 = PriceOption(store: "Market", pricePerUnit: pricePerUnit2)
//                item.priceOptions = [priceOption1, priceOption2]
//                return item
//            }(),
//            quantity: 2
//        )
//    }
//    .padding()
//    .background(Color.gray.opacity(0.1))
//}
