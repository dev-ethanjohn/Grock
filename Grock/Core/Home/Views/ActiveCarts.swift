import SwiftUI
import SwiftData

struct ActiveCarts: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(CartStateManager.self) private var stateManager
    @Bindable var viewModel: HomeViewModel
    
    
    @State private var colorChangeTrigger = UUID()
    
    // Remove these state variables
    // @State private var showEditBudgetForCart: Cart? = nil
    // @State private var cartToDelete: Cart? = nil
    // @State private var showingDeleteAlert = false
    // @State private var showingEditCartName = false
    
    // Add these callbacks
    let onDeleteCart: (Cart) -> Void
    let onRenameCart: (Cart) -> Void
    let cartNamespace: Namespace.ID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.hasCarts {
                cartListView
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                emptyStateView
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
            Spacer()
        }
//        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .center)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.hasCarts)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CartColorChanged"))) { _ in
                 // Trigger refresh when any cart color changes
                 colorChangeTrigger = UUID()
             }
        
    }
    
    private var cartListView: some View {
        // ✅ Use ScrollView instead of LazyVStack with custom blur
        ScrollView {
            VStack(spacing: 14) {
                Color.clear
                    .frame(height: max(0, viewModel.headerHeight - 16))
                
                ForEach(viewModel.displayedCarts) { cart in
                    if #available(iOS 18.0, *) {
                        NavigationLink {
                            CartDetailScreen(cart: cart)
                                .environment(vaultService)
                                .environment(cartViewModel)
                                .environment(stateManager)
                                .navigationTransition(.zoom(sourceID: cart.id, in: cartNamespace))
                                .onDisappear {
                                    viewModel.loadCarts()
                                    if viewModel.pendingCartToShow != nil {
                                        viewModel.completePendingCartDisplay()
                                    }
                                }
                        } label: {
                            HomeCartRowView(
                                cart: cart,
                                vaultService: viewModel.getVaultService(for: cart)
                            )
                            .contentShape(.interaction, RoundedRectangle(cornerRadius: 24))
                            .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 24))
                            .matchedTransitionSource(id: cart.id, in: cartNamespace)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                onRenameCart(cart)
                            } label: {
                                Label("Rename Cart", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                onDeleteCart(cart)
                            } label: {
                                Label("Delete Cart", systemImage: "trash")
                            }
                        }
                        .onLongPressGesture {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    } else {
                        // Fallback for older iOS versions
                        HomeCartRowView(
                            cart: cart,
                            vaultService: viewModel.getVaultService(for: cart)
                        )
                        .contentShape(.interaction, RoundedRectangle(cornerRadius: 24))
                        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 24))
                        .onTapGesture {
                            viewModel.selectCart(cart)
                        }
                        .contextMenu {
                            Button {
                                onRenameCart(cart)
                            } label: {
                                Label("Rename Cart", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                onDeleteCart(cart)
                            } label: {
                                Label("Delete Cart", systemImage: "trash")
                            }
                        }
                        .onLongPressGesture {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7),
                    value: viewModel.displayedCarts.count
                )
                .padding(.horizontal)
                
                Color.clear
                    .frame(height: 80)
            }
            // ✅ Add scrollTargetLayout for better performance
            .scrollTargetLayout()
        }
        // ✅ Optimize scroll behavior
        .scrollIndicators(.hidden)
        .blurScroll()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No carts yet!")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Create your first cart to start shopping")
                .font(.body)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.vertical, 40)
    }
}


extension ColorOption {
    static func getBackgroundColor(for cartId: String, isRow: Bool = false) -> Color {
        let key = "cartBackgroundColor_\(cartId)"
        
        if let savedHex = UserDefaults.standard.string(forKey: key),
           let colorOption = ColorOption.options.first(where: { $0.hex == savedHex }) {
            if isRow {
                // For rows: use the color directly (or white if clear)
                return colorOption.hex == "FFFFFF" ? Color.white : colorOption.color
            } else {
                // For background: use darker version
                return colorOption.hex == "FFFFFF" ? Color.clear.darker(by: 0.02) : colorOption.color.darker(by: 0.02)
            }
        }
        
        UserDefaults.standard.set(ColorOption.defaultColor.hex, forKey: key)
        let defaultOption = ColorOption.defaultColor
        
        if isRow {
            return defaultOption.hex == "FFFFFF" ? Color.white : defaultOption.color
        } else {
            return defaultOption.hex == "FFFFFF" ? Color.clear.darker(by: 0.02) : defaultOption.color.darker(by: 0.02)
        }
    }
}



import SwiftUI
import Observation

// MARK: - Cart Color Manager (using @Observable)
@Observable
final class CartColorManager {
    static let shared = CartColorManager()
    
    private init() {}
    
    private var colorCache: [String: ColorOption] = [:]
    
    func getColor(for cartId: String) -> ColorOption {
        if let cached = colorCache[cartId] {
            return cached
        }
        
        if let savedHex = UserDefaults.standard.string(forKey: "cartBackgroundColor_\(cartId)"),
           let savedColor = ColorOption.options.first(where: { $0.hex == savedHex }) {
            colorCache[cartId] = savedColor
            return savedColor
        }
        
        return .defaultColor
    }
    
    func setColor(_ color: ColorOption, for cartId: String) {
        colorCache[cartId] = color
        UserDefaults.standard.set(color.hex, forKey: "cartBackgroundColor_\(cartId)")
        
        // Post notification for other parts of app
        NotificationCenter.default.post(
            name: Notification.Name("CartColorChanged"),
            object: nil,
            userInfo: ["cartId": cartId, "colorHex": color.hex]
        )
    }
}
