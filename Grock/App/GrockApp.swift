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
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var vaultService: VaultService
    @State private var cartViewModel: CartViewModel
    @State private var homeViewModel: HomeViewModel
    @State private var cartStateManager: CartStateManager  // Add this
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showFreeStoreSelectionSheet = false
    
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
        .onAppear {
            refreshStoreSelectionRequirement()
            refreshSubscriptionStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshSubscriptionStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionStatusChanged)) { notification in
            let isPro = (notification.userInfo?["isPro"] as? Bool) ?? subscriptionManager.isPro
            refreshStoreSelectionRequirement(isPro: isPro)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showProUnlockedCelebration)) { notification in
            Task { @MainActor in
                let featureRawValue = notification.userInfo?["featureFocus"] as? String
                let featureFocus = featureRawValue.flatMap(GrockPaywallFeatureFocus.init(rawValue:))
                let contextRawValue = notification.userInfo?["celebrationContext"] as? String
                let celebrationContext = contextRawValue.flatMap(ProUnlockCelebrationContext.init(rawValue:))
                ProUnlockedCelebrationPresenter.shared.show(
                    featureFocus: featureFocus,
                    celebrationContext: celebrationContext
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleProUnlockedCelebration)) { _ in
            Task { @MainActor in
                ProUnlockedCelebrationPresenter.shared.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DataUpdated"))) { _ in
            refreshStoreSelectionRequirement(isPro: subscriptionManager.isPro)
        }
        .sheet(isPresented: $showFreeStoreSelectionSheet) {
            FreeStoreSelectionSheet(isPresented: $showFreeStoreSelectionSheet)
                .environment(vaultService)
                .interactiveDismissDisabled(true)
        }
    }

    private func refreshStoreSelectionRequirement(isPro: Bool? = nil) {
        let resolvedIsPro = isPro ?? subscriptionManager.isPro
        showFreeStoreSelectionSheet = vaultService.isFreeStoreSelectionRequired(isPro: resolvedIsPro)
    }

    private func refreshSubscriptionStatus() {
        Task { @MainActor in
            await subscriptionManager.refreshCustomerInfo()
            refreshStoreSelectionRequirement(isPro: subscriptionManager.isPro)
        }
    }
}

@main
struct GrockApp: App {
    let container: ModelContainer
    private static let userJotProjectIdKey = "USERJOT_PROJECT_ID"
    private static let revenueCatApiKeyKey = "REVENUECAT_API_KEY"
    private static let debugFallbackRevenueCatApiKey = "test_uifCKvbwWxUoARrWWcwzcpSlIud"
    
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
            #if DEBUG
            apiKey = Self.debugFallbackRevenueCatApiKey
            print("⚠️ Using RevenueCat Test Store key in DEBUG.")
            #else
            print("❌ Missing REVENUECAT_API_KEY in Info.plist. RevenueCat not configured.")
            return
            #endif
        }

        #if DEBUG
        Purchases.logLevel = .debug
        #else
        Purchases.logLevel = .warn

        if apiKey.lowercased().hasPrefix("test_") {
            print("❌ Test Store API key detected in RELEASE build. RevenueCat not configured.")
            return
        }
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
