import SwiftUI

struct FinishSheetHeaderView: View {
    let headerSummaryText: String
    let cart: Cart
    let cartBudget: Double
    let totalSpent: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Text(headerSummaryText)
                .fuzzyBubblesFont(18, weight: .bold)
                .foregroundColor(Color(hex: "231F30"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 50)
                .padding(.vertical, 20)
                .padding(.top, 32)
            
            HStack(spacing: 8) {
                FluidBudgetPillView(
                    cart: cart,
                    animatedBudget: cartBudget,
                    onBudgetTap: nil,
                    hasBackgroundImage: false,
                    isHeader: true,
                    customIndicatorSpent: totalSpent
                )
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

#Preview("FinishSheetHeaderView") {
    let previewCart = Cart(name: "Preview Trip", budget: 200)
    return FinishSheetHeaderView(
        headerSummaryText: "You set a $200 plan, and this trip stayed comfortably within it.",
        cart: previewCart,
        cartBudget: 200,
        totalSpent: 80
    )
    .padding()
    .background(Color.white)
}
