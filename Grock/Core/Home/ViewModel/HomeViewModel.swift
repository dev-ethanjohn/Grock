//
//  HomeViewModel.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/15/25.
//

import Foundation

import SwiftUI
import SwiftData
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var showVault: Bool = false
    @Published var isGuided: Bool = true
    
    // REMOVE these - we'll use selectedCart for everything
    // @Published var newlyCreatedCart: Cart? = nil
    // @Published var showCartPage: Bool = false
    
    private let modelContext: ModelContext
    private let cartViewModel: CartViewModel
    
    @Published var selectedCart: Cart?  // Use this for ALL cart presentations
    
    init(modelContext: ModelContext, cartViewModel: CartViewModel) {
        self.modelContext = modelContext
        self.cartViewModel = cartViewModel
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
    
    func handleCreateCart() {
        showVault = true
        if isGuided {
            isGuided = false
        }
    }
    
    func handleVaultButton() {
        showVault = true
        if isGuided {
            isGuided = false
        }
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
    }
    
    func getVaultService(for cart: Cart) -> VaultService? {
        cartViewModel.getVaultService
    }
    
    func onCreateCartFromVault(_ createdCart: Cart) {
        showVault = false
        // Set selectedCart instead of newlyCreatedCart
        selectedCart = createdCart
    }
}
