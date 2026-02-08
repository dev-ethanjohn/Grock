import SwiftUI
import Observation

@MainActor
@Observable
final class CategoriesManagerViewModel {
    var newCategoryName = ""
    var newCategoryEmoji = ""
    var createCategoryError: String?
    var draggedCategoryName: String?

    var tabs: [CategoryTabsModel]
    var activeTab: CategoryTabsModel.Tab
    var navigationDirection: CategoriesManagerNavigationDirection = .none
    var progress: CGFloat
    var headerHeight: CGFloat = 0
    var showCategoryPopover: Bool = false
    var selectedEmoji: String? = nil
    var cachedAllCategoryNames: [String] = []
    var selectedColorHex: String? = nil
    var showEmojiPicker: Bool = false
    var shownScrollOffset: CGFloat = 0
    var hiddenScrollOffset: CGFloat = 0
    var shownScrollViewHeight: CGFloat = 0
    var hiddenScrollViewHeight: CGFloat = 0
    var shownContentHeight: CGFloat = 0
    var hiddenContentHeight: CGFloat = 0


    let backgroundColors: [String]

    init(startOnHiddenTab: Bool) {
        self.tabs = [
            .init(id: .shown),
            .init(id: .hidden),
        ]
        let initialTab: CategoryTabsModel.Tab = startOnHiddenTab ? .hidden : .shown
        self.activeTab = initialTab
        self.progress = startOnHiddenTab ? 1 : 0
        self.backgroundColors = CategoriesManagerViewModel.buildBackgroundColors()
    }

    var popoverCanCreate: Bool {
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
    }

    private static func buildBackgroundColors() -> [String] {
        var colors = GroceryCategory.allCases.map { $0.pastelHex }

        let additionalColors = [
            "#E8E8E8", // Light Grey
            "#FFF59D", // Pale Yellow
            "#A5D6A7", // Mint Green
            "#FFCCBC", // Pale Pink
            "#C5E1A5", // Light Lime
            "#9FA8DA", // Periwinkle
            "#F48FB1", // Hot Pink
            "#CCFF90", // Lime Green
            "#EF5350", // Coral Red
            "#FFAB91", // Salmon
            "#FF8A65", // Peach
            "#4FC3F7", // Cyan
            "#42A5F5", // Blue
            "#AB47BC"  // Purple
        ]

        colors.append(contentsOf: additionalColors)

        var seen = Set<String>()
        var unique: [String] = []
        for color in colors {
            let normalized = color.replacingOccurrences(of: "#", with: "").uppercased()
            if !seen.contains(normalized) {
                seen.insert(normalized)
                unique.append(color)
            }
        }
        return unique
    }
}
