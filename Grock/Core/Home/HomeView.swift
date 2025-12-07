import SwiftData
import SwiftUI
 
struct HomeView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @State private var viewModel: HomeViewModel
 
    @State private var tabs: [CartTabsModel] = [
        .init(id: CartTabsModel.Tab.active),
        .init(id: CartTabsModel.Tab.completed),
        .init(id: CartTabsModel.Tab.statistics),
    ]
 
    @State private var showCreateCartPopover = false
 
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
    
    @State private var cartRefreshTrigger = UUID()
 
    init(viewModel: HomeViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
 
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.white.ignoresSafeArea()
 
                MenuView()
                    .opacity(viewModel.showMenu ? 1 : 0)
                    .offset(x: viewModel.showMenu ? 0 : -300)
                    .rotation3DEffect(
                        .degrees(viewModel.showMenu ? 0 : 30),
                        axis: (x: 0, y: 1, z: 0)
                    )
 
                mainContent
 
                menuIcon
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .ignoresSafeArea()
            .sheet(isPresented: $viewModel.showVault) {
                vaultSheet
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
            // In HomeView.swift
            .fullScreenCover(item: $viewModel.selectedCart) { cart in
                CartDetailScreen(cart: cart)
                    .onDisappear {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            viewModel.loadCarts()
                            cartRefreshTrigger = UUID()
                            
                            if viewModel.pendingCartToShow != nil {
                                viewModel.completePendingCartDisplay()
                            }
                            viewModel.selectedCart = nil
//                        }
                    }
                    .presentationCornerRadius(24)
            }
            .onAppear {
                viewModel.loadCarts()
                print("🏠 HomeView appeared - carts: \(viewModel.carts.count)")
                viewModel.checkPendingCart()
            }
            .onChange(of: viewModel.showVault) { oldValue, newValue in
                if !newValue {
                    viewModel.transferPendingCart()
                }
            }
            .onChange(of: viewModel.selectedCart) { oldValue, newValue in
                print(
                    "🔄 HomeView: selectedCart changed to \(newValue?.name ?? "nil")"
                )
            }
            .onChange(of: viewModel.showVault) { oldValue, newValue in
                withAnimation(.easeInOut(duration: 0.15)) {
                    vaultButtonScale = newValue ? 0.9 : 1.0
                }
            }
        }
    }
 
    private var mainContent: some View {
        ZStack(alignment: .topLeading) {
            Color.white.ignoresSafeArea()
 
            tabsOnly()
 
            headerView
 
            homeMenu
 
            VStack {
                Spacer()
                createCartButton
                    .frame(maxWidth: .infinity, alignment: .center)
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
 
    @ViewBuilder
    private func tabsOnly() -> some View {
        GeometryReader {
            let size = $0.size
 
            TabView(selection: $activeTab) {
                ActiveCarts(viewModel: viewModel, refreshTrigger: cartRefreshTrigger)
                    .tag(CartTabsModel.Tab.active)
                    .frame(width: size.width, height: size.height)
                    .rect { tabProgress(.active, rect: $0, size: size) }
 
                Text("Completed")
                    .tag(CartTabsModel.Tab.completed)
                    .frame(width: size.width, height: size.height)
                    .rect { tabProgress(.completed, rect: $0, size: size) }
 
                Text("Statistics")
                    .tag(CartTabsModel.Tab.statistics)
                    .frame(width: size.width, height: size.height)
                    .rect { tabProgress(.statistics, rect: $0, size: size) }
 
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .allowsHitTesting(!isDragging)
            .onChange(of: activeTab) { oldValue, newValue in
                guard tabBarScrollState != newValue else { return }
                withAnimation(.snappy) {
                    tabBarScrollState = newValue
                }
            }
        }
    }
 
    @ViewBuilder
    func exploreTabBar() -> some View {
        HStack(spacing: 20) {
            ScrollView(.horizontal) {
                HStack(spacing: 20) {
                    tabsCart()
                }
                .scrollTargetLayout()
                .padding(.leading, 2)
            }
            .scrollPosition(
                id: .init(
                    get: {
                        return tabBarScrollState
                    },
                    set: { _ in
 
                    }
                ),
                anchor: .center
            )
            .overlay(alignment: .bottom) {
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 0.5)
 
                    let inputRange = tabs.indices.compactMap {
                        return CGFloat($0)
                    }
                    let ouputRange = tabs.compactMap { return $0.size.width }
                    let outputPositionRange = tabs.compactMap { return $0.minX }
                    let indicatorWidth = progress.interpolate(
                        inputRange: inputRange,
                        outputRange: ouputRange
                    )
                    let indicatorPosition = progress.interpolate(
                        inputRange: inputRange,
                        outputRange: outputPositionRange
                    )
 
                    Capsule()
                        .fill(Color.black)
                        .frame(width: indicatorWidth, height: 2)
                        .offset(x: indicatorPosition)
                }
            }
            .scrollIndicators(.hidden)
        }
    }
 
    private func tabsCart() -> some View {
        ForEach($tabs) { $tab in
            Button(action: {
                delayTask?.cancel()
                delayTask = nil
 
                isDragging = true
 
                withAnimation(.easeInOut(duration: 0.3)) {
                    activeTab = tab.id
                    tabBarScrollState = tab.id
                    progress = CGFloat(
                        tabs.firstIndex(where: { $0.id == tab.id }) ?? 0
                    )
                }
 
                delayTask = .init { isDragging = false }
 
                if let delayTask {
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 0.3,
                        execute: delayTask
                    )
                }
            }) {
                Text(tab.id.rawValue)
                    .lexendFont(14, weight: .medium)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .foregroundStyle(
                        activeTab == tab.id ? Color.black : Color(.systemGray)
                    )
                    .contentShape(.rect)
                    .scaleEffect(activeTab == tab.id ? 1.05 : 1.0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.4),
                        value: activeTab
                    )
            }
            .buttonStyle(.plain)
            .rect { rect in
                tab.size = rect.size
                tab.minX = rect.minX
            }
        }
    }
 
    func tabProgress(_ tab: CartTabsModel.Tab, rect: CGRect, size: CGSize) {
        if let index = tabs.firstIndex(where: { $0.id == activeTab }),
            activeTab == tab, !isDragging
        {
            let offsetX = rect.minX - (size.width * CGFloat(index))
            progress = -offsetX / size.width
        }
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
            HStack {
                Spacer()
                trailingToolbarButton
            }
            .padding(.trailing)
            .padding(.top, 60)
 
            VStack(spacing: 12) {
                greetingText
                exploreTabBar()
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
                        viewModel.updateHeaderHeight(geometry.size.height)
                    }
                    .onChange(of: geometry.size.height) { oldValue, newValue in
                        viewModel.updateHeaderHeight(newValue)
                    }
            }
        )
    }
 
    private var homeMenu: some View {
        HStack {
            MenuIcon {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    viewModel.toggleMenu()
                }
            }
 
            Menu {
                Button(role: .destructive, action: viewModel.resetApp) {
                    Label(
                        "Reset App (Testing)",
                        systemImage: "arrow.counterclockwise"
                    )
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
        .offset(x: viewModel.showMenu ? 40 : 0, y: viewModel.showMenu ? 40 : 0)
        .opacity(viewModel.showMenu ? 0 : 1)
    }
 
    private var headerBackground: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.white.opacity(0.85), location: 0),
                    .init(color: Color.white.opacity(0.95), location: 0.1),
                    .init(color: Color.white.opacity(1.0), location: 0.2),
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
        }
    }
 
    private var greetingText: some View {
        Text("Hi Ethan,")
            .lexendFont(36, weight: .bold)
            .frame(maxWidth: .infinity, alignment: .leading)
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
        .padding(.bottom, 20)
    }
 
    private var trailingToolbarButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.handleVaultButton()
            }
        }) {
            HStack(spacing: 8) {
                Text("vault")
                    .fuzzyBubblesFont(13, weight: .bold)
                Image(systemName: "shippingbox")
                    .resizable()
                    .frame(width: 15, height: 15)
                    .symbolRenderingMode(.monochrome)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .foregroundColor(.black)
            .background(
                ZStack {
                    Color(.systemGray6)
                    LinearGradient(
                        colors: [
                            .white.opacity(0.2),
                            .clear,
                            .black.opacity(0.1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(Capsule())
            .shadow(
                color: .black.opacity(0.4),
                radius: 1,
                x: 0,
                y: 0.5
            )
            .scaleEffect(viewModel.showVault ? 0 : 1.0)
        }
        .buttonStyle(
            VaultCoordinatedButtonStyle(showVault: viewModel.showVault)
        )
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
