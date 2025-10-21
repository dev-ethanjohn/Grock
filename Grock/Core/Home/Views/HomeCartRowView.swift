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
        .padding(16)
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
            let pillWidth = max(progressWidth(geometry.size.width), 20)
            let minWidthForInternalText: CGFloat = 80
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white)
                    .frame(height: 20)
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "cacaca"), lineWidth: 1)
                    )

                Capsule()
                    .fill(budgetProgressColor)
                    .frame(width: pillWidth, height: 22)
                    .overlay(
                        Capsule()
                            .stroke(.black, lineWidth: 1)
                    )
                
                BudgetProgressText(
                    cart: cart,
                    budgetProgressColor: budgetProgressColor,
                    pillWidth: pillWidth,
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
    
    var body: some View {
        Group {
            if pillWidth >= minWidthForInternalText {
                Text(cart.totalSpent.formattedCurrency)
                    .lexendFont(14, weight: .bold)
                    .foregroundColor(budgetProgressColor.darker(by: 0.5).saturated(by: 0.4))
                    .padding(.horizontal, 12)
                    .frame(width: pillWidth, height: 22, alignment: .trailing)
            } else {
                HStack(spacing: 8) {
                    Capsule()
                        .fill(budgetProgressColor)
                        .frame(width: pillWidth, height: 22)
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
