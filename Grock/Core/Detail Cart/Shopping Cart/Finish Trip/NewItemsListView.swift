import SwiftUI

struct NewItemDisplay: Identifiable {
    let id: String
    let name: String
    let unit: String
    let price: Double
    let categoryEmoji: String?
    let categoryTitle: String?
}

struct NewItemsListView: View {
    let titleCount: Int
    @Binding var toggles: [String: Bool]
    let items: [NewItemDisplay]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("New items (\(titleCount))")
                    .lexendFont(16, weight: .bold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("save to vault?")
                    .lexendFont(14)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 0.5)
                .foregroundColor(Color(hex: "999").opacity(0.5))
                .padding(.horizontal, 24)
            
            ForEach(items) { item in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(item.name)
                                .lexendFont(16, weight: .regular)
                                .foregroundColor(.black)
                        }
                        let categoryText = item.categoryTitle?.trimmingCharacters(in: .whitespacesAndNewlines)
                        let suffix = (categoryText?.isEmpty == false) ? " • \(categoryText!)" : ""
                        Text("\(item.price.formattedCurrency) / \(item.unit)\(suffix)")
                            .lexendFont(12)
                            .foregroundColor(Color(hex: "888"))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { toggles[item.id] ?? true },
                        set: { toggles[item.id] = $0 }
                    ))
                    .labelsHidden()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
        }
        .padding(.bottom, 24)
    }
}

private struct NewItemsPreviewWrapper: View {
    @State private var toggles: [String: Bool] = [:]
    var body: some View {
        NewItemsListView(
            titleCount: 2,
            toggles: $toggles,
            items: [
                NewItemDisplay(id: "1", name: "Avocado", unit: "ea", price: 1.99, categoryEmoji: "🥑", categoryTitle: "Fresh Produce"),
                NewItemDisplay(id: "2", name: "Salsa", unit: "jar", price: 3.49, categoryEmoji: "🧂", categoryTitle: "Pantry")
            ]
        )
    }
}

#Preview("NewItemsListView") {
    NewItemsPreviewWrapper()
        .padding()
        .background(Color.white)
}
