//
//  Numbers.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/6/25.
//

import SwiftUI
import Foundation
import Combine

extension View {
    func numbersOnly(_ text: Binding<String>, includeDecimal: Bool, maxDigits: Int) -> some View {
        self
            .keyboardType(includeDecimal ? .decimalPad : .numberPad)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .onChange(of: text.wrappedValue) { oldValue, newValue in
                var filtered = newValue.filter { "0123456789".contains($0) }
                
                if includeDecimal {
                    // Allow decimal point - use unique variable name
                    let initialComponents = newValue.components(separatedBy: ".")
                    if initialComponents.count > 1 {
                        filtered = initialComponents[0] + "." + initialComponents[1...].joined()
                    }
                    
                    // Ensure only one decimal point exists
                    let decimalCount = newValue.components(separatedBy: ".").count - 1
                    if decimalCount > 1 {
                        let parts = newValue.split(separator: ".")
                        filtered = String(parts[0]) + "." + parts.dropFirst().joined()
                    }
                    
                    // Apply digit limit to integer part - use unique variable name
                    let filteredComponents = filtered.components(separatedBy: ".")
                    if filteredComponents[0].count > maxDigits {
                        let limitedInteger = String(filteredComponents[0].prefix(maxDigits))
                        filtered = filteredComponents.count > 1 ? limitedInteger + "." + filteredComponents[1] : limitedInteger
                    }
                    
                    // Apply 2-digit limit to decimal part
                    if filteredComponents.count > 1 && filteredComponents[1].count > 2 {
                        let limitedDecimal = String(filteredComponents[1].prefix(2))
                        filtered = filteredComponents[0] + "." + limitedDecimal
                    }
                } else {
                    // No decimals allowed - just limit digits
                    if filtered.count > maxDigits {
                        filtered = String(filtered.prefix(maxDigits))
                    }
                }
                
                if filtered != newValue {
                    text.wrappedValue = filtered
                }
            }
    }
}

