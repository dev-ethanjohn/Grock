import SwiftUI
import SwiftData

struct HomeCartRowView: View {
    let cart: Cart
    let vaultService: VaultService?
    
    @State private var viewModel: HomeCartRowViewModel
    @State private var appeared = false
    
    init(cart: Cart, vaultService: VaultService?) {
        self.cart = cart
        self.vaultService = vaultService
        self._viewModel = State(initialValue: HomeCartRowViewModel(cart: cart))
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
        let progress = cart.totalSpent / viewModel.animatedBudget
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
        }
        .onChange(of: cart.budget) { oldValue, newValue in
            guard oldValue != newValue else { return }
            viewModel.updateBudget(newValue, animated: true)
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
        // Handle zero budget case to avoid division by zero
        guard viewModel.animatedBudget > 0 else { return 0 }
        
        let progress = cart.totalSpent / viewModel.animatedBudget
        return CGFloat(min(progress, 1.0)) * totalWidth
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


import SwiftUI
import Observation

@Observable
class HomeCartRowViewModel {
    var animatedBudget: Double = 0
    private var cartId: String
    private var lastUpdateTime: Date = Date()
    private var updateWorkItem: DispatchWorkItem?
    
    init(cart: Cart) {
        self.cartId = cart.id
        self.animatedBudget = cart.budget
    }
    
    func updateBudget(_ newBudget: Double, animated: Bool = true) {
        // Cancel any pending updates
        updateWorkItem?.cancel()
        
        if animated {
            // Schedule with 0.2s delay
            let workItem = DispatchWorkItem { [weak self] in
                // Run animation on main thread
                Task { @MainActor in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self?.animatedBudget = newBudget
                    }
                }
            }
            
            updateWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
        } else {
            // Update immediately without animation
            animatedBudget = newBudget
        }
        
        lastUpdateTime = Date()
    }
    
    func handleNotification(userInfo: [AnyHashable: Any]) {
        guard let notificationCartId = userInfo["cartId"] as? String,
              notificationCartId == cartId,
              let newBudget = userInfo["newBudget"] as? Double else { return }
        
        updateBudget(newBudget, animated: true)
    }
}
