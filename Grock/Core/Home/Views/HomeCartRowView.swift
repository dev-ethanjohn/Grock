import SwiftUI
import SwiftData

struct HomeCartRowView: View {
    let cart: Cart
    let vaultService: VaultService?
    
    private var itemCount: Int {
        cart.cartItems.count
    }
    
    private var isOverBudget: Bool {
        cart.totalSpent > cart.budget
    }
    
    // Get unique categories from cart items using VaultService
    //    private var categories: [GroceryCategory] {
    //        var uniqueCategories: Set<GroceryCategory> = []
    //
    //        for cartItem in cart.cartItems {
    //            if let item = vaultService.findItemById(cartItem.itemId),
    //               let itemCategory = vaultService.getCategory(for: item.id),
    //               let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == itemCategory.name }) {
    //                uniqueCategories.insert(groceryCategory)
    //            }
    //        }
    //
    //        return Array(uniqueCategories).sorted(by: { $0.title < $1.title })
    //    }
    
    private var categories: [GroceryCategory] {
        if vaultService == nil {
            // Return mock categories for preview
            return [.freshProduce, .meatsSeafood, .dairyEggs, .bakeryBread]
        }
        
        // Real implementation when vaultService is available
        var uniqueCategories: Set<GroceryCategory> = []
        
        for cartItem in cart.cartItems {
            if let item = vaultService?.findItemById(cartItem.itemId),
               let itemCategory = vaultService?.getCategory(for: item.id),
               let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == itemCategory.name }) {
                uniqueCategories.insert(groceryCategory)
            }
        }
        
        return Array(uniqueCategories).sorted(by: { $0.title < $1.title })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text(cart.name)
                    .lexendFont(18, weight: .semibold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .lexendFont(14, weight: .semibold)
                    .foregroundStyle(Color(hex: "BABABA"))
            }
            
            
            VStack(spacing: 8) {
                HStack(alignment: .center, spacing: 8) {
                    BudgetProgressBar(cart: cart, budgetProgressColor: budgetProgressColor, progressWidth: progressWidth)
                    
                    Text(cart.budget.formattedCurrency)
                        .lexendFont(14, weight: .bold)
                        .foregroundColor(Color(hex: "333"))
                }
                .frame(height: 20)
                
                // Categories
                HStack {
                    if !categories.isEmpty {
                        HStack(spacing: 3) {
                            ForEach(categories, id: \.self) { category in
                                Text(category.emoji)
                                    .font(.system(size: 11))
                                    .frame(width: 20, height: 20)
                                    .background(category.pastelColor)
                                    .cornerRadius(8)
                                    .opacity(0.3)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
         
        }
        .padding()
        .background(Color.white)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "CACACA"), lineWidth: 1)
        ).padding(1)
        
    }
    
    private var budgetProgressColor: Color {
        let progress = cart.totalSpent / cart.budget
        if progress < 0.7 {
            return Color(hex: "98F476")
        } else if progress < 0.9 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        // Handle zero budget case to avoid division by zero
        guard cart.budget > 0 else { return 0 }
        
        let progress = cart.totalSpent / cart.budget
        return CGFloat(min(progress, 1.0)) * totalWidth
    }
}

struct BudgetProgressBar: View {
    let cart: Cart
    let budgetProgressColor: Color
    let progressWidth: (CGFloat) -> CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let rawPillWidth = progressWidth(geometry.size.width)
            let pillWidth = max(0, min(rawPillWidth, geometry.size.width))
            let minWidthForInternalText: CGFloat = 80
            
            // Add minimum visual width (e.g., 8 points)
            let visualPillWidth = max(20, pillWidth) // Always at least 8px wide
            
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
                    pillWidth: visualPillWidth, // Pass the visual width
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


#Preview {
    let mockCart = Cart(
        name: "Tues Brunch",
        budget: 2000.0,
        totalSpent: 654,
        fulfillmentStatus: 0.8144,
        createdAt: Date(),
        status: .planning
    )
    
    // Just pass nil for vaultService - it will use mock categories
    HomeCartRowView(cart: mockCart, vaultService: nil)
        .padding()
        .background(Color.gray.opacity(0.1))
}
