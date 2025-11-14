import SwiftUI

struct VaultCategorySectionView: View {
    let selectedCategory: GroceryCategory?
    let categoryScrollView: AnyView

    init(selectedCategory: GroceryCategory?, @ViewBuilder categoryScrollView: () -> some View) {
        self.selectedCategory = selectedCategory
        self.categoryScrollView = AnyView(categoryScrollView())
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                if let category = selectedCategory {
                    Text(category.title) 
                        .lexendFont(15, weight: .medium)
                        .contentTransition(.identity)
                        .animation(.spring(duration: 0.3), value: selectedCategory?.id)
                        .transition(.push(from: .leading))
                } else {
                    Text("Select Category")
                        .fuzzyBubblesFont(15, weight: .bold)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            categoryScrollView
                .padding(.bottom, 10)
                .background(
                    Rectangle()
                        .fill(.white)
                        .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 1)
                        .mask(
                            Rectangle()
                                .padding(.bottom, -20)
                        )
                )
        }
    }
}
