import SwiftUI
import SwiftData

struct HomeCartRowView: View {
    let cart: Cart
    let vaultService: VaultService?
    
    @State private var viewModel: HomeCartRowViewModel
    @State private var appeared = false
    @State private var currentProgress: Double = 0 

    init(cart: Cart, vaultService: VaultService?) {
        self.cart = cart
        self.vaultService = vaultService
        self._viewModel = State(initialValue: HomeCartRowViewModel(cart: cart))
        self._currentProgress = State(initialValue: cart.totalSpent / cart.budget)
    }
    
    
    private var itemCount: Int {
        cart.cartItems.count
    }
    
    private var isOverBudget: Bool {
        cart.totalSpent > cart.budget
    }
    
    private var categories: [GroceryCategory] {
        /// NOTE: for PREVIEW ONLY!
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
    
     private var budgetProgressColor: Color {
         let progress = currentProgress
         if progress < 0.7 {
             return Color(hex: "98F476")
         } else if progress < 0.9 {
             return .orange
         } else {
             return .red
         }
     }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                  headerRow
                  progressSection
              }
              .padding()
              .background(Color.white)
              .cornerRadius(24)
              .overlay(
                  RoundedRectangle(cornerRadius: 24)
                      .stroke(Color(hex: "CACACA"), lineWidth: 1)
              )
              .padding(1)
              .scaleEffect(appeared ? 1.0 : 0.95)
              .opacity(appeared ? 1.0 : 0)
              .onAppear {
                  withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                      appeared = true
                  }
                  // Update progress cache
                  currentProgress = cart.totalSpent / cart.budget
              }
              .onChange(of: cart.budget) { oldValue, newValue in
                  guard oldValue != newValue else { return }
                  viewModel.updateBudget(newValue, animated: true)
                  
                  // Update progress with animation
                  withAnimation(.linear(duration: 0.3)) {
                      currentProgress = cart.totalSpent / newValue
                  }
              }
              .onChange(of: cart.totalSpent) { oldValue, newValue in
                  // Update progress when total spent changes
                  withAnimation(.linear(duration: 0.3)) {
                      currentProgress = newValue / cart.budget
                  }
              }

    }
    
    private var headerRow: some View {
        HStack {
            Text(cart.name)
                .lexendFont(18, weight: .semibold)
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .lexendFont(14, weight: .semibold)
                .foregroundStyle(Color(hex: "BABABA"))
        }
    }
    
    private var progressSection: some View {
             VStack(spacing: 8) {
                 HStack(alignment: .center, spacing: 8) {
                     BudgetProgressBar(
                         cart: cart,
                         animatedBudget: viewModel.animatedBudget,
                         budgetProgressColor: budgetProgressColor,
                         progressWidth: progressWidth
                     )
                     
                     Text(viewModel.animatedBudget.formattedCurrency)
                         .lexendFont(14, weight: .bold)
                         .foregroundColor(Color(hex: "333"))
                         .contentTransition(.numericText())
                 }
                 .frame(height: 20)
                 
                 categoriesView
             }
         }
     
    private var categoriesView: some View {
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
     private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
         guard viewModel.animatedBudget > 0 else { return 0 }
         
         // Use the cached currentProgress for smoother animation
         return CGFloat(min(currentProgress, 1.0)) * totalWidth
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
    
    HomeCartRowView(cart: mockCart, vaultService: nil)
        .padding()
        .background(Color.gray.opacity(0.1))
}


