import SwiftUI

struct AddedItemDisplay: Identifiable {
    let id: String
    let name: String
    let qty: Double
}

struct AddedDuringShoppingListView: View {
    let items: [AddedItemDisplay]
    
    var body: some View {
        VStack(spacing: 6) {
            ForEach(items) { item in
                Text("\(item.qty.formattedQuantity) \(item.name)")
                    .lexendFont(13)
                    .foregroundColor(Color(hex: "231F30"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
            }
        }
        .padding(.horizontal, 20)
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
