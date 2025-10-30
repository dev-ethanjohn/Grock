import SwiftUI

struct CategoryButton: View {
    @Binding var selectedCategory: GroceryCategory?
    let selectedCategoryEmoji: String
    @Binding var showTooltip: Bool
    
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
                              ? Color.gray.opacity(0.2)
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
                    
                    if selectedCategory == nil {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    } else {
                        Text(selectedCategoryEmoji)
                            .font(.system(size: 18))
                    }
                }
            }
            .onTapGesture {
                if showTooltip {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showTooltip = false
                    }
                }
            }
            .padding(.trailing, 8)
        }
    }
}

struct TooltipPopover: View {
    var body: some View {
            HStack(spacing: 4) {
                Text("Select category")
                    .fuzzyBubblesFont(10, weight: .bold)
                    .foregroundColor(.white)
                
                Image(systemName: "arrow.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.2, blue: 0.25),
                        Color(red: 0.15, green: 0.15, blue: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
