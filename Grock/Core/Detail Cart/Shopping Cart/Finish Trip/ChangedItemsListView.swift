import SwiftUI

struct ChangedItemDisplay: Identifiable, Equatable {
    let id: String
    let name: String
    let plannedPrice: Double
    let actualPrice: Double
    let plannedQty: Double
    let actualQty: Double
    let unit: String
}

struct ChangedItemsListView: View {
    let items: [ChangedItemDisplay]
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(items) { item in
                let priceChanged = abs(item.actualPrice - item.plannedPrice) > 0.0001
                let qtyChanged = abs(item.actualQty - item.plannedQty) > 0.0001
                let delta = max(0, item.actualPrice - item.plannedPrice)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .lexendFont(16, weight: .regular)
                        .foregroundColor(.black)
                    
                    HStack(spacing: 6) {
                        if priceChanged {
                            Text("\(item.plannedPrice.formattedCurrency)")
                                .strikethrough()
                                .foregroundColor(Color(hex: "777"))
                            
                            Text("→ \(item.actualPrice.formattedCurrency) / \(item.unit)")
                                .foregroundColor(Color(hex: "231F30"))
                        }
                        
                        if priceChanged && qtyChanged {
                            Text("•")
                                .foregroundColor(Color(hex: "999"))
                        }
                        
                        if qtyChanged {
                            Text("\(item.plannedQty.formattedQuantity) → \(item.actualQty.formattedQuantity)\(item.unit.isEmpty ? "" : " \(item.unit)")")
                                .foregroundColor(Color(hex: "231F30"))
                        }
                        
                        Spacer()
                        
                        if priceChanged && delta > 0.0001 {
                            Text("↑ \(delta.formattedCurrency)")
                                .foregroundColor(Color(hex: "FA003F"))
                        }
                    }
                    .lexendFont(13)
                }
                .padding(.vertical, 6)
                
                if item != items.last {
                    DashedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                        .frame(height: 0.5)
                        .foregroundColor(Color(hex: "999").opacity(0.5))
                }
            }
        }
        .padding(.leading, 16)
    }
}

#Preview("ChangedItemsListView") {
    let sample: [ChangedItemDisplay] = [
        ChangedItemDisplay(id: "1", name: "Milk", plannedPrice: 3.0, actualPrice: 3.5, plannedQty: 1, actualQty: 2, unit: "ea"),
        ChangedItemDisplay(id: "2", name: "Eggs", plannedPrice: 4.0, actualPrice: 4.0, plannedQty: 1, actualQty: 1.5, unit: "dozen"),
        ChangedItemDisplay(id: "3", name: "Bread", plannedPrice: 2.5, actualPrice: 2.9, plannedQty: 1, actualQty: 1, unit: "ea")
    ]
    return ChangedItemsListView(items: sample)
        .padding()
        .background(Color.white)
}
