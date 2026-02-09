import SwiftUI

struct EmojiPickerSheet: View {
    @Binding var selectedEmoji: String?
    let usedEmojis: Set<String>
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    // Fixed grid: 7 columns x 3 rows per page
    private let columnsCount = 7
    private let rowsPerPage = 3

    // Spacing and padding
    private let columnSpacing: CGFloat = 12
    private let rowSpacing: CGFloat = 12
    private let horizontalPadding: CGFloat = 16
    private let verticalGridPadding: CGFloat = 16

    @State private var currentPage: Int = 0

    private var emojiCandidates: [String] {
        var combined = CategoriesManagerEmojiLibrary.top100
        for emoji in usedEmojis where !combined.contains(emoji) {
            combined.insert(emoji, at: 0)
        }
        return combined
    }

    private var pages: [[String]] {
        let perPage = columnsCount * rowsPerPage
        return emojiCandidates.chunked(into: perPage)
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: columnSpacing), count: columnsCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Select Emoji")
                .lexendFont(18, weight: .bold)
                .padding(.top, 32)

            // Grid pages
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    let page = pages[index]
                    LazyVGrid(columns: columns, spacing: rowSpacing) {
                        ForEach(page, id: \.self) { emoji in
                            let isUsed = usedEmojis.contains(emoji)
                            Button {
                                onSelect(emoji)
                            } label: {
                                ZStack(alignment: .bottomTrailing) {
                                    // Square cell without knowing numeric width
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedEmoji == emoji ? Color(.systemGray5) : Color.clear)
                                        .overlay(
                                            Text(emoji)
                                                .font(.system(size: 28)) // scales fine across sizes
                                        )
                                        .aspectRatio(1, contentMode: .fit)

                                    if isUsed {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.black)
                                            .padding(3)
                                            .background(Circle().fill(.white))
                                            .offset(x: 2, y: 2)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, verticalGridPadding)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic)) // show system dots
            .frame(height: 200) // Fixed height for the grid area including dots
        }
        .frame(width: 360) // Fixed width for consistent popover size
        .background(Color.white)
        .onAppear {
            // Customize system page control appearance
            UIPageControl.appearance().currentPageIndicatorTintColor = .black
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.4)
            
            if let selected = selectedEmoji,
               let pageIndex = pages.firstIndex(where: { $0.contains(selected) }) {
                currentPage = pageIndex
            } else {
                currentPage = 0
            }
        }
    }
}
