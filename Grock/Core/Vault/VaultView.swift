import SwiftUI
import SwiftData
import Lottie

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct VaultView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: GroceryCategory?
    @State private var toolbarAppeared = false
    @State private var showAddItemPopover = false
    
    @State private var createCartButtonVisible = true
    @State private var cartBadgeVisible = false
    
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showCartConfirmation = false
    @State private var fillAnimation: CGFloat = 0.0
    
    // Properties for different modes
    var onCreateCart: ((Cart) -> Void)?
    var existingCart: Cart?
    var onAddItemsToCart: (([String: Double]) -> Void)?
    var shouldTriggerCelebration: Bool = false
    
    @State private var hasInitializedFromExistingCart = false
    
    // Celebration States with Lottie
    @State private var showCelebration = false
    @State private var debugCelebrationCount = 0
    @State private var buttonScale: CGFloat = 1.0
    
    // NEW: Loading state to prevent animation issues
    @State private var vaultReady = false
    
    // Add duplicate error state
    @State private var duplicateError: String?
    
    // Chevron navigation
    @State private var showLeftChevron = false
    @State private var showRightChevron = false
    
    // Track navigation direction for slide animations
    @State private var navigationDirection: NavigationDirection = .none
    
    @State private var categorySectionHeight: CGFloat = 0
    
    enum NavigationDirection {
        case left, right, none
    }
    
    // guide
    @State private var showFirstItemTooltip = false
    @State private var firstItemId: String? = nil
    
    // Name entry popover
    @State private var showNameEntrySheet = false
    
    @AppStorage("userName") private var userName: String = ""
    @State private var isCelebrationSequenceActive = false
    
    private var hasEnteredName: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Track keyboard state for immediate dismissal
    @FocusState private var isAnyFieldFocused: Bool
    
    // Track keyboard visibility to prevent sheet dismissal
    @State private var isKeyboardVisible = false
    
    @State private var showDismissConfirmation = false
    
    // ✅ Updated to use @State with @Observable macro
    @State private var keyboardResponder = KeyboardResponder()
    @State private var focusedItemId: String?

    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @Namespace private var searchNamespace
    
    private var totalVaultItemsCount: Int {
        guard let vault = vaultService.vault else { return 0 }
        return vault.categories.reduce(0) { $0 + $1.items.count }
    }
    
    private var hasActiveItems: Bool {
        !cartViewModel.activeCartItems.isEmpty
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.endEditing()
    }
    
    var body: some View {
        baseContent
            .applyLifecycleModifiers(
                onAppear: handleOnAppear,
                onDisappear: handleOnDisappear,
                vaultService: vaultService,
                selectedCategory: $selectedCategory,
                showAddItemPopover: $showAddItemPopover,
                updateChevronVisibility: updateChevronVisibility
            )
            .applyTooltipModifiers(
                showFirstItemTooltip: $showFirstItemTooltip,
                firstItemId: firstItemId,
                showNameEntrySheet: $showNameEntrySheet
            )
            .onChange(of: searchText) { _, newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                guard let matchingCategory = matchCategoryForSearch(trimmed) else { return }
                guard matchingCategory != selectedCategory else { return }

                let oldIndex = selectedCategory.flatMap { GroceryCategory.allCases.firstIndex(of: $0) }
                let newIndex = GroceryCategory.allCases.firstIndex(of: matchingCategory)
                if let oldIndex, let newIndex {
                    navigationDirection = newIndex > oldIndex ? .right : .left
                }

                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedCategory = matchingCategory
                }
            }
            .onChange(of: userName) { _, _ in
                if hasEnteredName {
                    isCelebrationSequenceActive = false
                }
            }
    }
    
    private var baseContent: some View {
        mainZStack
            .applyBaseModifiers(
                isKeyboardVisible: isKeyboardVisible,
                focusedItemId: $focusedItemId
            )
            .applyOverlayModifiers(
                showCartConfirmation: $showCartConfirmation,
                showDismissConfirmation: $showDismissConfirmation,
                cartViewModel: cartViewModel,
                dismiss: dismiss
            )
            .applySheetModifiers(
                showCelebration: $showCelebration,
                showCartConfirmation: $showCartConfirmation,
                showNameEntrySheet: $showNameEntrySheet,
                createCartButtonVisible: $createCartButtonVisible,
                cartViewModel: cartViewModel,
                vaultService: vaultService,
                onCreateCart: onCreateCart,
                onCelebrationDismiss: handleCelebrationDismiss
            )
    }
    
    // MARK: - Main Content
    
    private var mainZStack: some View {
        ZStack(alignment: .bottom) {
            if vaultReady {
                mainContentStack
            } else {
                loadingView
            }
            
            if vaultService.vault != nil && !showCelebration && vaultReady {
                bottomContent
            }
            
            popoversOverlay
            
            keyboardDoneButtonOverlay
            
            if isCelebrationSequenceActive {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                    .zIndex(100)
            }
        }
    }
    
    private var mainContentStack: some View {
        VStack(spacing: 0) {
            VaultToolbarView(
                toolbarAppeared: $toolbarAppeared,
                searchText: $searchText,
                isSearching: $isSearching,
                matchedNamespace: searchNamespace,
                onAddTapped: {
                    dismissKeyboard()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAddItemPopover = true
                        createCartButtonVisible = false
                    }
                },
                onDismissTapped: {
                    if hasActiveItems {
                        showDismissConfirmation = true
                    } else {
                        dismiss()
                    }
                },
                onClearTapped: {
                    cartViewModel.activeCartItems.removeAll()
                },
                showClearButton: hasActiveItems
            )
            
            if let vault = vaultService.vault, !vault.categories.isEmpty {
                categoryContentWithSection
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var categoryContentWithSection: some View {
        ZStack(alignment: .top) {
            categoryContentScrollView
                .frame(maxHeight: .infinity)
                .padding(.top, categorySectionHeight)
                .zIndex(0)
            
            VaultCategorySectionView(selectedCategory: selectedCategory) {
                categoryScrollView
            }
            .onTapGesture {
                dismissKeyboard()
            }
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            categorySectionHeight = geo.size.height
                        }
                        .onChange(of: geo.size.height) { _, newValue in
                            categorySectionHeight = newValue
                        }
                }
            )
            .zIndex(1)
        }
    }
    
    private var loadingView: some View {
        ProgressView()
            .onAppear {
                vaultReady = true
            }
    }
    
    private var popoversOverlay: some View {
        Group {
            if showAddItemPopover {
                AddItemPopover(
                    isPresented: $showAddItemPopover,
                    createCartButtonVisible: $createCartButtonVisible,
                    onSave: { itemName, category, store, unit, price in
                        let success = vaultService.addItem(
                            name: itemName,
                            to: category,
                            store: store,
                            price: price,
                            unit: unit
                        )
                        
                        if success {
                            print("✅ Item added to vault: \(itemName)")
                        } else {
                            print("❌ Failed to add item - duplicate name: \(itemName)")
                        }
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            createCartButtonVisible = true
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(1)
                .onAppear {
                    createCartButtonVisible = false
                }
            }
        }
    }
    
    private var keyboardDoneButtonOverlay: some View {
        ZStack {
            if keyboardResponder.isVisible && focusedItemId != nil {
                KeyboardDoneButton(
                    keyboardHeight: keyboardResponder.currentHeight,
                    onDone: {
                        UIApplication.shared.endEditing()
                    }
                )
                .transition(.identity)
                .zIndex(10)
            }
        }
        .frame(maxHeight: .infinity)
    }
    
    private var bottomContent: some View {
        VaultBottomContent(
            totalVaultItemsCount: totalVaultItemsCount,
            hasActiveItems: hasActiveItems,
            existingCart: existingCart,
            showLeftChevron: showLeftChevron,
            showRightChevron: showRightChevron,
            createCartButtonVisible: createCartButtonVisible,
            buttonScale: buttonScale,
            fillAnimation: fillAnimation,
            showCartConfirmation: $showCartConfirmation,
            navigationDirection: navigationDirection,
            onNavigatePrevious: navigateToPreviousCategory,
            onNavigateNext: navigateToNextCategory,
            onAddItemsToCart: onAddItemsToCart,
            dismissKeyboard: dismissKeyboard
        )
        .onChange(of: hasActiveItems) { oldValue, newValue in
            handleActiveItemsChange(oldValue: oldValue, newValue: newValue)
        }
        .onAppear {
            if hasActiveItems {
                fillAnimation = 1.0
                buttonScale = 1.0
            } else {
                buttonScale = 0
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleActiveItemsChange(oldValue: Bool, newValue: Bool) {
        if newValue {
            if !oldValue {
                withAnimation(.spring(duration: 0.4)) {
                    fillAnimation = 1.0
                }
                startButtonBounce()
            }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                fillAnimation = 0.0
                buttonScale = 0
            }
        }
    }
    
    private func handleCelebrationDismiss() {
        print("🔍 handleCelebrationDismiss called. showCelebration: \(showCelebration)")
        if showCelebration {
            withAnimation(.easeOut(duration: 0.2)) {
                createCartButtonVisible = false
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                createCartButtonVisible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if hasActiveItems {
                    startButtonBounce()
                }
            }
            
            findAndHighlightFirstItem()
            print("🔍 findAndHighlightFirstItem returned. showFirstItemTooltip: \(showFirstItemTooltip)")
            
            // Fallback: If tooltip doesn't show (no first item), show name entry after celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                print("🔍 Fallback check running...")
                if !showFirstItemTooltip &&
                   !UserDefaults.standard.hasEnteredName &&
                   !UserDefaults.standard.hasPromptedForNameAfterVaultCelebration {
                    print("🔍 Fallback conditions met! Scheduling NameEntryPopover in 1.0s")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        print("🔍 Executing Fallback NameEntryPopover show")
                        showNameEntrySheet = true
                        UserDefaults.standard.hasPromptedForNameAfterVaultCelebration = true
                    }
                }
            }
        }
    }
    
    private func handleOnAppear() {
        // Ensure Create Cart button is hidden if name is not entered
        if !hasEnteredName {
            createCartButtonVisible = false
        }
        
        initializeActiveItemsFromExistingCart()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if selectedCategory == nil {
                selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
            }
            updateChevronVisibility()
        }
        
        print("🎉 VaultView onAppear - Checking celebration conditions:")
        print("🎉 shouldTriggerCelebration parameter: \(shouldTriggerCelebration)")
        
        let hasSeenCelebration = UserDefaults.standard.bool(forKey: "hasSeenVaultCelebration")
        print("🎉 hasSeenCelebration: \(hasSeenCelebration)")
        print("🎉 hasPromptedForNameAfterVaultCelebration: \(UserDefaults.standard.hasPromptedForNameAfterVaultCelebration)")
        
        if let vault = vaultService.vault {
            let totalItems = vault.categories.reduce(0) { $0 + $1.items.count }
            print("🎉 Total items in vault: \(totalItems)")
            print("🎉 Categories with items: \(vault.categories.filter { !$0.items.isEmpty }.count)")
        }
        
        if shouldTriggerCelebration {
            print("🎉 Celebration triggered by parent view!")
            showCelebration = true
            if !hasEnteredName {
                isCelebrationSequenceActive = true
            }
            UserDefaults.standard.set(true, forKey: "hasSeenVaultCelebration")
        } else {
            checkAndStartCelebration()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            toolbarAppeared = true
        }
        
        setupNotificationObservers()
    }
    
    private func handleOnDisappear() {
        NotificationCenter.default.removeObserver(self)
        dismissKeyboard()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ItemCategoryChanged"),
            object: nil,
            queue: .main
        ) { notification in
            if let newCategory = notification.userInfo?["newCategory"] as? GroceryCategory {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedCategory = newCategory
                }
                print("🔄 Auto-switched to category: \(newCategory.title)")
                updateChevronVisibility()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            isKeyboardVisible = true
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            isKeyboardVisible = false
        }
    }
    
    // MARK: - Category Views
    
    private var categoryScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    if let selectedCategory = selectedCategory,
                       let selectedIndex = GroceryCategory.allCases.firstIndex(of: selectedCategory) {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.black, lineWidth: 2)
                            .frame(width: 50, height: 50)
                            .offset(x: CGFloat(selectedIndex) * 51)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCategory)
                    }
                    
                    HStack(spacing: 1) {
                        ForEach(GroceryCategory.allCases, id: \.self) { category in
                            VaultCategoryIcon(
                                category: category,
                                isSelected: selectedCategory == category,
                                itemCount: getActiveItemCount(for: category),
                                hasItems: hasItems(in: category),
                                action: {
                                    dismissKeyboard()
                                    
                                    if let current = selectedCategory,
                                       let currentIndex = GroceryCategory.allCases.firstIndex(of: current),
                                       let newIndex = GroceryCategory.allCases.firstIndex(of: category) {
                                        navigationDirection = newIndex > currentIndex ? .right : .left
                                    }
                                    selectCategory(category, proxy: proxy)
                                }
                            )
                            .frame(width: 50, height: 50)
                            .id(category.id)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: selectedCategory) { oldValue, newValue in
                if let newCategory = newValue {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                        proxy.scrollTo(newCategory.id, anchor: .center)
                    }
                }
            }
            .onAppear {
                if let initialCategory = selectedCategory ?? firstCategoryWithItems ?? GroceryCategory.allCases.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            proxy.scrollTo(initialCategory.id, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private var categoryContentScrollView: some View {
        GeometryReader { geometry in
            if let selectedCategory = selectedCategory {
                CategoryItemsView(
                    category: selectedCategory,
                    searchText: searchText,
                    onDeleteItem: deleteItem
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .id(selectedCategory.id)
                .transition(.asymmetric(
                    insertion: navigationDirection == .right ?
                        .move(edge: .trailing) :
                            .move(edge: .leading),
                    removal: navigationDirection == .right ?
                        .move(edge: .leading) :
                            .move(edge: .trailing)
                ))
            }
        }
        .frame(maxHeight: .infinity)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedCategory)
    }
    
    struct CategoryItemsView: View {
        let category: GroceryCategory
        let searchText: String
        let onDeleteItem: (Item) -> Void
        
        @Environment(VaultService.self) private var vaultService
        @Environment(CartViewModel.self) private var cartViewModel
        
        private var categoryItems: [Item] {
            guard let vault = vaultService.vault,
                  let foundCategory = vault.categories.first(where: { $0.name == category.title })
            else { return [] }
            let items = foundCategory.items.sorted { $0.createdAt > $1.createdAt }
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return items
            } else {
                return items.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
            }
        }
        private var availableStores: [String] {
            let allStores = categoryItems.flatMap { item in
                item.priceOptions.map { $0.store }
            }
            return Array(Set(allStores)).sorted()
        }
        
        var body: some View {
            Group {
                if categoryItems.isEmpty {
                    emptyCategoryView
                } else {
                    VaultItemsListView(
                        items: categoryItems,
                        availableStores: availableStores,
                        selectedStore: .constant(nil),
                        category: category,
                        onDeleteItem: onDeleteItem
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        
        private var emptyCategoryView: some View {
            VStack {
                Spacer()
                Text(emptyMessage)
                    .foregroundColor(.gray)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
        }

        private var emptyMessage: String {
            let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty
            ? "No items yet in \(category.title) \(category.emoji)"
            : "No items found"
        }
    }
    
    // MARK: - Navigation Methods
    
    private func updateChevronVisibility() {
        guard let currentCategory = selectedCategory,
              let currentIndex = GroceryCategory.allCases.firstIndex(of: currentCategory) else {
            showLeftChevron = false
            showRightChevron = false
            return
        }
        
        showLeftChevron = currentIndex > 0
        showRightChevron = currentIndex < GroceryCategory.allCases.count - 1
    }
    
    private func navigateToPreviousCategory() {
        dismissKeyboard()
        
        guard let currentCategory = selectedCategory,
              let currentIndex = GroceryCategory.allCases.firstIndex(of: currentCategory),
              currentIndex > 0 else { return }
        
        let previousCategory = GroceryCategory.allCases[currentIndex - 1]
        navigationDirection = .left
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedCategory = previousCategory
        }
    }
    
    private func navigateToNextCategory() {
        dismissKeyboard()
        
        guard let currentCategory = selectedCategory,
              let currentIndex = GroceryCategory.allCases.firstIndex(of: currentCategory),
              currentIndex < GroceryCategory.allCases.count - 1 else { return }
        
        let nextCategory = GroceryCategory.allCases[currentIndex + 1]
        navigationDirection = .right
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedCategory = nextCategory
        }
    }
    
    private func selectCategory(_ category: GroceryCategory, proxy: ScrollViewProxy) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedCategory = category
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                proxy.scrollTo(category.id, anchor: .center)
            }
        }
    }
    
    // MARK: - Data Methods

    private func matchCategoryForSearch(_ text: String) -> GroceryCategory? {
        guard let vault = vaultService.vault else { return nil }
        for category in GroceryCategory.allCases {
            guard let foundCategory = vault.categories.first(where: { $0.name == category.title }) else { continue }
            if foundCategory.items.contains(where: { $0.name.localizedCaseInsensitiveContains(text) }) {
                return category
            }
        }
        return nil
    }
    
    private func checkAndStartCelebration() {
        let hasSeenCelebration = UserDefaults.standard.bool(forKey: "hasSeenVaultCelebration")
        
        guard !hasSeenCelebration else {
            print("⏭️ Skipping celebration - already seen")
            return
        }
        
        guard let vault = vaultService.vault else {
            print("⏭️ Skipping celebration - no vault")
            return
        }
        
        let totalItems = vault.categories.reduce(0) { $0 + $1.items.count }
        print("🎉 Total items in vault: \(totalItems)")
        
        guard totalItems > 0 else {
            print("⏭️ Skipping celebration - vault is empty")
            return
        }
        
        print("🎉 ✅ CONDITIONS MET - Starting celebration!")
        showCelebration = true
        UserDefaults.standard.set(true, forKey: "hasSeenVaultCelebration")
    }
    
    private func initializeActiveItemsFromExistingCart() {
        guard let existingCart = existingCart, !hasInitializedFromExistingCart else { return }
        
        print("🔄 VaultView: Initializing active items from existing cart '\(existingCart.name)'")
        
        cartViewModel.activeCartItems.removeAll()
        
        for cartItem in existingCart.cartItems {
            cartViewModel.activeCartItems[cartItem.itemId] = cartItem.quantity
            if let item = vaultService.findItemById(cartItem.itemId) {
                print("   - Activated: \(item.name) × \(cartItem.quantity)")
            }
        }
        
        print("   Total active items: \(cartViewModel.activeCartItems.count)")
        hasInitializedFromExistingCart = true
    }
    
    private var firstCategoryWithItems: GroceryCategory? {
        guard let vault = vaultService.vault else { return nil }
        
        for groceryCategory in GroceryCategory.allCases {
            if let vaultCategory = vault.categories.first(where: { $0.name == groceryCategory.title }),
               !vaultCategory.items.isEmpty {
                return groceryCategory
            }
        }
        return nil
    }
    
    private func getActiveItemCount(for category: GroceryCategory) -> Int {
        guard let vault = vaultService.vault else { return 0 }
        guard let foundCategory = vault.categories.first(where: { $0.name == category.title }) else { return 0 }
        
        let activeItemsCount = foundCategory.items.reduce(0) { count, item in
            let isActive = (cartViewModel.activeCartItems[item.id] ?? 0) > 0
            return count + (isActive ? 1 : 0)
        }
        
        return activeItemsCount
    }
    
    private func getTotalItemCount(for category: GroceryCategory) -> Int {
        guard let vault = vaultService.vault else { return 0 }
        guard let foundCategory = vault.categories.first(where: { $0.name == category.title }) else { return 0 }
        
        return foundCategory.items.count
    }
    
    private func hasItems(in category: GroceryCategory) -> Bool {
        return getTotalItemCount(for: category) > 0
    }
    
    private func deleteItem(_ item: Item) {
        print("🗑️ Deleting item: '\(item.name)'")
        
        cartViewModel.activeCartItems.removeValue(forKey: item.id)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            vaultService.deleteItem(item)
        }
        
        print("🔄 Active items after deletion: \(cartViewModel.activeCartItems.count)")
    }
    
    private func startButtonBounce() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            buttonScale = 0.95
        }
        
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
    
    private func findAndHighlightFirstItem() {
        print("🔍 findAndHighlightFirstItem called")
        guard let vault = vaultService.vault else {
            print("🔍 No vault found")
            return
        }
        
        for category in vault.categories {
            if let firstItem = category.items.first {
                print("🔍 Found first item: \(firstItem.name) (ID: \(firstItem.id))")
                firstItemId = firstItem.id
                showFirstItemTooltip = true
                break
            }
        }
        if !showFirstItemTooltip {
            print("🔍 No items found in any category")
        }
    }
}

// MARK: - View Modifier Extensions

extension View {
    func applyBaseModifiers(
        isKeyboardVisible: Bool,
        focusedItemId: Binding<String?>
    ) -> some View {
        self
            .onPreferenceChange(TextFieldFocusPreferenceKey.self) { itemId in
                focusedItemId.wrappedValue = itemId
            }
            .frame(maxHeight: .infinity)
            .ignoresSafeArea(.keyboard)
            .toolbar(.hidden)
            .interactiveDismissDisabled(isKeyboardVisible)
    }
    
    func applyOverlayModifiers(
        showCartConfirmation: Binding<Bool>,
        showDismissConfirmation: Binding<Bool>,
        cartViewModel: CartViewModel,
        dismiss: DismissAction
    ) -> some View {
        self
            .overlay {
                if showCartConfirmation.wrappedValue {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
            }
            .customActionSheet(
                isPresented: showDismissConfirmation,
                title: "Leave Vault?",
                message: "You have \(cartViewModel.activeCartItems.count) selected item(s) that will be lost if you leave.",
                primaryAction: {
                    cartViewModel.activeCartItems.removeAll()
                    dismiss()
                },
                secondaryAction: {}
            )
            .animation(.easeInOut(duration: 0.3), value: showCartConfirmation.wrappedValue)
    }
    
    func applySheetModifiers(
        showCelebration: Binding<Bool>,
        showCartConfirmation: Binding<Bool>,
        showNameEntrySheet: Binding<Bool>,
        createCartButtonVisible: Binding<Bool>,
        cartViewModel: CartViewModel,
        vaultService: VaultService,
        onCreateCart: ((Cart) -> Void)?,
        onCelebrationDismiss: @escaping () -> Void
    ) -> some View {
        self
            .sheet(isPresented: showNameEntrySheet) {
                NameEntrySheet(
                    isPresented: showNameEntrySheet,
                    createCartButtonVisible: createCartButtonVisible,
                    onSave: { name in
                        vaultService.updateUserName(name)
                        UserDefaults.standard.userName = name
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            createCartButtonVisible.wrappedValue = true
                        }
                    }
                )
                .presentationDetents([.height(100)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
                .interactiveDismissDisabled(true)
            }
            .fullScreenCover(isPresented: showCelebration) {
                CelebrationView(
                    isPresented: showCelebration,
                    title: "Welcome to Your Vault!",
                    subtitle: nil
                )
                .presentationBackground(.clear)
            }
            .fullScreenCover(isPresented: showCartConfirmation) {
                CartConfirmationPopover(
                    isPresented: showCartConfirmation,
                    activeCartItems: cartViewModel.activeCartItems,
                    vaultService: vaultService,
                    onConfirm: { title, budget in
                        print("🛒 Creating cart...")
                        
                        if let newCart = cartViewModel.createCartWithActiveItems(name: title, budget: budget) {
                            print("✅ Cart created: \(newCart.name)")
                            cartViewModel.activeCartItems.removeAll()
                            onCreateCart?(newCart)
                        } else {
                            print("❌ Failed to create cart")
                        }
                    },
                    onCancel: {
                        showCartConfirmation.wrappedValue = false
                    }
                )
                .presentationBackground(.clear)
            }
            .onChange(of: showCelebration.wrappedValue) { oldValue, newValue in
                onCelebrationDismiss()
            }
    }
    
    func applyLifecycleModifiers(
        onAppear: @escaping () -> Void,
        onDisappear: @escaping () -> Void,
        vaultService: VaultService,
        selectedCategory: Binding<GroceryCategory?>,
        showAddItemPopover: Binding<Bool>,
        updateChevronVisibility: @escaping () -> Void
    ) -> some View {
        self
            .onAppear(perform: onAppear)
            .onDisappear(perform: onDisappear)
            .onChange(of: vaultService.vault) { oldValue, newValue in
                if selectedCategory.wrappedValue == nil {
                    // Find first category with items
                    if let vault = newValue {
                        for groceryCategory in GroceryCategory.allCases {
                            if let vaultCategory = vault.categories.first(where: { $0.name == groceryCategory.title }),
                               !vaultCategory.items.isEmpty {
                                selectedCategory.wrappedValue = groceryCategory
                                break
                            }
                        }
                    }
                }
                updateChevronVisibility()
            }
            .onChange(of: showAddItemPopover.wrappedValue) { oldValue, newValue in
                if !newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("📝 After adding item - updated vault structure:")
                    }
                }
            }
            .onChange(of: selectedCategory.wrappedValue) { oldValue, newValue in
                updateChevronVisibility()
            }
    }
    
    func applyTooltipModifiers(
        showFirstItemTooltip: Binding<Bool>,
        firstItemId: String?,
        showNameEntrySheet: Binding<Bool>
    ) -> some View {
        self
            .overlay {
                if showFirstItemTooltip.wrappedValue, let firstItemId = firstItemId {
                    FirstItemTooltip(itemId: firstItemId, isPresented: showFirstItemTooltip)
                }
            }
            .onChange(of: showFirstItemTooltip.wrappedValue) {_, newValue in
                print("🔍 showFirstItemTooltip changed to: \(newValue)")
                if !newValue {
                    let hasEnteredName = UserDefaults.standard.hasEnteredName
                    let hasPrompted = UserDefaults.standard.hasPromptedForNameAfterVaultCelebration
                    print("🔍 Tooltip dismissed. Checking conditions:")
                    print("   - hasEnteredName: \(hasEnteredName)")
                    print("   - hasPromptedForNameAfterVaultCelebration: \(hasPrompted)")
                    
                    if !hasEnteredName && !hasPrompted {
                        print("🔍 Conditions met! Scheduling NameEntryPopover in 0.5s")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("🔍 Executing scheduled NameEntryPopover show")
                            showNameEntrySheet.wrappedValue = true
                            UserDefaults.standard.hasPromptedForNameAfterVaultCelebration = true
                        }
                    } else {
                        print("🔍 Conditions NOT met. Skipping NameEntryPopover.")
                    }
                }
            }
    }
}
