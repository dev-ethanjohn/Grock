//
//  OnboardingContainer.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

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
    @Environment(\.modelContext) private var context
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
                    removal: .identity // prevent reanimating again
                ))
            }

            if step == .firstItem {
                OnboardingFirstItemView(
                    viewModel: viewModel,
                    onFinish: {
                        //*vaultService is guaranteed to be available
                        viewModel.saveInitialData(vaultService: vaultService)
                        UserDefaults.standard.hasCompletedOnboarding = true
                        
                        withAnimation(.easeOut(duration: 0.2)) {
                            showPageIndicator = false
                        }
                        
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
                HomeView()
                    .environment(vaultService)
                    .environment(CartViewModel(vaultService: vaultService))
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
        
        print("📝 NEW ITEM DATA:")
        print("   Name: '\(viewModel.itemName)'")
        print("   Category: '\(viewModel.categoryName)'")
        print("   Store: '\(viewModel.storeName)'")
        print("   Price: ₱\(viewModel.itemPrice ?? 0)")
        print("   Unit: \(viewModel.unit)")
        
        if let vault = vaultService.vault {
            print("\n📦 VAULT SUMMARY:")
            print("   Categories: \(vault.categories.count)")
            
            let totalItems = vault.categories.reduce(0) { $0 + $1.items.count }
            print("   Total Items: \(totalItems)")
            
            for category in vault.categories {
                if !category.items.isEmpty {
                    print("   📁 \(category.name): \(category.items.count) items")
                    for item in category.items {
                        print("      🛒 \(item.name)")
                    }
                }
            }
        }
    }
}
