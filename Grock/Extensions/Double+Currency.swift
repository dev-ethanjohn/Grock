//
//  Double+Currency.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/14/25.
//

import Foundation

extension Double {
    var formattedCurrency: String {
        let symbol = CurrencyManager.shared.selectedCurrency.symbol
        let fractionDigits: Int
        if self == Double(Int(self)) {
            fractionDigits = 0
        } else if self * 10 == Double(Int(self * 10)) {
            fractionDigits = 1
        } else {
            fractionDigits = 2
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        
        let formatted = formatter.string(from: NSNumber(value: self))
            ?? String(format: "%.\(fractionDigits)f", self)
        
        return "\(symbol)\(formatted)"
    }

    var formattedCurrencySpaced: String {
        let symbol = CurrencyManager.shared.selectedCurrency.symbol
        let formatted = formattedCurrency
        guard formatted.hasPrefix(symbol) else { return formatted }
        let amount = formatted.dropFirst(symbol.count)
        return "\(symbol) \(amount)"
    }
    
    var formattedQuantity: String {
        let fractionDigits: Int
        if self == Double(Int(self)) {
            fractionDigits = 0
        } else if self * 10 == Double(Int(self * 10)) {
            fractionDigits = 1
        } else {
            fractionDigits = 2
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        
        return formatter.string(from: NSNumber(value: self))
            ?? String(format: "%.\(fractionDigits)f", self)
    }
    
    func formattedDecimal(maxFractionDigits: Int) -> String {
        guard isFinite else { return "—" }
        return formatted(.number.grouping(.automatic).precision(.fractionLength(0...maxFractionDigits)))
    }
    
    var formattedPricePerUnitValue: String {
        let absValue = abs(self)
        if absValue >= 1 {
            return formattedDecimal(maxFractionDigits: 2)
        }
        if absValue >= 0.01 {
            return formattedDecimal(maxFractionDigits: 4)
        }
        return formattedDecimal(maxFractionDigits: 6)
    }
}
