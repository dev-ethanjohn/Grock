import SwiftUI
import Lottie
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
    @State private var closeButtonScale: CGFloat = 0.0
    @State private var closeButtonPressed = false
    @State private var closeButtonDidAppear = false
    @State private var showCompactAddButton = false
    @State private var addButtonDidAppear = false
    @Namespace private var addButtonNamespace

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
        let names = computeAllCategoryNames()
        viewModel.cachedAllCategoryNames = names
        viewModel.backgroundColors = categoryBackgroundColors(from: names)
    }

    private var usedColorNamesByHex: [String: [String]] {
        var result: [String: [String]] = [:]
        for name in customCategoryNames {
            guard let hex = backgroundHex(for: name) else { continue }
            let normalized = normalizedHex(hex)
            guard !normalized.isEmpty else { continue }
            result[normalized, default: []].append(name)
        }
        return result
    }

    private func normalizedHex(_ hex: String) -> String {
        hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
    }

    private func categoryBackgroundColors(from names: [String]) -> [String] {
        let items = names.enumerated().compactMap { index, name -> (hex: String, hue: CGFloat, brightness: CGFloat, index: Int)? in
            guard let hex = backgroundHex(for: name) else { return nil }
            let components = colorComponents(forHex: hex) ?? (hue: 1.0, brightness: 1.0)
            return (hex: hex, hue: components.hue, brightness: components.brightness, index: index)
        }

        return items.sorted {
            if $0.hue != $1.hue { return $0.hue < $1.hue }
            if $0.brightness != $1.brightness { return $0.brightness < $1.brightness }
            return $0.index < $1.index
        }
        .map(\.hex)
    }

    private func backgroundHex(for name: String) -> String? {
        if let customCategory = vaultService.getCategory(named: name),
           let hex = customCategory.colorHex,
           !hex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return hex
        }

        if let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == name }) {
            return groceryCategory.pastelHex
        }

        return generatedPastelHex(for: name)
    }

    private func generatedPastelHex(for name: String) -> String? {
        let color = UIColor(name.generatedPastelColor)
        return hexString(for: color)
    }

    private func colorComponents(forHex hex: String) -> (hue: CGFloat, brightness: CGFloat)? {
        guard let rgb = rgbComponents(forHex: hex) else { return nil }
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        let uiColor = UIColor(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return nil
        }
        return (hue, brightness)
    }

    private func rgbComponents(forHex hex: String) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard !cleaned.isEmpty else { return nil }
        var int: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&int) else { return nil }

        let r, g, b: UInt64
        switch cleaned.count {
        case 3:
            (r, g, b) = (
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17
            )
        case 6:
            (r, g, b) = (
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        case 8:
            (r, g, b) = (
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            return nil
        }

        return (
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0
        )
    }

    private func hexString(for color: UIColor) -> String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(format: "%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
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

    private var usedEmojiNamesByEmoji: [String: [String]] {
        var result: [String: [String]] = [:]
        for name in customCategoryNames {
            let emoji = vaultService.displayEmoji(forCategoryName: name).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !emoji.isEmpty else { continue }
            result[emoji, default: []].append(name)
        }
        return result
    }

    private var usedIconSet: Set<String> {
        Set(usedEmojiNamesByEmoji.keys)
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
                .presentationDragIndicator(.visible)
                .ignoresSafeArea(.keyboard)
        }
        .onAppear {
            let index = viewModel.tabs.firstIndex(where: { $0.id == viewModel.activeTab }) ?? 0
            viewModel.progress = CGFloat(index)
            updateCachedCategories()
            showCompactAddButton = false
            if !addButtonDidAppear {
                addButtonDidAppear = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation(.interactiveSpring(response: 0.55, dampingFraction: 0.6, blendDuration: 0.25)) {
                        showCompactAddButton = true
                    }
                }
            }
        }
        .onChange(of: vaultService.vault?.categories) { _, _ in
            updateCachedCategories()
        }
    }
    
    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .fuzzyBubblesFont(24, weight: .bold)
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
//        .overlay(alignment: .topTrailing) {
//            debugMinYOverlay
//                .padding(.trailing, 16)
//                .padding(.top, 8)
//        }
    }

    private var debugMinYOverlay: some View {
        let minY = viewModel.activeTab == .shown
            ? viewModel.shownScrollOffset
            : viewModel.hiddenScrollOffset
        return Text("minY: \(String(format: "%.1f", minY))")
            .lexendFont(12, weight: .semibold)
            .foregroundStyle(Color.black.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.8))
            )
            .overlay(
                Capsule()
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
    }

    private var categoryPopover: some View {
        CreateCategorySheet(
            viewModel: viewModel,
            usedColorNamesByHex: usedColorNamesByHex,
            usedEmojis: usedIconSet,
            usedEmojiNamesByEmoji: usedEmojiNamesByEmoji,
            onSave: createCategoryFromPopover
        )
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
                        .init(color: .white, location: 0.85),
                        .init(color: .white.opacity(0.7), location: 0.9),
                        .init(color: .white.opacity(0.2), location: 0.95),
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
        .padding(.leading, 4)
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
            .offset(y: -4)
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
            if showCompactAddButton {
                addCategoryButtonCapsule(isCompact: true)
            } else {
                addCategoryButtonCapsule(isCompact: false)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create category")
        .padding(.trailing, 16)
        .padding(.bottom, safeAreaBottomPadding + 16)
    }

    @ViewBuilder
    private func addCategoryButtonCapsule(isCompact: Bool) -> some View {
        ZStack {
            if isCompact {
                Image(systemName: "plus")
                    .lexendFont(18, weight: .bold)
                    .foregroundStyle(.white)
                    .matchedGeometryEffect(id: "addButtonContent", in: addButtonNamespace)
            } else {
                Text("Add New Category")
                    .fuzzyBubblesFont(18, weight: .bold)
                    .foregroundColor(.white)
                    .matchedGeometryEffect(id: "addButtonContent", in: addButtonNamespace)
            }
        }
        .padding(.horizontal, isCompact ? 0 : 20)
        .frame(width: isCompact ? 44 : nil, height: 44)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                .black.opacity(0.85),
                                .black.opacity(1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .matchedGeometryEffect(id: "addButtonBackground", in: addButtonNamespace)
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var closeButton: some View {
        Button(action: {
            handleCloseButtonTap()
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(.white)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(closeButtonScale * (closeButtonPressed ? 0.9 : 1.0))
        .animation(.spring(response: 0.35, dampingFraction: 0.55), value: closeButtonScale)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: closeButtonPressed)
        .accessibilityLabel("Close")
        .onAppear {
            animateCloseButtonIn()
        }
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
                let isActive = viewModel.activeTab == tab.id
                let labelColor = isActive ? Color.black : Color(.systemGray)

                HStack(spacing: 6) {
                    Text(tab.id.rawValue)
                        .lexendFont(14, weight: .medium)
                        .foregroundStyle(labelColor)
                    
                    if tab.id == .shown {
                        Image("star")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .saturation(isActive ? 1 : 0)
                            .opacity(isActive ? 1 : 0.6)
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 10)
                .scaleEffect(isActive ? 1.05 : 1.0)
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
        let scrollSpaceName = isShownColumn ? "categoriesShownScroll" : "categoriesHiddenScroll"
        GeometryReader { containerProxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Initial offset spacer
                    Color.clear
                        .frame(height: max(0, viewModel.headerHeight - 16))
                    
                    // Your column content
                    column(
                        names: names,
                        isShownColumn: isShownColumn,
                        scrollSpaceName: scrollSpaceName
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, safeAreaBottomPadding + (UIScreen.main.bounds.height * 0.08))
                }
                .background(
                    GeometryReader { contentProxy in
                        Color.clear
//                            .onAppear {
//                                print("Initial minY: \(contentProxy.frame(in: .global).minY)")
//                            }
//                            .onChange(of: contentProxy.frame(in: .global).minY) { oldValue, newValue in
//                                print("Scroll minY changed: \(newValue)")
//                                updateScrollOffset(newValue, isShownColumn: isShownColumn)
//                            }
                            .preference(
                                key: CategoryScrollContentHeightPreferenceKey.self,
                                value: contentProxy.size.height
                            )
                    }
                )
            }
            .scrollIndicators(.hidden)
            .onAppear {
                updateScrollViewHeight(containerProxy.size.height, isShownColumn: isShownColumn)
            }
            .onChange(of: containerProxy.size.height) { _, newValue in
                updateScrollViewHeight(newValue, isShownColumn: isShownColumn)
            }
            .onPreferenceChange(CategoryScrollContentHeightPreferenceKey.self) { value in
                updateContentHeight(value, isShownColumn: isShownColumn)
            }
        }
        .padding(.bottom, -safeAreaBottomPadding)
        .ignoresSafeArea(.container, edges: .bottom)
    }
    
    @ViewBuilder
    private func column(names: [String], isShownColumn: Bool, scrollSpaceName: String) -> some View {
        let rowHeight: CGFloat = 62
        let rowSpacing: CGFloat = 8
        let selectionOutset: CGFloat = 2
        let rowTransition: AnyTransition = isShownColumn
            ? .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.96, anchor: .center))
            )
            : .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.96, anchor: .center))
            )

        VStack(spacing: 16) {
            LazyVStack(spacing: rowSpacing) {
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
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    hideCategory(named: name)
                                }
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showCategory(named: name, select: true)
                                }
                            }
                        },
                        onTap: {
                            if isShownColumn {
                                selectedCategoryName = name
                            }
                        }
                    )
                    .frame(height: rowHeight)
                    .transition(rowTransition)

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

            if isShownColumn {
                let shouldShowAddPrompt = showCompactAddButton && !names.isEmpty
                VStack(spacing: 8) {
                    Text("Add new category")
                        .fuzzyBubblesFont(16, weight: .bold)
                        .foregroundStyle(Color.black.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                    LottieView(animation: .named("Arrow"))
                        .playing(.fromProgress(0, toProgress: 0.5, loopMode: .playOnce))
                        .scaleEffect(x: -0.8, y: -0.8)
                        .allowsHitTesting(false)
                        .frame(height: 80)
                        .frame(width: 92)
                        .rotationEffect(.degrees(224))
                }
                .opacity(shouldShowAddPrompt ? 0.7 : 0)
                .accessibilityHidden(!shouldShowAddPrompt)
                .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: names)
        .overlay(alignment: .topLeading) {
            GeometryReader { geo in
                if isShownColumn,
                   let selectedCategoryName,
                   let selectedIndex = names.firstIndex(of: selectedCategoryName) {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 2)
                        .frame(
                            width: max(0, geo.size.width + (selectionOutset * 2)),
                            height: max(0, rowHeight + (selectionOutset * 2))
                        )
                        .offset(
                            x: -selectionOutset,
                            y: CGFloat(selectedIndex) * (rowHeight + rowSpacing) - selectionOutset
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selectedCategoryName)
                        .allowsHitTesting(false)
                        .zIndex(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func updateScrollOffset(_ value: CGFloat, isShownColumn: Bool) {
        if isShownColumn {
            viewModel.shownScrollOffset = value
        } else {
            viewModel.hiddenScrollOffset = value
        }
    }

    private func updateContentHeight(_ value: CGFloat, isShownColumn: Bool) {
        if isShownColumn {
            viewModel.shownContentHeight = value
        } else {
            viewModel.hiddenContentHeight = value
        }
    }

    private func updateScrollViewHeight(_ value: CGFloat, isShownColumn: Bool) {
        if isShownColumn {
            viewModel.shownScrollViewHeight = value
        } else {
            viewModel.hiddenScrollViewHeight = value
        }
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

    private func animateCloseButtonIn() {
        guard !closeButtonDidAppear else { return }
        closeButtonDidAppear = true
        closeButtonScale = 0.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                closeButtonScale = 1.0
            }
        }
    }

    private func handleCloseButtonTap() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            closeButtonPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                closeButtonPressed = false
                closeButtonScale = 0.7
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            if let onClose {
                onClose()
            } else {
                dismiss()
            }
        }
    }

}

private struct CharacterRevealLabel: View {
    let text: String
    let delay: Double
    let fontSize: CGFloat
    let weight: Font.Weight
    let color: Color
    let revealTrigger: Bool

    @State private var revealedCharacters: Int = 0
    @State private var didAppear = false

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .fuzzyBubblesFont(fontSize, weight: weight)
                    .foregroundStyle(color)
                    .opacity(index < revealedCharacters ? 1 : 0)
                    .offset(y: index < revealedCharacters ? 0 : 4)
                    .animation(
                        .interpolatingSpring(stiffness: 240, damping: 14)
                        .delay(Double(index) * 0.01 + delay),
                        value: revealedCharacters
                    )
            }
        }
        .onAppear {
            guard !didAppear else { return }
            didAppear = true
            if revealTrigger {
                startReveal()
            }
        }
        .onChange(of: revealTrigger) { _, newValue in
            if newValue {
                startReveal()
            } else {
                revealedCharacters = 0
            }
        }
        .onChange(of: text) { _, _ in
            if revealTrigger {
                startReveal()
            }
        }
    }

    private func startReveal() {
        revealedCharacters = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeOut(duration: 0.32)) {
                revealedCharacters = text.count
            }
        }
    }
}

private struct CategoryScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct CategoryScrollContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
