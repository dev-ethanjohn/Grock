import SwiftUI
import Observation
import UIKit

struct CreateCategorySheet: View {
    @Bindable var viewModel: CategoriesManagerViewModel
    let onSave: () -> Void
    @FocusState private var isNameFocused: Bool
    @State private var didRequestInitialFocus = false
    @State private var colorPage = 0

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
                Button(action: {
                    viewModel.showEmojiPicker = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.selectedColorHex != nil ? Color(hex: viewModel.selectedColorHex!).darker(by: 0.2) : Color.clear)

                        if viewModel.selectedColorHex == nil {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        }

                        if !viewModel.newCategoryEmoji.isEmpty {
                            Text(viewModel.newCategoryEmoji)
                                .font(.system(size: 24))
                        } else if let first = viewModel.newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).first {
                            Text(String(first).uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.black)
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.gray)
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

            if let createCategoryError = viewModel.createCategoryError {
                Text(createCategoryError)
                    .lexendFont(12, weight: .medium)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)

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
        return VStack(spacing: 4) {
            TabView(selection: $colorPage) {
                ForEach(0..<pages.count, id: \.self) { pageIndex in
                    ColorGridPage(
                        colors: pages[pageIndex],
                        defaultHexes: defaultColorSet,
                        cellSize: layout.cellSize,
                        columnsCount: layout.columnsCount,
                        columnSpacing: layout.columnSpacing,
                        rowSpacing: layout.rowSpacing,
                        leftPadding: pageIndex == 0 ? 0 : layout.pageHorizontalPadding,
                        rightPadding: layout.pageHorizontalPadding,
                        selectedColorHex: $viewModel.selectedColorHex,
                        onSelect: { _ in
                            HapticManager.shared.playButtonTap()
                        }
                    )
                    .frame(maxWidth: .infinity, minHeight: layout.gridHeight, alignment: .top)
                    .tag(pageIndex)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: layout.gridHeight)
            .padding(.vertical, 2)

            if pages.count > 1 {
                PageDotsView(currentPage: $colorPage, gradients: gradients)
                    .frame(height: 18)
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
        let pageHorizontalPadding: CGFloat = 4
        let availableWidth = UIScreen.main.bounds.width
            - (outerHorizontalPadding * 2)
            - (pageHorizontalPadding * 2)
        let cellSize = max(0, floor((availableWidth - (columnSpacing * CGFloat(columnsCount - 1))) / CGFloat(columnsCount)))
        let gridHeight = (cellSize * CGFloat(rowsCount)) + (rowSpacing * CGFloat(rowsCount - 1))
        return ColorGridLayout(
            columnsCount: columnsCount,
            rowsCount: rowsCount,
            overlapColumns: overlapColumns,
            columnSpacing: columnSpacing,
            rowSpacing: rowSpacing,
            cellSize: cellSize,
            gridHeight: gridHeight,
            pageHorizontalPadding: pageHorizontalPadding
        )
    }

    private var defaultColorSet: Set<String> {
        Set(CategoryPalette.defaultHexes.map { $0.normalizedHex })
    }

    private var palettePages: [[String]] {
        CategoryPalette.pages
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
}

private struct ColorGridPage: View {
    let colors: [String]
    let defaultHexes: Set<String>
    let cellSize: CGFloat
    let columnsCount: Int
    let columnSpacing: CGFloat
    let rowSpacing: CGFloat
    let leftPadding: CGFloat
    let rightPadding: CGFloat
    @Binding var selectedColorHex: String?
    let onSelect: (String) -> Void

    var body: some View {
        return VStack(spacing: 0) {
            GeometryReader { geo in
                let availableWidth = geo.size.width
                let totalSpacing = columnSpacing * CGFloat(columnsCount - 1)
                let computedCell = max(0, floor((availableWidth - totalSpacing) / CGFloat(columnsCount)))
                let columns = Array(repeating: GridItem(.fixed(computedCell), spacing: columnSpacing), count: columnsCount)
                LazyVGrid(columns: columns, spacing: rowSpacing) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { _, colorHex in
                        let normalizedHex = colorHex.normalizedHex
                        let isSelected = selectedColorHex?.normalizedHex == normalizedHex
                        let isDefault = defaultHexes.contains(normalizedHex)
                        Button(action: {
                            selectedColorHex = colorHex
                            onSelect(colorHex)
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: colorHex).darker(by: 0.2))
                                    .frame(width: computedCell, height: computedCell)

                                if isDefault {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.black)
                                        .padding(4)
                                        .background(
                                            Circle()
                                                .fill(.white)
                                        )
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                        .padding(2)
                                }

                                if isSelected {
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color.black.opacity(0.7), lineWidth: 2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
        }
        .padding(.leading, leftPadding + 1)
        .padding(.trailing, rightPadding + 1)
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
            onSave: {}
        )
        .padding()
        .background(Color(.systemGray6))
    }
}
