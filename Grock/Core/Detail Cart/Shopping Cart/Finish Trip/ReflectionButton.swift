import SwiftUI

struct ReflectionButton: View {
    let text: String
    let emoji: String
    @State private var isSelected = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isSelected.toggle()
            }
        }) {
            HStack(spacing: 6) {
                Text(emoji)
                Text(text)
                    .lexendFont(14, weight: .medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.black : Color(hex: "F5F5F5"))
            .foregroundColor(isSelected ? .white : .black)
            .cornerRadius(20)
        }
    }
}

#Preview("ReflectionButton") {
    ReflectionButton(text: "Feeling optimistic", emoji: "🙂")
        .padding()
        .background(Color.white)
}
