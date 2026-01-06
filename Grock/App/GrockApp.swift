//import SwiftUI
//import SwiftData
//
//struct ContentView: View {
//    @Environment(\.modelContext) private var modelContext
//    @State private var vaultService: VaultService
//    @State private var cartViewModel: CartViewModel
//    @State private var homeViewModel: HomeViewModel
//    
//    init(modelContext: ModelContext) {
//        let vaultService = VaultService(modelContext: modelContext)
//        _vaultService = State(initialValue: vaultService)
//        
//        let cartViewModel = CartViewModel(vaultService: vaultService)
//        _cartViewModel = State(initialValue: cartViewModel)
//        
//        _homeViewModel = State(initialValue: HomeViewModel(
//            modelContext: modelContext,
//            cartViewModel: cartViewModel,
//            vaultService: vaultService 
//        ))
//    }
//    
//    var body: some View {
//        Group {
//            if UserDefaults.standard.hasCompletedOnboarding {
//                HomeView(viewModel: homeViewModel)
//                    .environment(vaultService)
//                    .environment(cartViewModel)
//            } else {
//                OnboardingContainer()
//                    .environment(vaultService)
//                    .environment(cartViewModel)
//                    .environment(homeViewModel)
//            }
//        }
//    }
//}
//
//@main
//struct GrockApp: App {
//    let container: ModelContainer
//    
//    init() {
//        do {
//            // MARK: *DEV
//            // Always start with fresh database during development
//            let schema = Schema([
//                User.self, Vault.self, Category.self, Item.self,
//                PriceOption.self, PricePerUnit.self, Cart.self, CartItem.self
//            ])
//            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//            
//            // 🔥 DELETE EXISTING DATABASE TO FIX MIGRATION
//            if FileManager.default.fileExists(atPath: config.url.path) {
//                try FileManager.default.removeItem(at: config.url)
//                print("🗑️ Deleted old database to fix migration issues")
//            }
//            
//            container = try ModelContainer(for: schema, configurations: config)
//            print("✅ Created fresh persistent database")
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentViewWrapper()
//        }
//        .modelContainer(container)
//    }
//}
//
//struct ContentViewWrapper: View {
//    @Environment(\.modelContext) private var modelContext
//    
//    var body: some View {
//        ContentView(modelContext: modelContext)
//    }
//}

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vaultService: VaultService
    @State private var cartViewModel: CartViewModel
    @State private var homeViewModel: HomeViewModel
    @State private var cartStateManager: CartStateManager  // Add this
    
    init(modelContext: ModelContext) {
        let vaultService = VaultService(modelContext: modelContext)
        _vaultService = State(initialValue: vaultService)
        
        let cartViewModel = CartViewModel(vaultService: vaultService)
        _cartViewModel = State(initialValue: cartViewModel)
        
        _homeViewModel = State(initialValue: HomeViewModel(
            modelContext: modelContext,
            cartViewModel: cartViewModel,
            vaultService: vaultService
        ))
        
        // Initialize CartStateManager
        _cartStateManager = State(initialValue: CartStateManager())
    }
    
    var body: some View {
        Group {
            if UserDefaults.standard.hasCompletedOnboarding {
                HomeView(viewModel: homeViewModel)
                    .environment(vaultService)
                    .environment(cartViewModel)
                    .environment(cartStateManager)
            } else {
                OnboardingContainer()
                    .environment(vaultService)
                    .environment(cartViewModel)
                    .environment(homeViewModel)
                    .environment(cartStateManager)
            }
        }
    }
}

@main
struct GrockApp: App {
    let container: ModelContainer
    
//    init() {
//        do {
//            let schema = Schema([
//                User.self, Vault.self, Category.self, Item.self,
//                PriceOption.self, PricePerUnit.self, Cart.self, CartItem.self
//            ])
//            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//            
//            #if DEBUG
//            // DEVELOPMENT: Delete database on each launch
//            if FileManager.default.fileExists(atPath: config.url.path) {
//                try FileManager.default.removeItem(at: config.url)
//                print("🗑️ Deleted old database (DEBUG mode)")
//            }
//            #endif
//            
//            container = try ModelContainer(for: schema, configurations: config)
//            
//            #if DEBUG
//            print("✅ Created fresh database (DEBUG mode)")
//            #else
//            print("✅ Loaded persistent database (PRODUCTION)")
//            #endif
//        } catch {
//            fatalError("Could not create ModelContainer: \(error)")
//        }
//    }
    init() {
        do {
            // MARK: *PRODUCTION
            // Persistent database - data will be preserved between app launches
            let schema = Schema([
                User.self, Vault.self, Category.self, Item.self,
                PriceOption.self, PricePerUnit.self, Cart.self, CartItem.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            
            // ✅ PRODUCTION: Comment out database deletion code
            /*
            // 🔥 DELETE EXISTING DATABASE TO FIX MIGRATION
            if FileManager.default.fileExists(atPath: config.url.path) {
                try FileManager.default.removeItem(at: config.url)
                print("🗑️ Deleted old database to fix migration issues")
            }
            */
            
            container = try ModelContainer(for: schema, configurations: config)
            print("✅ Loaded persistent database (data preserved)")
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
