import SwiftUI
import UIKit

struct FluidBudgetPillView: View {
    let cart: Cart
    let animatedBudget: Double
    let onBudgetTap: (() -> Void)?
    let hasBackgroundImage: Bool
    let isHeader: Bool // 👈 New parameter to identify if it's in header
    var customTotalSpent: Double? = nil // 👈 Optional custom spent amount
    var customIndicatorSpent: Double? = nil
    
    @Environment(VaultService.self) private var vaultService
    @Namespace private var animationNamespace
    @State private var pillWidth: CGFloat = 0
    @State private var didSetInitialPillWidth = false
    
    private var displayedSpent: Double {
        customTotalSpent ?? cart.totalSpent
    }
    
    private var progress: Double {
        guard animatedBudget > 0 else { return 0 }
        let spent = displayedSpent
        return min(spent / animatedBudget, 1.0)
    }
    
    private var indicatorProgress: Double {
        guard animatedBudget > 0 else { return 0 }
        let spent = customIndicatorSpent ?? displayedSpent
        return min(spent / animatedBudget, 1.0)
    }
    
    private var budgetProgressColor: Color {
        let clampedProgress = min(max(self.progress, 0), 1)
        let safe = UIColor(Color.Grock.budgetSafe)
        let warning = UIColor(Color.Grock.budgetWarning)
        let over = UIColor(Color.Grock.budgetOver)
        
        if clampedProgress <= 0.7 {
            return Color(safe)
        } else if clampedProgress <= 0.9 {
            let ratio = CGFloat((clampedProgress - 0.7) / 0.2)
            return mixedColor(from: safe, to: warning, ratio: ratio)
        } else {
            let ratio = CGFloat((clampedProgress - 0.9) / 0.1)
            return mixedColor(from: warning, to: over, ratio: ratio)
        }
    }
    
    // Text color for text INSIDE the pill
    private var insidePillTextColor: Color {
        // Darker variant of the small pill background color
        budgetProgressColor.darker(by: 0.4).saturated(by: 0.2)
    }
    
    // Text color for text OUTSIDE the pill
    private var outsidePillTextColor: Color {
        // Darker variant of the small pill background color
        budgetProgressColor.darker(by: 0.4).saturated(by: 0.2)
    }
    
    // Budget button text color
    private var budgetButtonTextColor: Color {
        if isHeader {
            return .black // Header has white background, so black text
        } else if hasBackgroundImage {
            return .white // White on background images
        } else {
            return .black // Black on solid color backgrounds
        }
    }

    private var trackBorderColor: Color {
        isHeader ? Color(hex: "cacaca") : .black
    }

    private var trackBorderWidth: CGFloat {
        0.5
    }
    
    private var hasBudget: Bool {
        animatedBudget > 0
    }
    
    var body: some View {
        let showsIndicator = customIndicatorSpent != nil
        let barHeight: CGFloat = 22
        let totalHeight: CGFloat = showsIndicator ? 46 : barHeight
        
        HStack(alignment: .bottom, spacing: 16) {
            GeometryReader { geometry in
                let targetWidth = CGFloat(progress) * geometry.size.width
                let indicatorWidth = CGFloat(indicatorProgress) * geometry.size.width
                let visualWidth = max(20, targetWidth)
                let effectivePillWidth = didSetInitialPillWidth ? pillWidth : visualWidth
                let shouldShowTextInside = effectivePillWidth >= 100
                let barTopOffset = max(0, geometry.size.height - barHeight)
                
                ZStack(alignment: .topLeading) {
                    if let customIndicatorSpent {
                        let clampedCenterX = min(max(indicatorWidth, 70), geometry.size.width - 70)
                        Text("you spent \(customIndicatorSpent.formattedCurrency)")
                            .lexendFont(12)
                            .foregroundColor(Color.Grock.textSecondary)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.25), value: customIndicatorSpent)
                            .fixedSize()
                            .position(x: clampedCenterX, y: 6)
                    }
                    
                    // Background track
                    Capsule()
                        .fill(Color.white)
                        .frame(height: 20)
                        .overlay(
                            Capsule()
                                .stroke(trackBorderColor, lineWidth: trackBorderWidth)
                        )
                        .offset(y: barTopOffset + 1)
                    
                    // Animated progress fill with gradient
                    if shouldShowTextInside && effectivePillWidth > 30 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        budgetProgressColor,
                                        budgetProgressColor.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: effectivePillWidth, height: 22)
                            .overlay(
                                Capsule()
                                    .stroke(.black, lineWidth: 1)
                            )
                            .matchedGeometryEffect(id: "pillFill", in: animationNamespace)
                            .offset(y: barTopOffset)
                            .animation(.easeInOut(duration: 0.28), value: progress)
                    }
                    
                    if customIndicatorSpent != nil {
                        let clampedX = max(0, min(geometry.size.width, indicatorWidth)) - 1
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 2, height: barHeight)
                            .offset(x: clampedX, y: barTopOffset)
                        
                        Circle()
                            .fill(Color.black)
                            .frame(width: 6, height: 6)
                            .offset(x: clampedX - 2, y: barTopOffset - 3)
                    }
                    
                    HStack(spacing: 8) {
                        if shouldShowTextInside && effectivePillWidth > 30 {
                            // Text INSIDE the pill
                            Text(displayedSpent.formattedCurrency)
                                .lexendFont(14, weight: .bold)
                                .foregroundColor(insidePillTextColor)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.25), value: displayedSpent)
                                .matchedGeometryEffect(id: "amount", in: animationNamespace)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.95)),
                                    removal: .move(edge: .trailing)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.95))
                                ))
                                .frame(width: effectivePillWidth - 24, height: barHeight, alignment: .trailing)
                                .padding(.leading, 12)
                                .offset(y: barTopOffset)
                        }
                        
                        if !shouldShowTextInside || effectivePillWidth < 40 {
                            // Mini pill when too narrow
                            Capsule()
                                .fill(budgetProgressColor)
                                .frame(width: max(20, effectivePillWidth), height: 22)
                                .overlay(
                                    Capsule()
                                        .stroke(.black, lineWidth: 1)
                                )
                                .offset(y: barTopOffset)
                                .animation(.easeInOut(duration: 0.28), value: progress)
                            
                            // Text OUTSIDE the pill
                            Text(displayedSpent.formattedCurrency)
                                .lexendFont(14, weight: .bold)
                                .foregroundColor(outsidePillTextColor)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.25), value: displayedSpent)
                                .matchedGeometryEffect(id: "amount", in: animationNamespace)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.95)),
                                    removal: .move(edge: .leading)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.95))
                                ))
                                .frame(height: barHeight)
                                .offset(y: barTopOffset)
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: shouldShowTextInside)
                    .frame(maxWidth: geometry.size.width, alignment: .leading)
                }
                .onAppear {
                    pillWidth = visualWidth
                    didSetInitialPillWidth = true
                }
                .onChange(of: visualWidth) { oldValue, newValue in
                    guard didSetInitialPillWidth else {
                        pillWidth = newValue
                        didSetInitialPillWidth = true
                        return
                    }
                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) {
                        pillWidth = newValue
                    }
                }
            }
            .frame(height: totalHeight)
            
            // Budget amount button
            Button(action: {
                onBudgetTap?()
            }) {
                Text(animatedBudget.formattedCurrency)
                    .lexendFont(14, weight: .bold)
                    .foregroundColor(budgetButtonTextColor) // 👈 Use computed color
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: animatedBudget)
            }
            .buttonStyle(.plain)
            .frame(height: barHeight)
        }
        .frame(height: totalHeight)
    }

    private func mixedColor(from start: UIColor, to end: UIColor, ratio: CGFloat) -> Color {
        let clampedRatio = min(max(ratio, 0), 1)
        
        var r1: CGFloat = 0
        var g1: CGFloat = 0
        var b1: CGFloat = 0
        var a1: CGFloat = 0
        var r2: CGFloat = 0
        var g2: CGFloat = 0
        var b2: CGFloat = 0
        var a2: CGFloat = 0
        
        guard start.getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              end.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else {
            return Color(end)
        }
        
        let red = r1 + (r2 - r1) * clampedRatio
        let green = g1 + (g2 - g1) * clampedRatio
        let blue = b1 + (b2 - b1) * clampedRatio
        let alpha = a1 + (a2 - a1) * clampedRatio
        
        return Color(UIColor(red: red, green: green, blue: blue, alpha: alpha))
    }
}
