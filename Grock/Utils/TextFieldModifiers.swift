import SwiftUI

struct NormalizedTextModifier: ViewModifier {
    @Binding var text: String
    
    func body(content: Content) -> some View {
        content
            .onChange(of: text) { oldValue, newValue in
                let processed = TextValidator.processTextInput(newValue)
                if processed != newValue {
                    text = processed
                }
            }
    }
}

struct NormalizedNumberModifier: ViewModifier {
    @Binding var text: String
    let allowDecimal: Bool
    let maxDecimalPlaces: Int
    
    func body(content: Content) -> some View {
        content
            .onChange(of: text) { oldValue, newValue in
                let processed = TextValidator.processNumericInput(newValue, allowDecimal: allowDecimal, maxDecimalPlaces: maxDecimalPlaces)
                if processed != newValue {
                    text = processed
                }
            }
    }
}

/// as modifiers -> use sa textfields
extension View {
    func normalizedText(_ text: Binding<String>) -> some View {
        self.modifier(NormalizedTextModifier(text: text))
    }
    
    func normalizedNumber(_ text: Binding<String>, allowDecimal: Bool = true, maxDecimalPlaces: Int = 2) -> some View {
        self.modifier(NormalizedNumberModifier(text: text, allowDecimal: allowDecimal, maxDecimalPlaces: maxDecimalPlaces))
    }
}
