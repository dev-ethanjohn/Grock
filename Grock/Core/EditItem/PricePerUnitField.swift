import SwiftUI

struct PricePerUnitField: View {
    @Binding var price: String
    let hasError: Bool
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Price/unit")
                .lexend(.footnote)
                .foregroundColor(.gray)
            Spacer(minLength: 4)
            
            HStack(spacing: 4) {
                Text(CurrencyManager.shared.selectedCurrency.symbol)
                    .lexendFont(16)
                    .foregroundStyle(price.isEmpty ? .gray : .black)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: CurrencyManager.shared.selectedCurrency.symbol)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(price.isEmpty ? "0" : price)
                    .foregroundStyle(price.isEmpty ? .gray : .black)
                    .scalableText()
                    .lineLimit(1)
                    .overlay(
                        TextField("0", text: $price)
                            .scalableText()
                            .keyboardType(.decimalPad)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .numbersOnly($price, includeDecimal: true)
                            .focused($isFocused)
                            .opacity(isFocused ? 1 : 0)
                    )
            }
            .layoutPriority(1)
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
