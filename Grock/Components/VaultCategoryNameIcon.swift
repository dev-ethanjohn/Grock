import SwiftUI
import Foundation

struct VaultCategoryNameIcon: View {
    let name: String
    let isSelected: Bool
    let itemCount: Int
    let hasItems: Bool
    let iconText: String?
    let isLocked: Bool
    let action: () -> Void
    
    @State private var opacityBounce: Double = 1.0
    @State private var fillAnimation: CGFloat = 0.0
    @State private var iconScale: Double = 1.0
    
    @Environment(VaultService.self) private var vaultService

    init(
        name: String,
        isSelected: Bool,
        itemCount: Int,
        hasItems: Bool,
        iconText: String?,
        isLocked: Bool = false,
        action: @escaping () -> Void
    ) {
        self.name = name
        self.isSelected = isSelected
        self.itemCount = itemCount
        self.hasItems = hasItems
        self.iconText = iconText
        self.isLocked = isLocked
        self.action = action
    }

    private var groceryCategory: GroceryCategory? {
        GroceryCategory.allCases.first(where: { $0.title == name })
    }
    
    private var baseColor: Color {
        // PRIORITY 1: Check if there's a custom override in Vault
        if let customCategory = vaultService.getCategory(named: name),
           let hex = customCategory.colorHex {
            return Color(hex: hex)
        }
        
        // PRIORITY 2: Default GroceryCategory color
        if let groceryCategory {
            return groceryCategory.pastelColor
        }
        
        // PRIORITY 3: Fallback generated color
        return name.generatedPastelColor
    }
    
    private var resolvedIconText: String {
        if let iconText, !iconText.isEmpty { return iconText }
        if let groceryCategory { return groceryCategory.emoji }
        return String(name.prefix(1)).uppercased()
    }
    
    private var iconFontSize: CGFloat {
        if groceryCategory != nil { return 24 }
        return isAlphabeticIcon ? 18 : 24
    }

    private var isAlphabeticIcon: Bool {
        resolvedIconText.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
    }

    private var iconOpacity: Double {
        return hasItems ? opacityBounce : 0.3
    }
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            RadialGradient(
                                colors: [
                                    baseColor.darker(by: 0.07).saturated(by: 0.03),
                                    baseColor.darker(by: 0.15).saturated(by: 0.05),
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: fillAnimation * 30
                            )
                        )
                        .overlay {
                            if !isLocked {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black.opacity(0.6), lineWidth: 0.5)
                            }
                        }

                        .frame(width: 42, height: 42)
                        .scaleEffect(iconScale)
                    
                    Text(resolvedIconText)
                        .font(.system(size: iconFontSize, weight: isAlphabeticIcon ? .bold : .regular))
                        .frame(width: 42, height: 42)
                        .scaleEffect(iconScale)
                }
                .grayscale(isLocked ? 1 : 0)
                .opacity(iconOpacity)
                .overlay {
                    if isLocked {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.7))
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    if isLocked {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 20, height: 20)
                            Text("💎")
                                .font(.system(size: 10))
                        }
                        .offset(x: 3, y: 3)
                        .allowsHitTesting(false)
                    }
                }
                
                if itemCount > 0 {
                    Text("\(itemCount)")
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .offset(x: 2, y: -2)
                        .background(.white)
                        .clipShape(Capsule())
                        .transition(.scale(scale: 0.2, anchor: .topTrailing))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemCount)
                }

            }
            .padding(2)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemCount > 0)
        }
        .onChange(of: hasItems) { _, newValue in
            guard !isLocked else { return }
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    opacityBounce = 0.9
                    fillAnimation = 0.3
                    iconScale = 0.95
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        opacityBounce = 1.08
                        fillAnimation = 1.1
                        iconScale = 1.06
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        opacityBounce = 1.0
                        fillAnimation = 1.0
                        iconScale = 1.0
                    }
                }
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    opacityBounce = 0.4
                    fillAnimation = 0.0
                    iconScale = 0.97
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        iconScale = 1.0
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
