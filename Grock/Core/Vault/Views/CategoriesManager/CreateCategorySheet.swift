import SwiftUI
import Observation
import UIKit

struct CreateCategorySheet: View {
    @Bindable var viewModel: CategoriesManagerViewModel
    let usedColorNamesByHex: [String: [String]]
    let usedEmojis: Set<String>
    let usedEmojiNamesByEmoji: [String: [String]]
    let onSave: () -> Void
    @FocusState private var isNameFocused: Bool
    @State private var didRequestInitialFocus = false
    @State private var colorPage = 0
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var toastHideWorkItem: DispatchWorkItem?
    @State private var toastScale: CGFloat = 0.95
    @State private var showEmojiPicker = false

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Create New Category")
                    .fuzzyBubblesFont(18, weight: .bold)
                    .foregroundStyle(.black)

                Spacer()

                Button(action: {
                    onSave()
                }) {
                    Text("Save")
                        .lexendFont(14, weight: .bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.popoverCanCreate)
                .opacity(viewModel.popoverCanCreate ? 1 : 0.5)
            }
            .padding(.top)

            // Input Row
            HStack(spacing: 12) {
                //EMOJI CONTAINER
                Button(action: {
                    viewModel.selectedEmoji = viewModel.newCategoryEmoji.isEmpty ? nil : viewModel.newCategoryEmoji
                    showEmojiPicker = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.selectedColorHex != nil ? Color(hex: viewModel.selectedColorHex!).darker(by: 0.2) : Color.clear)

                        if viewModel.selectedColorHex == nil {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        }

                        Group {
                            if !viewModel.newCategoryEmoji.isEmpty {
                                Text(viewModel.newCategoryEmoji)
                                    .font(.system(size: 24))
                            } else {
                                Image("no_emoji")
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)
                                    .foregroundStyle(.gray)
                            }
                        }
                        .popover(isPresented: $showEmojiPicker, arrowEdge: .top) {
                            EmojiPickerSheet(
                                selectedEmoji: $viewModel.selectedEmoji,
                                usedEmojis: usedEmojis,
                                usedEmojiNamesByEmoji: usedEmojiNamesByEmoji
                            ) { emoji in
                                viewModel.selectedEmoji = emoji
                                viewModel.newCategoryEmoji = emoji
                                HapticManager.shared.playButtonTap()
                                showEmojiPicker = false
                            }
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                    .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
              
                
                TextField("Category name...", text: $viewModel.newCategoryName)
                    .lexendFont(16, weight: .medium)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .focused($isNameFocused)
                    .submitLabel(.done)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
            )

            if let createCategoryError = viewModel.createCategoryError {
                Text(createCategoryError)
                    .lexendFont(12, weight: .medium)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Content (Color Grid with Pagination)
            colorGridSection

            Spacer(minLength: 0)
        }
        .padding(24)
        .background(Color.white)
        .safeAreaInset(edge: .top, spacing: 0) {
            Color.clear.frame(height: 12)
        }
        .onAppear {
            requestInitialFocusIfNeeded()
        }
    }

    private func requestInitialFocusIfNeeded() {
        guard !didRequestInitialFocus else { return }
        didRequestInitialFocus = true
        
        DispatchQueue.main.async {
            isNameFocused = true
        }
    }

    private var colorGridSection: some View {
        let layout = colorGridLayout
        let pages = palettePages
        let gradients = indicatorGradients
        return ZStack(alignment: .top) {
            VStack(spacing: 0) {
                TabView(selection: $colorPage) {
                    ForEach(0..<pages.count, id: \.self) { pageIndex in
                    ColorGridPage(
                        colors: pages[pageIndex],
                        usedHexes: usedColorSet,
                        cellSize: layout.cellSize,
                        columnsCount: layout.columnsCount,
                        columnSpacing: layout.columnSpacing,
                        rowSpacing: layout.rowSpacing,
                        leftPadding: layout.pageHorizontalPadding,
                        rightPadding: layout.pageHorizontalPadding,
                        contentPadding: layout.selectionPadding,
                        selectedColorHex: $viewModel.selectedColorHex,
                            onSelect: { _ in
                                HapticManager.shared.playButtonTap()
                            },
                            onUnavailableTap: { hex in
                                showUsedColorToast(for: hex)
                            }
                        )
                        .frame(maxWidth: .infinity, minHeight: layout.gridHeight, alignment: .top)
                        .tag(pageIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: layout.gridHeight)

                if pages.count > 1 {
                    PageDotsView(currentPage: $colorPage, gradients: gradients)
                        .frame(height: 18)
                        .offset(y: -4)
                }
            }
            .overlay(alignment: .bottom) {
                if let message = toastMessage {
                    let dotsHeight: CGFloat = pages.count > 1 ? 18 : 0
                    Text(message)
                        .lexendFont(10, weight: .semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.9))
                        )
                        .scaleEffect(showToast ? toastScale : 0)
                        .padding(.bottom, dotsHeight + 4)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .allowsHitTesting(false)
                        .offset(y: 24)
                }
            }
        }
    }

    private var colorGridLayout: ColorGridLayout {
        let columnsCount = 7
        let rowsCount = 3
        let overlapColumns = 2
        let columnSpacing: CGFloat = 10
        let rowSpacing: CGFloat = 10
        let outerHorizontalPadding: CGFloat = 12
        let pageHorizontalPadding: CGFloat = 0
        let selectionPadding: CGFloat = 4
        let availableWidth = UIScreen.main.bounds.width
            - (outerHorizontalPadding * 2)
            - (pageHorizontalPadding * 2)
            - (selectionPadding * 2)
        let cellSize = max(0, floor((availableWidth - (columnSpacing * CGFloat(columnsCount - 1))) / CGFloat(columnsCount)))
        let gridHeight = (cellSize * CGFloat(rowsCount)) + (rowSpacing * CGFloat(rowsCount - 1)) + (selectionPadding * 2)
        return ColorGridLayout(
            columnsCount: columnsCount,
            rowsCount: rowsCount,
            overlapColumns: overlapColumns,
            columnSpacing: columnSpacing,
            rowSpacing: rowSpacing,
            cellSize: cellSize,
            gridHeight: gridHeight,
            pageHorizontalPadding: pageHorizontalPadding,
            selectionPadding: selectionPadding
        )
    }

    private var usedColorSet: Set<String> {
        Set(usedColorNamesByHex.keys)
    }

    private var palettePages: [[String]] {
        let defaultHexes = Set(CategoryPalette.defaultHexes.map { $0.normalizedHex })
        return CategoryPalette.basePages.map { page in
            page
                .map { $0.normalizedHex }
                .filter { !defaultHexes.contains($0) }
        }
    }

    private var indicatorGradients: [[Color]] {
        let layout = colorGridLayout
        let pages = palettePages
        var result: [[Color]] = []
        for page in pages {
            guard !page.isEmpty else {
                result.append([Color.black, Color.black])
                continue
            }
            let leftIndex = 0
            let rightIndex = min(page.count - 1, layout.columnsCount - 1)
            let leftHex = page[leftIndex]
            let rightHex = page[rightIndex]
            let leftColor = Color(hex: leftHex).darker(by: 0.2)
            let rightColor = Color(hex: rightHex).darker(by: 0.2)
            result.append([leftColor, rightColor])
        }
        return result
    }

    private func showUsedColorToast(for hex: String) {
        let normalized = hex.normalizedHex
        let names = usedColorNamesByHex[normalized] ?? []
        let message: String
        if names.isEmpty {
            message = "Oops — that color is already taken."
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

private struct ColorGridLayout {
    let columnsCount: Int
    let rowsCount: Int
    let overlapColumns: Int
    let columnSpacing: CGFloat
    let rowSpacing: CGFloat
    let cellSize: CGFloat
    let gridHeight: CGFloat
    let pageHorizontalPadding: CGFloat
    let selectionPadding: CGFloat
}

private struct ColorGridPage: View {
    let colors: [String]
    let usedHexes: Set<String>
    let cellSize: CGFloat
    let columnsCount: Int
    let columnSpacing: CGFloat
    let rowSpacing: CGFloat
    let leftPadding: CGFloat
    let rightPadding: CGFloat
    let contentPadding: CGFloat
    @Binding var selectedColorHex: String?
    let onSelect: (String) -> Void
    let onUnavailableTap: (String) -> Void

    var body: some View {
        return VStack(spacing: 0) {
            GeometryReader { geo in
                let availableWidth = geo.size.width
                let totalSpacing = columnSpacing * CGFloat(columnsCount - 1)
                let computedCell = max(0, floor((availableWidth - totalSpacing) / CGFloat(columnsCount)))
                let gridWidth = (computedCell * CGFloat(columnsCount)) + totalSpacing
                let columns = Array(repeating: GridItem(.fixed(computedCell), spacing: columnSpacing), count: columnsCount)
                ZStack(alignment: .topLeading) {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: rowSpacing) {
                        ForEach(Array(colors.enumerated()), id: \.offset) { _, colorHex in
                            let normalizedHex = colorHex.normalizedHex
                            let isUsed = usedHexes.contains(normalizedHex)
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: colorHex).darker(by: 0.2))
                                    .frame(width: computedCell, height: computedCell)

                                if isUsed {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(.black)
                                        .padding(4)
                                        .background(
                                            Circle()
                                                .fill(.white)
                                        )
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                        .offset(x: 2, y: 2)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard !isUsed else {
                                    onUnavailableTap(colorHex)
                                    return
                                }
                                selectedColorHex = colorHex
                                onSelect(colorHex)
                            }
                        }
                    }
                    .frame(width: gridWidth, alignment: .leading)

                    if let selectedIndex = selectedIndex(in: colors) {
                        let row = selectedIndex / columnsCount
                        let col = selectedIndex % columnsCount
                        let xOffset = CGFloat(col) * (computedCell + columnSpacing)
                        let yOffset = CGFloat(row) * (computedCell + rowSpacing)
                        let outerInset: CGFloat = 4
                        let borderCornerRadius: CGFloat = 8 + outerInset

                        RoundedRectangle(cornerRadius: borderCornerRadius)
                            .strokeBorder(Color.black.opacity(0.7), lineWidth: 2)
                            .frame(width: computedCell + (outerInset * 2), height: computedCell + (outerInset * 2))
                            .offset(x: xOffset - outerInset, y: yOffset - outerInset)
                            .animation(.spring(response: 0.22, dampingFraction: 0.8), value: selectedIndex)
                            .allowsHitTesting(false)
                    }
                }
            }
            
        }
        .padding(.leading, leftPadding + 1 + contentPadding)
        .padding(.trailing, rightPadding + 1 + contentPadding)
        .padding(.vertical, contentPadding)
    }

    private func selectedIndex(in colors: [String]) -> Int? {
        guard let selected = selectedColorHex?.normalizedHex else { return nil }
        return colors.firstIndex(where: { $0.normalizedHex == selected })
    }
}

private struct PageIndicatorView: UIViewRepresentable {
    @Binding var currentPage: Int
    let pageCount: Int

    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = pageCount
        control.currentPage = currentPage
        control.currentPageIndicatorTintColor = .black
        control.pageIndicatorTintColor = .systemGray4
        control.isUserInteractionEnabled = false
        return control
    }

    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.numberOfPages = pageCount
        uiView.currentPage = currentPage
    }
}

private struct PageDotsView: View {
    @Binding var currentPage: Int
    let gradients: [[Color]]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<gradients.count, id: \.self) { index in
                let isActive = index == currentPage
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradients[index],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isActive ? 10 : 8, height: isActive ? 10 : 8)
                    .opacity(isActive ? 1.0 : 0.6)
                    .onTapGesture {
                        currentPage = index
                    }
            }
        }
    }
}

private extension String {
    var normalizedHex: String {
        trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
    }
}

#Preview {
    CreateCategorySheetPreview()
}

private struct CreateCategorySheetPreview: View {
    @State private var viewModel = CategoriesManagerViewModel(startOnHiddenTab: false)

    var body: some View {
        CreateCategorySheet(
            viewModel: viewModel,
            usedColorNamesByHex: [:],
            usedEmojis: [],
            usedEmojiNamesByEmoji: [:],
            onSave: {}
        )
        .padding()
        .background(Color(.systemGray6))
    }
}
