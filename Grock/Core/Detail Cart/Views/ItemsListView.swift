import SwiftUI

struct ItemsListView: View {
    let cart: Cart
    let totalItemCount: Int
    let sortedStoresWithRefresh: [String]
    let storeItemsWithRefresh: (String) -> [(cartItem: CartItem, item: Item?)]
    @Binding var fulfilledCount: Int
    let backgroundColor: Color
    let rowBackgroundColor: Color
    let hasBackgroundImage: Bool
    let backgroundImage: UIImage?
    let onFulfillItem: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        MainContentView(
            cart: cart,
            totalItemCount: totalItemCount,
            sortedStoresWithRefresh: sortedStoresWithRefresh,
            storeItemsWithRefresh: storeItemsWithRefresh,
            fulfilledCount: $fulfilledCount,
            backgroundColor: backgroundColor,
            rowBackgroundColor: rowBackgroundColor,
            hasBackgroundImage: hasBackgroundImage,
            backgroundImage: backgroundImage,
            onFulfillItem: onFulfillItem,
            onEditItem: onEditItem,
            onDeleteItem: onDeleteItem,
            vaultService: vaultService
        )
        .onChange(of: cart.cartItems) { oldItems, newItems in
            // Update the fulfilled count when cart items change
            let newFulfilledCount = newItems.filter { $0.isFulfilled }.count
            if fulfilledCount != newFulfilledCount {
                fulfilledCount = newFulfilledCount
            }
        }
        .onChange(of: cart.status) { oldStatus, newStatus in
            print("🔄 Cart status changed in ItemsListView: \(oldStatus) → \(newStatus)")
            print("   Display items will now: \(newStatus == .planning ? "Show ALL items" : "Show only unfulfilled, non-skipped")")
        }
    }
}

// MARK: - Main Content View
private struct MainContentView: View {
    let cart: Cart
    let totalItemCount: Int
    let sortedStoresWithRefresh: [String]
    let storeItemsWithRefresh: (String) -> [(cartItem: CartItem, item: Item?)]
    @Binding var fulfilledCount: Int
    let backgroundColor: Color
    let rowBackgroundColor: Color
    let hasBackgroundImage: Bool
    let backgroundImage: UIImage?
    let onFulfillItem: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    let vaultService: VaultService
    
    // Computed properties
    private var allItemsCompleted: Bool {
        guard cart.isShopping else { return false }
        
        let allItems = sortedStoresWithRefresh.flatMap { storeItemsWithRefresh($0) }
        let allUnfulfilledItems = allItems.filter {
            !$0.cartItem.isFulfilled && !$0.cartItem.isSkippedDuringShopping
        }
        return allUnfulfilledItems.isEmpty && totalItemCount > 0
    }
    
    private var hasDisplayItems: Bool {
        for store in sortedStoresWithRefresh {
            if !getDisplayItems(for: store).isEmpty {
                return true
            }
        }
        return false
    }
    
    var body: some View {
        GeometryReader { geometry in
            let calculatedHeight = estimatedHeight
            let maxAllowedHeight = geometry.size.height * 0.8
            
            VStack(spacing: 0) {
                if cart.isShopping && allItemsCompleted {
                    ShoppingCompleteCelebrationView(
                        backgroundColor: backgroundColor,
                        rowBackgroundColor: rowBackgroundColor,
                        maxAllowedHeight: maxAllowedHeight
                    )
                } else if !hasDisplayItems && cart.isPlanning {
                    EmptyCartView()
                        .transition(.scale)
                        .offset(y: UIScreen.main.bounds.height * 0.4)
                } else {
                    ItemsListContent(
                        cart: cart,
                        sortedStoresWithRefresh: sortedStoresWithRefresh,
                        storeItemsWithRefresh: storeItemsWithRefresh,
                        backgroundColor: backgroundColor,
                        rowBackgroundColor: rowBackgroundColor,
                        hasBackgroundImage: hasBackgroundImage,
                        backgroundImage: backgroundImage,
                        onFulfillItem: onFulfillItem,
                        onEditItem: onEditItem,
                        onDeleteItem: onDeleteItem,
                        geometry: geometry,
                        calculatedHeight: calculatedHeight,
                        maxAllowedHeight: maxAllowedHeight
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getDisplayItems(for store: String) -> [(cartItem: CartItem, item: Item?)] {
        let allItems = storeItemsWithRefresh(store)
        
        let filteredItems = allItems.filter { cartItem, _ in
            guard cartItem.quantity > 0 else { return false }
            
            switch cart.status {
            case .planning: return true
            case .shopping: return !cartItem.isFulfilled && !cartItem.isSkippedDuringShopping
            case .completed: return true
            }
        }
        
        return filteredItems.sorted { $0.cartItem.addedAt > $1.cartItem.addedAt }
    }
    
    private var sortedStoresByNewestItem: [String] {
        var storeTimestamps: [String: Date] = [:]
        
        for store in sortedStoresWithRefresh {
            let displayItems = getDisplayItems(for: store)
            let newestDate = displayItems
                .map { $0.cartItem.addedAt }
                .max() ?? Date.distantPast
            storeTimestamps[store] = newestDate
        }
        
        return storeTimestamps.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    private var availableWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let cartDetailPadding: CGFloat = 17
        let itemRowPadding: CGFloat = cart.isShopping ? 36 : 28
        let internalSpacing: CGFloat = 4
        let safetyBuffer: CGFloat = 3
        
        let totalPadding = cartDetailPadding + itemRowPadding + internalSpacing + safetyBuffer
        let calculatedWidth = screenWidth - totalPadding
        
        return max(min(calculatedWidth, 250), 150)
    }
    
    private func estimateRowHeight(for itemName: String, isFirstInSection: Bool = true) -> CGFloat {
        let averageCharWidth: CGFloat = 8.0
        let estimatedTextWidth = CGFloat(itemName.count) * averageCharWidth
        let numberOfLines = ceil(estimatedTextWidth / availableWidth)
        
        let singleLineTextHeight: CGFloat = 22
        let verticalPadding: CGFloat = 24
        let internalSpacing: CGFloat = 10
        
        let baseHeight = singleLineTextHeight + verticalPadding + internalSpacing
        let additionalLineHeight: CGFloat = 24
        let itemHeight = baseHeight + (max(0, numberOfLines - 1) * additionalLineHeight)
        let dividerHeight: CGFloat = isFirstInSection ? 0 : 12.0
        
        return itemHeight + dividerHeight
    }
    
    private var estimatedHeight: CGFloat {
        let sectionHeaderHeight: CGFloat = 34
        let sectionSpacing: CGFloat = 8
        let listPadding: CGFloat = 24
        
        var totalHeight: CGFloat = listPadding
        
        for store in sortedStoresWithRefresh {
            let displayItems = getDisplayItems(for: store)
            
            if !displayItems.isEmpty {
                totalHeight += sectionHeaderHeight
                
                for (index, (_, item)) in displayItems.enumerated() {
                    let itemName = item?.name ?? "Unknown"
                    let isFirstInStore = index == 0
                    totalHeight += estimateRowHeight(for: itemName, isFirstInSection: isFirstInStore)
                }
                
                if store != sortedStoresWithRefresh.last {
                    totalHeight += sectionSpacing
                }
            }
        }
        
        return totalHeight
    }
}

// MARK: - Shopping Complete Celebration View
private struct ShoppingCompleteCelebrationView: View {
    let backgroundColor: Color
    let rowBackgroundColor: Color
    let maxAllowedHeight: CGFloat
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(hex: "FF6B6B"))
            
            Text("Shopping Trip Complete! 🎉")
                .lexendFont(18, weight: .bold)
                .foregroundColor(Color(hex: "333"))
                .multilineTextAlignment(.center)
            
            Text("Congratulations! You've checked off all items.")
                .lexendFont(14)
                .foregroundColor(Color(hex: "666"))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text("Ready to finish your trip?")
                .lexendFont(12)
                .foregroundColor(Color(hex: "999"))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 4)
        }
        .frame(height: min(200, maxAllowedHeight))
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [backgroundColor, rowBackgroundColor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "FF6B6B").opacity(0.3), lineWidth: 2)
        )
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Items List Content
private struct ItemsListContent: View {
    let cart: Cart
    let sortedStoresWithRefresh: [String]
    let storeItemsWithRefresh: (String) -> [(cartItem: CartItem, item: Item?)]
    let backgroundColor: Color
    let rowBackgroundColor: Color
    let hasBackgroundImage: Bool
    let backgroundImage: UIImage?
    let onFulfillItem: (CartItem) -> Void
    let onEditItem: (CartItem) -> Void
    let onDeleteItem: (CartItem) -> Void
    let geometry: GeometryProxy
    let calculatedHeight: CGFloat
    let maxAllowedHeight: CGFloat
    
    @Environment(VaultService.self) private var vaultService
    
    // Helper methods
    private func getDisplayItems(for store: String) -> [(cartItem: CartItem, item: Item?)] {
        let allItems = storeItemsWithRefresh(store)
        
        let filteredItems = allItems.filter { cartItem, _ in
            guard cartItem.quantity > 0 else { return false }
            
            switch cart.status {
            case .planning: return true
            case .shopping: return !cartItem.isFulfilled && !cartItem.isSkippedDuringShopping
            case .completed: return true
            }
        }
        
        return filteredItems.sorted { $0.cartItem.addedAt > $1.cartItem.addedAt }
    }
    
    private var sortedStoresByNewestItem: [String] {
        var storeTimestamps: [String: Date] = [:]
        
        for store in sortedStoresWithRefresh {
            let displayItems = getDisplayItems(for: store)
            let newestDate = displayItems
                .map { $0.cartItem.addedAt }
                .max() ?? Date.distantPast
            storeTimestamps[store] = newestDate
        }
        
        return storeTimestamps.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    var body: some View {
        List {
            ForEach(Array(sortedStoresByNewestItem.enumerated()), id: \.offset) { (index, store) in
                let displayItems = getDisplayItems(for: store)
                
                if !displayItems.isEmpty {
                    StoreSectionListView(
                        store: store,
                        items: displayItems,
                        cart: cart,
                        onFulfillItem: { cartItem in
                            onFulfillItem(cartItem)
                        },
                        onEditItem: onEditItem,
                        onDeleteItem: onDeleteItem,
                        isLastStore: index == sortedStoresByNewestItem.count - 1,
                        backgroundColor: backgroundColor,
                        rowBackgroundColor: rowBackgroundColor,
                        hasBackgroundImage: hasBackgroundImage
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(rowBackgroundColor)
                }
            }
        }
        .frame(height: min(calculatedHeight, maxAllowedHeight))
        .listStyle(PlainListStyle())
        .listSectionSpacing(0)
        .background(
            ListBackgroundView(
                hasBackgroundImage: hasBackgroundImage,
                backgroundImage: backgroundImage,
                backgroundColor: backgroundColor,
                geometry: geometry
            )
        )
        .cornerRadius(16)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: calculatedHeight)
        
        if cart.isShopping {
            ShoppingProgressSummary(cart: cart)
                .presentationCornerRadius(24)
                .environment(vaultService)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

// MARK: - List Background View
private struct ListBackgroundView: View {
    let hasBackgroundImage: Bool
    let backgroundImage: UIImage?
    let backgroundColor: Color
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            if hasBackgroundImage, let backgroundImage = backgroundImage {
                ZStack {
                               Image(uiImage: backgroundImage)
                                   .resizable()
                                   .scaledToFill()
                                   .frame(width: geometry.size.width, height: geometry.size.height)
                                   .clipped()
                                   .blur(radius: 1.5)
                               
                               // Dark overlay (2% opacity black)
                               Color.black.opacity(0.2)
                           }
                    .overlay(
                        VisibleNoiseView(
                            grainSize: 0.5,
                            density: 0.5,
                            opacity: 0.25
                        )
                    )
                    .opacity(0.7)
                    .cornerRadius(16)
            } else {
                backgroundColor
            }
        }
    }
}

// MARK: - Visible Noise View
struct VisibleNoiseView: View {
    let grainSize: CGFloat    // 0.5-1.5 for visible grain
    let density: CGFloat      // 0.1-0.3 for visible density
    let opacity: CGFloat      // 0.2-0.4 for visible opacity
    
    @State private var noiseImage: UIImage?
    private let cacheSize = CGSize(width: 300, height: 300) // Larger for better quality
    
    var body: some View {
        Group {
            if let noiseImage = noiseImage {
                Image(uiImage: noiseImage)
                    .resizable()
                    .interpolation(.none) // Keep pixels sharp
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .blendMode(.overlay)
                    .opacity(opacity)
            } else {
                // Fallback while generating
                Rectangle()
                    .fill(.gray.opacity(0.1))
            }
        }
        .onAppear {
            generateVisibleNoise()
        }
    }
    
    private func generateVisibleNoise() {
        let renderer = UIGraphicsImageRenderer(size: cacheSize)
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Single pixel noise for fine grain
            let pixelSize = max(1, Int(grainSize))
            let cols = Int(cacheSize.width) / pixelSize
            let rows = Int(cacheSize.height) / pixelSize
            
            // Draw visible noise
            for row in 0..<rows {
                for col in 0..<cols {
                    // Use density to decide whether to draw
                    if CGFloat.random(in: 0...1) < density {
                        // Wider range of grays for visibility
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
        
        self.noiseImage = image
    }
}

// MARK: - Demo View to Test Noise
struct NoiseDemoView: View {
    @State private var opacity: CGFloat = 0.3
    @State private var density: CGFloat = 0.2
    @State private var grainSize: CGFloat = 1.0
    
    var body: some View {
        VStack {
            // Background with noise for testing
            Rectangle()
                .fill(.blue.opacity(0.3))
                .frame(height: 300)
                .overlay(
                    VisibleNoiseView(
                        grainSize: grainSize,
                        density: density,
                        opacity: opacity
                    )
                )
                .cornerRadius(12)
                .padding()
            
            // Controls to adjust noise
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Opacity: \(opacity, specifier: "%.2f")")
                        .font(.caption)
                    Slider(value: $opacity, in: 0.1...0.5, step: 0.05)
                }
                
                VStack(alignment: .leading) {
                    Text("Density: \(density, specifier: "%.2f")")
                        .font(.caption)
                    Slider(value: $density, in: 0.05...0.4, step: 0.05)
                }
                
                VStack(alignment: .leading) {
                    Text("Grain Size: \(grainSize, specifier: "%.1f")")
                        .font(.caption)
                    Slider(value: $grainSize, in: 0.5...2.0, step: 0.1)
                }
                
                // Presets
                HStack {
                    Button("Subtle") {
                        opacity = 0.15
                        density = 0.1
                        grainSize = 0.8
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Visible") {
                        opacity = 0.25
                        density = 0.2
                        grainSize = 1.0
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Strong") {
                        opacity = 0.35
                        density = 0.3
                        grainSize = 1.5
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

// MARK: - Alternative: Simple Canvas Noise (Easier to see)
struct SimpleCanvasNoise: View {
    let opacity: CGFloat
    
    var body: some View {
        Canvas { context, size in
            // Draw more points to be visible
            let pointCount = Int(size.width * size.height * 0.001) // 0.1% density
            
            for _ in 0..<pointCount {
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
                // Use more contrast
                let gray = Double.random(in: 0.3...0.7)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                    with: .color(Color(white: gray))
                )
            }
        }
        .blendMode(.overlay)
        .opacity(opacity)
        .allowsHitTesting(false)
    }
}
