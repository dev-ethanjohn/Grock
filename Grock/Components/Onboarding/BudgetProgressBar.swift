import SwiftUI

//struct BudgetProgressBar: View {
//    let cart: Cart
//    let animatedBudget: Double
//    let budgetProgressColor: Color
//    let progressWidth: (CGFloat) -> CGFloat
//    
//    @State private var currentProgressWidth: CGFloat = 0
//    
//    var body: some View {
//        GeometryReader { geometry in
//            let rawPillWidth = progressWidth(geometry.size.width)
//            let pillWidth = max(0, min(rawPillWidth, geometry.size.width))
//            let minWidthForInternalText: CGFloat = 80
//            
//            let visualPillWidth = max(20, pillWidth)
//            
//            ZStack(alignment: .leading) {
//                // Background capsule
//                Capsule()
//                    .fill(Color.white)
//                    .frame(height: 20)
//                    .overlay(
//                        Capsule()
//                            .stroke(Color(hex: "cacaca"), lineWidth: 1)
//                    )
//
//                // Progress capsule with minimum width
//                Capsule()
//                    .fill(budgetProgressColor)
//                    .frame(width: currentProgressWidth, height: 22) // Use animated width
//                    .overlay(
//                        Capsule()
//                            .stroke(.black, lineWidth: 1)
//                    )
//                    .onAppear {
//                        currentProgressWidth = visualPillWidth
//                    }
//                    .onChange(of: visualPillWidth) { oldValue, newValue in
//                        withAnimation(.easeInOut(duration: 0.3)) {
//                            currentProgressWidth = newValue
//                        }
//                    }
//                
//                // Text overlay
//                BudgetProgressText(
//                    cart: cart,
//                    budgetProgressColor: budgetProgressColor,
//                    pillWidth: currentProgressWidth, // Use animated width
//                    minWidthForInternalText: minWidthForInternalText
//                )
//            }
//        }
//        .frame(height: 22)
//    }
//}
struct BudgetProgressBar: View {
    let cart: Cart
    let animatedBudget: Double
    let budgetProgressColor: Color
    let progressWidth: (CGFloat) -> CGFloat
    
    @State private var currentProgressWidth: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            let rawPillWidth = progressWidth(geometry.size.width)
            let pillWidth = max(0, min(rawPillWidth, geometry.size.width))
            let minWidthForInternalText: CGFloat = 80
            let visualPillWidth = max(20, pillWidth)
            
            ZStack(alignment: .leading) {
                // Background capsule - static
                Capsule()
                    .fill(Color.white)
                    .frame(height: 20)
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "cacaca"), lineWidth: 1)
                    )

                // Progress capsule - animated with .linear for smoother animation
                Capsule()
                    .fill(budgetProgressColor)
                    .frame(width: currentProgressWidth, height: 22)
                    .overlay(
                        Capsule()
                            .stroke(.black, lineWidth: 1)
                    )
                
                // Text overlay
                BudgetProgressText(
                    cart: cart,
                    budgetProgressColor: budgetProgressColor,
                    pillWidth: currentProgressWidth,
                    minWidthForInternalText: minWidthForInternalText
                )
            }
            .onAppear {
                currentProgressWidth = visualPillWidth
            }
            .onChange(of: visualPillWidth) { oldValue, newValue in
                // Use .linear animation for smoother width changes
                withAnimation(.linear(duration: 0.3)) {
                    currentProgressWidth = newValue
                }
            }
        }
        .frame(height: 22)
    }
}

//struct BudgetProgressText: View {
//    let cart: Cart
//    let budgetProgressColor: Color
//    let pillWidth: CGFloat
//    let minWidthForInternalText: CGFloat
//    
//    private var safePillWidth: CGFloat {
//        max(0, pillWidth)
//    }
//    
//    var body: some View {
//        Group {
//            if safePillWidth >= minWidthForInternalText {
//                Text(cart.totalSpent.formattedCurrency)
//                    .lexendFont(14, weight: .bold)
//                    .foregroundColor(budgetProgressColor.darker(by: 0.5).saturated(by: 0.4))
//                    .padding(.horizontal, 12)
//                    .frame(width: safePillWidth, height: 22, alignment: .trailing)
//            } else {
//                HStack(spacing: 8) {
//                    Capsule()
//                        .fill(budgetProgressColor)
//                        .frame(width: safePillWidth, height: 22)
//                        .overlay(
//                            Capsule()
//                                .stroke(.black, lineWidth: 1)
//                        )
//                    
//                    Text(cart.totalSpent.formattedCurrency)
//                        .lexendFont(14, weight: .bold)
//                        .foregroundColor(Color(hex: "007B02"))
//                }
//            }
//        }
//    }
//}
struct BudgetProgressText: View {
    let cart: Cart
    let budgetProgressColor: Color
    let pillWidth: CGFloat
    let minWidthForInternalText: CGFloat
    
    private var textColor: Color {
        budgetProgressColor.darker(by: 0.5).saturated(by: 0.4)
    }
    
    private var safePillWidth: CGFloat {
        max(0, pillWidth)
    }
    
    private var shouldShowTextInside: Bool {
        safePillWidth >= minWidthForInternalText
    }
    
    var body: some View {
        ZStack {
            if shouldShowTextInside {
                Text(cart.totalSpent.formattedCurrency)
                    .lexendFont(14, weight: .bold)
                    .foregroundColor(textColor)
                    .padding(.horizontal, 12)
                    .frame(width: safePillWidth, height: 22, alignment: .trailing)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
            
            if !shouldShowTextInside {
                HStack(spacing: 8) {
                    Capsule()
                        .fill(budgetProgressColor)
                        .frame(width: safePillWidth, height: 22)
                        .overlay(
                            Capsule()
                                .stroke(.black, lineWidth: 1)
                        )
                    
                    Text(cart.totalSpent.formattedCurrency)
                        .lexendFont(14, weight: .bold)
                        .foregroundColor(Color(hex: "007B02"))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: shouldShowTextInside)
    }
}


//#Preview {
//    BudgetProgressBar(
//        cart: Cart(
//            name: "Hello",
//            budget: 100.0,
//            totalSpent: 75.0
//        ),
//        budgetProgressColor: .green,
//        progressWidth: { width in
//            return width * 0.7
//        }
//    )
//    .padding()
//}
