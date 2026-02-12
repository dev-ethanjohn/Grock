import SwiftUI
import SwiftData
import Lottie

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct PendingCartConfirmation: Equatable {
    let title: String
    let budget: Double
}

struct VaultView: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategoryName: String?
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
    @State private var showCategoryPickerSheet = false
    @State private var categoryManagerStartOnHidden = false
    @State private var showCategoryManagerContent = false
    
    @AppStorage("visibleCategoryNames") private var visibleCategoryNamesData: Data = Data()
    
    enum NavigationDirection {
        case left, right, none
    }

    @State private var pendingCartConfirmation: PendingCartConfirmation?
    
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
    @State private var showDeleteConfirmation = false
    @State private var itemToDelete: Item?
    
    // ✅ Updated to use @State with @Observable macro
    @State private var keyboardResponder = KeyboardResponder()
    @State private var focusedItemId: String?

    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @Namespace private var searchNamespace
    @Namespace private var categoryManagerNamespace
    
    private var totalVaultItemsCount: Int {
        guard let vault = vaultService.vault else { return 0 }
        return vault.categories.reduce(0) { $0 + $1.items.count }
    }
    
    private var hasActiveItems: Bool {
        !cartViewModel.activeCartItems.isEmpty
    }
    
    private var defaultCategoryNames: [String] {
        GroceryCategory.allCases.map(\.title)
    }
    
    private var customCategoryNames: [String] {
        guard let vault = vaultService.vault else { return [] }
        let defaultSet = Set(defaultCategoryNames)
        return vault.categories
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.name)
            .filter { !defaultSet.contains($0) }
    }
    
    private var allCategoryNames: [String] {
        var seen = Set<String>()
        var results: [String] = []
        
        for name in defaultCategoryNames + customCategoryNames {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard !seen.contains(trimmed.lowercased()) else { continue }
            seen.insert(trimmed.lowercased())
            results.append(trimmed)
        }
        
        return results
    }
    
    private var visibleCategories: [String] {
        let decoded = (try? JSONDecoder().decode([String].self, from: visibleCategoryNamesData))
            .map {
                $0.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
            }
        let configured = (decoded?.isEmpty == false) ? decoded! : defaultCategoryNames

        let canonicalByKey = Dictionary(uniqueKeysWithValues: allCategoryNames.map { ($0.lowercased(), $0) })
        var seen = Set<String>()
        var result: [String] = []

        for name in configured {
            let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard let canonical = canonicalByKey[key], !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(canonical)
        }

        return result.isEmpty ? defaultCategoryNames : result
    }
    
    private var visibleCategoriesBinding: Binding<[String]> {
        Binding(
            get: { visibleCategories },
            set: { newValue in
                let normalized = newValue
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                visibleCategoryNamesData = (try? JSONEncoder().encode(normalized)) ?? Data()
            }
        )
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.endEditing()
    }

    private func openCategoryManager() {
        showCategoryManagerContent = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showCategoryPickerSheet = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCategoryManagerContent = true
            }
        }
    }

    private func closeCategoryManager() {
        withAnimation(.easeInOut(duration: 0.15)) {
            showCategoryManagerContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                showCategoryPickerSheet = false
            }
        }
        categoryManagerStartOnHidden = false
    }

    private var categoryManagerOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .fill(Color.white)
                .matchedGeometryEffect(id: "categoryManagerMorph", in: categoryManagerNamespace, isSource: false)
                .ignoresSafeArea()

            NavigationStack {
                CategoriesManagerSheet(
                    title: "Manage Categories",
                    startOnHiddenTab: categoryManagerStartOnHidden,
                    selectedCategoryName: $selectedCategoryName,
                    visibleCategoryNames: visibleCategoriesBinding,
                    activeItemCount: { getActiveItemCount(forCategoryNamed: $0) },
                    hasItems: { hasItems(inCategoryNamed: $0) },
                    onClose: closeCategoryManager
                )
            }
            .ignoresSafeArea()
            .opacity(showCategoryManagerContent ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showCategoryManagerContent)
        }
        .zIndex(10)
    }
    
    var body: some View {
        contentWithCategoryManager
            .applyLifecycleModifiers(
                onAppear: handleOnAppear,
                onDisappear: handleOnDisappear,
                vaultService: vaultService,
                visibleCategoryNames: visibleCategories,
                selectedCategoryName: $selectedCategoryName,
                showAddItemPopover: $showAddItemPopover,
                updateChevronVisibility: updateChevronVisibility
            )
            .applyTooltipModifiers(
                showFirstItemTooltip: $showFirstItemTooltip,
                firstItemId: firstItemId,
                showNameEntrySheet: $showNameEntrySheet
            )
            .onChange(of: showCategoryPickerSheet) { _, isPresented in
                if !isPresented {
                    categoryManagerStartOnHidden = false
                }
            }
            .onChange(of: searchText) { _, newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                guard let matchingCategoryName = matchCategoryForSearch(trimmed) else { return }
                guard matchingCategoryName != selectedCategoryName else { return }

                let oldIndex = selectedCategoryName.flatMap { visibleCategories.firstIndex(of: $0) }
                let newIndex = visibleCategories.firstIndex(of: matchingCategoryName)
                if let oldIndex, let newIndex {
                    navigationDirection = newIndex > oldIndex ? .right : .left
                }

                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedCategoryName = matchingCategoryName
                }
            }
            .onChange(of: visibleCategoryNamesData) { _, _ in
                if let selectedCategoryName,
                   !visibleCategories.contains(selectedCategoryName) {
                    self.selectedCategoryName = visibleCategories.first
                }
                updateChevronVisibility()
            }
            .onChange(of: userName) { _, _ in
                if hasEnteredName {
                    isCelebrationSequenceActive = false
                }
            }
    }
    
    @ViewBuilder
    private var contentWithCategoryManager: some View {
        if #available(iOS 18.0, *) {
            baseContent
                .fullScreenCover(isPresented: $showCategoryPickerSheet) {
                    NavigationStack {
                        CategoriesManagerSheet(
                            title: "Manage Categories",
                            startOnHiddenTab: categoryManagerStartOnHidden,
                            selectedCategoryName: $selectedCategoryName,
                            visibleCategoryNames: visibleCategoriesBinding,
                            activeItemCount: { getActiveItemCount(forCategoryNamed: $0) },
                            hasItems: { hasItems(inCategoryNamed: $0) },
                            onClose: closeCategoryManager
                        )
                    }
                }
        } else {
            ZStack {
                baseContent
                    .disabled(showCategoryPickerSheet)

                if showCategoryPickerSheet {
                    categoryManagerOverlay
                }
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
            .alert("Remove Item", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { itemToDelete = nil }
                Button("Remove", role: .destructive) { executeDelete() }
            } message: {
                Text("Are you sure you want to remove this item from your vault? This will also remove it from all carts.")
            }
            .applySheetModifiers(
                showCelebration: $showCelebration,
                showCartConfirmation: $showCartConfirmation,
                pendingCartConfirmation: $pendingCartConfirmation,
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
            
            VaultCategorySectionView(selectedCategoryTitle: selectedCategoryName) {
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
                    onSave: { itemName, categoryName, store, unit, price in
                        _ = vaultService.addItem(
                            name: itemName,
                            toCategoryName: categoryName,
                            store: store,
                            price: price,
                            unit: unit
                        )
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
            if selectedCategoryName == nil {
                selectedCategoryName = firstVisibleCategoryWithItems ?? visibleCategories.first
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
            if let newCategoryName = notification.userInfo?["newCategoryName"] as? String {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedCategoryName = newCategoryName
                }
                print("🔄 Auto-switched to category: \(newCategoryName)")
                updateChevronVisibility()
            } else if let newCategory = notification.userInfo?["newCategory"] as? GroceryCategory {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedCategoryName = newCategory.title
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
            let iconSize: CGFloat = 50
            let iconSpacing: CGFloat = 0
            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .leading) {
                        if let selectedCategoryName,
                           let selectedIndex = visibleCategories.firstIndex(of: selectedCategoryName) {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.black, lineWidth: 2)
                                .frame(width: iconSize, height: iconSize)
                                .offset(x: CGFloat(selectedIndex) * (iconSize + iconSpacing))
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCategoryName)
                        }
                        
                        HStack(spacing: iconSpacing) {
                            ForEach(visibleCategories, id: \.self) { categoryName in
                                VaultCategoryNameIcon(
                                    name: categoryName,
                                    isSelected: selectedCategoryName == categoryName,
                                    itemCount: getActiveItemCount(forCategoryNamed: categoryName),
                                    hasItems: hasItems(inCategoryNamed: categoryName),
                                    iconText: vaultService.displayEmoji(forCategoryName: categoryName),
                                    action: {
                                        dismissKeyboard()
                                        
                                        if let current = selectedCategoryName,
                                           let currentIndex = visibleCategories.firstIndex(of: current),
                                           let newIndex = visibleCategories.firstIndex(of: categoryName) {
                                            navigationDirection = newIndex > currentIndex ? .right : .left
                                        }
                                        selectCategory(named: categoryName)
                                    }
                                )
                                .frame(width: iconSize, height: iconSize)
                                .id(categoryName)
                            }

                            Image(systemName: "plus.square.dashed")
                                .font(.system(size: 46, weight: .light))
                                .foregroundStyle(Color(.systemGray3))
                                .offset(x: -2)
                                .onTapGesture {
                                    categoryManagerStartOnHidden = true
                                    openCategoryManager()
                                }
                        }
                        .padding(.trailing, 80)
                    }
                    .padding(.vertical, 1)
                    .padding(.leading)
                    .padding(.trailing, 4)
                }
                .overlay(alignment: .trailing) {
                    GroceryCategoryScrollRightOverlay(
                        backgroundColor: .white,
                        namespace: categoryManagerNamespace,
                        isExpanded: showCategoryPickerSheet
                    ) {
                        dismissKeyboard()
                        categoryManagerStartOnHidden = false
                        openCategoryManager()
                    }
                }
            }
            .onChange(of: selectedCategoryName) { _, newValue in
                if let newName = newValue {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.95)) {
                        proxy.scrollTo(newName, anchor: .center)
                    }
                }
            }
            .onAppear {
                if let initialCategory = selectedCategoryName ?? firstVisibleCategoryWithItems ?? visibleCategories.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                            proxy.scrollTo(initialCategory, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private var categoryContentScrollView: some View {
        GeometryReader { geometry in
            if let selectedCategoryName {
                CategoryItemsView(
                    categoryName: selectedCategoryName,
                    searchText: searchText,
                    onDeleteItem: deleteItem
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                .id(selectedCategoryName)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedCategoryName)
    }
    
    struct CategoryItemsView: View {
        let categoryName: String
        let searchText: String
        let onDeleteItem: (Item) -> Void
        
        @Environment(VaultService.self) private var vaultService
        @Environment(CartViewModel.self) private var cartViewModel
        
        private var groceryCategory: GroceryCategory? {
            GroceryCategory.allCases.first(where: { $0.title == categoryName })
        }
        
        private var categoryItems: [Item] {
            guard let foundCategory = vaultService.getCategory(named: categoryName) else { return [] }
            // Filter out deleted items
            let items = foundCategory.items
                .filter { !$0.isDeleted }
                .sorted { $0.createdAt > $1.createdAt }
            
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
                        category: groceryCategory,
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
            ? "No items yet in \(categoryName) \(vaultService.displayEmoji(forCategoryName: categoryName))"
            : "No items found"
        }
    }
    
    // MARK: - Navigation Methods
    
    private func updateChevronVisibility() {
        guard let currentCategoryName = selectedCategoryName,
              let currentIndex = visibleCategories.firstIndex(of: currentCategoryName) else {
            showLeftChevron = false
            showRightChevron = false
            return
        }
        
        showLeftChevron = currentIndex > 0
        showRightChevron = currentIndex < visibleCategories.count - 1
    }
    
    private func navigateToPreviousCategory() {
        dismissKeyboard()
        
        guard let currentCategoryName = selectedCategoryName,
              let currentIndex = visibleCategories.firstIndex(of: currentCategoryName),
              currentIndex > 0 else { return }
        
        let previousCategory = visibleCategories[currentIndex - 1]
        navigationDirection = .left
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedCategoryName = previousCategory
        }
    }
    
    private func navigateToNextCategory() {
        dismissKeyboard()
        
        guard let currentCategoryName = selectedCategoryName,
              let currentIndex = visibleCategories.firstIndex(of: currentCategoryName),
              currentIndex < visibleCategories.count - 1 else { return }
        
        let nextCategory = visibleCategories[currentIndex + 1]
        navigationDirection = .right
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedCategoryName = nextCategory
        }
    }
    
    private func selectCategory(named categoryName: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            selectedCategoryName = categoryName
        }
    }
    
    // MARK: - Data Methods

    private func matchCategoryForSearch(_ text: String) -> String? {
        guard let vault = vaultService.vault else { return nil }
        for categoryName in visibleCategories {
            guard let foundCategory = vault.categories.first(where: { $0.name == categoryName }) else { continue }
            if foundCategory.items.contains(where: { $0.name.localizedCaseInsensitiveContains(text) }) {
                return categoryName
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
    
    private var firstVisibleCategoryWithItems: String? {
        guard let vault = vaultService.vault else { return nil }
        
        for categoryName in visibleCategories {
            if let vaultCategory = vault.categories.first(where: { $0.name == categoryName }),
               !vaultCategory.items.isEmpty {
                return categoryName
            }
        }
        return nil
    }
    
    private func getActiveItemCount(forCategoryNamed categoryName: String) -> Int {
        guard let vault = vaultService.vault else { return 0 }
        guard let foundCategory = vault.categories.first(where: { $0.name == categoryName }) else { return 0 }
        
        let activeItemsCount = foundCategory.items.reduce(0) { count, item in
            let isActive = (cartViewModel.activeCartItems[item.id] ?? 0) > 0
            return count + (isActive ? 1 : 0)
        }
        
        return activeItemsCount
    }
    
    private func getTotalItemCount(forCategoryNamed categoryName: String) -> Int {
        guard let vault = vaultService.vault else { return 0 }
        guard let foundCategory = vault.categories.first(where: { $0.name == categoryName }) else { return 0 }
        
        return foundCategory.items.count
    }
    
    private func hasItems(inCategoryNamed categoryName: String) -> Bool {
        getTotalItemCount(forCategoryNamed: categoryName) > 0
    }
    
    private func deleteItem(_ item: Item) {
        itemToDelete = item
        showDeleteConfirmation = true
    }
    
    private func executeDelete() {
        guard let item = itemToDelete else { return }
        
        print("🗑️ Deleting item: '\(item.name)'")
        
        cartViewModel.activeCartItems.removeValue(forKey: item.id)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            vaultService.deleteItem(item)
        }
        
        print("🔄 Active items after deletion: \(cartViewModel.activeCartItems.count)")
        itemToDelete = nil
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
        pendingCartConfirmation: Binding<PendingCartConfirmation?>,
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
            .fullScreenCover(isPresented: showCartConfirmation, onDismiss: {
                guard let pending = pendingCartConfirmation.wrappedValue else { return }
                pendingCartConfirmation.wrappedValue = nil

                print("🛒 Creating cart...")
                
                // Add delay to ensure popover dismissal animation completes
                // and prevents premature VaultView state reset/dismissal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if let newCart = cartViewModel.createCartWithActiveItems(name: pending.title, budget: pending.budget, notifyChanges: false) {
                        print("✅ Cart created: \(newCart.name)")
                        onCreateCart?(newCart)
                    } else {
                        print("❌ Failed to create cart")
                    }
                }
            }) {
                CartConfirmationPopover(
                    isPresented: showCartConfirmation,
                    activeCartItems: cartViewModel.activeCartItems,
                    vaultService: vaultService,
                    onConfirm: { title, budget in
                        pendingCartConfirmation.wrappedValue = PendingCartConfirmation(
                            title: title,
                            budget: budget
                        )
                        showCartConfirmation.wrappedValue = false
                    },
                    onCancel: {
                        pendingCartConfirmation.wrappedValue = nil
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
        visibleCategoryNames: [String],
        selectedCategoryName: Binding<String?>,
        showAddItemPopover: Binding<Bool>,
        updateChevronVisibility: @escaping () -> Void
    ) -> some View {
        self
            .onAppear(perform: onAppear)
            .onDisappear(perform: onDisappear)
            .onChange(of: vaultService.vault) { oldValue, newValue in
                if selectedCategoryName.wrappedValue == nil {
                    if let vault = newValue {
                        for categoryName in visibleCategoryNames {
                            if let vaultCategory = vault.categories.first(where: { $0.name == categoryName }),
                               !vaultCategory.items.isEmpty {
                                selectedCategoryName.wrappedValue = categoryName
                                break
                            }
                        }
                    }
                    
                    if selectedCategoryName.wrappedValue == nil {
                        selectedCategoryName.wrappedValue = visibleCategoryNames.first
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
            .onChange(of: selectedCategoryName.wrappedValue) { oldValue, newValue in
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
