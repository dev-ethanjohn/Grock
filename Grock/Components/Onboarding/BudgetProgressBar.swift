import SwiftUI

struct FluidBudgetPillView: View {
    let cart: Cart
    let animatedBudget: Double
    let onBudgetTap: (() -> Void)?
    let hasBackgroundImage: Bool
    let isHeader: Bool // 👈 New parameter to identify if it's in header
    
    @Environment(VaultService.self) private var vaultService
    @Namespace private var animationNamespace
    @State private var pillWidth: CGFloat = 0
    
    private var progress: Double {
        guard animatedBudget > 0 else { return 0 }
        let spent = cart.totalSpent
        return min(spent / animatedBudget, 1.0)
    }
    
    private var budgetProgressColor: Color {
        let progress = self.progress
        if progress < 0.7 {
            return Color(hex: "98F476")
        } else if progress < 0.9 {
            return Color(hex: "F4B576")
        } else {
            return Color(hex: "F47676")
        }
    }
    
    // Text color for text INSIDE the pill
    private var insidePillTextColor: Color {
        // Text inside the green pill should be black (or dark) for contrast
        return budgetProgressColor.darker(by: 0.5).saturated(by: 0.4)
    }
    
    // Text color for text OUTSIDE the pill
    private var outsidePillTextColor: Color {
        if isHeader {
            return Color(hex: "007B02") // Header always uses dark green (on white background)
        } else if hasBackgroundImage {
            return .white // White on background images (HomeCartRowView)
        } else {
            return Color(hex: "007B02") // Dark green on solid color backgrounds
        }
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
    
    private var shouldShowTextInside: Bool {
        pillWidth >= 100
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            GeometryReader { geometry in
                let targetWidth = CGFloat(progress) * geometry.size.width
                let visualWidth = max(20, targetWidth)
                
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 20)
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "cacaca"), lineWidth: 0.3)
                        )
                    
                    // Animated progress fill with gradient
                    if shouldShowTextInside && pillWidth > 30 {
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
                            .frame(width: pillWidth, height: 22)
                            .overlay(
                                Capsule()
                                    .stroke(.black, lineWidth: 1)
                            )
                            .matchedGeometryEffect(id: "pillFill", in: animationNamespace)
                    }
                    
                    HStack(spacing: 8) {
                        if shouldShowTextInside && pillWidth > 30 {
                            // Text INSIDE the pill
                            Text(cart.totalSpent.formattedCurrency)
                                .lexendFont(14, weight: .bold)
                                .foregroundColor(insidePillTextColor)
                                .matchedGeometryEffect(id: "amount", in: animationNamespace)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.95)),
                                    removal: .move(edge: .trailing)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.95))
                                ))
                                .frame(maxWidth: pillWidth - 24, alignment: .trailing)
                                .padding(.leading, 12)
                        }
                        
                        if !shouldShowTextInside || pillWidth < 40 {
                            // Mini pill when too narrow
                            Capsule()
                                .fill(budgetProgressColor)
                                .frame(width: max(20, pillWidth), height: 22)
                                .overlay(
                                    Capsule()
                                        .stroke(.black, lineWidth: 1)
                                )
                            
                            // Text OUTSIDE the pill
                            Text(cart.totalSpent.formattedCurrency)
                                .lexendFont(14, weight: .bold)
                                .foregroundColor(outsidePillTextColor)
                                .matchedGeometryEffect(id: "amount", in: animationNamespace)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.95)),
                                    removal: .move(edge: .leading)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.95))
                                ))
                        }
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: shouldShowTextInside)
                    .frame(maxWidth: geometry.size.width, alignment: .leading)
                }
                .onAppear {
                    pillWidth = visualWidth
                }
                .onChange(of: visualWidth) { oldValue, newValue in
                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) {
                        pillWidth = newValue
                    }
                }
            }
            .frame(height: 22)
            
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
        }
        .frame(height: 22)
    }
}
