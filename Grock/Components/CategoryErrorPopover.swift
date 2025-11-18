import SwiftUI

struct CategoryErrorPopover: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Category is required")
                .fuzzyBubblesFont(10, weight: .bold)
           
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 7, weight: .black))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Color(hex: "#FA003F")
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    CategoryErrorPopover()
        .scaleEffect(2.5)
}


