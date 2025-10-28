import SwiftUI
import SwiftData

enum OnboardingStep {
    case welcome
    case lastStore
    case firstItem
    case done
}

struct OnboardingContainer: View {
    @State private var step: OnboardingStep = .welcome
    @Environment(\.modelContext) private var modelContext
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(VaultService.self) private var vaultService
    @State private var storeFieldAnimated = false

    @State private var viewModel = OnboardingViewModel()
    @Namespace private var animationNamespace
    @State private var showPageIndicator = false
    @State private var hasShownInfoDropdown = false

    var body: some View {
        ZStack {
            if step == .welcome {
                OnboardingWelcomeView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        step = .lastStore
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showPageIndicator = true
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            if step == .lastStore {
                OnboardingLastStoreView(
                    viewModel: viewModel,
                    storeFieldAnimated: $storeFieldAnimated,
                    hasShownInfoDropdown: $hasShownInfoDropdown
                ) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        step = .firstItem
                    }
                } onSkip: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 1)) {
                        step = .firstItem
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .identity
                ))
            }

            if step == .firstItem {
                OnboardingFirstItemView(
                    viewModel: viewModel,
                    onFinish: {
                        // ✅ Only save to vault
                        viewModel.saveInitialData(vaultService: vaultService)
                        
                        // ✅ Save data for preloading into active items
                        UserDefaults.standard.set([
                            "itemName": viewModel.itemName,
                            "categoryName": viewModel.categoryName,
                            "portion": viewModel.portion ?? 1.0
                        ] as [String : Any], forKey: "onboardingItemData")
                        
                        // Mark onboarding as complete
                        UserDefaults.standard.hasCompletedOnboarding = true
                        
                        withAnimation(.easeOut(duration: 0.2)) {
                            showPageIndicator = false
                        }
                        
                        // ✅ Transition to done (HomeView will auto-show vault)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            step = .done
                        }
                    },
                    onBack: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 1)) {
                            step = .lastStore
                        }
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .leading)
                ))
            }

            if step == .done {
                OnboardingCompletedHomeView(
                    modelContext: modelContext,
                    cartViewModel: cartViewModel,
                    vaultService: vaultService
                )
                .transition(.opacity)
                .onAppear {
                    printOnboardingCompletion()
                }
            }

            if (step == .lastStore || step == .firstItem) && showPageIndicator {
                VStack {
                    PageIndicator(currentStep: step)
                        .padding(.top)
                        .scaleEffect(showPageIndicator ? 1.0 : 0.0)
                        .opacity(showPageIndicator ? 1.0 : 0.0)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: step)
        .onChange(of: step) { oldValue, newValue in
            if newValue == .welcome || newValue == .done {
                withAnimation(.easeOut(duration: 0.1)) {
                    showPageIndicator = false
                }
            }
        }
    }
    
    private func printOnboardingCompletion() {
        print("\n🎯 ONBOARDING COMPLETE - DATA CHECK")
        // ... your existing print code
    }
}

struct OnboardingCompletedHomeView: View {
    let modelContext: ModelContext
    let cartViewModel: CartViewModel
    let vaultService: VaultService
    
    var body: some View {
        HomeView(
            modelContext: modelContext,
            cartViewModel: cartViewModel,
            shouldAutoShowVault: true  // ✅ Flag to auto-open vault
        )
        .environment(vaultService)
        .environment(cartViewModel)
        .onAppear {
            // ✅ Preload onboarding item into activeCartItems
            preloadOnboardingItem()
        }
    }
    
    private func preloadOnboardingItem() {
        guard let data = UserDefaults.standard.dictionary(forKey: "onboardingItemData"),
              let itemName = data["itemName"] as? String,
              let categoryName = data["categoryName"] as? String,
              let portion = data["portion"] as? Double,
              let category = vaultService.vault?.categories.first(where: { $0.name == categoryName }),
              let item = category.items.first(where: { $0.name == itemName }) else {
            print("⚠️ Could not preload onboarding item")
            return
        }
        
        cartViewModel.activeCartItems[item.id] = portion
        print("✅ Preloaded onboarding item '\(itemName)' with portion \(portion) into activeCartItems")
        
        // Optional: Clear temp data
        UserDefaults.standard.removeObject(forKey: "onboardingItemData")
    }
}
