import SwiftUI

struct ChangedItemRowView: View {
    let item: ChangedItemDisplay
    
    var body: some View {
        let plannedTotal = item.plannedPrice * item.plannedQty
        let actualTotal = item.actualPrice * item.actualQty
        let totalDelta = actualTotal - plannedTotal
        let impactAbs = abs(totalDelta)
        let isIncrease = totalDelta > 0
        let priceChanged = abs(item.actualPrice - item.plannedPrice) > 0.0001
        let qtyChanged = abs(item.actualQty - item.plannedQty) > 0.0001
        
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .lexendFont(16)
                    .foregroundColor(.black)
                
                changePills(priceChanged: priceChanged, qtyChanged: qtyChanged)
            }
            
            Spacer()
            
            if (priceChanged || qtyChanged) && impactAbs > 0.0001 {
                Text("\(isIncrease ? "+" : "-")\(impactAbs.formattedCurrency)")
                    .foregroundColor(isIncrease ? Color(hex: "FA003F") : Color(hex: "4CAF50"))
                    .lexendFont(13, weight: .semibold)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func changePills(priceChanged: Bool, qtyChanged: Bool) -> some View {
        HStack(spacing: 16) {
            if priceChanged {
                let delta = item.actualPrice - item.plannedPrice
                let isIncrease = delta > 0
                let deltaText = abs(delta).formattedQuantity
                ChangePillView(
                    currentText: "\(item.actualPrice.formattedCurrency)",
                    impactText: "\(isIncrease ? "+" : "-")\(deltaText)",
                    isIncrease: isIncrease,
                    unitSuffix: item.unit,
                    slashUnit: true
                )
            }
            if qtyChanged {
                let delta = item.actualQty - item.plannedQty
                let isIncrease = delta > 0
                let deltaText = abs(delta).formattedQuantity
                ChangePillView(
                    currentText: "\(item.actualQty.formattedQuantity)",
                    impactText: "\(isIncrease ? "+" : "-")\(deltaText)",
                    isIncrease: isIncrease,
                    unitSuffix: item.unit.isEmpty ? nil : item.unit,
                    slashUnit: false
                )
            }
        }
    }
}

#Preview("ChangedItemRowView") {
    let sample = ChangedItemDisplay(id: "1", name: "Milk", plannedPrice: 3.0, actualPrice: 3.5, plannedQty: 1, actualQty: 2, unit: "ea")
    return VStack {
        ChangedItemRowView(item: sample)
            .padding()
            .fixedSize(horizontal: false, vertical: true)
        Spacer()
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
