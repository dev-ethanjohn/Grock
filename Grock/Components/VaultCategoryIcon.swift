import SwiftUI

struct VaultCategoryIcon: View {
    let category: GroceryCategory
    let isSelected: Bool
    let itemCount: Int
    let hasItems: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(category.pastelColor.darker(by: 0.07).saturated(by: 0.03))
                    .frame(width: 42, height: 42)
                
                Text(category.emoji)
                    .font(.system(size: 24))
                    .frame(width: 42, height: 42)
                
                if itemCount > 0 {
                    Text("\(itemCount)")
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .offset(x: 2, y: -2)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
