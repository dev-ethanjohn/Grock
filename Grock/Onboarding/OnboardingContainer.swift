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
    @State private var storeFieldAnimated = false


    @State private var viewModel = OnboardingViewModel()
    @Namespace private var animationNamespace
    @State private var showPageIndicator = false
    @State private var  hasShownInfoDropdown = false

    var body: some View {
        ZStack {
            // Main content layers
            if step == .welcome {
                OnboardingWelcomeView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        step = .lastStore
                    }
                    
                    // Animate indicator in separately with delay
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
                    storeFieldAnimated: $storeFieldAnimated, hasShownInfoDropdown: $hasShownInfoDropdown
                ) {
                    withAnimation(.spring(response: 0.5 , dampingFraction: 0.9)) {
                    step = .firstItem
                    }
                } onSkip: {
                    withAnimation(.spring(response: 0.5 , dampingFraction: 1)) {
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
                        viewModel.saveInitialData(context: context)
                        UserDefaults.standard.hasCompletedOnboarding = true
                        
                        // Hide indicator before transitioning to done
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
                    },
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading), // FirstItem moves in from the left
                    removal: .move(edge: .leading) // FirstItem moves out to the left when going back
                ))
            }

            if step == .done {
                HomeView()
                    .transition(.opacity)
            }
            
            // Page indicator overlay - only show for lastStore and firstItem
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
}

// MARK: - Page Indicator Component
struct PageIndicator: View {
    let currentStep: OnboardingStep
    
    private var currentIndex: Int {
        switch currentStep {
        case .lastStore: return 0
        case .firstItem: return 1
        default: return 0
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.primary : Color.primary.opacity(0.25))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentIndex ? 1.3 : 1.0)
            }
            .padding(.top, 8)
        }
    }
}
