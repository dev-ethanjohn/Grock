import SwiftUI

struct CategoryManagerRow: View {
    let name: String
    let iconText: String
    let isSelected: Bool
    let hasItems: Bool
    let actionSymbol: String
    let actionEnabled: Bool
    let action: () -> Void
    let isFeatureLocked: Bool
    let onEdit: (() -> Void)?
    let onTap: () -> Void

    init(
        name: String,
        iconText: String,
        isSelected: Bool,
        hasItems: Bool,
        actionSymbol: String,
        actionEnabled: Bool,
        action: @escaping () -> Void,
        isFeatureLocked: Bool = false,
        onEdit: (() -> Void)? = nil,
        onTap: @escaping () -> Void
    ) {
        self.name = name
        self.iconText = iconText
        self.isSelected = isSelected
        self.hasItems = hasItems
        self.actionSymbol = actionSymbol
        self.actionEnabled = actionEnabled
        self.action = action
        self.isFeatureLocked = isFeatureLocked
        self.onEdit = onEdit
        self.onTap = onTap
    }

    private var groceryCategory: GroceryCategory? {
        GroceryCategory.allCases.first(where: { $0.title == name })
    }

    private var isSystemCategory: Bool {
        groceryCategory != nil
    }

    private var systemBadge: some View {
        Text("Default")
            .lexendFont(8, weight: .bold)
            .foregroundStyle(Color.black.opacity(0.52))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.05))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .fixedSize()
            .accessibilityLabel("Default category")
    }

    var body: some View {
        HStack(spacing: 10) {
            VaultCategoryNameIcon(
                name: name,
                isSelected: isSelected,
                itemCount: 0,
                hasItems: hasItems,
                iconText: iconText,
                isLocked: isFeatureLocked,
                action: {}
            )
            .frame(width: 46, height: 46)
            .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 3) {
                if isSystemCategory {
                    systemBadge
                }
                Text(name)
                    .lexendFont(14, weight: .medium)
                    .foregroundStyle(.black)
                    .lineLimit(2)
            }

            Spacer()

            HStack(spacing: 10) {
                if let onEdit, !isSystemCategory {
                    Button(action: {
                        onEdit()
                    }) {
                        Text("Edit")
                            .lexendFont(12, weight: .semibold)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(hex: "FFC94A"))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(.black, lineWidth: 1)
                            )
                            .fixedSize()
                    }
                    .buttonStyle(.plain)
                    .saturation(isFeatureLocked ? 0 : 1)
                    .opacity(isFeatureLocked ? 0.5 : 1)
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
