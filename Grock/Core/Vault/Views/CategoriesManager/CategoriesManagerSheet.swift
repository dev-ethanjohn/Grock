import SwiftUI
import UniformTypeIdentifiers
import UIKit
import SwiftData

struct CategoriesManagerSheet: View {
    let title: String
    let startOnHiddenTab: Bool
    let onClose: (() -> Void)?
    @Binding var selectedCategoryName: String?
    @Binding var visibleCategoryNames: [String]
    let activeItemCount: (String) -> Int
    let hasItems: (String) -> Bool
    
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CategoriesManagerViewModel
    @FocusState private var categoryNameFocused: Bool

    init(
        title: String,
        startOnHiddenTab: Bool = false,
        selectedCategoryName: Binding<String?>,
        visibleCategoryNames: Binding<[String]>,
        activeItemCount: @escaping (String) -> Int,
        hasItems: @escaping (String) -> Bool,
        onClose: (() -> Void)? = nil
    ) {
        self.title = title
        self.startOnHiddenTab = startOnHiddenTab
        self._selectedCategoryName = selectedCategoryName
        self._visibleCategoryNames = visibleCategoryNames
        self.activeItemCount = activeItemCount
        self.hasItems = hasItems
        self.onClose = onClose
        self._viewModel = State(initialValue: CategoriesManagerViewModel(startOnHiddenTab: startOnHiddenTab))
    }
    
    private var normalizedVisibleNames: Set<String> {
        Set(visibleNamesOrdered.map { normalizedKey($0) })
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
        if viewModel.cachedAllCategoryNames.isEmpty {
            return computeAllCategoryNames()
        }
        return viewModel.cachedAllCategoryNames
    }
    
    private func computeAllCategoryNames() -> [String] {
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

    private func updateCachedCategories() {
        viewModel.cachedAllCategoryNames = computeAllCategoryNames()
    }
    
    private var shownNames: [String] {
        filteredNames(from: visibleNamesOrdered)
    }
    
    private var hiddenNames: [String] {
        let visibleSet = normalizedVisibleNames
        return filteredNames(
            from: allCategoryNames.filter { !visibleSet.contains(normalizedKey($0)) }
        )
    }

    private var visibleNamesOrdered: [String] {
        normalizedVisibleNames(from: visibleCategoryNames)
    }

    private var visibleNamesBinding: Binding<[String]> {
        Binding(
            get: { visibleNamesOrdered },
            set: { visibleCategoryNames = normalizedVisibleNames(from: $0) }
        )
    }

    private var currentCategoryIcons: [(name: String, icon: String)] {
        allCategoryNames.map { name in
            (name: name, icon: vaultService.displayEmoji(forCategoryName: name))
        }
    }

    private var usedIconSet: Set<String> {
        Set(currentCategoryIcons.map(\.icon))
    }

    private var emojiCandidates: [String] {
        // Use the same list or a shared source. 
        // For now, let's just return a placeholder or remove this if unused.
        // Since we moved to EmojiPickerSheet, we might not need this here unless used elsewhere.
        // But to avoid errors, I'll keep it but point to the new file's library if possible, 
        // or just leave it as is if it's private.
        // Actually, let's make the library internal in the new file and use it here?
        // No, I'll just leave this private list here for now to avoid breaking other things if any.
        CategoriesManagerEmojiLibrary.top100
    }

    private var safeAreaBottomPadding: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windows = scenes.compactMap { ($0 as? UIWindowScene)?.windows }.flatMap { $0 }
        let inset = windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom
            ?? windows.first?.safeAreaInsets.bottom
            ?? 0
        return inset > 0 ? inset : 0
    }

    private var safeAreaTopPadding: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windows = scenes.compactMap { ($0 as? UIWindowScene)?.windows }.flatMap { $0 }
        let inset = windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.top
            ?? windows.first?.safeAreaInsets.top
            ?? 0
        return inset > 0 ? inset : 0
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { proxy in
                let size = proxy.size
                
                Group {
                    if viewModel.activeTab == .shown {
                        tabColumn(
                            names: shownNames,
                            isShownColumn: true
                        )
                        .frame(width: size.width, height: size.height)
                        .transition(.asymmetric(
                            insertion: viewModel.navigationDirection == .right ? .move(edge: .trailing) : .move(edge: .leading),
                            removal: viewModel.navigationDirection == .right ? .move(edge: .leading) : .move(edge: .trailing)
                        ))
                    } else {
                        tabColumn(
                            names: hiddenNames,
                            isShownColumn: false
                        )
                        .frame(width: size.width, height: size.height)
                        .transition(.asymmetric(
                            insertion: viewModel.navigationDirection == .right ? .move(edge: .trailing) : .move(edge: .leading),
                            removal: viewModel.navigationDirection == .right ? .move(edge: .leading) : .move(edge: .trailing)
                        ))
                    }
                }
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < -50 {
                                if viewModel.activeTab == .shown {
                                    viewModel.navigationDirection = .right
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        viewModel.activeTab = .hidden
                                        viewModel.progress = 1
                                    }
                                }
                            } else if value.translation.width > 50 {
                                if viewModel.activeTab == .hidden {
                                    viewModel.navigationDirection = .left
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        viewModel.activeTab = .shown
                                        viewModel.progress = 0
                                    }
                                }
                            }
                        }
                )
            }
            
            header
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                viewModel.headerHeight = geo.size.height
                            }
                            .onChange(of: geo.size.height) { _, newValue in
                                viewModel.headerHeight = newValue
                            }
                    }
                )
        }
        .background(.white)
        .overlay(alignment: .bottomTrailing) {
            floatingCreateButton
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showCategoryPopover) {
            categoryPopover
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
                .ignoresSafeArea(.keyboard)
        }
        .sheet(isPresented: $viewModel.showEmojiPicker) {
            EmojiPickerSheet(selectedEmoji: $viewModel.selectedEmoji) { emoji in
                viewModel.newCategoryEmoji = emoji
                HapticManager.shared.playButtonTap()
                viewModel.showEmojiPicker = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.showCategoryPopover) { _, isPresented in
            if isPresented {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    categoryNameFocused = true
                }
            } else {
                categoryNameFocused = false
            }
        }
        .onAppear {
            let index = viewModel.tabs.firstIndex(where: { $0.id == viewModel.activeTab }) ?? 0
            viewModel.progress = CGFloat(index)
            updateCachedCategories()
        }
        .onChange(of: vaultService.vault?.categories) { _, _ in
            updateCachedCategories()
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .fuzzyBubblesFont(20, weight: .bold)
                    .foregroundStyle(.black)
                Spacer()
                closeButton
            }
            .frame(height: 44)
            .padding(.top, 22)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            tabBar
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(headerBackground)
    }

    private var categoryPopover: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Create New Category")
                    .fuzzyBubblesFont(18, weight: .bold)
                    .foregroundStyle(.black)
                
                Spacer()
                
                Button(action: {
                    createCategoryFromPopover()
                }) {
                    Text("Save")
                        .lexendFont(14, weight: .bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.popoverCanCreate)
                .opacity(viewModel.popoverCanCreate ? 1 : 0.5)
            }
            
            // Input Row
            HStack(spacing: 12) {
                // Icon Preview / Emoji Selector
                Button(action: {
                    viewModel.showEmojiPicker = true
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.selectedColorHex != nil ? Color(hex: viewModel.selectedColorHex!) : Color.clear)
                        
                        if viewModel.selectedColorHex == nil {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        }
                        
                        if !viewModel.newCategoryEmoji.isEmpty {
                            Text(viewModel.newCategoryEmoji)
                                .font(.system(size: 24))
                        } else if let first = viewModel.newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).first {
                            Text(String(first).uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.black)
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.gray)
                        }
                    }
                    .frame(width: 48, height: 48)
                }
                .buttonStyle(.plain)
                
                TextField("Category name...", text: $viewModel.newCategoryName)
                    .lexendFont(16, weight: .medium)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .focused($categoryNameFocused)
                    .submitLabel(.done)
            }
            
            if let createCategoryError = viewModel.createCategoryError {
                Text(createCategoryError)
                    .lexendFont(12, weight: .medium)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
            
            // Content (Color Grid with Pagination)
            TabView {
                let chunks = Array(viewModel.backgroundColors.chunked(into: 14))
                ForEach(0..<chunks.count, id: \.self) { pageIndex in
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                        ForEach(chunks[pageIndex], id: \.self) { colorHex in
                            Button(action: {
                                viewModel.selectedColorHex = colorHex
                                HapticManager.shared.playButtonTap()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(hex: colorHex))
                                        .frame(height: 44)
                                    
                                    if viewModel.selectedColorHex == colorHex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.black.opacity(0.6))
                                            .padding(4)
                                            .background(
                                                Circle()
                                                    .fill(.white.opacity(0.4))
                                            )
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                            .padding(2)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 1) // Avoid clipping
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 120) // Adjust height for 2 rows + page indicator
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor = .black
                UIPageControl.appearance().pageIndicatorTintColor = .systemGray4
            }
            
            Spacer(minLength: 0)
        }
        .padding(24)
        .background(Color.white)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                categoryNameFocused = true
            }
        }
    }

    private var currentIconsGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(minimum: 44), spacing: 8), count: 7)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(currentCategoryIcons, id: \.name) { item in
                Button(action: {
                    viewModel.selectedEmoji = item.icon
                    viewModel.newCategoryEmoji = item.icon
                    HapticManager.shared.playButtonTap()
                }) {
                    Text(item.icon)
                        .font(.system(size: 20))
                        .frame(minWidth: 44, minHeight: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(item.name) category icon")
            }
        }
    }

    private var emojiPickerGrid: some View {
        let rows = Array(repeating: GridItem(.fixed(44), spacing: 8), count: 4)
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: rows, spacing: 8) {
                ForEach(emojiCandidates, id: \.self) { emoji in
                    let isUsed = usedIconSet.contains(emoji)
                    ZStack(alignment: .topTrailing) {
                        Button(action: {
                            guard !isUsed else { return }
                            viewModel.selectedEmoji = emoji
                            viewModel.newCategoryEmoji = emoji
                            HapticManager.shared.playButtonTap()
                        }) {
                            Text(emoji)
                                .font(.system(size: 20))
                                .frame(minWidth: 44, minHeight: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            viewModel.selectedEmoji == emoji ? Color.black : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .opacity(isUsed ? 0.5 : 1.0)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Emoji \(emoji)")

                        if isUsed {
                            Button(action: {
                                removeEmojiFromCategories(emoji)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(
                                        Circle()
                                            .fill(Color.black)
                                    )
                            }
                            .buttonStyle(.plain)
                            .offset(x: 4, y: -4)
                            .accessibilityLabel("Remove \(emoji) from categories")
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
        }
    }

    private var headerBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .white, location: 0),
                        .init(color: .white, location: 0.7),
                        .init(color: .white.opacity(0.9), location: 0.85),
                        .init(color: .white.opacity(0.5), location: 0.9),
                        .init(color: .white.opacity(0), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: max(0, viewModel.headerHeight + safeAreaTopPadding + 80))
            .offset(y: -safeAreaTopPadding)
            .ignoresSafeArea(.all, edges: .top)
    }

    private var tabBar: some View {
        HStack(spacing: 22) {
            tabButtons()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .coordinateSpace(name: "categoryTabs")
        .overlay(alignment: .bottom) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 0.5)

                let inputRange = viewModel.tabs.indices.compactMap { CGFloat($0) }
                let outputRange = viewModel.tabs.compactMap { $0.size.width }
                let outputPositionRange = viewModel.tabs.compactMap { $0.minX }
                let indicatorWidth = viewModel.progress.interpolate(
                    inputRange: inputRange,
                    outputRange: outputRange
                )
                let indicatorPosition = viewModel.progress.interpolate(
                    inputRange: inputRange,
                    outputRange: outputPositionRange
                )

                Capsule()
                    .fill(Color.black)
                    .frame(width: indicatorWidth, height: 2)
                    .offset(x: indicatorPosition)
            }
            .allowsHitTesting(false)
        }
    }

    private var floatingCreateButton: some View {
        Button(action: {
            viewModel.createCategoryError = nil
            viewModel.newCategoryName = ""
            viewModel.newCategoryEmoji = ""
            viewModel.selectedEmoji = nil
            HapticManager.shared.playButtonTap()
            viewModel.showCategoryPopover = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create category")
        .padding(.trailing, 16)
        .padding(.bottom, safeAreaBottomPadding + 16)
    }

    private var closeButton: some View {
        Button(action: {
            if let onClose {
                onClose()
            } else {
                dismiss()
            }
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")
    }

    private func tabButtons() -> some View {
        ForEach($viewModel.tabs) { $tab in
            Button(action: {
                guard viewModel.activeTab != tab.id else { return }
                
                let targetIndex = viewModel.tabs.firstIndex(where: { $0.id == tab.id }) ?? 0
                let currentIndex = viewModel.tabs.firstIndex(where: { $0.id == viewModel.activeTab }) ?? 0
                viewModel.navigationDirection = targetIndex > currentIndex ? .right : .left
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    viewModel.activeTab = tab.id
                    viewModel.progress = CGFloat(targetIndex)
                }
            }) {
                Text(tab.id.rawValue)
                    .lexendFont(14, weight: .medium)
                    .padding(.top, 6)
                    .padding(.bottom, 10)
                    .foregroundStyle(
                        viewModel.activeTab == tab.id ? Color.black : Color(.systemGray)
                    )
                    .contentShape(.rect)
                    .scaleEffect(viewModel.activeTab == tab.id ? 1.05 : 1.0)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.4),
                        value: viewModel.activeTab
                    )
            }
            .buttonStyle(.plain)
            .rect(in: .named("categoryTabs")) { rect in
                guard tab.size != rect.size || tab.minX != rect.minX else { return }
                tab.size = rect.size
                tab.minX = rect.minX
            }
        }
    }

    @ViewBuilder
    private func tabColumn(names: [String], isShownColumn: Bool) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: max(0, viewModel.headerHeight - 16))

                column(
                    names: names,
                    isShownColumn: isShownColumn
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, safeAreaBottomPadding + 80)
            }
        }
        .scrollIndicators(.hidden)
        .padding(.bottom, -safeAreaBottomPadding)
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    @ViewBuilder
    private func column(names: [String], isShownColumn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVStack(spacing: 8) {
                ForEach(names, id: \.self) { name in
                    let iconText = vaultService.displayEmoji(forCategoryName: name)
                    let row = CategoryManagerRow(
                        name: name,
                        iconText: iconText,
                        isSelected: selectedCategoryName == name,
                        activeCount: activeItemCount(name),
                        hasItems: hasItems(name),
                        actionSymbol: isShownColumn ? "xmark" : "plus",
                        actionEnabled: isShownColumn ? shownNames.count > 1 : true,
                        action: {
                            if isShownColumn {
                                hideCategory(named: name)
                            } else {
                                showCategory(named: name, select: true)
                            }
                        },
                        onTap: {
                            if isShownColumn {
                                selectedCategoryName = name
                            } else {
                                showCategory(named: name, select: true)
                            }
                        }
                    )
                    
                    if isShownColumn {
                        row
                            .onDrag {
                                viewModel.draggedCategoryName = name
                                return NSItemProvider(object: name as NSString)
                            }
                            .onDrop(
                                of: [UTType.text],
                                delegate: CategoryDropDelegate(
                                    item: name,
                                    items: visibleNamesBinding,
                                    draggedItem: $viewModel.draggedCategoryName
                                )
                            )
                    } else {
                        row
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    private func showCategory(named name: String, select: Bool) {
        var ordered = visibleNamesOrdered
        let key = normalizedKey(name)
        if !ordered.contains(where: { normalizedKey($0) == key }) {
            ordered.append(name)
        }
        visibleCategoryNames = normalizedVisibleNames(from: ordered)
        
        if select {
            selectedCategoryName = name
        }
    }
    
    private func hideCategory(named name: String) {
        let key = normalizedKey(name)
        let ordered = visibleNamesOrdered.filter { normalizedKey($0) != key }
        guard !ordered.isEmpty else { return }
        
        visibleCategoryNames = normalizedVisibleNames(from: ordered)
        
        if selectedCategoryName.map(normalizedKey) == key {
            selectedCategoryName = ordered.first
        }
    }
    
    private func createCategory() {
        viewModel.createCategoryError = nil
        
        let trimmed = viewModel.newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let emoji = normalizeEmojiInput(viewModel.newCategoryEmoji)
        
        let exists = allCategoryNames.contains { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
        guard !exists else {
            viewModel.createCategoryError = "That category already exists."
            return
        }
        
        guard vaultService.createCustomCategory(named: trimmed, emoji: emoji.isEmpty ? nil : emoji) != nil else {
            viewModel.createCategoryError = "Couldn’t create that category."
            return
        }
        
        updateCachedCategories()
        viewModel.newCategoryName = ""
        viewModel.newCategoryEmoji = ""
    }

    private func createCategoryFromPopover() {
        let trimmed = viewModel.newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if allCategoryNames.contains(where: { normalizedKey($0) == normalizedKey(trimmed) }) {
            viewModel.createCategoryError = "That category already exists."
            HapticManager.shared.playMedium()
            return
        }

        let emoji = viewModel.newCategoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmoji = emoji.isEmpty ? nil : String(emoji.prefix(1))

        guard vaultService.createCustomCategory(named: trimmed, emoji: normalizedEmoji, colorHex: viewModel.selectedColorHex) != nil else {
            viewModel.createCategoryError = "Couldn’t create that category."
            HapticManager.shared.playMedium()
            return
        }

        HapticManager.shared.playSuccess()
        updateCachedCategories()
        viewModel.newCategoryName = ""
        viewModel.newCategoryEmoji = ""
        viewModel.selectedEmoji = nil
        dismissCategoryPopover()
    }

    private func dismissCategoryPopover() {
        UIApplication.shared.endEditing()
        categoryNameFocused = false
        viewModel.showCategoryPopover = false
    }

    private func removeEmojiFromCategories(_ emoji: String) {
        guard let vault = vaultService.vault else { return }
        let normalized = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }

        var didUpdate = false
        for category in vault.categories {
            let stored = category.emoji?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if stored.hasPrefix(normalized) {
                category.emoji = VaultService.removedEmojiSentinel
                didUpdate = true
            }
        }

        if didUpdate {
            vaultService.saveContext()
            if viewModel.selectedEmoji == normalized {
                viewModel.selectedEmoji = nil
                viewModel.newCategoryEmoji = ""
            }
            HapticManager.shared.playLight()
        } else {
            HapticManager.shared.playMedium()
        }
    }

    private func normalizeEmojiInput(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first else { return "" }
        return String(first)
    }

    private func normalizedKey(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normalizedVisibleNames(from names: [String]) -> [String] {
        let canonicalByKey = Dictionary(
            uniqueKeysWithValues: allCategoryNames.map { (normalizedKey($0), $0) }
        )
        var seen = Set<String>()
        var result: [String] = []
        for name in names {
            let key = normalizedKey(name)
            guard let canonical = canonicalByKey[key], !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(canonical)
        }
        return result
    }

    private func filteredNames(from names: [String]) -> [String] {
        names
    }

}

@MainActor
private func makeCategoriesManagerPreview() -> some View {
    let container = try! ModelContainer(
        for: User.self, Vault.self, Category.self, Item.self, PriceOption.self, PricePerUnit.self, Cart.self, CartItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let service = VaultService(modelContext: context)

    return CategoriesManagerPreviewContent(service: service)
}

private struct CategoriesManagerPreviewContent: View {
    @State private var selectedCategoryName: String? = "Produce"
    @State private var visibleCategoryNames: [String] = ["Produce", "Dairy", "Bakery", "Pantry"]
    let service: VaultService

    var body: some View {
        CategoriesManagerSheet(
            title: "Categories",
            startOnHiddenTab: false,
            selectedCategoryName: $selectedCategoryName,
            visibleCategoryNames: $visibleCategoryNames,
            activeItemCount: { _ in 0 },
            hasItems: { _ in false }
        )
        .environment(service)
    }
}

#Preview("CategoriesManagerSheet") {
    makeCategoriesManagerPreview()
}
