//
//  OnboardingLastStoreView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import SwiftUI

struct OnboardingLastStoreView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Binding var storeFieldAnimated: Bool
    @Binding var hasShownInfoDropdown: Bool
    var onNext: () -> Void
    var onSkip: () -> Void
    
    @FocusState private var storeFieldIsFocused: Bool
    @State private var showTextField = false
    @State private var showNextButton = false
    @State private var fillAnimation: CGFloat = 0.0
    @State private var showInfoDropdown = false
    @State private var buttonScale: CGFloat = 1.0
    @State private var shakeOffset: CGFloat = 0
    @State private var showError = false
    
    var body: some View {
        VStack {
            
            HStack {
                Spacer()
                Button("Skip") {
                    onSkip()
                }
                .font(.fuzzyBold_16)
                .foregroundColor(.secondary)
            }
            .padding(.top)
            .padding(.horizontal)
            
            Spacer()
                .frame(height: 60)
            
            Text("Where was your last grocery trip?")
                .font(.fuzzyBold_24)
                .multilineTextAlignment(.center)

            
            TextField("e.g. Walmart, SM, Costco", text: $viewModel.storeName)
                .multilineTextAlignment(.center)
                .autocorrectionDisabled()
                .padding(.vertical, 8)
                .overlay(
                    VStack {
                        Spacer()
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                )
                .focused($storeFieldIsFocused)
                .scaleEffect(showTextField ? 1.0 : 0.0)
                .opacity(showTextField ? 1.0 : 0.0)
                .padding(.horizontal, 60)
                .padding(.top, 28)
            
            
            // Character requirement hint
            if showError {
                Text("Store name needs at least 2 characters")
                    .font(.caption)
                    .foregroundColor(Color(hex: "FF6F71"))
                    .padding(.top, 8)
                    .scaleEffect(showError ? 1.0 : 0)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.25), value: showError)
            }

            
            Spacer()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showInfoDropdown = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showInfoDropdown = false
                        }
                    }
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .overlay(alignment: .topLeading) {
                    if showInfoDropdown {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Add  store so prices match where you shop — not just estimates.")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .padding(12)
                                .multilineTextAlignment(.leading)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Material.ultraThick)
                                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 4)
                        )
                        .frame(width: 240)
                        .frame(height: 200)
                        .offset(x: 12, y: -120)
                        .transition(.asymmetric(
                               insertion: .scale(scale: 0.85, anchor: .topLeading)
//                                   .combined(with: .opacity)
                                   .animation(.spring(response: 0.35, dampingFraction: 0.65)),
                               removal: .scale(scale: 0.95, anchor: .topLeading)
                                   .combined(with: .opacity)
                                   .animation(.spring(response: 0.25, dampingFraction: 0.75))
                           ))
                    }
                }
                
                Spacer()
                
                Button {
                    guard viewModel.storeName.count >= 2 else {
                        triggerError()
                        return
                    }
                    onNext()
                } label: {
                    Text("Next")
                        .font(.fuzzyBold_16)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 24)
                        .background(
                            Capsule()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.black, Color.gray.opacity(0.3)],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: fillAnimation * 80
                                    )
                                )
                        )
                        .scaleEffect(showNextButton ? buttonScale : 0.0)
                        .offset(x: shakeOffset)
                }

            }
            .padding(.vertical, 8)
            .padding(.horizontal)
        }
        .onAppear {
            // animate only if it hasn't animated yet in this session
            if !storeFieldAnimated {
                showTextField = false
                showNextButton = false
                withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
                    showTextField = true
                }
                // Delay the next button animation slightly
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2)) {
                    showNextButton = true
                }
                storeFieldIsFocused = true
                storeFieldAnimated = true // mark as animated
            } else {
                // just show field immediately without animation
                showTextField = true
                showNextButton = true
                storeFieldIsFocused = true
            }
            
            // NEW: Check if text exists and restore fill animation
            if !viewModel.storeName.isEmpty {
                fillAnimation = 1.0
                startButtonBounce() // Start bounce if text already exists
            }
            
            if !hasShownInfoDropdown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showInfoDropdown = true
                    }
                    hasShownInfoDropdown = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showInfoDropdown = false
                        }
                    }
                }
            }
        }
        .onChange(of: viewModel.storeName) { oldValue, newValue in
            if newValue.count >= 2 {
                if oldValue.count < 2 {
                    // Just reached requirement
                    withAnimation(.spring(duration: 0.4)) {
                        fillAnimation = 1.0
                    }
                    startButtonBounce()
                }
                // Always hide error once valid
                showError = false
            } else {
                // Just reset visuals (not error display!)
                withAnimation(.easeInOut(duration: 0.3)) {
                    fillAnimation = 0.0
                    buttonScale = 1.0
                }
                // ❌ Do NOT set showError = true here
            }
        }

    }
    
    // Bounce animation function
    private func startButtonBounce() {
        // Start immediately without the 0.2s delay
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            buttonScale = 0.95
        }
        
        // Then scale up to 1.1 with bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                buttonScale = 1.1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                buttonScale = 1.0
            }
        }
    }
    
    // Error feedback with shake and haptic
    private func triggerError() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        // Show error state
        showError = true
        
        // Visual shake animation
        let shakeSequence = [0, -8, 8, -6, 6, -4, 4, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    shakeOffset = CGFloat(offset)
                }
            }
        }
        
        // Hide error after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showError = false
            }
        }
    }
}


#Preview {
    OnboardingLastStoreView(viewModel: OnboardingViewModel(), storeFieldAnimated: .constant(false), hasShownInfoDropdown: .constant(false), onNext: {}, onSkip: {})
}
