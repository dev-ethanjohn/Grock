import SwiftUI

struct VaultBottomContent: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    let totalVaultItemsCount: Int
    let hasActiveItems: Bool
    let existingCart: Cart?
    let showLeftChevron: Bool
    let showRightChevron: Bool
    let createCartButtonVisible: Bool
    let buttonScale: CGFloat
    let fillAnimation: CGFloat
    
    @Binding var showCartConfirmation: Bool
    var navigationDirection: VaultView.NavigationDirection
    
    let onNavigatePrevious: () -> Void
    let onNavigateNext: () -> Void
    let onAddItemsToCart: (([String: Double]) -> Void)?
    let dismissKeyboard: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            ZStack(alignment: .bottom) {
                if totalVaultItemsCount >= 2 {
                    gradientOverlay
                }
                
                HStack {
                    leftChevronButton
                    Spacer()
                    createCartButton
                    Spacer()
                    rightChevronButton
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    private var gradientOverlay: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.white.opacity(0.0), location: 0.0),
                    .init(color: Color.white.opacity(0.6), location: 0.25),
                    .init(color: Color.white.opacity(0.95), location: 0.55),
                    .init(color: Color.white.opacity(1.0), location: 1.0),
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: 150)
        .allowsHitTesting(false)
    }
    
    private var leftChevronButton: some View {
        Group {
            if showLeftChevron {
                Button(action: onNavigatePrevious) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Material.thin)
                                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
                        )
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showLeftChevron)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
            }
        }
    }
    
    private var rightChevronButton: some View {
        Group {
            if showRightChevron {
                Button(action: onNavigateNext) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Material.thin)
                                .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 2)
                        )
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showRightChevron)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 44, height: 44)
            }
        }
    }
    
    private var createCartButton: some View {
        Button(action: {
            dismissKeyboard()
            
            if existingCart != nil {
                onAddItemsToCart?(cartViewModel.activeCartItems)
                dismiss()
            } else {
                withAnimation {
                    showCartConfirmation = true
                }
            }
        }) {
            Text(existingCart != nil ? "Add to Cart" : "Create cart")
                .fuzzyBubblesFont(16, weight: .bold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .frame(height: 44)
                .background(buttonBackground)
                .cornerRadius(25)
        }
        .overlay(alignment: .topLeading) {
            if hasActiveItems {
                cartBadge
            }
        }
        .buttonStyle(.solid)
        .scaleEffect(createCartButtonVisible ? buttonScale : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: createCartButtonVisible)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
        .disabled(!hasActiveItems)
    }
    
    private var buttonBackground: some View {
        Capsule()
            .fill(
                hasActiveItems
                ? RadialGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    center: .center,
                    startRadius: 0,
                    endRadius: fillAnimation * 300
                )
                : RadialGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 0
                )
            )
    }
    
    private var cartBadge: some View {
        Text("\(cartViewModel.activeCartItems.count)")
            .fuzzyBubblesFont(16, weight: .bold)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cartViewModel.activeCartItems.count)
            .foregroundColor(.black)
            .frame(width: 25, height: 25)
            .background(Color.white)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.black, lineWidth: 2)
            )
            .offset(x: -8, y: -4)
            .scaleEffect(createCartButtonVisible ? 1 : 0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.6),
                value: createCartButtonVisible
            )
    }
}
