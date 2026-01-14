import SwiftData
import SwiftUI
import Lottie

struct HomeView: View {
    @AppStorage("hasShownVaultAnimation") private var hasShownVaultAnimation = false
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @State private var viewModel: HomeViewModel
    @State private var cartStateManager: CartStateManager
    @Namespace private var vaultButtonNamespace
    
    @State private var tabs: [CartTabsModel] = [
        .init(id: CartTabsModel.Tab.active),
        .init(id: CartTabsModel.Tab.completed),
        .init(id: CartTabsModel.Tab.statistics),
    ]
    
    @State private var showCreateCartPopover = false
    @State private var showInsights = false
    
    @State private var activeTab: CartTabsModel.Tab = .active
    @State private var tabBarScrollState: CartTabsModel.Tab?
    @State private var progress: CGFloat = .zero
    @State private var isDragging: Bool = false
    @State private var delayTask: DispatchWorkItem?
    
    //create post trasnsition/animation interaction
    @State private var showCreatePost: Bool = false
    @State private var isAnimating = false
    @State private var isScalingDown = false
    
    @State private var vaultButtonScale: CGFloat = 1.0
    @State private var isVaultButtonExpanded: Bool
    @State private var animationTask: DispatchWorkItem?
    
    @State private var cartRefreshTrigger = UUID()
    
    // ADD THESE STATE VARIABLES for rename cart
    @State private var cartToRename: Cart? = nil
    @State private var cartToDelete: Cart? = nil
    @State private var showingDeleteAlert = false
    @State private var showProWelcomeSheet = false
    
    // Name entry sheet state
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("hasSeenProWelcome") private var hasSeenProWelcome: Bool = false
    
    init(viewModel: HomeViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self._cartStateManager = State(initialValue: CartStateManager())
        _isVaultButtonExpanded = State(initialValue: !UserDefaults.standard.bool(forKey: "hasShownVaultAnimation"))
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(hex: "#e0e0e0").ignoresSafeArea()
                
                MenuView()
                    .opacity(viewModel.showMenu ? 1 : 0)
                    .offset(x: viewModel.showMenu ? 0 : -300)
                    .rotation3DEffect(
                        .degrees(viewModel.showMenu ? 0 : 30),
                        axis: (x: 0, y: 1, z: 0)
                    )
                
                mainContent
                
                menuIcon
                
                // Rename cart popover overlay (using if conditional)
                if let cartToRename = cartToRename {
                    RenameCartNamePopover(
                        isPresented: Binding(
                            get: { self.cartToRename != nil },
                            set: { if !$0 { self.cartToRename = nil } }
                        ),
                        currentName: cartToRename.name,
                        onSave: { newName in
                            cartToRename.name = newName
                            vaultService.updateCartTotals(cart: cartToRename)
                            self.cartToRename = nil
                        },
                        onDismiss: {
                            self.cartToRename = nil
                        }
                    )
                    .environment(vaultService)
                    .zIndex(1000) // Ensure it's on top
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .ignoresSafeArea()
            .sheet(isPresented: $viewModel.showVault) {
                vaultSheet
            }
            .sheet(isPresented: $showInsights) {
                InsightsView()
                    .environment(vaultService)
                    .environment(cartViewModel)
            }
            .sheet(isPresented: $showProWelcomeSheet) {
                ProWelcomeSheet(isPresented: $showProWelcomeSheet)
            }
            .customPopover(isPresented: $showCreateCartPopover) {
                CreateCartPopover(
                    onConfirm: { title, budget in
                        let success = viewModel.handleCreateCartConfirmation(title: title, budget: budget)
                        if success {
                            showCreateCartPopover = false
                        }
                    },
                    onCancel: {
                        showCreateCartPopover = false
                        viewModel.cartViewModel.clearDuplicateError()
                    },
                    isPresented: $showCreateCartPopover,
                )
            }
            // Add delete alert
            .alert("Delete Cart", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    cartToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let cart = cartToDelete {
                        deleteCart(cart)
                        cartToDelete = nil
                    }
                }
            } message: {
                if let cart = cartToDelete {
                    Text("Are you sure you want to delete \"\(cart.name)\"? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete this cart? This action cannot be undone.")
                }
            }
            // In HomeView.swift
            .fullScreenCover(item: $viewModel.selectedCart) { cart in
                CartDetailScreen(cart: cart)
                    .environment(vaultService)
                    .environment(cartViewModel)
                    .environment(cartStateManager) // ADD THIS LINE - Pass CartStateManager
                    .onDisappear {
                        viewModel.loadCarts()
                        
                        if viewModel.pendingCartToShow != nil {
                            viewModel.completePendingCartDisplay()
                        }
                        
                        viewModel.selectedCart = nil
                    }
            }
            .onChange(of: viewModel.showVault) { oldValue, newValue in
                if !newValue {
                    viewModel.transferPendingCart()
                    scheduleVaultButtonAnimation()
                    checkForProWelcome()
                } else {
                    cancelVaultButtonAnimation()
                }
            }
            .onChange(of: viewModel.selectedCart) { oldValue, newValue in
                if newValue == nil {
                    scheduleVaultButtonAnimation()
                    checkForProWelcome()
                } else {
                    cancelVaultButtonAnimation()
                }
            }
            .onAppear {
                scheduleVaultButtonAnimation()
                checkForProWelcome()
            }
            .onChange(of: hasCompletedOnboarding) { _, _ in
                scheduleVaultButtonAnimation()
            }
            .onChange(of: hasSeenProWelcome) { _, newValue in
                if newValue {
                    scheduleVaultButtonAnimation()
                }
            }
        }
    }
    
    private var mainContent: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: "#ffffff").ignoresSafeArea()
            
            ActiveCarts(
                viewModel: viewModel,
                onDeleteCart: { cart in
                    cartToDelete = cart
                    showingDeleteAlert = true
                },
                onRenameCart: { cart in
                    cartToRename = cart
                }
            )
            
            headerView
            
            homeMenu
            
            VStack {
                Spacer()
                ZStack(alignment: .bottomTrailing) {
                    createCartButton
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Button(action: {
                        showInsights = true
                    }) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 32)
                    .padding(.bottom, 36)
                }
            }
        }
        .ignoresSafeArea()
        .mask(
            RoundedRectangle(
                cornerRadius: viewModel.showMenu ? 30 : 24,
                style: .continuous
            )
        )
        .rotation3DEffect(
            .degrees(viewModel.showMenu ? 30 : 0),
            axis: (x: 0, y: -1, z: 0)
        )
        .offset(x: viewModel.showMenu ? 265 : 0)
        .scaleEffect(viewModel.showMenu ? 0.9 : 1)
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: -2, y: -5)
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 2, y: 0)
    }
    
    private var menuIcon: some View {
        MenuIcon {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                print("menu tapped")
                viewModel.toggleMenu()
            }
        }
        .padding(.top, 110)
        .offset(
            x: viewModel.getMenuIconOffset().x,
            y: viewModel.getMenuIconOffset().y
        )
        .opacity(viewModel.menuIconOpacity)
    }
    
    private var headerView: some View {
        VStack(spacing: 0) {
            // This container will have total height of 92px (60 + 32)
            // and center its content vertically
            ZStack {
                if !isVaultButtonExpanded {
                    greetingText
                        .transition(.scale.combined(with: .opacity))
                }
                
                HStack {
                    Spacer()
                    trailingToolbarButton
                        .padding(.trailing)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
            .frame(height: 122)
            .animation(.spring(response: 0.4, dampingFraction: 0.65), value: isVaultButtonExpanded)
            
            Text("Your Trip")
                .lexendFont(13)
                .foregroundStyle(Color(.systemGray))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom)
        }
        .frame(maxWidth: .infinity)
        .background(headerBackground)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        viewModel.updateHeaderHeight(geometry.size.height)
                    }
                    .onChange(of: geometry.size.height) { oldValue, newValue in
                        viewModel.updateHeaderHeight(newValue)
                    }
            }
        )
    }
    
    private var currencyPicker: some View {
        Picker("Currency", selection: $viewModel.selectedCurrency) {
            ForEach(CurrencyManager.shared.availableCurrencies, id: \.self) { currency in
                Text(currency.symbol + " " + currency.code).tag(currency)
            }
        }
    }
    
    private var homeMenu: some View {
        HStack {
            MenuIcon {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    viewModel.toggleMenu()
                }
            }
            
            Menu {
                Section {
                    Button(role: .destructive, action: viewModel.resetApp) {
                        Label(
                            "Reset App (Testing)",
                            systemImage: "arrow.counterclockwise"
                        )
                    }
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 20)
            }
        }
        .padding(.top, 62)
        .padding(.leading)
        .offset(x: viewModel.showMenu ? 40 : 0, y: viewModel.showMenu ? 40 : 0)
        .opacity(viewModel.showMenu ? 0 : 1)
    }
    
    private var headerBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "ffffff").opacity(0.85), location: 0),
                    .init(color: Color(hex: "ffffff").opacity(0.95), location: 0.1),
                    .init(color: Color(hex: "ffffff").opacity(1.0), location: 0.2),
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            HStack {
                Rectangle()
                    .fill(Color(hex: "ffffff"))
                    .frame(width: 14)
                Spacer()
                Rectangle()
                    .fill(Color(hex: "ffffff"))
                    .frame(width: 14)
            }
        }
    }
    
    private var greetingText: some View {
        let userName = vaultService.currentUser?.name ?? "there"
        let nameCount = userName.count
        let minScaleFactor: CGFloat = {
            if nameCount >= 17 { return 0.8 }
            if nameCount >= 12 { return 0.9 }
            return 1.0
        }()
        
        return ZStack(alignment: .center) {
            Text("\(userName) ")
                .foregroundColor(.black)
                .shantellSansFont(18)
                .multilineTextAlignment(.center)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.65, alignment: .center)
                .minimumScaleFactor(minScaleFactor)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
            
            HStack(spacing: 16) {
                Text("\(userName) ")
                    .shantellSansFont(18)
                    .hidden()
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(minScaleFactor)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: true)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.65)
                

                LottieView(animation: .named("Hi"))
                    .playing(.fromProgress(0, toProgress: 0.5, loopMode: .loop))
                    .allowsHitTesting(false)
                    .frame(width: 30, height: 36)
                    .offset(x: 4)
            }
            .fixedSize()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var createCartButton: some View {
        Button(action: {
            showCreateCartPopover = true
        }) {
            Text("Create Cart")
                .fuzzyBubblesFont(18, weight: .bold)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(.black)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .padding(.bottom)
        .padding(.bottom)
        .padding(.bottom, 20)
    }
    
    private var trailingToolbarButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.handleVaultButton()
            }
        }) {
            ZStack {
                if isVaultButtonExpanded {
                    // Expanded state: Full button with background
                    HStack(spacing: 8) {
                        Text("vault")
                            .shantellSansFont(12)
                            .foregroundColor(.black)
                            .matchedGeometryEffect(id: "vaultText", in: vaultButtonNamespace)
                        
                        Image(systemName: "shippingbox")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .matchedGeometryEffect(id: "vaultIcon", in: vaultButtonNamespace)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.2),
                                        .clear,
                                        .black.opacity(0.1),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .clipShape(Capsule())
                            )
                            .shadow(
                                color: .black.opacity(0.4),
                                radius: 1,
                                x: 0,
                                y: 0.5
                            )
                            .matchedGeometryEffect(id: "vaultBackground", in: vaultButtonNamespace)
                    )
                    .padding(.vertical, 4)
                    .transition(.scale.combined(with: .opacity))
                } else {
                    // Collapsed state: Just the icon
                    Image(systemName: "shippingbox")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .matchedGeometryEffect(id: "vaultIcon", in: vaultButtonNamespace)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.65), value: isVaultButtonExpanded)
        }
        .buttonStyle(
            VaultCoordinatedButtonStyle(showVault: viewModel.showVault)
        )
    }

    private func vaultShippingboxIcon(size: CGFloat) -> some View {
        Image(systemName: "shippingbox")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .symbolRenderingMode(.monochrome)
            .matchedGeometryEffect(id: "vaultShippingbox", in: vaultButtonNamespace)
    }
    
    private var vaultSheet: some View {
        NavigationStack {
            VaultView(onCreateCart: viewModel.onCreateCartFromVault)
                .environment(vaultService)
                .environment(cartViewModel)
                .presentationCornerRadius(32)
                .interactiveDismissDisabled(cartViewModel.hasActiveItems)
        }
    }
    
    private func tabButton(title: String, tabIndex: Int) -> some View {
        Button(action: { viewModel.selectedTab = tabIndex }) {
            Text(title)
                .lexendFont(15)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(viewModel.selectedTab == tabIndex ? .black : .clear)
                .foregroundColor(
                    viewModel.selectedTab == tabIndex ? .white : .black
                )
                .clipShape(Capsule())
        }
    }
    
    private func deleteCart(_ cart: Cart) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            cartViewModel.deleteCart(cart)
        }
    }
    
    // MARK: - Pro Welcome Logic
    private func checkForProWelcome() {
        // Conditions:
        // 1. Not seen yet
        guard !UserDefaults.standard.hasSeenProWelcome else { return }
        
        // 2. Has completed onboarding
        guard hasCompletedOnboarding else { return }
        
        // 3. Has entered name (Vault celebration finished)
        // Use SwiftData as source of truth for name
        guard let name = vaultService.currentUser?.name, 
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // 4. We are on HomeView (Vault dismissed, Cart Detail dismissed)
        if !viewModel.showVault && viewModel.selectedCart == nil {
            print("🎁 Showing Pro Welcome Sheet")
            showProWelcomeSheet = true
        }
    }

    // MARK: - Vault Button Animation Logic
    private func scheduleVaultButtonAnimation() {
        print("DEBUG: Checking vault animation conditions")
        print("DEBUG: hasShownVaultAnimation: \(hasShownVaultAnimation)")
        print("DEBUG: showVault: \(viewModel.showVault)")
        print("DEBUG: selectedCart: \(String(describing: viewModel.selectedCart))")
        print("DEBUG: hasCompletedOnboarding: \(hasCompletedOnboarding)")
        print("DEBUG: currentUserName: \(vaultService.currentUser?.name ?? "nil")")
        print("DEBUG: hasSeenProWelcome: \(hasSeenProWelcome)")

        // Only schedule if we haven't shown it, vault is closed, and no cart is selected
        // AND user has completed onboarding and entered their name
        // AND user has seen the Pro Welcome sheet
        guard !hasShownVaultAnimation,
              !viewModel.showVault,
              viewModel.selectedCart == nil,
              hasCompletedOnboarding,
              let name = vaultService.currentUser?.name, !name.isEmpty,
              hasSeenProWelcome else {
            print("DEBUG: Conditions not met for vault animation")
            return 
        }
        
        print("DEBUG: Scheduling vault animation")

        // Cancel any existing task
        cancelVaultButtonAnimation()
        
        let task = DispatchWorkItem {
            print("DEBUG: Executing vault animation - collapsing button")
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVaultButtonExpanded = false
            }
            self.hasShownVaultAnimation = true
        }
        
        self.animationTask = task
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
    }
    
    private func cancelVaultButtonAnimation() {
        if let task = animationTask {
            print("DEBUG: Cancelling vault animation")
            task.cancel()
            animationTask = nil
        }
    }
}

struct VaultCoordinatedButtonStyle: ButtonStyle {
    let showVault: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed ? 0 : showVault ? 0.5 : 1.0
            )
            .animation(
                .spring(response: 0.3, dampingFraction: 0.75),
                value: configuration.isPressed
            )
            .animation(
                .spring(response: 0.3, dampingFraction: 0.75),
                value: showVault
            )
            .brightness(configuration.isPressed ? -0.2 : 0)
    }
}
