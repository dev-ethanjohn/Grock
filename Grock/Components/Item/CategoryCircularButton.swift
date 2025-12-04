import SwiftUI

struct CategoryCircularButton: View {
    @Binding var selectedCategory: GroceryCategory?
    let selectedCategoryEmoji: String
    let hasError: Bool
    
    var body: some View {
        HStack {
            Spacer()
            Menu {
                Section {
                    Text("Grocery Categories")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(GroceryCategory.allCases) { category in
                        Text("\(category.title) \(category.emoji)")
                            .tag(category as GroceryCategory?)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                ZStack {
                    // Main circle that morphs
                    Circle()
                        .fill(selectedCategory == nil
                              ? .gray.opacity(0.2)
                              : selectedCategory!.pastelColor)
                        .frame(width: 34, height: 34)
                    
                    // Outer stroke (non-animating)
                    Circle()
                        .stroke(
                            selectedCategory == nil
                            ? Color.gray
                            : selectedCategory!.pastelColor.darker(by: 0.2),
                            lineWidth: 1.5
                        )
                        .frame(width: 34, height: 34)
//                        .allowsHitTesting(false) // so it doesn't affect tap area
                    
                    // Error stroke
                    if hasError {
                        Circle()
                            .stroke(Color(hex: "#FA003F"), lineWidth: 2)
                            .frame(width: 34 + 8, height: 34 + 8)
                    }
                    
                    // Content
                    if selectedCategory == nil {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray)
                    } else {
                        Text(selectedCategoryEmoji)
                            .font(.system(size: 18))
                    }
                }
                .frame(width: 40, height: 40)
                .contentShape(Circle())

            }
            
//            .labelStyle(.iconOnly) // optional, just for Menu label styling
            .offset(x: -4)
//            .contentShape(Circle())
        }
    }
}
