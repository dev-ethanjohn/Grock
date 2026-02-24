import Foundation
import SwiftUI

struct CategoryTabsModel: Identifiable {
    let id: Tab
    var size: CGSize = .zero
    var minX: CGFloat = .zero

    enum Tab: String, CaseIterable {
        case shown = "My Bar"
        case hidden = "Archive"
    }
}

enum CategoriesManagerNavigationDirection {
    case left, right, none
}

enum CategoriesManagerEmojiLibrary {
    static let top100: [String] = [
        "😀","😃","😄","😁","😆","😅","😂","🤣","😊","😇",
        "🙂","🙃","😉","😌","😍","🥰","😘","😗","😙","😚",
        "😋","😛","😝","😜","🤪","🤨","🧐","🤓","😎","🥸",
        "🤩","😏","😒","😞","😔","😟","😕","🙁","☹️","😣",
        "😖","😫","😩","🥺","😢","😭","😤","😠","😡","🤬",
        "🤯","😳","🥵","🥶","😱","😨","😰","😥","😓","🤗",
        "🤔","🤭","🤫","🤥","😶","😐","😑","😬","🙄","😯",
        "😦","😧","😮","😲","🥱","😴","🤤","😪","😵","🤐",
        "🥴","🤢","🤮","🤧","😷","🤒","🤕","🤑","🤠","😈",
        "👿","🤡","👻","💀","☠️","👽","🤖","🎃","😺","😸"
    ]
}
