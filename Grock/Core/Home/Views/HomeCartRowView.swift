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
    
    // Add this to observe currency changes
    @State private var currencyManager = CurrencyManager.shared
    
    // ✅ Cache active categories to avoid recalculation
      @State private var cachedActiveCategories: [GroceryCategory] = []
      @State private var lastCartItemsCount: Int = 0
    
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
    
    private var cardBackground: some View {
        Group {
            if hasBackgroundImage, let backgroundImage {
                ZStack {
                    Image(uiImage: backgroundImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .blur(radius: 2)
                        .overlay(Color.black.opacity(0.4))
                    
                    VisibleNoiseView(
                        grainSize: 0.0001,
                        density: 0.5,
                        opacity: 0.20
                    )
                }
            } else {
                ZStack {
                    backgroundColor
                }
            }
        }
    }
    
//    private var shoppingModeOverlay: some View {
//        EmptyView()
//    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 24)
            .stroke(
                Color.gray.opacity(1),
                lineWidth: 0.3
            )
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
            let selectedCurrency = CurrencyManager.shared.selectedCurrency
            return "\(selectedCurrency.symbol)0.00"
        }
        
        let fulfilledTotal = cart.cartItems
            .filter { cartItem in
                cartItem.quantity > 0 && cartItem.isFulfilled
            }
            .reduce(0.0) { total, cartItem in
                total + cartItem.getTotalPrice(from: vault, cart: cart)
            }
        
        let selectedCurrency = CurrencyManager.shared.selectedCurrency
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        
        let formattedAmount = numberFormatter.string(from: NSNumber(value: fulfilledTotal)) ?? String(format: "%.2f", fulfilledTotal)
        return "\(selectedCurrency.symbol)\(formattedAmount)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow
            progressSection
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
//        .overlay(shoppingModeOverlay)
//        .shadow(
//            color: Color.black.opacity(cart.isShopping ? 0.25 : 0),
//            radius: 0.5,
//            x: 0,
//            y: 0.5
//        )
        .overlay(borderOverlay)
        .scaleEffect(appeared ? 1.0 : 0.95)
        .opacity(appeared ? 1.0 : 0)
        // ✅ Add drawingGroup to offload rendering to GPU
        // .drawingGroup()
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
                currentProgress = cart.budget > 0 ? cart.totalSpent / cart.budget : 0
                
                // ✅ Load image asynchronously
                loadBackgroundImageAsync()
                
                // ✅ Calculate categories once
                updateActiveCategories()
            }
        .onChange(of: cart.cartItems.count) { oldValue, newValue in
                 // ✅ Only recalculate when cart items change
                 if newValue != lastCartItemsCount {
                     updateActiveCategories()
                     lastCartItemsCount = newValue
                 }
             }
        .onChange(of: cart.budget) { oldValue, newValue in
            guard oldValue != newValue else { return }
            viewModel.updateBudget(newValue, animated: true)
            
            withAnimation(.linear(duration: 0.3)) {
                currentProgress = newValue > 0 ? cart.totalSpent / newValue : 0
            }
        }
        .onChange(of: cart.totalSpent) { oldValue, newValue in
            withAnimation(.linear(duration: 0.3)) {
                currentProgress = cart.budget > 0 ? newValue / cart.budget : 0
            }
        }
        .onChange(of: CurrencyManager.shared.selectedCurrency) { oldValue, newValue in
            // When currency changes, update the local state to trigger view refresh
            currencyManager = CurrencyManager.shared
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
    
    
    //NOTE: OPTIMIZATIONS
    // MARK: - Async Image Loading
    private func loadBackgroundImageAsync() {
        // Check flag first (fast)
        let cartId = cart.id // Capture on MainActor
        let hasImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cartId)
        hasBackgroundImage = hasImage
        
        guard hasImage else {
            backgroundImage = nil
            return
        }
        
        // Try cache first (fast)
        if let cachedImage = ImageCacheManager.shared.getImage(forCartId: cartId) {
            backgroundImage = cachedImage
            return
        }
        
        // ✅ Load from disk asynchronously
        Task.detached(priority: .userInitiated) { [cartId] in
            let image = CartBackgroundImageManager.shared.loadImage(forCartId: cartId)
            
            await MainActor.run {
                self.backgroundImage = image
                self.hasBackgroundImage = image != nil
                
                // Cache it
                if let image = image {
                    ImageCacheManager.shared.saveImage(image, forCartId: cartId)
                }
            }
        }
    }
    
    // MARK: - Optimized Category Calculation
    private func updateActiveCategories() {
        // VaultService is MainActor-isolated, so we must access it on the main thread.
        // The caching in VaultService ensures this is efficient (O(N) lookup) after the first run.
        // Offloading to a detached task would require snapshotting the entire vault state, which is expensive.
        self.cachedActiveCategories = calculateActiveCategories()
    }
    
    private func calculateActiveCategories() -> [GroceryCategory] {
         guard !cart.cartItems.isEmpty else { return [] }
         
         var categorySet = Set<GroceryCategory>()
         
         for item in cart.cartItems {
             guard item.quantity > 0 else { continue }
             
             if item.isShoppingOnlyItem {
                 if let raw = item.shoppingOnlyCategory,
                    let cat = GroceryCategory(rawValue: raw) {
                     categorySet.insert(cat)
                 }
             } else {
                 // ✅ Use cached lookup instead of nested loops
                 if let categoryName = vaultService?.getCategoryName(for: item.itemId),
                    let groceryCat = GroceryCategory.allCases.first(where: { $0.title == categoryName }) {
                     categorySet.insert(groceryCat)
                 }
             }
         }
         
         return GroceryCategory.allCases.filter { categorySet.contains($0) }
     }
    
    private var headerRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(cart.name)
                        .fuzzyBubblesFont(18, weight: .bold)
                        .foregroundColor(hasBackgroundImage ? .white : .black)
                    if cart.isShopping {
                        CharacterRevealViewWithoutUnderline(
                            text: "(\(fulfilledItems)/\(totalItems))",
                            delay: 0.15
                        )
                        .id("header-reveal-\(fulfilledItems)-\(totalItems)")
                        .fuzzyBubblesFont(12, weight: .bold)
                        .foregroundColor(hasBackgroundImage ? .white : .black)
                    }
                }
                
                if cart.isShopping {
                    Text("Shopping")
                        .lexendFont(10, weight: .medium)
                        .foregroundColor(
                            hasBackgroundImage
                            ? .white.opacity(0.8)
                            : Color.black.opacity(0.5)
                        )
                        .offset(y: -4)
                }
            }
            .offset(y: -2)
            
            Spacer()
            
            HStack(alignment: .center, spacing: 2) {
                Image(systemName: "chevron.right")
                    .lexendFont(13, weight: .semibold)
                    .foregroundColor(hasBackgroundImage ? .white : .black)
            }
            
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            
//            if cart.isShopping {
//                CharacterRevealViewWithoutUnderline(
//                    text: "(\(fulfilledItems)/\(totalItems))",
//                    delay: 0.15
//                )
//                .id("reveal-\(fulfilledItems)-\(totalItems)")
//                .fuzzyBubblesFont(12, weight: .bold)
//                .padding(.leading, 4)
//                .foregroundColor(hasBackgroundImage ? .white : .black)
//            }
            
            FluidBudgetPillView(
                cart: cart,
                animatedBudget: viewModel.animatedBudget,
                onBudgetTap: nil,
                hasBackgroundImage: hasBackgroundImage,
                isHeader: false
            )
            
            if cart.isShopping {
                // Horizontal category list
                categoryProgressList
                    .padding(.top, 3)
            }

            
        }
    }
    
    // MARK: - Category Progress List
//    private var categoryProgressList: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 4) {
//                // Use a lighter-weight approach if possible, or ensure activeCategories is efficient
//                ForEach(activeCategories, id: \.self) { category in
//                    let isFulfilled = isCategoryFulfilled(category)
//                    
//                    ZStack {
//                        RoundedRectangle(cornerRadius: 6)
//                            .fill(
//                                RadialGradient(
//                                    colors: [
//                                        category.pastelColor.darker(by: 0.07).saturated(by: 0.03),
//                                        category.pastelColor.darker(by: 0.15).saturated(by: 0.05)
//                                    ],
//                                    center: .center,
//                                    startRadius: 0,
//                                    endRadius: 30
//                                )
//                            )
//                            // Remove shadow for list performance
//                            .shadow(
//                                color: .black.opacity(0.1),
//                                radius: 2,
//                                x: 0,
//                                y: 1
//                            )
//                            .frame(width: 18, height: 18)
//                        
//                        Text(category.emoji)
//                            .font(.system(size: 11))
//                    }
//                    .opacity(isFulfilled ? 1.0 : 0.5)
//                }
//            }
//            .padding(.horizontal, 4)
//            .padding(.bottom, 4)
//        }
//    }
    private var categoryProgressList: some View {
          ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 4) {
                  // ✅ Use cached categories instead of computing every frame
                  ForEach(cachedActiveCategories, id: \.self) { category in
                      let isFulfilled = isCategoryFulfilled(category)
                      
                      ZStack {
                          RoundedRectangle(cornerRadius: 6)
                              .fill(
                                  RadialGradient(
                                      colors: [
                                          category.pastelColor.darker(by: 0.07).saturated(by: 0.03),
                                          category.pastelColor.darker(by: 0.15).saturated(by: 0.05)
                                      ],
                                      center: .center,
                                      startRadius: 0,
                                      endRadius: 30
                                  )
                              )
                              .frame(width: 18, height: 18)
                          
                          Text(category.emoji)
                              .font(.system(size: 11))
                      }
                      .opacity(isFulfilled ? 1.0 : 0.5)
                  }
              }
              .padding(.horizontal, 4)
              .padding(.bottom, 4)
          }
      }
    
    // Compute categories present in this cart
    private var activeCategories: [GroceryCategory] {
        // Optimization: Early exit if cart is empty
        if cart.cartItems.isEmpty { return [] }
        
        var categorySet = Set<GroceryCategory>()
        
        // Use a simpler loop to avoid creating intermediate arrays
        for item in cart.cartItems {
            if item.quantity <= 0 { continue }
            
            if item.isShoppingOnlyItem {
                if let raw = item.shoppingOnlyCategory,
                   let cat = GroceryCategory(rawValue: raw) {
                    categorySet.insert(cat)
                }
            } else if let vault = vaultService?.vault {
                // Optimization: Avoid triple nested loop if possible.
                // ideally VaultService should provide a fast lookup map: [ItemId: Category]
                // For now, we keep the logic but maybe we can optimize the search order or cache it?
                // This is still O(N*M) but slightly cleaner.
                
                // TODO: Add caching for item->category lookup in VaultService to fix this properly
                if let category = vault.categories.first(where: { $0.items.contains(where: { $0.id == item.itemId }) }) {
                    if let groceryCat = GroceryCategory.allCases.first(where: { $0.title == category.name }) {
                        categorySet.insert(groceryCat)
                    }
                }
            }
        }
        
        return GroceryCategory.allCases.filter { categorySet.contains($0) }
    }
    
    private func isCategoryFulfilled(_ category: GroceryCategory) -> Bool {
        cart.cartItems.contains { item in
            guard item.quantity > 0 && item.isFulfilled else { return false }
            
            if item.isShoppingOnlyItem {
                return item.shoppingOnlyCategory == category.rawValue
            } else if let vault = vaultService?.vault {
                if let itemCategory = vault.categories.first(where: { $0.items.contains(where: { $0.id == item.itemId }) }) {
                    return itemCategory.name == category.title
                }
            }
            return false
        }
    }
    
    // MARK: - Background Image Loading
    private func loadBackgroundImage() {
        let cartId = cart.id
        let hasImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cartId)
        hasBackgroundImage = hasImage
        
        guard hasImage else {
            backgroundImage = nil
            return
        }
        
        if let cachedImage = ImageCacheManager.shared.getImage(forCartId: cartId) {
            backgroundImage = cachedImage
            return
        }
        
        Task.detached(priority: .userInitiated) { [cartId] in
            let image = CartBackgroundImageManager.shared.loadImage(forCartId: cartId)?.resized(to: 1400)
            await MainActor.run {
                self.backgroundImage = image
                self.hasBackgroundImage = image != nil
                if let image {
                    ImageCacheManager.shared.saveImage(image, forCartId: cartId)
                }
            }
        }
    }
}

// MARK: - Noise Overlay View for Solid Colors
struct NoiseOverlayView: View {
    let grainSize: CGFloat
    let density: CGFloat
    let opacity: CGFloat
    
    // Static noise cache to prevent regeneration
    private static var cachedNoiseImage: UIImage?
    private static var isGenerating = false
    
    var body: some View {
        Group {
            if let image = Self.cachedNoiseImage {
                Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blendMode(.softLight)
                .opacity(opacity)
            } else {
                // Fallback or placeholder while generating (though we generate on appear if needed)
                Color.clear
                    .onAppear {
                        if Self.cachedNoiseImage == nil && !Self.isGenerating {
                            generateNoise()
                        }
                    }
            }
        }
    }
    
    private func generateNoise() {
        // Generate on background thread to avoid hitching
        Self.isGenerating = true
        DispatchQueue.global(qos: .userInitiated).async {
            let size = CGSize(width: 300, height: 300)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            let image = renderer.image { context in
                let cgContext = context.cgContext
                // Fill with transparent base
                cgContext.setFillColor(UIColor.clear.cgColor)
                cgContext.fill(CGRect(origin: .zero, size: size))
                
                // Use larger pixel size for performance
                let pixelSize = 2
                let cols = Int(size.width) / pixelSize
                let rows = Int(size.height) / pixelSize
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        if Double.random(in: 0...1) < 0.5 { // Fixed density for cache
                            let gray = CGFloat.random(in: 0.2...0.8)
                            cgContext.setFillColor(UIColor(white: gray, alpha: 1.0).cgColor)
                            
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
            
            DispatchQueue.main.async {
                Self.cachedNoiseImage = image
                Self.isGenerating = false
            }
        }
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
