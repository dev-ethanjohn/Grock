import SwiftUI

struct CategoryTooltipPopover: View {
    var body: some View {
            HStack(spacing: 4) {
                Text("Select category")
                    .fuzzyBubblesFont(10, weight: .bold)
               
                Image(systemName: "arrow.down")
                    .font(.system(size: 7, weight: .black))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.2, blue: 0.25),
                        Color(red: 0.15, green: 0.15, blue: 0.2)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 5)
    }
}

#Preview {
    CategoryTooltipPopover()
        .scaleEffect(2.5)
}
