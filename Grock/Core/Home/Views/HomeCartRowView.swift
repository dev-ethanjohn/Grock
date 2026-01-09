import SwiftUI
import SwiftData
import Lottie

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
    
    // Total items includes ONLY ACTIVE items (non-skipped, non-deleted)
    private var totalItems: Int {
        cart.cartItems.filter { cartItem in
            // Exclude items that should not be counted:
            // 1. Shopping-only items with quantity <= 0 (effectively deleted/removed)
            // 2. Vault items that are skipped during shopping
            // 3. Vault items with quantity <= 0 (effectively inactive)
            
            if cartItem.isShoppingOnlyItem {
                // Shopping-only items: only count if quantity > 0
                return cartItem.quantity > 0
            } else {
                // Vault items: only count if quantity > 0 AND not skipped
                return cartItem.quantity > 0 && !cartItem.isSkippedDuringShopping
            }
        }.count
    }
    
    private var fulfilledItems: Int {
        cart.cartItems.filter { cartItem in
            // Include ALL items (both vault and shopping-only) that are fulfilled
            cartItem.isFulfilled &&
            cartItem.quantity > 0  // Still in cart
        }.count
    }
    
    private var fulfilledItemsTotal: String {
        guard let vault = vaultService?.vault else {
            return CurrencyFormatter.shared.format(amount: 0)
        }
        
        let fulfilledTotal = cart.cartItems
            .filter { cartItem in
                cartItem.quantity > 0 && cartItem.isFulfilled
            }
            .reduce(0.0) { total, cartItem in
                total + cartItem.getTotalPrice(from: vault, cart: cart)
            }
        
        return CurrencyFormatter.shared.format(amount: fulfilledTotal)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                            .blur(radius: 2)
                            .overlay(Color.black.opacity(0.4))
                        
                        VisibleNoiseView(
                            grainSize: 0.0001,      // Medium grain size
                            density: 0.5,        // Visible but not overwhelming
                            opacity: 0.20       // Subtle but noticeable
                        )
                    }
                } else {
                    ZStack {
                        backgroundColor
                            .overlay {
                                NoiseOverlayView(
                                    grainSize: 0.1,
                                    density: 0.7,
                                    opacity: 0.70
                                )
                            }
                    }
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
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
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
        HStack(alignment: .top) {
            Text(cart.name)
                .shantellSansFont(18)
                .foregroundColor(hasBackgroundImage ? .white : .black)
                .offset(y: -4)
            
            Spacer()
            
            HStack(alignment: .center, spacing: 2) {
                if cart.isShopping {
                    
                    LottieView(animation: .named("Shopping"))
                        .playing(.fromProgress(0, toProgress: 0.5, loopMode: .loop))
                        .colorMultiply(hasBackgroundImage ? .white : .black)
                        .frame(width: 18, height: 18)
                    
                    
                }
                
                Image(systemName: "chevron.right")
                    .lexendFont(13, weight: .semibold)
                    .foregroundColor(hasBackgroundImage ? .white : .black)
            }
            
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            if cart.isShopping {
                CharacterRevealViewWithoutUnderline(
                    text: "\(fulfilledItems)/\(totalItems) items fulfilled, totalling \(fulfilledItemsTotal)",
                    delay: 0.15
                )
                .id("reveal-\(fulfilledItems)-\(totalItems)-\(fulfilledItemsTotal)")
                .fuzzyBubblesFont(12, weight: .bold)
                .padding(.leading, 4)
                .foregroundColor(hasBackgroundImage ? .white : .black)
            }
            
            FluidBudgetPillView(
                cart: cart,
                animatedBudget: viewModel.animatedBudget,
                onBudgetTap: nil,
                hasBackgroundImage: hasBackgroundImage,
                isHeader: false
            )
            
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

// MARK: - Noise Overlay View for Solid Colors
struct NoiseOverlayView: View {
    let grainSize: CGFloat
    let density: CGFloat
    let opacity: CGFloat
    
    @State private var noiseImage: UIImage?
    private let cacheSize = CGSize(width: 300, height: 300)
    
    var body: some View {
        Group {
            if let noiseImage = noiseImage {
                Image(uiImage: noiseImage)
                    .resizable()
                    .interpolation(.none)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blendMode(.softLight) // More visible on solid colors than .overlay
                    .opacity(opacity)
            }
        }
        .onAppear {
            generateNoise()
        }
    }
    
    private func generateNoise() {
        let renderer = UIGraphicsImageRenderer(size: cacheSize)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            let pixelSize = max(1, Int(grainSize))
            let cols = Int(cacheSize.width) / pixelSize
            let rows = Int(cacheSize.height) / pixelSize
            
            for row in 0..<rows {
                for col in 0..<cols {
                    if CGFloat.random(in: 0...1) < density {
                        let gray = CGFloat.random(in: 0.2...0.8)
                        UIColor(white: gray, alpha: 1.0).setFill()
                        
                        let rect = CGRect(
                            x: col * pixelSize,
                            y: row * pixelSize,
                            width: pixelSize,
                            height: pixelSize
                        )
                        cgContext.fill(rect)
                    }
                }
            }
        }
        
        noiseImage = image
    }
}

// MARK: - Character Reveal View Without Underline (Local to HomeCartRowView)
struct CharacterRevealViewWithoutUnderline: View {
    let text: String
    let delay: Double
    @State private var revealedCharacters: Int = 0
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .opacity(index < revealedCharacters ? 1 : 0)
                    .offset(y: index < revealedCharacters ? 0 : 4)
                    .animation(
                        .interpolatingSpring(
                            stiffness: 240,
                            damping: 14
                        )
                        .delay(Double(index) * 0.01 + delay),
                        value: revealedCharacters
                    )
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(
                    .easeOut(duration: 0.32)
                ) {
                    revealedCharacters = text.count
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.25) {
                withAnimation(
                    .spring(
                        response: 0.2,
                        dampingFraction: 0.8,
                        blendDuration: 0.1
                    )
                ) {
                    isAnimating = true
                }
            }
            
            // Ensure all characters are revealed after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + (Double(text.count) * 0.01) + 0.5) {
                revealedCharacters = text.count
            }
        }
        .scaleEffect(isAnimating ? 1.007 : 1.0)
        .animation(
            .easeInOut(duration: 0.15)
            .repeatCount(1, autoreverses: true)
            .delay(delay + 0.5),
            value: isAnimating
        )
    }
}
