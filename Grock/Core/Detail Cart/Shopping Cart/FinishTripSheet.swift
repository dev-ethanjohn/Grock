import SwiftUI

struct FinishTripSheet: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    @State private var detent: PresentationDetent = .medium
    
    // Computed properties
    private var cartInsights: CartInsights {
        vaultService.getCartInsights(cart: cart)
    }
    
    private var fulfilledCount: Int {
        cart.cartItems.filter { $0.isFulfilled }.count
    }
    
    private var skippedCount: Int {
        cart.cartItems.filter { $0.isSkippedDuringShopping }.count
    }
    
    private var addedDuringShoppingCount: Int {
        cart.cartItems.filter { $0.addedDuringShopping || $0.isShoppingOnlyItem }.count
    }
    
    private var totalSpent: Double {
        cart.totalSpent
    }
    
    // The cart's budget
    private var cartBudget: Double {
        cart.budget
    }
    
    // Difference between actual spent and budget
    private var budgetDifference: Double {
        totalSpent - cartBudget
    }
    
    private var differenceText: String {
        let difference = abs(budgetDifference)
        
        #if DEBUG
        print("🧮 FinishTripSheet Debug:")
        print("   totalSpent: \(totalSpent)")
        print("   cartBudget: \(cartBudget)")
        print("   budgetDifference: \(budgetDifference)")
        print("   |budgetDifference|: \(difference)")
        #endif
        
        if budgetDifference > 0.01 {
            // Over budget by more than 1 cent
            return "₱\(String(format: "%.0f", difference)) over your budget"
        } else if budgetDifference < -0.01 {
            // Under budget by more than 1 cent
            return "₱\(String(format: "%.0f", difference)) under your budget"
        } else {
            // Within 1 cent of budget - considered as on budget
            return "Exactly on budget"
        }
    }
    
    private var differenceColor: Color {
        if budgetDifference > 0.01 {
            return Color(hex: "FA003F") // Red for over budget
        } else if budgetDifference < -0.01 {
            return Color(hex: "4CAF50") // Green for under budget
        } else {
            return Color(hex: "666") // Gray for on budget
        }
    }
    
    private var emojiForDifference: String {
        if budgetDifference < -0.01 {
            return "🎉" // Celebration for under budget
        } else if budgetDifference > 0.01 {
            return "📈" // Neutral for over budget
        } else {
            return "🎯" // Bullseye for on budget
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Big number section
            VStack(spacing: 8) {
                Text("How did your shopping go?")
                    .lexendFont(20, weight: .semibold)
                    .foregroundColor(Color(hex: "231F30"))
                    .padding(.top, 32)
                
                Text(totalSpent.formattedCurrency)
                    .lexendFont(48, weight: .bold)
                    .foregroundColor(Color(hex: "231F30"))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: totalSpent)
                
                HStack(spacing: 4) {
                    Text(emojiForDifference)
                        .font(.system(size: 16))
                    
                    Text(differenceText)
                        .lexendFont(16)
                        .foregroundColor(differenceColor)
                }
                .padding(.bottom, 32)
            }
            
            // Separator
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 0.5)
                .foregroundColor(Color(hex: "999").opacity(0.5))
                .padding(.horizontal)
            
            // Three pills summary
            HStack(spacing: 12) {
                StatPill(
                    emoji: "✅",
                    count: fulfilledCount,
                    label: "fulfilled"
                )
                
                StatPill(
                    emoji: "⏭",
                    count: skippedCount,
                    label: "skipped"
                )
                
                StatPill(
                    emoji: "🆕",
                    count: addedDuringShoppingCount,
                    label: "added"
                )
            }
            .padding(.vertical, 28)
            
            // Budget context (optional - shows budget amount)
            if cartBudget > 0 {
                HStack {
                    Text("Budget: \(cartBudget.formattedCurrency)")
                        .lexendFont(14)
                        .foregroundColor(Color(hex: "666"))
                    
                    Spacer()
                    
                    Text("Remaining: \(max(0, cartBudget - totalSpent).formattedCurrency)")
                        .lexendFont(14, weight: .medium)
                        .foregroundColor(cartBudget - totalSpent >= 0 ? Color(hex: "4CAF50") : Color(hex: "FA003F"))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            
            // Done button
            VStack(spacing: 12) {
                Button(action: {
                    // Complete shopping and dismiss
                    vaultService.completeShopping(cart: cart)
                    dismiss()
                }) {
                    Text("Done")
                        .lexendFont(18, weight: .semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(50)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            
            Spacer()
        }
        .presentationDetents([.medium], selection: $detent)
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .interactiveDismissDisabled(false) // Allow dismissal
        .background(Color.white)
    }
}

// MARK: - Stat Pill Component
private struct StatPill: View {
    let emoji: String
    let count: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text(emoji)
                    .font(.system(size: 16))
                
                Text("\(count)")
                    .lexendFont(18, weight: .semibold)
            }
            
            Text(label)
                .lexendFont(12)
                .foregroundColor(Color(hex: "666"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F7F2ED"))
        )
    }
}

