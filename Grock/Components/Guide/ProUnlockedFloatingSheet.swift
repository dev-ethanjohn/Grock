import SwiftUI

struct ProUnlockedFloatingSheet: View {
    var contextualMessage: String?

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("You made a power move 💪")
                .lexendFont(17, weight: .semibold)
                .foregroundStyle(.black)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            if let contextualMessage, !contextualMessage.isEmpty {
                Text(contextualMessage)
                    .lexendFont(13, weight: .regular)
                    .foregroundStyle(.black.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 6)
        )
    }
}

#Preview {
    ZStack {
        Color(hex: "F7F7F7").ignoresSafeArea()
        VStack {
            Spacer()
            ProUnlockedFloatingSheet(
                contextualMessage: "You can now add unlimited stores and compare prices across all of them."
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }
}
