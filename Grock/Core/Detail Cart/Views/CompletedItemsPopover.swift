import SwiftUI
import SwiftData

struct CompletedItemsPopover: View {
    @Binding var isPresented: Bool
    let completedItems: [CartItem]
    let cart: Cart
    var namespace: Namespace.ID
    
    @Environment(VaultService.self) private var vaultService
    
    // Animation state
    @State private var popoverScale: CGFloat = 0.5
    @State private var popoverOpacity: Double = 0
    @State private var contentOffset: CGFloat = 300
    @State private var backgroundOpacity: Double = 0
    
    private var groupedItems: [String: [(cartItem: CartItem, item: Item?)]] {
        let itemsWithDetails = completedItems.map { cartItem in
            (cartItem, vaultService.findItemById(cartItem.itemId))
        }
        let grouped = Dictionary(grouping: itemsWithDetails) { cartItem, item in
            cartItem.getStore(cart: cart)
        }
        return grouped.filter { !$0.key.isEmpty && !$0.value.isEmpty }
    }
    
    private var sortedStores: [String] {
        Array(groupedItems.keys).sorted()
    }
    
    private var totalSpent: Double {
        completedItems.reduce(0) { $0 + ($1.actualPrice ?? 0) }
    }
    
    var body: some View {
        ZStack {
            backgroundView
            popoverContentView
        }
        .onAppear {
            animateIn()
        }
    }
    
    private var backgroundView: some View {
        Color.black.opacity(0.4)
            .opacity(backgroundOpacity)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                dismissPopover()
            }
            .blur(radius: 20, opaque: true)
    }
    
    private var popoverContentView: some View {
        VStack(spacing: 0) {
            handleBar
            headerView
            
            if completedItems.isEmpty {
                emptyStateView
            } else {
                itemsListView
            }
            
            doneButton
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.8)
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .frame(maxHeight: .infinity, alignment: .bottom)
        .offset(y: contentOffset)
        .scaleEffect(popoverScale)
        .opacity(popoverOpacity)
        .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: -5)
        .matchedGeometryEffect(id: "finishTripButton", in: namespace, properties: .frame, isSource: false)
    }
    
    private var handleBar: some View {
        Capsule()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 40, height: 5)
            .padding(.top, 8)
    }
    
    private var headerView: some View {
        HStack {
            Text("Completed Items")
                .lexendFont(18, weight: .bold)
                .foregroundColor(.black)
            
            Spacer()
            
            Button(action: dismissPopover) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 30, height: 30)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No items completed yet")
                .lexendFont(16, weight: .medium)
                .foregroundColor(.gray)
        }
        .frame(maxHeight: .infinity)
        .padding(.vertical, 40)
    }
    
    private var itemsListView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(sortedStores, id: \.self) { store in
                    storeSectionView(for: store)
                }
                
                totalSectionView
            }
            .padding(.bottom, 30)
        }
    }
    
    private func storeSectionView(for store: String) -> some View {
        Group {
            if let storeItems = groupedItems[store] {
                VStack(spacing: 0) {
                    // Store header
                    HStack {
                        Text(store)
                            .lexendFont(14, weight: .bold)
                            .foregroundColor(.black.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(storeItems.count) item\(storeItems.count == 1 ? "" : "s")")
                            .lexendFont(12, weight: .medium)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(hex: "F5F5F5"))
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                    .padding(.top, store == sortedStores.first ? 0 : 16)
                    
                    // Items in store
                    VStack(spacing: 0) {
                        ForEach(Array(storeItems.enumerated()), id: \.offset) { index, itemTuple in
                            storeItemRow(itemTuple: itemTuple, isLastItem: index == storeItems.count - 1)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private func storeItemRow(itemTuple: (cartItem: CartItem, item: Item?), isLastItem: Bool) -> some View {
        let (cartItem, item) = itemTuple
        
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Checkmark indicator
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                    .frame(width: 24)
                
                // Item name and details
                VStack(alignment: .leading, spacing: 2) {
                    Text(item?.name ?? "Unknown Item")
                        .lexendFont(14, weight: .medium)
                        .foregroundColor(.black)
                    
                    // quantity is NON-OPTIONAL Double, so direct comparison
                    if cartItem.quantity > 1 {
                        Text("Qty: \(cartItem.quantity, specifier: "%.0f")")
                            .lexendFont(12, weight: .regular)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Price
                priceView(for: cartItem)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Separator
            if !isLastItem {
                Divider()
                    .padding(.leading, 56)
                    .padding(.trailing, 20)
            }
        }
    }
    
    private func priceView(for cartItem: CartItem) -> some View {
        Group {
            if cartItem.isFulfilled, let actualPrice = cartItem.actualPrice, actualPrice > 0 {
                Text(actualPrice.formattedCurrency)
                    .lexendFont(14, weight: .bold)
                    .foregroundColor(.black)
            } else if let plannedPrice = cartItem.plannedPrice, plannedPrice > 0 {
                Text(plannedPrice.formattedCurrency)
                    .lexendFont(14, weight: .regular)
                    .foregroundColor(.gray)
            } else {
                Text("N/A")
                    .lexendFont(14, weight: .regular)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var totalSectionView: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 20)
            
            HStack {
                Text("Total Spent")
                    .lexendFont(16, weight: .bold)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(totalSpent.formattedCurrency)
                    .lexendFont(16, weight: .bold)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 20)
        }
        .padding(.top, 16)
    }
    
    private var doneButton: some View {
        Button(action: dismissPopover) {
            Text("Done")
                .lexendFont(16, weight: .semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color(hex: "4CAF50"))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
        }
    }
    
    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            backgroundOpacity = 1
            popoverOpacity = 1
            contentOffset = 0
            popoverScale = 1
        }
    }
    
    private func dismissPopover() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            backgroundOpacity = 0
            popoverOpacity = 0
            contentOffset = 300
            popoverScale = 0.5
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Preview
//#Preview {
//    struct CompletedItemsPopoverPreview: View {
//        @State private var isPresented = true
//        @Namespace private var namespace
//        
//        // Mock data for preview
//        private var mockCart: Cart {
//            let cart = Cart(name: "Test Cart", budget: 100.0)
//            return cart
//        }
//        
//        private var mockCompletedItems: [CartItem] {
//            [
//                CartItem(
//                    itemId: "1",
//                    quantity: 2,
//                    plannedStore: "Walmart",
//                    isFulfilled: true,
//                    plannedPrice: 2.99,
//                    actualPrice: 3.49
//                ),
//                CartItem(
//                    itemId: "2",
//                    quantity: 1,
//                    plannedStore: "Walmart",
//                    isFulfilled: true,
//                    plannedPrice: 5.99,
//                    actualPrice: 5.99
//                ),
//                CartItem(
//                    itemId: "3",
//                    quantity: 3,
//                    plannedStore: "Target",
//                    isFulfilled: true,
//                    plannedPrice: 1.49,
//                    actualPrice: 1.29
//                )
//            ]
//        }
//        
//        var body: some View {
//            ZStack {
//                Color.gray.opacity(0.3)
//                    .edgesIgnoringSafeArea(.all)
//                
//                CompletedItemsPopover(
//                    isPresented: $isPresented,
//                    completedItems: mockCompletedItems,
//                    cart: mockCart,
//                    namespace: namespace
//                )
////                .environment(VaultService.preview)
//            }
//        }
//    }
//    
//    return CompletedItemsPopoverPreview()
//}

// MARK: - Helper Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

//// MARK: - Mock VaultService for Preview
//extension VaultService {
//    static var preview: VaultService {
//        let service = VaultService(modelContext: <#ModelContext#>)
//        // Configure mock data if needed
//        return service
//    }
//}
