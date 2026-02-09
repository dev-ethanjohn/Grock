import SwiftUI
import UIKit
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
    var shownScrollOffset: CGFloat = 0
    var hiddenScrollOffset: CGFloat = 0
    var shownScrollViewHeight: CGFloat = 0
    var hiddenScrollViewHeight: CGFloat = 0
    var shownContentHeight: CGFloat = 0
    var hiddenContentHeight: CGFloat = 0


    var backgroundColors: [String]

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
        let hexes = GroceryCategory.allCases.map { $0.pastelHex }
        return hexes.sorted { a, b in
            let ah = hsb(forHex: a)
            let bh = hsb(forHex: b)
            let aKey = ah.map { ($0.s < 0.08 ? 2 + $0.h : $0.h) } ?? 3
            let bKey = bh.map { ($0.s < 0.08 ? 2 + $0.h : $0.h) } ?? 3
            return aKey < bKey
        }
    }

    private static func hsb(forHex hex: String) -> (h: CGFloat, s: CGFloat, b: CGFloat)? {
        let uiColor = UIColor(Color(hex: hex))
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return nil }
        return (h, s, b)
    }
}
