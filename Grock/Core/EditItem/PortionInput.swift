import SwiftUI

struct PortionInput: View {
    @Binding var portion: Double?
    let hasError: Bool
    
    @State private var portionString: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Text("Portion")
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
            TextField("0.0", text: $portionString)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .normalizedNumber($portionString, allowDecimal: true, maxDecimalPlaces: 2)
                .font(.subheadline)
                .bold()
                .fixedSize(horizontal: true, vertical: false)
                .focused($isFocused)
                .onChange(of: portionString) { _, newValue in
                    let numberString = newValue.replacingOccurrences(
                        of: Locale.current.decimalSeparator ?? ".",
                        with: "."
                    )
                    portion = Double(numberString)
                }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    Color(hex: "#FA003F"),
                    lineWidth: hasError ? 2.0 : 0
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }
}
