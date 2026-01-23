import SwiftUI

struct AccordionCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    let background: Color
    let accent: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(background.opacity(0.9))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .lexendFont(14, weight: .semibold)
                    .foregroundColor(Color(hex: "231F30"))
                Text(subtitle)
                    .lexendFont(12)
                    .foregroundColor(Color(hex: "666"))
            }
            
            Spacer()
            
            Image(systemName: "chevron.up")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "231F30"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(background.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(background.opacity(0.8), lineWidth: 1)
        )
    }
}

#Preview("AccordionCardView") {
    AccordionCardView(
        icon: "arrow.left.arrow.right",
        title: "What changed (3)",
        subtitle: "Price or quantity differed from plan",
        background: Color(hex: "F0E2FF"),
        accent: Color(hex: "7300DF")
    )
    .padding()
    .background(Color.white)
}
