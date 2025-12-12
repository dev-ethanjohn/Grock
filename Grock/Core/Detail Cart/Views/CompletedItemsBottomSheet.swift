//import SwiftUI
//
//struct CompletedItemsBottomSheet: View {
//    @Binding var isPresented: Bool
//    let completedItems: [CartItem]
//    let cart: Cart
//    let vaultService: VaultService
//    
//    @State private var selectedDetent: PresentationDetent = .fraction(0.25)
//    
//    private var totalCompleted: Int {
//        completedItems.count
//    }
//    
//    private var completedItemsWithDetails: [(cartItem: CartItem, item: Item?)] {
//        completedItems.map { cartItem in
//            (cartItem, vaultService.findItemById(cartItem.itemId))
//        }
//    }
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Header
//            VStack(alignment: .leading, spacing: 8) {
//                HStack {
//                    Text("Completed")
//                        .lexendFont(20, weight: .bold)
//                        .foregroundColor(.black)
//                    
//                    Spacer()
//                    
//                    // Close button (only show in large detent)
//                    if selectedDetent == .large || selectedDetent == .medium {
//                        Button(action: {
//                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                                selectedDetent = .fraction(0.25)
//                            }
//                        }) {
//                            Image(systemName: "chevron.down")
//                                .font(.system(size: 16, weight: .medium))
//                                .foregroundColor(.black)
//                                .padding(8)
//                                .background(Color(hex: "F0F0F0"))
//                                .clipShape(Circle())
//                        }
//                        .buttonStyle(.plain)
//                    }
//                }
//                
//                HStack {
//                    Text("\(totalCompleted) items")
//                        .lexendFont(14)
//                        .foregroundColor(Color(hex: "666"))
//                    
//                    if totalCompleted > 0 {
//                        Spacer()
//                        
//                        Text("Tap to expand")
//                            .lexendFont(12)
//                            .foregroundColor(Color(hex: "999"))
//                            .padding(.horizontal, 8)
//                            .padding(.vertical, 4)
//                            .background(Color(hex: "F0F0F0"))
//                            .cornerRadius(12)
//                    }
//                }
//            }
//            .padding(.horizontal, 20)
//            .padding(.top, 20)
//            .padding(.bottom, 16)
//            .background(Color.white)
//            
//            // Content area
//            if selectedDetent == .large || selectedDetent == .medium {
//                // Expanded view - show list of completed items
//                ScrollView {
//                    LazyVStack(spacing: 0) {
//                        ForEach(Array(completedItemsWithDetails.enumerated()), id: \.offset) { index, tuple in
//                            CompletedItemRow(
//                                cartItem: tuple.cartItem,
//                                item: tuple.item,
//                                cart: cart,
//                                isLastItem: index == completedItemsWithDetails.count - 1
//                            )
//                            
//                            if index < completedItemsWithDetails.count - 1 {
//                                Divider()
//                                    .padding(.horizontal, 20)
//                            }
//                        }
//                    }
//                    .padding(.bottom, 100) // Space for action bar
//                }
//                .background(Color(hex: "F7F2ED"))
//            } else {
//                // Collapsed view - just show empty state or summary
//                if totalCompleted == 0 {
//                    VStack(spacing: 16) {
//                        Image(systemName: "checkmark.circle")
//                            .font(.system(size: 40))
//                            .foregroundColor(Color(hex: "999"))
//                        
//                        Text("No items completed yet")
//                            .lexendFont(14)
//                            .foregroundColor(Color(hex: "666"))
//                    }
//                    .frame(maxWidth: .infinity, minHeight: 100)
//                    .background(Color(hex: "F7F2ED"))
//                } else {
//                    // Show a preview of completed items (first 2-3)
//                    VStack(spacing: 12) {
//                        ForEach(Array(completedItemsWithDetails.prefix(3).enumerated()), id: \.offset) { index, tuple in
//                            CompletedItemPreviewRow(
//                                cartItem: tuple.cartItem,
//                                item: tuple.item
//                            )
//                        }
//                        
//                        if totalCompleted > 3 {
//                            Text("+\(totalCompleted - 3) more")
//                                .lexendFont(12)
//                                .foregroundColor(Color(hex: "999"))
//                                .padding(.top, 4)
//                        }
//                    }
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 16)
//                    .frame(maxWidth: .infinity)
//                    .background(Color(hex: "F7F2ED"))
//                }
//            }
//        }
//        .background(Color.white)
//        .cornerRadius(24, corners: [.topLeft, .topRight])
//        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
//        .gesture(
//            DragGesture()
//                .onChanged { value in
//                    // Handle drag for interactive detent changes
//                }
//        )
//        .onTapGesture {
//            // Expand on tap when collapsed
//            if selectedDetent == .fraction(0.25) && totalCompleted > 0 {
//                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                    selectedDetent = .large
//                }
//            }
//        }
//    }
//}
//
//struct CompletedItemRow: View {
//    let cartItem: CartItem
//    let item: Item?
//    let cart: Cart
//    let isLastItem: Bool
//    
//    @Environment(VaultService.self) private var vaultService
//    
//    private var itemName: String {
//        item?.name ?? "Unknown Item"
//    }
//    
//    private var price: Double {
//        guard let vault = vaultService.vault else { return 0.0 }
//        return cartItem.getPrice(from: vault, cart: cart)
//    }
//    
//    private var unit: String {
//        guard let vault = vaultService.vault else { return "" }
//        return cartItem.getUnit(from: vault, cart: cart)
//    }
//    
//    private var quantity: Double {
//        cartItem.getQuantity(cart: cart)
//    }
//    
//    private var totalPrice: Double {
//        guard let vault = vaultService.vault else { return 0.0 }
//        return cartItem.getTotalPrice(from: vault, cart: cart)
//    }
//    
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            Image(systemName: "checkmark.circle.fill")
//                .font(.system(size: 16))
//                .foregroundColor(.green)
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text("\(quantityString) \(itemName)")
//                    .lexendFont(16, weight: .regular)
//                    .foregroundColor(.black)
//                
//                HStack(spacing: 4) {
//                    Text("\(formatCurrency(price)) / \(unit)")
//                        .lexendFont(12)
//                        .foregroundColor(Color(hex: "666"))
//                    
//                    Spacer()
//                    
//                    Text(formatCurrency(totalPrice))
//                        .lexendFont(14, weight: .bold)
//                        .foregroundColor(.black)
//                }
//            }
//        }
//        .padding(.horizontal, 20)
//        .padding(.vertical, 12)
//        .background(Color.white)
//    }
//    
//    private var quantityString: String {
//        let qty = quantity
//        return qty == Double(Int(qty)) ? "\(Int(qty))\(unit)" : String(format: "%.2f\(unit)", qty)
//    }
//    
//    private func formatCurrency(_ value: Double) -> String {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .currency
//        formatter.currencyCode = "PHP"
//        formatter.maximumFractionDigits = value == Double(Int(value)) ? 0 : 2
//        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
//    }
//}
//
//struct CompletedItemPreviewRow: View {
//    let cartItem: CartItem
//    let item: Item?
//    
//    private var itemName: String {
//        item?.name ?? "Unknown Item"
//    }
//    
//    private var quantity: Double {
//        cartItem.quantity
//    }
//    
//    var body: some View {
//        HStack {
//            Image(systemName: "checkmark.circle.fill")
//                .font(.system(size: 12))
//                .foregroundColor(.green)
//            
//            Text("\(quantity.formatted) \(itemName)")
//                .lexendFont(13)
//                .foregroundColor(Color(hex: "666"))
//                .lineLimit(1)
//            
//            Spacer()
//        }
//    }
//}
//
//// MARK: - Corner Radius Extension
//
//
//extension Double {
//    var formatted: String {
//        self == Double(Int(self)) ? "\(Int(self))" : String(format: "%.1f", self)
//    }
//}
//
