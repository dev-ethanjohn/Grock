import Foundation
import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class HomeViewModel {
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    let cartViewModel: CartViewModel
    private let vaultService: VaultService
    
    // MARK: - UI State
    var selectedTab: Int = 0
    var showVault: Bool = false
    var selectedCart: Cart?
    var pendingSelectedCart: Cart? = nil
    
    // New: Pending cart display management (Using String since Cart.id is String)
    var pendingCartToShow: Cart? = nil
    private var hiddenCartIds: Set<String> = []
    
    // Currency selection
    var selectedCurrency: Currency {
        get { CurrencyManager.shared.selectedCurrency }
        set {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                CurrencyManager.shared.setCurrency(newValue)
            }
        }
    }
    
    // MARK: - Animation States
    var showMenu = false
    var isDismissed = false
    var headerHeight: CGFloat = 0
    
    init(modelContext: ModelContext, cartViewModel: CartViewModel, vaultService: VaultService) {
        self.modelContext = modelContext
        self.cartViewModel = cartViewModel
        self.vaultService = vaultService
    }

    // Cached display carts to avoid re-sorting/filtering on every render
    var displayedCarts: [Cart] {
        // Always show active carts since we removed tabs
        let baseCarts = cartViewModel.activeCarts.sorted { $0.createdAt > $1.createdAt }
        
        // Filter out hidden carts
        return baseCarts.filter { cart in
            !hiddenCartIds.contains(cart.id)
        }
    }
    
    var carts: [Cart] {
        cartViewModel.carts
    }
    
    var activeCarts: [Cart] {
        cartViewModel.activeCarts
    }
    
    var completedCarts: [Cart] {
        cartViewModel.completedCarts
    }
    
    var hasCarts: Bool {
        !displayedCarts.isEmpty
    }
    
    // MARK: - Navigation Methods
    func shouldAutoSelectCart() -> Bool {
        return selectedCart == nil && !activeCarts.isEmpty
    }
    
    func getMostRecentActiveCart() -> Cart? {
        return activeCarts.sorted { $0.createdAt > $1.createdAt }.first
    }
    
    // MARK: - User Actions
    func handleVaultButton() {
        print("🏠 Vault button tapped")
        showVault = true
    }

    // Create empty cart with hiding logic
    func createEmptyCart(title: String, budget: Double) -> Bool {
         print("🏠 HomeViewModel: Creating empty cart '\(title)' with budget \(budget)")
         
         // Validate cart name using cartViewModel
         let validation = cartViewModel.validateCartName(title)
         guard validation.isValid else {
             print("❌ Cannot create cart: \(validation.errorMessage ?? "Unknown error")")
             // You could set an error state here to show in the UI
             return false
         }
         
         if let newCart = cartViewModel.createEmptyCart(name: title, budget: budget) {
             print("✅ Empty cart created: \(newCart.name)")
             
             // Hide from list initially
             hiddenCartIds.insert(newCart.id)
             pendingCartToShow = newCart
             
             // Auto-select the new cart to open detail screen
             selectedCart = newCart
             return true
         }
         
         return false
     }
    func completePendingCartDisplay() {
        guard let cart = pendingCartToShow else { return }
        
        print("🎯 HomeViewModel: Showing cart in list - \(cart.name)")
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            hiddenCartIds.remove(cart.id)
            pendingCartToShow = nil
        }
    }
    
    func handleCreateCartConfirmation(title: String, budget: Double) -> Bool {
        return createEmptyCart(title: title, budget: budget)
    }
//    func handleCreateCartCancellation() {
//        // Nothing to do here
//    }

    func toggleMenu() {
        showMenu.toggle()
        
        if !showMenu {
            isDismissed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    self.isDismissed = false
                }
            }
        }
    }
    
    // MARK: - Data Management
    func loadCarts() {
        cartViewModel.loadCarts()
        #if DEBUG
        let total = cartViewModel.carts.count
        let active = cartViewModel.activeCarts.count
        let completed = cartViewModel.completedCarts.count
        print("🏠 Carts loaded: \(total) (\(active) active, \(completed) completed)")
        #endif
    }
    
    func getVaultService(for cart: Cart) -> VaultService? {
        return vaultService
    }
    
    func onCreateCartFromVault(_ createdCart: Cart) {
        print("🔄 HomeViewModel: onCreateCartFromVault called")
        print("   Created cart: \(createdCart.name), ID: \(createdCart.id)")
        print("   Cart items: \(createdCart.cartItems.count)")
        
        // Refresh to include the new cart
        cartViewModel.loadCarts()
        
        print("🔄 HomeViewModel: After loadCarts - available carts: \(cartViewModel.carts.count)")
        
        // Store the pending cart immediately
        if let exactCart = cartViewModel.carts.first(where: { $0.id == createdCart.id }) {
            print("🎯 HomeViewModel: Found exact cart in list - Setting as pending")
            self.pendingSelectedCart = exactCart
        } else {
            print("⚠️ HomeViewModel: Cart not found in list, queuing created cart")
            self.pendingSelectedCart = createdCart
        }
        
        showVault = false
        
        print("✅ HomeViewModel: Vault closed, cart is pending and detail screen will open")
    }
    
    func transferPendingCart() {
        if let pending = pendingSelectedCart {
            print("✅ Transferring pending to selectedCart: \(pending.name)")
            
            // 🎯 Also hide this cart when transferring from pending
            hiddenCartIds.insert(pending.id)
            pendingCartToShow = pending
            
            // Delay selection to allow Vault sheet to dismiss completely
            // This prevents "abrupt" transitions and navigation conflicts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                withAnimation {
                    self?.selectedCart = pending
                    self?.pendingSelectedCart = nil
                }
            }
        }
    }
    
    func checkPendingCart() {
        if let pending = pendingSelectedCart {
            print("🔍 Found pending cart on appear: \(pending.name)")
            transferPendingCart()
        }
    }
    
    func selectCart(_ cart: Cart) {
        selectedCart = cart
    }
    
    // MARK: - App Management
    func resetApp() {
        // Fully reset SwiftData user and vault so app behaves like a new install
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            
            for user in users {
                modelContext.delete(user)
            }
            
            try modelContext.save()
            
            vaultService.currentUser = nil
            vaultService.loadUserAndVault()
        } catch {
            print("❌ Error resetting user and vault: \(error)")
        }

        // Reset celebration flags
        UserDefaults.standard.set(false, forKey: "hasSeenFirstShoppingCartCelebration")
        UserDefaults.standard.set(false, forKey: "hasSeenVaultCelebration")
        UserDefaults.standard.hasCompletedOnboarding = false
        
        // Reset name-related flags
        UserDefaults.standard.userName = nil
        UserDefaults.standard.hasPromptedForNameAfterOnboarding = false
        UserDefaults.standard.hasPromptedForNameAfterVaultCelebration = false
        UserDefaults.standard.hasSeenProWelcome = false
        
        // Reset vault animation flag
        UserDefaults.standard.set(false, forKey: "hasShownVaultAnimation")

        // Clear hidden cart state
        hiddenCartIds.removeAll()
        pendingCartToShow = nil

        // Reload carts to reflect the reset state
        cartViewModel.loadCarts()

        print("✅ Reset done: Vault cleared and celebration flags reset")
        print("   - hasSeenFirstShoppingCartCelebration: false")
        print("   - hasSeenVaultCelebration: false")
        print("   - hasCompletedOnboarding: false")
        print("   - userName: cleared")
        print("   - hasPromptedForNameAfterOnboarding: false")
        print("   - hasPromptedForNameAfterVaultCelebration: false")
        print("   - hasSeenProWelcome: false")
    }
    
    // MARK: - UI Helpers
    func updateHeaderHeight(_ height: CGFloat) {
        headerHeight = height
    }
    
    func getMenuIconOffset() -> (x: CGFloat, y: CGFloat) {
        return (
            x: showMenu ? 80 : -20,
            y: showMenu ? -60 : isDismissed ? -120 : 0
        )
    }
    
    var menuIconOpacity: Double {
        showMenu ? 1 : 0
    }
    
    func validateCartName(_ name: String) -> (isValid: Bool, errorMessage: String?) {
        return cartViewModel.validateCartName(name)
    }
}
