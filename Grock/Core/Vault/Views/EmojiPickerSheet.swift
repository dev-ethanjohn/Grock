import SwiftUI

struct EmojiPickerSheet: View {
    @Binding var selectedEmoji: String?
    let usedEmojis: Set<String>
    let usedEmojiNamesByEmoji: [String: [String]]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    // Fixed grid: 7 columns x 4 rows per page
    private let columnsCount = 7
    private let rowsPerPage = 4
    private let popoverWidth: CGFloat = 320

    // Spacing and padding
    private let columnSpacing: CGFloat = 12
    private let rowSpacing: CGFloat = 12
    private let horizontalPadding: CGFloat = 16
    private let verticalGridPadding: CGFloat = 16
    private let selectionInset: CGFloat = 4
    private let headerTopPadding: CGFloat = 24
    private let headerBottomPadding: CGFloat = 12
    private let pageDotsHeight: CGFloat = 18
    private let targetGridHeight: CGFloat = 210

    @State private var currentPage: Int = 0
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var toastHideWorkItem: DispatchWorkItem?
    @State private var toastScale: CGFloat = 0.95

    private struct EmojiGroup {
        let title: String
        let emojis: [String]
    }

    private let groups: [EmojiGroup] = [
        EmojiGroup(title: "Meals & Proteins", emojis: [
            "🍗","🍖","🥩","🥓","🍔","🌭","🍕","🍳","🥚","🧀",
            "🥛","🧈","🥞","🍲","🍛","🍜","🍟","🍣","🍱","🥟",
            "🍤","🦐","🦞","🦀","🦑","🐙","🐟","🐠"
        ]),
        EmojiGroup(title: "Produce", emojis: [
            "🍏","🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🫐",
            "🍈","🍒","🍑","🥭","🍍","🥥","🥝","🍅","🍆","🥑",
            "🥦","🥬","🥒","🌶️","🫑","🌽","🥕","🫒"
        ]),

        EmojiGroup(title: "Pantry, Snacks & Drinks", emojis: [
            "🍞","🥖","🥐","🥯","🥨","🍚","🍙","🍘","🍥","🥣",
            "🥫","🫙","🧂","🍯","🥜","🌰","🫘","🍪","🍩","🍿",
            "☕️","🍵","🧋","🧃","🥤","🍶","🍺","🍻"
        ]),
        EmojiGroup(title: "Activities", emojis: [
            "⚽️","🏀","🏈","⚾️","🥎","🎾","🏐","🏉","🎱","🏓",
            "🏸","🥅","⛳️","🏹","🎣","🥊","🥋","⛸️","🥌","🛷",
            "🎿","🛹","🚴‍♀️","🚴‍♂️","🏂","🏋️‍♀️","🏋️‍♂️","🤸‍♀️"
        ]),
        EmojiGroup(title: "Objects & Home", emojis: [
            "📱","💻","🖥️","🖨️","⌨️","🖱️","📷","📸","🎥","📺",
            "📻","🎙️","⏰","⌚️","🧮","🧲","🔦","🕯️","🪑","🛋️",
            "🛏️","🛁","🚿","🧴","🪥","🧹","🧺","🧻"
        ]),
        EmojiGroup(title: "Animals & Nature", emojis: [
            "🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐻‍❄️","🐨",
            "🐯","🦁","🐮","🐷","🐸","🐵","🐔","🐧","🐦","🦆",
            "🦅","🦉","🐺","🐴","🦄","🐝","🦋","🐌"
        ]),
        EmojiGroup(title: "Travel & Places", emojis: [
            "🌍","🌎","🌏","🗺️","🧭","⛰️","🏔️","🗻","🏕️","🏖️",
            "🏜️","🏝️","🏞️","🏟️","🏛️","🏗️","🧱","🏘️","🏙️","🏠",
            "🏡","🏢","🏣","🏥","🏦","🏨","🏪","🏫"
        ]),
        EmojiGroup(title: "Smileys & Emotion", emojis: [
            "😀","😃","😄","😁","😆","😅","😂","🤣","😊","😇",
            "🙂","🙃","😉","😌","😍","🥰","😘","😗","😙","😚",
            "😋","😛","😝","😜","🤪","🤨","🧐","🤓"
        ]),
        EmojiGroup(title: "People & Body", emojis: [
            "👋","🤚","🖐️","✋","🖖","👌","🤌","🤏","✌️","🤞",
            "🤟","🤘","🤙","👈","👉","👆","👇","☝️","👍","👎",
            "✊","👊","🤛","🤜","🤲","🤝","🙌","👐"
        ]),
    ]

    private var gridHeight: CGFloat {
        let availableWidth = popoverWidth - (horizontalPadding * 2)
        let totalSpacing = columnSpacing * CGFloat(columnsCount - 1)
        let cellSize = max(0, floor((availableWidth - totalSpacing) / CGFloat(columnsCount)))
        let rowsHeight = (cellSize * CGFloat(rowsPerPage)) + (rowSpacing * CGFloat(rowsPerPage - 1))
        let computed = rowsHeight + verticalGridPadding + selectionInset + pageDotsHeight
        return max(computed, targetGridHeight)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text(groups[currentPage].title)
                .lexendFont(16, weight: .medium)
                .padding(.top, headerTopPadding)
                .padding(.bottom, headerBottomPadding)

            // Grid pages
            TabView(selection: $currentPage) {
                    ForEach(groups.indices, id: \.self) { index in
                        let page = groups[index].emojis
                        GeometryReader { geo in
                            let availableWidth = geo.size.width - (horizontalPadding * 2)
                            let totalSpacing = columnSpacing * CGFloat(columnsCount - 1)
                            let cellSize = max(0, floor((availableWidth - totalSpacing) / CGFloat(columnsCount)))
                            let gridWidth = (cellSize * CGFloat(columnsCount)) + totalSpacing
                            let columns = Array(repeating: GridItem(.fixed(cellSize), spacing: columnSpacing), count: columnsCount)

                            ScrollView(.vertical, showsIndicators: false) {
                                ZStack(alignment: .topLeading) {
                                    LazyVGrid(columns: columns, spacing: rowSpacing) {
                                        ForEach(page, id: \.self) { emoji in
                                            let isUsed = usedEmojis.contains(emoji)
                                            Button {
                                                guard !isUsed else {
                                                    showUsedEmojiToast(for: emoji)
                                                    return
                                                }
                                                selectedEmoji = emoji
                                                onSelect(emoji)
                                            } label: {
                                                ZStack(alignment: .bottomTrailing) {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(selectedEmoji == emoji ? Color(.systemGray5) : Color.clear)
                                                        .frame(width: cellSize, height: cellSize)
                                                        .overlay(
                                                            Text(emoji)
                                                                .font(.system(size: 28))
                                                        )

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
                                    .frame(width: gridWidth, alignment: .leading)

                                    if let selectedIndex = selectedIndex(in: page) {
                                        let row = selectedIndex / columnsCount
                                        let col = selectedIndex % columnsCount
                                        let xOffset = CGFloat(col) * (cellSize + columnSpacing)
                                        let yOffset = CGFloat(row) * (cellSize + rowSpacing)
                                        let outerInset: CGFloat = selectionInset
                                        let borderCornerRadius: CGFloat = 12 + outerInset

                                        RoundedRectangle(cornerRadius: borderCornerRadius)
                                            .strokeBorder(Color.black.opacity(0.7), lineWidth: 2)
                                            .frame(width: cellSize + (outerInset * 2), height: cellSize + (outerInset * 2))
                                            .offset(x: xOffset - outerInset, y: yOffset - outerInset)
                                            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: selectedIndex)
                                            .allowsHitTesting(false)
                                    }
                                }
                                .padding(.horizontal, horizontalPadding)
                                .padding(.top, selectionInset)
                                .padding(.bottom, verticalGridPadding)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: gridHeight)
                .overlay(alignment: .bottom) {
                    Text(toastMessage ?? "")
                        .lexendFont(10, weight: .semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(showToast ? 0.9 : 0))
                        )
                        .scaleEffect(showToast ? toastScale : 0)
                        .opacity(showToast ? 1 : 0)
                        .padding(.bottom, pageDotsHeight + 4)
                        .allowsHitTesting(false)
                        .offset(y: 12)
                }
        }
        .frame(width: popoverWidth)
        .background(Color.white)
        .onAppear {
            UIPageControl.appearance().currentPageIndicatorTintColor = .black
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.4)

            if let selected = selectedEmoji,
               let pageIndex = groups.firstIndex(where: { $0.emojis.contains(selected) }) {
                currentPage = pageIndex
            } else {
                currentPage = 0
            }
        }
    }

    private func selectedIndex(in emojis: [String]) -> Int? {
        guard let selected = selectedEmoji else { return nil }
        return emojis.firstIndex(of: selected)
    }

    private func showUsedEmojiToast(for emoji: String) {
        let names = usedEmojiNamesByEmoji[emoji] ?? []
        let message: String
        if names.isEmpty {
            message = "Oops — that emoji is already taken."
        } else if names.count == 1 {
            message = "Already claimed by \(names[0])."
        } else if names.count == 2 {
            message = "Claimed by \(names[0]) and \(names[1])."
        } else {
            message = "Claimed by \(names[0]), \(names[1]) and \(names.count - 2) more."
        }

        toastHideWorkItem?.cancel()
        toastMessage = message
        if !showToast {
            showToast = true
        }
        toastScale = 0
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            toastScale = 1.0
        }

        let workItem = DispatchWorkItem {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                toastScale = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showToast = false
            }
        }
        toastHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: workItem)
    }
}
