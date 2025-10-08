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
    
    // Initialize services immediately with the context
    init(modelContext: ModelContext) {
        let vaultService = VaultService(modelContext: modelContext)
        _vaultService = State(initialValue: vaultService)
        _cartViewModel = State(initialValue: CartViewModel(vaultService: vaultService))
    }
    
    var body: some View {
        Group {
            if UserDefaults.standard.hasCompletedOnboarding {
                HomeView()
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
            // ✅ DEVELOPMENT: In-memory database (resets on app close)
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: Vault.self, Category.self, Item.self, configurations: config)
            print("✅ Development: Using in-memory database")
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

// Helper view to get the modelContext
struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ContentView(modelContext: modelContext)
    }
}
