import SwiftUI

struct TotalDisplay: View {
    let calculatedTotal: Double
    
    var body: some View {
        HStack(spacing: 2) {
            //TODO: use locale currency
            Text("Total: \(CurrencyManager.shared.selectedCurrency.symbol)")
                .lexendFont(14, weight: .semibold)
            
            Text(calculatedTotal, format: .number.precision(.fractionLength(2)))
                .lexendFont(16, weight: .semibold)
                .contentTransition(.numericText(value: calculatedTotal))
                .animation(.spring(duration: 0.1), value: calculatedTotal)
        }
        .foregroundColor(.black)
        .padding(.top, 4)
    }
}
#Preview {
    TotalDisplay(calculatedTotal: 20.3)
}
