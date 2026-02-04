import SwiftUI

struct AddedItemDisplay: Identifiable {
    let id: String
    let name: String
    let qty: Double
}

struct AddedDuringShoppingListView: View {
    let items: [AddedItemDisplay]
    
    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(item.qty.formattedQuantity) \(item.name)")
                        .lexendFont(16, weight: .regular)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 2)
                
                if index != items.count - 1 {
                    DashedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                        .frame(height: 0.5)
                        .foregroundColor(Color(hex: "999").opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .padding(.top, 2)
    }
}

#Preview("AddedDuringShoppingListView") {
    let sample: [AddedItemDisplay] = [
        AddedItemDisplay(id: "1", name: "Bananas", qty: 6),
        AddedItemDisplay(id: "2", name: "Sparkling Water", qty: 2)
    ]
    return AddedDuringShoppingListView(items: sample)
        .padding()
        .background(Color.white)
}
