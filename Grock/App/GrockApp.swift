//
//  GrockApp.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vaultService: VaultService
    @State private var cartViewModel: CartViewModel
    
    init(modelContext: ModelContext) {
        let vaultService = VaultService(modelContext: modelContext)
        _vaultService = State(initialValue: vaultService)
        _cartViewModel = State(initialValue: CartViewModel(vaultService: vaultService))
    }
    
    var body: some View {
        Group {
            if UserDefaults.standard.hasCompletedOnboarding {
                HomeView(modelContext: modelContext, cartViewModel: cartViewModel)
                    .environment(vaultService)
                    .environment(cartViewModel)
            } else {
                OnboardingContainer()
                    .environment(vaultService)
            }
        }
    }
}

@main
struct GrockApp: App {
    let container: ModelContainer
    
    init() {
        do {
            // MARK: *DEV
            // Always start with fresh database during development
            let schema = Schema([
                User.self, Vault.self, Category.self, Item.self,
                PriceOption.self, PricePerUnit.self, Cart.self, CartItem.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            // 🔥 DELETE EXISTING DATABASE TO FIX MIGRATION
            if FileManager.default.fileExists(atPath: config.url.path) {
                try FileManager.default.removeItem(at: config.url)
                print("🗑️ Deleted old database to fix migration issues")
            }
            
            container = try ModelContainer(for: schema, configurations: config)
            print("✅ Created fresh persistent database")
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentViewWrapper()
        }
        .modelContainer(container)
    }
}

struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ContentView(modelContext: modelContext)
    }
}
