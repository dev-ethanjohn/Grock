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
    let onEdit: (() -> Void)?
    let onTap: () -> Void

    @Environment(VaultService.self) private var vaultService

    init(
        name: String,
        iconText: String,
        isSelected: Bool,
        activeCount: Int,
        hasItems: Bool,
        actionSymbol: String,
        actionEnabled: Bool,
        action: @escaping () -> Void,
        onEdit: (() -> Void)? = nil,
        onTap: @escaping () -> Void
    ) {
        self.name = name
        self.iconText = iconText
        self.isSelected = isSelected
        self.activeCount = activeCount
        self.hasItems = hasItems
        self.actionSymbol = actionSymbol
        self.actionEnabled = actionEnabled
        self.action = action
        self.onEdit = onEdit
        self.onTap = onTap
    }

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

    private var isSystemCategory: Bool {
        groceryCategory != nil
    }

    private var systemBadge: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.black.opacity(0.35))
    }

    var body: some View {
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

            }

            HStack(spacing: 6) {
                Text(name)
                    .lexendFont(14, weight: .medium)
                    .foregroundStyle(.black)
                    .lineLimit(2)
                if isSystemCategory {
                    systemBadge
                }
            }

            Spacer()

            HStack(spacing: 10) {
                if let onEdit, !isSystemCategory {
                    Button(action: {
                        onEdit()
                    }) {
                        Text("Edit")
                            .lexendFont(12, weight: .semibold)
                            .foregroundStyle(Color.black.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.06))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                            )
                            .fixedSize()
                    }
                    .buttonStyle(.plain)
                }

                Button(action: {
                    guard actionEnabled else { return }
                    action()
                }) {
                    Image(systemName: actionSymbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .allowsHitTesting(actionEnabled)
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
        .contentShape(.rect)
        .onTapGesture {
            onTap()
        }
    }
}
