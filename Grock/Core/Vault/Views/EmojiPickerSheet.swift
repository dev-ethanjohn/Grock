import SwiftUI

struct EmojiPickerSheet: View {
    @Binding var selectedEmoji: String?
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private var emojiCandidates: [String] {
        CategoriesManagerEmojiLibrary.top100
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Select Emoji")
                .lexendFont(18, weight: .bold)
                .padding(.top, 24)
                .padding(.bottom, 16)
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                    ForEach(emojiCandidates, id: \.self) { emoji in
                        Button(action: {
                            onSelect(emoji)
                        }) {
                            Text(emoji)
                                .font(.system(size: 32))
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedEmoji == emoji ? Color(.systemGray5) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
        }
        .background(Color.white)
    }
}
