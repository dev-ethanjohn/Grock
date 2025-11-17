import Foundation

class TextValidator {
    /// Normalizes text input by removing leading spaces and collapsing multiple spaces
    static func normalizeSpaces(_ text: String) -> String {
        var processed = text
        
        // Remove leading spaces
        if processed.hasPrefix(" ") {
            processed = String(processed.dropFirst())
        }
        
        // Normalize multiple spaces to single spaces
        processed = processed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return processed
    }
    
    /// Validates and normalizes general text input (store names, item names, etc.)
    static func processTextInput(_ text: String) -> String {
        return normalizeSpaces(text)
    }
    
    /// Validates and processes numeric input (prices, quantities)
    static func processNumericInput(_ text: String, allowDecimal: Bool = true, maxDecimalPlaces: Int = 2) -> String {
        var processed = text
        
        // Remove non-numeric characters except decimal point if allowed
        if allowDecimal {
            processed = processed.filter { "0123456789.".contains($0) }
            
            // Auto-add leading zero if user starts with decimal point
            if processed.hasPrefix(".") {
                processed = "0" + processed
            }
            
            // Ensure only one decimal point
            let components = processed.components(separatedBy: ".")
            if components.count > 2 {
                processed = components[0] + "." + components[1...].joined()
            }
            
            // Remove leading zeros but allow "0." and single "0"
            if processed.count > 1 && processed.hasPrefix("0") && !processed.hasPrefix("0.") {
                processed = String(processed.dropFirst())
            }
            
            // Limit decimal places
            if let dotIndex = processed.firstIndex(of: ".") {
                let decimalPart = String(processed[processed.index(after: dotIndex)...])
                if decimalPart.count > maxDecimalPlaces {
                    let endIndex = processed.index(dotIndex, offsetBy: maxDecimalPlaces + 1)
                    processed = String(processed[..<endIndex])
                }
            }
        } else {
            processed = processed.filter { "0123456789".contains($0) }
            // Remove leading zeros for integers
            if processed.count > 1 && processed.hasPrefix("0") {
                processed = String(processed.dropFirst())
            }
        }
        
        return processed
    }
}
