import SwiftUI

struct PortionInput: View {
    @Binding var portion: Double?
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
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }
}
