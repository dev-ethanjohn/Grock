import SwiftUI
import SwiftData

struct HomeCartRowView: View {
    let cart: Cart
    let vaultService: VaultService?
    
    @State private var viewModel: HomeCartRowViewModel
    @State private var appeared = false
    @State private var currentProgress: Double = 0
    @State private var backgroundImage: UIImage? = nil
    @State private var hasBackgroundImage = false
    
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
    
    private var backgroundColor: Color {
        if hasBackgroundImage {
            return Color.clear
        } else {
            return ColorOption.getBackgroundColor(for: cart.id, isRow: true)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            progressSection
        }
        .padding()
        .background(
            Group {
                if hasBackgroundImage, let backgroundImage = backgroundImage {
                    ZStack {
                        // Background image with overlay
                        Image(uiImage: backgroundImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .blur(radius: 1)
                            .overlay(Color.black.opacity(0.3))
                        
                        VisibleNoiseView(
                            grainSize: 0.0001,      // Medium grain size
                            density: 1,        // Visible but not overwhelming
                            opacity: 0.15        // Subtle but noticeable
                        )
                    }
                } else {
                    // Solid color background
                    backgroundColor
                }
            }
        )
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
            currentProgress = cart.totalSpent / cart.budget
            
            // Load background image
            loadBackgroundImage()
        }
        .onChange(of: cart.budget) { oldValue, newValue in
            guard oldValue != newValue else { return }
            viewModel.updateBudget(newValue, animated: true)
            
            withAnimation(.linear(duration: 0.3)) {
                currentProgress = cart.totalSpent / newValue
            }
        }
        .onChange(of: cart.totalSpent) { oldValue, newValue in
            withAnimation(.linear(duration: 0.3)) {
                currentProgress = newValue / cart.budget
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CartBackgroundImageChanged"))) { notification in
            // Reload image when notification is received
            if let cartId = notification.userInfo?["cartId"] as? String,
               cartId == cart.id {
                loadBackgroundImage()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CartColorChanged"))) { notification in
            // Also reload when color changes (in case image is removed)
            if let cartId = notification.userInfo?["cartId"] as? String,
               cartId == cart.id {
                loadBackgroundImage()
            }
        }
    }
    
    private var headerRow: some View {
        HStack {
            Text(cart.name)
                .shantellSansFont(18)
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .lexendFont(14, weight: .semibold)
                .foregroundStyle(Color(hex: "BABABA"))
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            // Using the original FluidBudgetPillView with budget shown inside it
            FluidBudgetPillView(
                cart: cart,
                animatedBudget: viewModel.animatedBudget,
                onBudgetTap: nil // No tap action needed for home screen
            )
            
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
                            .background(category.pastelColor.opacity(0.6))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Background Image Loading
    
    private func loadBackgroundImage() {
        // Check if we have a background image
        hasBackgroundImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cart.id)
        
        if hasBackgroundImage {
            // Try cache first
            if let cachedImage = ImageCacheManager.shared.getImage(forCartId: cart.id) {
                backgroundImage = cachedImage
            } else {
                // Load from disk
                backgroundImage = CartBackgroundImageManager.shared.loadImage(forCartId: cart.id)
                hasBackgroundImage = backgroundImage != nil
                
                // Cache it for next time
                if let image = backgroundImage {
                    ImageCacheManager.shared.saveImage(image, forCartId: cart.id)
                }
            }
        } else {
            backgroundImage = nil
        }
    }
}
