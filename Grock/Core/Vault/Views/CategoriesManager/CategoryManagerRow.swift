import SwiftUI

struct CategoryManagerRow: View {
    let name: String
    let iconText: String
    let isSelected: Bool
    let activeCount: Int
    let hasItems: Bool
    let actionSymbol: String
    let actionEnabled: Bool
    let action: () -> Void
    let onTap: () -> Void

    @Environment(VaultService.self) private var vaultService

    private var groceryCategory: GroceryCategory? {
        GroceryCategory.allCases.first(where: { $0.title == name })
    }

    private var displayIcon: String { iconText }

    private var iconFontSize: CGFloat {
        if groceryCategory != nil { return 24 }
        return isAlphabeticIcon ? 18 : 24
    }

    private var isAlphabeticIcon: Bool {
        iconText.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
    }

    private var iconBackground: Color {
        if let customCategory = vaultService.getCategory(named: name),
           let hex = customCategory.colorHex {
            return Color(hex: hex)
        }

        if let groceryCategory {
            return groceryCategory.pastelColor
        }

        return name.generatedPastelColor
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            RadialGradient(
                                colors: [
                                    iconBackground.darker(by: 0.07).saturated(by: 0.03),
                                    iconBackground.darker(by: 0.15).saturated(by: 0.05),
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 42, height: 42)

                    Text(displayIcon)
                        .font(.system(size: iconFontSize, weight: isAlphabeticIcon ? .bold : .regular))
                        .foregroundStyle(.black)
                        .frame(width: 42, height: 42)

                    if activeCount > 0 {
                        Text("\(activeCount)")
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundColor(.black)
                            .offset(x: 2, y: -2)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                }

                Text(name)
                    .lexendFont(14, weight: .medium)
                    .foregroundStyle(.black)
                    .lineLimit(2)

                Spacer()

                Button(action: {
                    guard actionEnabled else { return }
                    action()
                }) {
                    Image(systemName: actionSymbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(actionEnabled)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? .black : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
