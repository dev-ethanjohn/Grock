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
import UserJot
import RevenueCat

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
    private static let userJotProjectIdKey = "USERJOT_PROJECT_ID"
    private static let revenueCatApiKeyKey = "REVENUECAT_API_KEY"
    private static let fallbackRevenueCatApiKey = "test_xweOqIKUKoKfGiXNiaHyZxujWJj"
    
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
            configureRevenueCat()
            configureUserJot()
            Task { @MainActor in
                SubscriptionManager.shared.start()
            }
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
    
    private func configureUserJot() {
        guard let rawProjectId = Bundle.main.object(forInfoDictionaryKey: Self.userJotProjectIdKey) as? String else {
            print("⚠️ USERJOT_PROJECT_ID is missing in Info.plist")
            return
        }
        
        let projectId = rawProjectId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !projectId.isEmpty, projectId != "YOUR_PROJECT_ID" else {
            print("⚠️ USERJOT_PROJECT_ID is not configured. Set it in Info.plist.")
            return
        }
        
        UserJot.setup(projectId: projectId)
        print("✅ UserJot setup complete")
    }

    private func configureRevenueCat() {
        let infoPlistApiKey = (Bundle.main.object(forInfoDictionaryKey: Self.revenueCatApiKeyKey) as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let apiKey: String
        if let infoPlistApiKey, !infoPlistApiKey.isEmpty, infoPlistApiKey != "YOUR_REVENUECAT_API_KEY" {
            apiKey = infoPlistApiKey
        } else {
            apiKey = Self.fallbackRevenueCatApiKey
        }

        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn
        #endif

        if Purchases.isConfigured {
            print("ℹ️ RevenueCat already configured")
            return
        }

        Purchases.configure(withAPIKey: apiKey)
        print("✅ RevenueCat setup complete")
    }
}

struct ContentViewWrapper: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ContentView(modelContext: modelContext)
    }
}
