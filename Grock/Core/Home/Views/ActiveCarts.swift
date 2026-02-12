import SwiftUI
import SwiftData
import Lottie

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
                    Group {
                        if #available(iOS 18.0, *) {
                            NavigationLink {
                                CartDetailScreen(cart: cart)
                                    .environment(vaultService)
                                    .environment(cartViewModel)
                                    .environment(stateManager)
                                    .navigationTransition(.zoom(sourceID: cart.id, in: cartNamespace))
                                    .onDisappear {
                                        viewModel.loadCarts()
                                    }
                            } label: {
                                HomeCartRowView(
                                    cart: cart,
                                    vaultService: viewModel.getVaultService(for: cart),
                                    cartNamespace: cartNamespace
                                )
                                .contentShape(.interaction, RoundedRectangle(cornerRadius: 24))
                                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 24))
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
                        insertion: .opacity.combined(with: .scale(scale: 0.0, anchor: .top)),
                        removal: .opacity.combined(with: .scale(scale: 0.0, anchor: .top))
                    ))
                }
                
                Color.clear
                    .frame(height: 80)
            }
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7),
                value: viewModel.displayedCarts.count
            )
            .padding(.horizontal)
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .blurScroll()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            LottieView(animation: .named("Empty"))
                .playing(.fromProgress(0, toProgress: 1, loopMode: .loop))
                .allowsHitTesting(false)
                .frame(width: 180, height: 180)
            
            Text("Let's plan your shopping!")
                .fuzzyBubblesFont(24, weight: .bold)
                .foregroundColor(.black.opacity(0.8))
                .multilineTextAlignment(.center)
            
            emptyStateDescriptionText
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 28)
            
            Spacer()
        }
        .padding(.vertical, 40)
    }
    
    private var emptyStateDescriptionText: Text {
        let bodyColor = Color.gray.opacity(0.9)
        let accentColor = Color.black.opacity(0.6)
        
        let start = Text("Tap \"")
            .lexend(.subheadline, weight: .light)
            .foregroundColor(bodyColor)
        
        let createCart = Text("Create Cart")
            .lexend(.subheadline, weight: .medium)
            .foregroundColor(accentColor)
        
        let middle = Text("\" to start fresh, or open the ")
            .lexend(.subheadline, weight: .light)
            .foregroundColor(bodyColor)
        
        let vault = Text("Vault")
            .lexend(.subheadline, weight: .medium)
            .foregroundColor(accentColor)
        
        let end = Text(" to build a cart from saved items.")
            .lexend(.subheadline, weight: .light)
            .foregroundColor(bodyColor)
        
        return start + createCart + middle + vault + end
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
