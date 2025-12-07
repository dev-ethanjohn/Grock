//
//  BudgetProgressBar.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/13/25.
//

import SwiftUI

struct BudgetProgressBar: View {
    let cart: Cart
    let animatedBudget: Double
    let budgetProgressColor: Color
    let progressWidth: (CGFloat) -> CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let rawPillWidth = progressWidth(geometry.size.width)
            let pillWidth = max(0, min(rawPillWidth, geometry.size.width))
            let minWidthForInternalText: CGFloat = 80
            
            let visualPillWidth = max(20, pillWidth)
            
            ZStack(alignment: .leading) {
                // Background capsule
                Capsule()
                    .fill(Color.white)
                    .frame(height: 20)
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "cacaca"), lineWidth: 1)
                    )

                // Progress capsule with minimum width
                Capsule()
                    .fill(budgetProgressColor)
                    .frame(width: visualPillWidth, height: 22)
                    .overlay(
                        Capsule()
                            .stroke(.black, lineWidth: 1)
                    )
                
                // Text overlay
                BudgetProgressText(
                    cart: cart,
                    budgetProgressColor: budgetProgressColor,
                    pillWidth: visualPillWidth,
                    minWidthForInternalText: minWidthForInternalText
                )
            }
        }
        .frame(height: 22)
    }
}

struct BudgetProgressText: View {
    let cart: Cart
    let budgetProgressColor: Color
    let pillWidth: CGFloat
    let minWidthForInternalText: CGFloat
    
    private var safePillWidth: CGFloat {
        max(0, pillWidth)
    }
    
    var body: some View {
        Group {
            if safePillWidth >= minWidthForInternalText {
                Text(cart.totalSpent.formattedCurrency)
                    .lexendFont(14, weight: .bold)
                    .foregroundColor(budgetProgressColor.darker(by: 0.5).saturated(by: 0.4))
                    .padding(.horizontal, 12)
                    .frame(width: safePillWidth, height: 22, alignment: .trailing)
            } else {
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
            }
        }
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
