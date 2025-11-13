//
//  HomeViewModel.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/12/25.
//

import Foundation
import SwiftUI
import SwiftData
import Observation

@MainActor
@Observable
final class HomeViewModel {
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let cartViewModel: CartViewModel
    private let vaultService: VaultService
    // Remove vaultService dependency - we get it from cartViewModel
    
    // MARK: - UI State
    var selectedTab: Int = 0
    var showVault: Bool = false
    var selectedCart: Cart?
    var pendingSelectedCart: Cart? = nil
    
    // MARK: - Animation States
    var showMenu = false
    var isDismissed = false
    var headerHeight: CGFloat = 0
    
    // MARK: - Computed Properties
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
    
    var hasCarts: Bool {
        !carts.isEmpty
    }
    
    // MARK: - Initialization
    init(modelContext: ModelContext, cartViewModel: CartViewModel, vaultService: VaultService) {
         self.modelContext = modelContext
         self.cartViewModel = cartViewModel
         self.vaultService = vaultService
     }
    
    // MARK: - Navigation Methods
    func shouldAutoSelectCart() -> Bool {
        return selectedCart == nil && !activeCarts.isEmpty
    }
    
    func getMostRecentActiveCart() -> Cart? {
        return activeCarts.sorted { $0.createdAt > $1.createdAt }.first
    }
    
    // MARK: - User Actions
    func handleCreateCart() {
        print("🏠 Create cart button tapped")
        showVault = true
    }
    
    func handleVaultButton() {
        print("🏠 Vault button tapped")
        showVault = true
    }
    
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
        print("🏠 Carts loaded: \(cartViewModel.carts.count)")
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
            print("🎯 HomeViewModel: Found exact cart in list - queuing as pending")
            self.pendingSelectedCart = exactCart
        } else {
            print("⚠️ HomeViewModel: Cart not found in list, queuing created cart")
            self.pendingSelectedCart = createdCart
        }
        
        showVault = false
        
        print("✅ HomeViewModel: Vault closed, pendingSelectedCart set to: \(pendingSelectedCart?.name ?? "nil")")
    }
    
    // MARK: - Cart Selection
    func transferPendingCart() {
        if let pending = pendingSelectedCart {
            print("✅ Transferring pending to selectedCart: \(pending.name)")
            selectedCart = pending
            pendingSelectedCart = nil
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
        // Clear the vault using vaultService
        if let vault = vaultService.vault {
            // Clear all items and categories from the vault
            vault.categories.forEach { category in
                category.items.removeAll()
            }
            vault.categories.removeAll()
            vault.carts.removeAll()
        }

        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("❌ Error saving after reset: \(error)")
        }

        // Reset celebration flags
        UserDefaults.standard.set(false, forKey: "hasSeenFirstShoppingCartCelebration")
        UserDefaults.standard.set(false, forKey: "hasSeenVaultCelebration")
        UserDefaults.standard.hasCompletedOnboarding = false

        // Reload carts to reflect the reset state
        cartViewModel.loadCarts()

        print("✅ Reset done: Vault cleared and celebration flags reset")
        print("   - hasSeenFirstShoppingCartCelebration: false")
        print("   - hasSeenVaultCelebration: false")
        print("   - hasCompletedOnboarding: false")
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
}
