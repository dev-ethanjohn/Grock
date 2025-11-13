import SwiftUI
import SwiftData

struct OnboardingContainer: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(VaultService.self) private var vaultService
    @Environment(HomeViewModel.self) private var homeViewModel
    @Namespace private var animationNamespace

    var body: some View {
        ZStack {
            if viewModel.currentStep == .welcome {
                OnboardingWelcomeView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }

            if viewModel.currentStep == .lastStore {
                OnboardingLastStoreView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .identity
                    ))
            }

            if viewModel.currentStep == .firstItem {
                OnboardingFirstItemView(viewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            }

            if viewModel.currentStep == .done {
                OnboardingCompletedHomeView()
                    .transition(.opacity)
                    .onAppear {
                        printOnboardingCompletion()
                    }
            }

            if (viewModel.currentStep == .lastStore || viewModel.currentStep == .firstItem) && viewModel.showPageIndicator {
                VStack {
                    PageIndicator(currentStep: viewModel.currentStep)
                        .padding(.top)
                        .scaleEffect(viewModel.showPageIndicator ? 1.0 : 0.0)
                        .opacity(viewModel.showPageIndicator ? 1.0 : 0.0)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.currentStep)
        .onChange(of: viewModel.currentStep) { oldValue, newValue in
            if newValue == .welcome || newValue == .done {
                withAnimation(.easeOut(duration: 0.1)) {
                    viewModel.showPageIndicator = false
                }
            }
        }
    }
    
    private func printOnboardingCompletion() {
        print("\n🎯 ONBOARDING COMPLETE - DATA CHECK")
    }
}

struct OnboardingCompletedHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(VaultService.self) private var vaultService
    @Environment(HomeViewModel.self) private var homeViewModel
    
    var body: some View {
        HomeView(viewModel: homeViewModel)
            .onAppear {
                preloadOnboardingItem()
                homeViewModel.showVault = true
            }
    }
    
    private func preloadOnboardingItem() {
        guard let data = UserDefaults.standard.dictionary(forKey: "onboardingItemData"),
              let itemName = data["itemName"] as? String,
              let categoryName = data["categoryName"] as? String,
              let category = vaultService.vault?.categories.first(where: { $0.name == categoryName }),
              let item = category.items.first(where: { $0.name == itemName }) else {
            print("⚠️ Could not preload onboarding item")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            cartViewModel.activeCartItems[item.id] = 1.0
            print("✅ Preloaded onboarding item '\(itemName)' with DEFAULT quantity 1 into activeCartItems")
            UserDefaults.standard.removeObject(forKey: "onboardingItemData")
        }
    }
}
