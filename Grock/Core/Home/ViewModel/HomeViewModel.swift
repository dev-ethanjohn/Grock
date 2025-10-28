import Foundation
import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class HomeViewModel {
    var selectedTab: Int = 0
    var showVault: Bool = false
    var selectedCart: Cart?
    var pendingSelectedCart: Cart? = nil
    
    private let modelContext: ModelContext
    private let cartViewModel: CartViewModel
    
    init(modelContext: ModelContext, cartViewModel: CartViewModel) {
        self.modelContext = modelContext
        self.cartViewModel = cartViewModel
        print("🏠 HomeViewModel initialized")
    }
    
    var displayedCarts: [Cart] {
        switch selectedTab {
        case 0:
            return cartViewModel.activeCarts.sorted { $0.createdAt > $1.createdAt }
        case 1:
            return cartViewModel.completedCarts.sorted { $0.createdAt > $1.createdAt }
        default:
            return []
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
    
    func shouldAutoSelectCart() -> Bool {
        return selectedCart == nil && !activeCarts.isEmpty
    }
    
    func getMostRecentActiveCart() -> Cart? {
        return activeCarts.sorted { $0.createdAt > $1.createdAt }.first
    }
    
    func handleCreateCart() {
        print("🏠 Create cart button tapped")
        showVault = true
    }
    
    func handleVaultButton() {
        print("🏠 Vault button tapped")
        showVault = true
    }
    
    func resetApp() {
        let vaults = try? modelContext.fetch(FetchDescriptor<Vault>())
        vaults?.forEach { modelContext.delete($0) }

        try? modelContext.save()

        UserDefaults.standard.hasCompletedOnboarding = false
        cartViewModel.loadCarts()

        print("✅ Reset done: Vault cleared")
    }
    
    func loadCarts() {
        cartViewModel.loadCarts()
        print("🏠 Carts loaded: \(cartViewModel.carts.count)")
    }
    
    func getVaultService(for cart: Cart) -> VaultService? {
        cartViewModel.getVaultService
    }
    
    func onCreateCartFromVault(_ createdCart: Cart) {
        print("🔄 HomeViewModel: onCreateCartFromVault called")
        print("   Created cart: \(createdCart.name), ID: \(createdCart.id)")
        print("   Cart items: \(createdCart.cartItems.count)")
        
        // Refresh to include the new cart
        cartViewModel.loadCarts()
        
        print("🔄 HomeViewModel: After loadCarts - available carts: \(cartViewModel.carts.count)")
        
        // store the pending cart immediately
        if let exactCart = cartViewModel.carts.first(where: { $0.id == createdCart.id }) {
            print("🎯 HomeViewModel: Found exact cart in list - queuing as pending")
            self.pendingSelectedCart = exactCart
        } else {
            print("⚠️ HomeViewModel: Cart not found in list, queuing created cart")
            self.pendingSelectedCart = createdCart
        }
        
        showVault = false
        
        print("✅ HomeViewModel: Vault closed, pendingSelectedCart set to: \(pendingSelectedCart?.name ?? "nil")")
    }
    
    // transfer pending cart
    func transferPendingCart() {
        if let pending = pendingSelectedCart {
            print("✅ Transferring pending to selectedCart: \(pending.name)")
            selectedCart = pending
            pendingSelectedCart = nil
        }
    }
    
    //check for pending cart on view appear
    func checkPendingCart() {
        if let pending = pendingSelectedCart {
            print("🔍 Found pending cart on appear: \(pending.name)")
            transferPendingCart()
        }
    }
}
