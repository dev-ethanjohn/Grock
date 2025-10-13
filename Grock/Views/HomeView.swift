import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var selectedTab: Int = 0
    @State private var showVault: Bool = false
    @State private var showCartPage: Bool = false
    @Environment(\.modelContext) private var context
    @State private var isGuided: Bool = true
    
    @State private var newlyCreatedCart: Cart? = nil
    
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
                if let cart = newlyCreatedCart {
                    CartDetailView(cart: cart)
                        .onAppear {
                            newlyCreatedCart = nil
                        }
                } else {
                    CartPageView() // Fallback
                }
            }
            .navigationDestination(for: Cart.self) { cart in
                CartDetailView(cart: cart)
            }
            .onAppear {
                cartViewModel.loadCarts()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            greetingText
            tabButtons
            
            if cartViewModel.carts.isEmpty {
                emptyStateView
            } else {
                cartsListView
            }
            
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
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No carts yet!")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Create your first cart to start shopping")
                .font(.body)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.vertical, 40)
    }
    
    private var cartsListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(selectedTab == 0 ? "Active Carts" : "Cart History")
                .font(.title2)
                .bold()
            
            List {
                ForEach(displayedCarts) { cart in
                    NavigationLink(value: cart) {
                        CartRowView(cart: cart)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(PlainListStyle())
            .frame(maxHeight: .infinity)
        }
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
    
    // MARK: - Computed Properties
    
    private var displayedCarts: [Cart] {
        switch selectedTab {
        case 0: // Planned (Active carts)
            return cartViewModel.activeCarts.sorted { $0.createdAt > $1.createdAt }
        case 1: // History (Completed carts)
            return cartViewModel.completedCarts.sorted { $0.createdAt > $1.createdAt }
        default:
            return []
        }
    }
    
    // ... rest of your existing code (tutorialOverlay, fingerPointer, toolbarContent, etc.) ...
    
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
            VaultView(onCreateCart: { createdCart in
                showVault = false
                newlyCreatedCart = createdCart
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
        let vaults = try? context.fetch(FetchDescriptor<Vault>())
        vaults?.forEach { context.delete($0) }

        try? context.save()

        UserDefaults.standard.hasCompletedOnboarding = false

        print("✅ Reset done: Vault cleared")
    }
}

// MARK: - Cart Row View (Add this to your HomeView file)
struct CartRowView: View {
    let cart: Cart
    
    private var itemCount: Int {
        cart.cartItems.count
    }
    
    private var isOverBudget: Bool {
        cart.totalSpent > cart.budget
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(cart.name)
                    .font(.fuzzyBold_16)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(cart.status.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(cart.status.color)
                    .cornerRadius(6)
            }
            
            HStack {
                Text("\(itemCount) item\(itemCount == 1 ? "" : "s")")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("₱\(cart.totalSpent, specifier: "%.2f")")
       
                    .foregroundColor(isOverBudget ? .red : .black)
                
                Text("/ ₱\(cart.budget, specifier: "%.2f")")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            // Budget progress bar
            if cart.budget > 0 {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(budgetProgressColor)
                            .frame(width: min(progressWidth(for: geometry.size.width), geometry.size.width), height: 4)
                    }
                    .cornerRadius(2)
                }
                .frame(height: 4)
            }
            
            Text("Created \(formattedDate)")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var budgetProgressColor: Color {
        let progress = cart.totalSpent / cart.budget
        if progress < 0.7 {
            return .green
        } else if progress < 0.9 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let progress = cart.totalSpent / cart.budget
        return CGFloat(min(progress, 1.0)) * totalWidth
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: cart.createdAt)
    }
}

// ... rest of your existing FingerPointer and TutorialOverlay code ...


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
