import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var selectedTab: Int = 0
    @State private var showVault: Bool = false
    @State private var showCartPage: Bool = false
    @Environment(\.modelContext) private var context
    @State private var isGuided: Bool = true
    
    //vault is presented as a sheet, sheets make new envi context. so need access the existing environment object
    @Environment(CartViewModel.self) private var cartViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                mainContent
                
                if isGuided {
                    tutorialOverlay
                    fingerPointer
                }
            }
            .toolbar { toolbarContent }
            .sheet(isPresented: $showVault) {
                vaultSheet
            }
            .navigationDestination(isPresented: $showCartPage) {
                CartPageView()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            greetingText
            tabButtons
            Spacer()
            emptyStateText
            Spacer()
            createCartButton
        }
        .padding(.horizontal)
    }
    
    private var greetingText: some View {
        Text("Hi Ethan,")
            .font(.largeTitle)
            .bold()
            .padding(.top)
    }
    
    private var tabButtons: some View {
        HStack {
            tabButton(title: "Planned", tabIndex: 0)
            tabButton(title: "History", tabIndex: 1)
        }
    }
    
    private func tabButton(title: String, tabIndex: Int) -> some View {
        Button(action: { selectedTab = tabIndex }) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedTab == tabIndex ? .black : .clear)
                .foregroundColor(selectedTab == tabIndex ? .white : .black)
                .clipShape(Capsule())
        }
        .disabled(isGuided)
    }
    
    private var emptyStateText: some View {
        Text("No carts yet! Create one to start shopping")
            .foregroundColor(.gray)
    }
    
    private var createCartButton: some View {
        Button(action: handleCreateCart) {
            Text("Create Cart")
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.black)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .disabled(isGuided)
        .padding(.bottom)
    }
    
    private var tutorialOverlay: some View {
        TutorialOverlay {
            showVault = true
            isGuided = false
        }
    }
    
    private var fingerPointer: some View {
        FingerPointer()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 20)
            .padding(.top, 60)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            leadingToolbarButton
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            trailingToolbarButton
        }
    }
    
    private var leadingToolbarButton: some View {
        Menu {
            Button(role: .destructive, action: resetApp) {
                Label("Reset App (Testing)", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "line.horizontal.3")
                .foregroundColor(.black)
        }
    }
    
    private var trailingToolbarButton: some View {
        Button(action: handleVaultButton) {
            HStack(spacing: 8) {
                Text("vault")
                    .font(.fuzzyBold_13)
                Image(systemName: "shippingbox")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 30))
        }
    }
    
    private var vaultSheet: some View {
        NavigationStack {
            VaultView(onCreateCart: {
                showVault = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showCartPage = true
                }
            })
            .environment(cartViewModel)
        }
    }
    
    // MARK: - Actions
    private func handleCreateCart() {
        showVault = true
        if isGuided { isGuided = false }
    }
    
    private func handleVaultButton() {
        showVault = true
        if isGuided { isGuided = false }
    }
    
    private func resetApp() {
        // Delete vaults (stores are now part of the vault hierarchy)
        let vaults = try? context.fetch(FetchDescriptor<Vault>())
        vaults?.forEach { context.delete($0) }

        try? context.save()

        // Reset onboarding flag
        UserDefaults.standard.hasCompletedOnboarding = false

        print("✅ Reset done: Vault cleared (stores are now strings within items)")
    }
}


struct FingerPointer: View {
    @State private var animateOffset: CGFloat = 0
    
    var body: some View {
        Text("👉")
            .font(.title2)
            .offset(x: animateOffset)
            .rotationEffect(.degrees(-30))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    animateOffset = 15
                }
            }
    }
}

struct TutorialOverlay: View {
    let onVaultTapped: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea(.all)
                .allowsHitTesting(false)
            
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    Text("👆 Tap the vault button to continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("This is where you'll manage your saved items")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 100)
                
                Spacer()
            }
        }
    }
}

// MARK: - Cart Page View
struct CartPageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CartViewModel.self) private var cartViewModel
    
    var body: some View {
        VStack {
            Text("Cart Content")
                .font(.title)
                .padding()
            
            Text("This is your cart page with navigation title")
                .foregroundColor(.gray)
            
            Spacer()
            
            Button("Go Back to Home") {
                dismiss()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle("cart")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    HomeView()
}
