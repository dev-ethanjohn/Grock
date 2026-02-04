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
                ChangedItemRowView(item: item)
                
                
                if item != items.last {
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

#Preview("ChangedItemsListView") {
    let sample: [ChangedItemDisplay] = [
        ChangedItemDisplay(id: "1", name: "Milk", plannedPrice: 3.0, actualPrice: 3.5, plannedQty: 1, actualQty: 2, unit: "ea"),
        ChangedItemDisplay(id: "2", name: "Eggs", plannedPrice: 4.0, actualPrice: 4.0, plannedQty: 1, actualQty: 1.5, unit: "dozen"),
        ChangedItemDisplay(id: "3", name: "Bread", plannedPrice: 2.5, actualPrice: 2.9, plannedQty: 1, actualQty: 1, unit: "ea")
    ]
    return VStack {
        ChangedItemsListView(items: sample)
            .padding()
            .fixedSize(horizontal: false, vertical: true)
        Spacer()
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
