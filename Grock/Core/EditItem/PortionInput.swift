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
                    if numberString.isEmpty {
                        portion = nil
                    } else {
                        portion = Double(numberString)
                    }
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
        .onAppear {
            //Initialize portionString from portion when view appears
            if let portionValue = portion, portionValue > 0 {
                portionString = formatPortion(portionValue)
            } else {
                portionString = ""
            }
            print("🟢 PortionInput appeared - portion: \(portion ?? 0), portionString: '\(portionString)'")
        }
        .onChange(of: portion) { oldValue, newValue in
            // Update portionString when portion changes programmatically
            if let newValue = newValue, newValue > 0 {
                portionString = formatPortion(newValue)
                print("🔄 Portion changed to \(newValue), updating portionString to '\(portionString)'")
            } else if newValue == nil || newValue == 0 {
                portionString = ""
                print("🔄 Portion changed to nil/0, clearing portionString")
            }
        }
    }
    
    private func formatPortion(_ value: Double) -> String {
        let formatted = String(format: "%.2f", value)
        if formatted.hasSuffix(".00") {
            return String(format: "%.0f", value)
        } else if formatted.hasSuffix("0") {
            return String(format: "%.1f", value)
        }
        return formatted
    }
}
