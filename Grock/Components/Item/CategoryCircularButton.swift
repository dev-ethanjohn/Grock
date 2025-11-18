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
                    Circle()
                        .fill(selectedCategory == nil
                              ? .gray.opacity(0.2)
                              : selectedCategory!.pastelColor)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedCategory == nil
                                     ? Color.gray
                                     : selectedCategory!.pastelColor.darker(by: 0.2),
                                    lineWidth: 1.5
                                )
                        )
                        .overlay(
                            // Outer red stroke for errors
                            Circle()
                                .stroke(
                                    Color(hex: "#FA003F"),
                                    lineWidth: hasError ? 2.0 : 0
                                )
                                .padding(hasError ? -4 : 0) // Push the stroke outside
                        )
                    
                    if selectedCategory == nil {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.gray) // Always gray, no change for error
                    } else {
                        Text(selectedCategoryEmoji)
                            .font(.system(size: 18))
                    }
                }
                .offset(x: -4)
            }
        }
    }
}
