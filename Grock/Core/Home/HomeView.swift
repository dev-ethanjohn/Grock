import SwiftUI
import SwiftData

struct HomeView: View {
 
    @State private var headerHeight: CGFloat = 0
    
    @Environment(\.modelContext) private var modelContext
      @Environment(VaultService.self) private var vaultService
      @Environment(CartViewModel.self) private var cartViewModel
      @StateObject private var viewModel: HomeViewModel
      
      init(modelContext: ModelContext, cartViewModel: CartViewModel) {
          _viewModel = StateObject(wrappedValue: HomeViewModel(
              modelContext: modelContext,
              cartViewModel: cartViewModel
          ))
      }
    
    var body: some View {
        NavigationStack {
            ZStack {
                mainContent
                
                if viewModel.isGuided {
                    tutorialOverlay
                    fingerPointer
                }
            }
            .sheet(isPresented: $viewModel.showVault) {
                vaultSheet
            }
            .navigationDestination(isPresented: $viewModel.showCartPage) {
                if let cart = viewModel.newlyCreatedCart {
                    CartDetailView(cart: cart)
                        .onAppear {
                            viewModel.newlyCreatedCart = nil
                        }
                }
            }
            .navigationDestination(for: Cart.self) { cart in
                CartDetailView(cart: cart)
            }
            .onAppear {
                viewModel.loadCarts()
            }
        }
    }
    
    private var mainContent: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.carts.isEmpty {
                    emptyStateView
                        .padding(.top, headerHeight)
                        .padding(.horizontal)
                } else {
                    ScrollView {

                        Color.clear
                            .frame(height: headerHeight)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.displayedCarts) { cart in
                                NavigationLink(value: cart) {
                                    CartRowView(cart: cart, vaultService: viewModel.getVaultService(for: cart))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                     
                        Color.clear
                            .frame(height: 80)
                    }
                }
                
                Spacer()
            }
            
            customHeader
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                headerHeight = geometry.size.height
                            }
                            .onChange(of: geometry.size.height) {_, newHeight in
                                headerHeight = newHeight
                            }
                    }
                )
            
            VStack {
                Spacer()
                createCartButton
                    .padding(.horizontal)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    private var customHeader: some View {
        VStack(spacing: 0) {
            HStack {
                leadingToolbarButton
                Spacer()
                trailingToolbarButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            
            VStack(spacing: 24) {
                greetingText
                tabButtons
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
        .background(headerBackground)
    }
    
    private var greetingText: some View {
        Text("Hi Ethan,")
            .fuzzyBubblesFont(36, weight: .bold)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var headerBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.white.opacity(0.5), location: 0),
                    .init(color: Color.white.opacity(0.85), location: 0.2),
                    .init(color: Color.white.opacity(1.0), location: 0.4)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            HStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 14)
                Spacer()
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 14)
            }
            BlurView(removeAllFilters: true)
                .blur(radius: 6, opaque: true)
        }
    }
    
    private var tabButtons: some View {
        HStack(spacing: 4) {
            tabButton(title: "Planned", tabIndex: 0)
            tabButton(title: "History", tabIndex: 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func tabButton(title: String, tabIndex: Int) -> some View {
        Button(action: { viewModel.selectedTab = tabIndex }) {
            Text(title)
                .lexendFont(15)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(viewModel.selectedTab == tabIndex ? .black : .clear)
                .foregroundColor(viewModel.selectedTab == tabIndex ? .white : .black)
                .clipShape(Capsule())
        }
        .disabled(viewModel.isGuided)
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
    
    private var createCartButton: some View {
        Button(action: viewModel.handleCreateCart) {
            Text("Create Cart")
                .fontWeight(.semibold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.black)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .disabled(viewModel.isGuided)
        .padding(.bottom)
        .background(.white)
    }
    
    private var tutorialOverlay: some View {
        TutorialOverlay {
            viewModel.showVault = true
            viewModel.isGuided = false
        }
    }
    
    private var fingerPointer: some View {
        FingerPointer()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 20)
            .padding(.top, 120)
    }
    
    private var leadingToolbarButton: some View {
        Menu {
            Button(role: .destructive, action: viewModel.resetApp) {
                Label("Reset App (Testing)", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image("menu")
                .resizable()
                .frame(width: 24, height: 20)
        }
    }
    
    private var trailingToolbarButton: some View {
        Button(action: viewModel.handleVaultButton) {
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
            VaultView(onCreateCart: viewModel.onCreateCartFromVault)
    
        }
    }
}

//#Preview {
//    HomeView()
//}


