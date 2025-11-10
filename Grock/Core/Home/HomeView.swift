import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var headerHeight: CGFloat = 0
    
    @Environment(\.modelContext) private var modelContext
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    
    @State  var showMenu = false
    
    @State  var viewModel: HomeViewModel
    @State  var isDismissed: Bool = false
    
    func toggleMenu() {
        showMenu.toggle()
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                
                Color.white.ignoresSafeArea()
                
                MenuView()
                    .opacity(showMenu ? 1 : 0)
                    .offset(x: showMenu ? 0 : -300)
                    .rotation3DEffect(.degrees(showMenu ? 0 : 30), axis: (x: 0, y: 1, z: 0))
                
                mainContent
                 
                
                
                MenuIcon {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        print("menu tapped")
                        toggleMenu()
                    }
                }
                .padding(.top, 110)
                .offset(x: showMenu ? 80 : -20,
                        y: showMenu ? -60 : isDismissed ? -120 : 0)
                .opacity(showMenu ? 1 : 0)
                .onChange(of: showMenu) {_, newValue in
                    if !newValue {
                        isDismissed = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                isDismissed = false
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .sheet(isPresented: $viewModel.showVault) {
                vaultSheet
            }
            .fullScreenCover(item: $viewModel.selectedCart) { cart in
                CartDetailScreen(cart: cart)
                    .onDisappear {
                        viewModel.selectedCart = nil
                    }
            }
            .onAppear {
                viewModel.loadCarts()
                print("🏠 HomeView appeared - carts: \(viewModel.carts.count)")
                
                // ✅ FIX: Check for pending cart immediately on appear
                viewModel.checkPendingCart()
            }
            .onChange(of: viewModel.showVault) { oldValue, newValue in
                // ✅ FIX: Set selectedCart after vault fully dismisses
                if !newValue {
                    viewModel.transferPendingCart()
                }
            }
            .onChange(of: viewModel.selectedCart) { oldValue, newValue in
                print("🔄 HomeView: selectedCart changed to \(newValue?.name ?? "nil")")
            }
        }
    }
    
    
    private var mainContent: some View {
        ZStack(alignment: .topLeading) {
            
            Color.white.ignoresSafeArea()
            //1
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
                                cartRowButton(cart: cart)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            
            //2
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    trailingToolbarButton
                }
                .padding(.trailing)
                .padding(.top, 60)
                
                
                VStack(spacing: 24) {
                    greetingText
                    tabButtons
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity)
            .background(headerBackground)
            .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                headerHeight = geometry.size.height
                            }
                            .onChange(of: geometry.size.height) { oldValue, newValue in
                                headerHeight = newValue
                            }
                    }
                )
            
            HStack {
                MenuIcon() {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        print("menu tapped")
                        toggleMenu()
                    }
                }
                
                Menu {
                    Button(role: .destructive, action: viewModel.resetApp) {
                        Label("Reset App (Testing)", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 20)
                }
            }
            .padding(.top, 60)
            .padding(.leading)
            .offset(x: showMenu ? 40 : 0, y: showMenu ? 40 : 0)
            .opacity(showMenu ? 0 : 1)
            
            //3
            VStack {
                Spacer()
                createCartButton
                    .padding(.horizontal)
            }
        }
        .ignoresSafeArea()
        .mask(RoundedRectangle(cornerRadius: showMenu ? 30 : 24, style: .continuous))
        .rotation3DEffect(.degrees(showMenu ? 30 : 0), axis: (x: 0, y: -1, z: 0))
        .offset(x: showMenu ? 265 : 0)
        .scaleEffect(showMenu ? 0.9 : 1)
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: -2, y: -5)
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 2, y: 0)
      
        
    }
    
    private func cartRowButton(cart: Cart) -> some View {
        Button(action: {
            viewModel.selectedCart = cart
        }) {
            HomeCartRowView(cart: cart, vaultService: viewModel.getVaultService(for: cart))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
//    private var customHeader: some View {
//        VStack(spacing: 0) {
//            HStack {
//                leadingToolbarButton
//                Spacer()
//                trailingToolbarButton
//            }
//            .padding(.horizontal)
//            .padding(.top, 60)
//            
//            VStack(spacing: 24) {
//                greetingText
//                tabButtons
//            }
//            .padding(.horizontal)
//            .padding(.bottom, 4)
//        }
//        .frame(maxWidth: .infinity)
//        .background(headerBackground)
//    }
    
    private var greetingText: some View {
        Text("Hi Ethan,")
            .lexendFont(36, weight: .bold)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var headerBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.white.opacity(0.85), location: 0),
                    .init(color: Color.white.opacity(0.95), location: 0.1),
                    .init(color: Color.white.opacity(1.0), location: 0.2)
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
//            BlurView()
//                .blur(radius: 6, opaque: true)
        }
    }
    
    private var headerBlur: some View {
                    BlurView(removeAllFilters: true)
                        .blur(radius: 6, opaque: true)
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
                .fuzzyBubblesFont(18, weight: .bold)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(.black)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .padding(.bottom)
        .padding(.bottom, 20)
    }
//    
//    private var leadingToolbarButton: some View {
//        HStack {
//            
////            Image("menu")
////                .resizable()
////                .frame(width: 24, height: 20)
//            
//            Menu {
//                Button(role: .destructive, action: viewModel.resetApp) {
//                    Label("Reset App (Testing)", systemImage: "arrow.counterclockwise")
//                }
//            } label: {
//                Image(systemName: "arrow.counterclockwise")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 24, height: 20)
//            }
//        }
//        
//    }
    
    private var trailingToolbarButton: some View {
        Button(action: viewModel.handleVaultButton) {
            HStack(spacing: 8) {
                Text("vault")
                    .fuzzyBubblesFont(13, weight: .bold)
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
                .environment(vaultService)
                .environment(cartViewModel)
        }
    }
    
    private func autoSelectFirstCart() {
        if viewModel.shouldAutoSelectCart(), let mostRecentCart = viewModel.getMostRecentActiveCart() {
            print("🏠 Auto-selecting cart: \(mostRecentCart.name)")
            viewModel.selectedCart = mostRecentCart
        }
    }
}

struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
