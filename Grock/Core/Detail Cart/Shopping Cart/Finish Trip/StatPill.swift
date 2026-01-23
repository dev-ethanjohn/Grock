import SwiftUI

struct StatPill: View {
    let emoji: String
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(emoji)
                    .font(.system(size: 16))
                
                Text("\(count)")
                    .lexendFont(18, weight: .semibold)
            }
            
            Text(label)
                .lexendFont(12)
                .foregroundColor(Color(hex: "666"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F7F2ED"))
        )
    }
}

#Preview("StatPill") {
    HStack {
        StatPill(emoji: "✅", count: 4, label: "Fulfilled")
        StatPill(emoji: "➕", count: 2, label: "Added")
        StatPill(emoji: "🚫", count: 1, label: "Skipped")
    }
    .padding()
    .background(Color.white)
}
