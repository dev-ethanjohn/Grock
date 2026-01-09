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
        if self == Double(Int(self)) {
            return "\(symbol)\(Int(self))"
        } else if self * 10 == Double(Int(self * 10)) {
            return String(format: "\(symbol)%.1f", self)
        } else {
            return String(format: "\(symbol)%.2f", self)
        }
    }
    
    var formattedQuantity: String {
           if self == Double(Int(self)) {
               return "\(Int(self))"
           } else if self * 10 == Double(Int(self * 10)) {
               return String(format: "%.1f", self)
           } else {
               return String(format: "%.2f", self)
           }
       }
}
