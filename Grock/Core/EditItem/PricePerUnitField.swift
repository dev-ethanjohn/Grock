import SwiftUI

struct PricePerUnitField: View {
    @Binding var price: String
    let hasError: Bool
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Text("Price/unit")
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
            
            HStack(spacing: 4) {
                Text(CurrencyManager.shared.selectedCurrency.symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(price.isEmpty ? .gray : .black)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: CurrencyManager.shared.selectedCurrency.symbol)
                
                Text(price.isEmpty ? "0" : price)
                    .normalizedNumber($price)
                    .foregroundStyle(price.isEmpty ? .gray : .black)
                    .scalableText()
                    .overlay(
                        TextField("0", text: $price)
                            .scalableText()
                            .keyboardType(.decimalPad)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .numbersOnly($price, includeDecimal: true, maxDigits: 5)
                            .focused($isFocused)
                            .opacity(isFocused ? 1 : 0)
                    )
                    .fixedSize(horizontal: true, vertical: false)
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
