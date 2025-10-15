//
//  Double+Currency.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/14/25.
//

import Foundation

extension Double {
    var formattedCurrency: String {
        if self == Double(Int(self)) {
            return "₱\(Int(self))"
        } else if self * 10 == Double(Int(self * 10)) {
            return String(format: "₱%.1f", self)
        } else {
            return String(format: "₱%.2f", self)
        }
    }
}
