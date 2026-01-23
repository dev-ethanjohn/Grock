import SwiftUI

struct SkippedItemDisplay: Identifiable {
    let id: String
    let name: String
    let qty: Double
}

struct SkippedItemsListView: View {
    let items: [SkippedItemDisplay]
    
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

#Preview("SkippedItemsListView") {
    let sample: [SkippedItemDisplay] = [
        SkippedItemDisplay(id: "1", name: "Yogurt", qty: 3),
        SkippedItemDisplay(id: "2", name: "Granola", qty: 1)
    ]
    return SkippedItemsListView(items: sample)
        .padding()
        .background(Color.white)
}
