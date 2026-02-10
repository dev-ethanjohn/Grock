import SwiftUI
import Observation

struct EditCategorySheet: View {
    @Bindable var viewModel: CategoriesManagerViewModel
    let usedColorNamesByHex: [String: [String]]
    let usedEmojis: Set<String>
    let usedEmojiNamesByEmoji: [String: [String]]
    let existingCategoryKeys: Set<String>
    let categoryName: String
    let deleteMessage: String?
    let onSave: () -> Void
    let onDelete: () -> Void

    var body: some View {
        CreateCategorySheet(
            viewModel: viewModel,
            usedColorNamesByHex: usedColorNamesByHex,
            usedEmojis: usedEmojis,
            usedEmojiNamesByEmoji: usedEmojiNamesByEmoji,
            existingCategoryKeys: existingCategoryKeys,
            editingCategoryName: categoryName,
            deleteMessage: deleteMessage,
            onSave: onSave,
            onDelete: onDelete
        )
    }
}

#Preview {
    EditCategorySheetPreview()
}

private struct EditCategorySheetPreview: View {
    @State private var viewModel: CategoriesManagerViewModel = {
        let model = CategoriesManagerViewModel(startOnHiddenTab: false)
        model.newCategoryName = "Snacks"
        model.newCategoryEmoji = "🍿"
        model.selectedEmoji = "🍿"
        model.selectedColorHex = "FFD633"
        return model
    }()

    var body: some View {
        EditCategorySheet(
            viewModel: viewModel,
            usedColorNamesByHex: [:],
            usedEmojis: [],
            usedEmojiNamesByEmoji: [:],
            existingCategoryKeys: [],
            categoryName: "Snacks",
            deleteMessage: "This will remove the category from your list.",
            onSave: {},
            onDelete: {}
        )
        .padding()
        .background(Color(.systemGray6))
    }
}
