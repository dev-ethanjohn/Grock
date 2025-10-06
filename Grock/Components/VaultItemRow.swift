import SwiftUI

struct VaultItemRow: View {
    let item: Item
    let category: GroceryCategory?
    var onDelete: (() -> Void)?
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Circle()
                .fill(category?.pastelColor.saturated(by: 1).darker(by: 0.2) ?? Color.primary)
                .frame(width: 8, height: 8)
                .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .foregroundColor(Color(hex: "888"))
                + Text(" >")
                    .font(.fuzzyBold_20)
                    .foregroundStyle(Color(hex: "bbb"))
                
                if let priceOption = item.priceOptions.first {
                    HStack(spacing: 4) {
                        Text("₱\(priceOption.pricePerUnit.priceValue, specifier: "%.2f")")
                        Text("/ \(priceOption.pricePerUnit.unit)")
                            .font(.caption)
                        Spacer()
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "888"))
                }
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "plus")
                    .foregroundColor(.gray)
                    .font(.footnote)
                    .bold()
                    .padding(6)
                    .background(Color(hex: "fff"))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 4)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                // Edit action
                print("Edit item: \(item.name)")
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
        .background(.white)
    }
}
