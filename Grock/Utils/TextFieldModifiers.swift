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

/// as modifiers -> use sa textfields
extension View {
    func normalizedText(_ text: Binding<String>) -> some View {
        self.modifier(NormalizedTextModifier(text: text))
    }
}
