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
            return Color(hex: "FFB166")
        } else {
            return Color(hex: "F47676")
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
                            .overlay(Color.black.opacity(0.4))
                        
                        VisibleNoiseView(
                            grainSize: 0.0001,      // Medium grain size
                            density: 1,        // Visible but not overwhelming
                            opacity: 0.20       // Subtle but noticeable
                        )
                    }
                } else {
                    // Solid color background
                    backgroundColor
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            // Shopping mode: animated titanium glowing border (behind the border)
            ShoppingModeGradientView(cornerRadius: 24, hasBackgroundImage: hasBackgroundImage)
                .opacity(cart.isShopping ? 1 : 0)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.3), value: cart.isShopping)
        )
        .overlay(
            // Border always visible (on top)
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "CACACA"), lineWidth: 1)
        )
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
        .onChange(of: cart.status) { oldValue, newValue in
            // Smooth transition when cart status changes
            withAnimation(.easeInOut(duration: 0.5)) {
                // Gradient will automatically appear/disappear based on cart.isShopping
            }
        }
    }
    
    private var headerRow: some View {
        HStack {
            Text(cart.name)
                .shantellSansFont(18)
                .foregroundColor(hasBackgroundImage ? .white : .black)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .lexendFont(14, weight: .semibold)
                .foregroundColor(hasBackgroundImage ? .white : .black)
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            FluidBudgetPillView(
                cart: cart,
                animatedBudget: viewModel.animatedBudget,
                onBudgetTap: nil,
                hasBackgroundImage: hasBackgroundImage,
                isHeader: false
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
