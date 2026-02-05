import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct VaultCategorySectionView: View {
    let selectedCategoryTitle: String?
    let categoryScrollView: AnyView

    init(selectedCategoryTitle: String?, @ViewBuilder categoryScrollView: () -> some View) {
        self.selectedCategoryTitle = selectedCategoryTitle
        self.categoryScrollView = AnyView(categoryScrollView())
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                if let title = selectedCategoryTitle {
                    Text(title)
                        .fuzzyBubblesFont(15, weight: .bold)
                        .contentTransition(.identity)
                        .animation(.spring(duration: 0.3), value: selectedCategoryTitle)
                        .transition(.push(from: .leading))
                } else {
                    Text("Select Category")
                        .fuzzyBubblesFont(15, weight: .bold)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            categoryScrollView
                .padding(.bottom, 10)
                .background(
                    Rectangle()
                        .fill(.white)
                        .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 1)
                        .mask(
                            Rectangle()
                                .padding(.bottom, -20)
                )
            )
        }
    }
}

private struct CategoryTabsModel: Identifiable {
    let id: Tab
    var size: CGSize = .zero
    var minX: CGFloat = .zero
    
    enum Tab: String, CaseIterable {
        case shown = "My Bar"
        case hidden = "More"
    }
}

struct CategoriesManagerSheet: View {
    let title: String
    let startOnHiddenTab: Bool
    @Binding var selectedCategoryName: String?
    @Binding var visibleCategoryNames: [String]
    let activeItemCount: (String) -> Int
    let hasItems: (String) -> Bool
    
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCreateCategoryAlert = false
    @State private var newCategoryName = ""
    @State private var newCategoryEmoji = ""
    @State private var createCategoryError: String?
    @State private var draggedCategoryName: String?
    
    @State private var tabs: [CategoryTabsModel] = [
        .init(id: .shown),
        .init(id: .hidden),
    ]
    @State private var activeTab: CategoryTabsModel.Tab = .shown
    @State private var tabBarScrollState: CategoryTabsModel.Tab?
    @State private var progress: CGFloat = .zero
    @State private var isDragging: Bool = false
    @State private var delayTask: DispatchWorkItem?

    init(
        title: String,
        startOnHiddenTab: Bool = false,
        selectedCategoryName: Binding<String?>,
        visibleCategoryNames: Binding<[String]>,
        activeItemCount: @escaping (String) -> Int,
        hasItems: @escaping (String) -> Bool
    ) {
        self.title = title
        self.startOnHiddenTab = startOnHiddenTab
        self._selectedCategoryName = selectedCategoryName
        self._visibleCategoryNames = visibleCategoryNames
        self.activeItemCount = activeItemCount
        self.hasItems = hasItems

        let initialTab: CategoryTabsModel.Tab = startOnHiddenTab ? .hidden : .shown
        self._activeTab = State(initialValue: initialTab)
        self._tabBarScrollState = State(initialValue: initialTab)
        self._progress = State(initialValue: startOnHiddenTab ? 1 : 0)
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
    
    private var shownNames: [String] {
        visibleNamesOrdered
    }
    
    private var hiddenNames: [String] {
        allCategoryNames.filter { !normalizedVisibleNames.contains(normalizedKey($0)) }
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
    
    var body: some View {
        VStack(spacing: 0) {
            tabBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            GeometryReader { proxy in
                let size = proxy.size
                
                TabView(selection: $activeTab) {
                    tabColumn(
                        title: "My Bar",
                        subtitle: "Drag to reorder, tap X to remove",
                        names: shownNames,
                        isShownColumn: true
                    )
                    .tag(CategoryTabsModel.Tab.shown)
                    .frame(width: size.width, height: size.height)
                    .rect { tabProgress(.shown, rect: $0, size: size) }
                    
                    tabColumn(
                        title: "More",
                        subtitle: "Tap + to add to your bar",
                        names: hiddenNames,
                        isShownColumn: false
                    )
                    .tag(CategoryTabsModel.Tab.hidden)
                    .frame(width: size.width, height: size.height)
                    .rect { tabProgress(.hidden, rect: $0, size: size) }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .allowsHitTesting(!isDragging)
                .onChange(of: activeTab) { _, newValue in
                    guard tabBarScrollState != newValue else { return }
                    withAnimation(.snappy) {
                        tabBarScrollState = newValue
                    }
                }
            }
        }
        .background(.white)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundStyle(.black)
            }
        }
        .alert("New Category", isPresented: $showCreateCategoryAlert) {
            TextField("Name", text: $newCategoryName)
            TextField("Icon (Emoji)", text: $newCategoryEmoji)
                .onChange(of: newCategoryEmoji) { _, newValue in
                    let normalized = normalizeEmojiInput(newValue)
                    if normalized != newValue {
                        newCategoryEmoji = normalized
                    }
                }
            
            Button("Create") {
                createCategory()
            }
            
            Button("Cancel", role: .cancel) {
                createCategoryError = nil
                newCategoryName = ""
                newCategoryEmoji = ""
            }
        } message: {
            Text(createCategoryError ?? "Create a custom category you can add to your bar.")
        }
        .onAppear {
            let index = tabs.firstIndex(where: { $0.id == activeTab }) ?? 0
            progress = CGFloat(index)
            tabBarScrollState = activeTab
        }
    }

    private var tabBar: some View {
        HStack {
            Spacer(minLength: 0)
            HStack(spacing: 22) {
                tabButtons()
            }
            Spacer(minLength: 0)
        }
        .coordinateSpace(name: "categoryTabs")
        .overlay(alignment: .bottom) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 0.5)

                let inputRange = tabs.indices.compactMap { CGFloat($0) }
                let outputRange = tabs.compactMap { $0.size.width }
                let outputPositionRange = tabs.compactMap { $0.minX }
                let indicatorWidth = progress.interpolate(
                    inputRange: inputRange,
                    outputRange: outputRange
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
    }

    private func tabButtons() -> some View {
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
                    .padding(.top, 6)
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
            .rect(in: .named("categoryTabs")) { rect in
                tab.size = rect.size
                tab.minX = rect.minX
            }
        }
    }

    private func tabProgress(_ tab: CategoryTabsModel.Tab, rect: CGRect, size: CGSize) {
        if let index = tabs.firstIndex(where: { $0.id == activeTab }),
           activeTab == tab,
           !isDragging {
            let offsetX = rect.minX - (size.width * CGFloat(index))
            progress = -offsetX / size.width
        }
    }

    @ViewBuilder
    private func tabColumn(title: String, subtitle: String, names: [String], isShownColumn: Bool) -> some View {
        ScrollView {
            column(
                title: title,
                subtitle: subtitle,
                names: names,
                isShownColumn: isShownColumn
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
    
    @ViewBuilder
    private func column(title: String, subtitle: String, names: [String], isShownColumn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .lexendFont(14, weight: .bold)
                        .foregroundStyle(.black)
                    
                    Text(subtitle)
                        .lexendFont(10, weight: .regular)
                        .foregroundStyle(.gray)
                }
                
                Spacer()
                
                if !isShownColumn {
                    Button {
                        createCategoryError = nil
                        newCategoryName = ""
                        showCreateCategoryAlert = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color(.systemGray6))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Create category")
                }
            }
            .padding(.bottom, 2)
            
            VStack(spacing: 8) {
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
                                draggedCategoryName = name
                                return NSItemProvider(object: name as NSString)
                            }
                            .onDrop(
                                of: [UTType.text],
                                delegate: CategoryDropDelegate(
                                    item: name,
                                    items: visibleNamesBinding,
                                    draggedItem: $draggedCategoryName
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
        createCategoryError = nil
        
        let trimmed = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let emoji = normalizeEmojiInput(newCategoryEmoji)
        
        let exists = allCategoryNames.contains { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
        guard !exists else {
            createCategoryError = "That category already exists."
            return
        }
        
        guard vaultService.createCustomCategory(named: trimmed, emoji: emoji.isEmpty ? nil : emoji) != nil else {
            createCategoryError = "Couldn’t create that category."
            return
        }
        
        newCategoryName = ""
        newCategoryEmoji = ""
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
}

private struct CategoryDropDelegate: DropDelegate {
    let item: String
    @Binding var items: [String]
    @Binding var draggedItem: String?

    func dropEntered(info: DropInfo) {
        guard let draggedItem, draggedItem != item else { return }
        guard let fromIndex = items.firstIndex(of: draggedItem),
              let toIndex = items.firstIndex(of: item) else { return }

        if items[toIndex] != draggedItem {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                items.move(
                    fromOffsets: IndexSet(integer: fromIndex),
                    toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex
                )
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

private struct CategoryManagerRow: View {
    let name: String
    let iconText: String
    let isSelected: Bool
    let activeCount: Int
    let hasItems: Bool
    let actionSymbol: String
    let actionEnabled: Bool
    let action: () -> Void
    let onTap: () -> Void
    
    private var groceryCategory: GroceryCategory? {
        GroceryCategory.allCases.first(where: { $0.title == name })
    }
    
    private var displayIcon: String { iconText }

    private var iconFontSize: CGFloat {
        if groceryCategory != nil { return 24 }
        return isAlphabeticIcon ? 18 : 24
    }

    private var isAlphabeticIcon: Bool {
        iconText.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
    }
    
    private var iconBackground: Color {
        if let groceryCategory { return groceryCategory.pastelColor }
        return name.generatedPastelColor
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            RadialGradient(
                                colors: [
                                    iconBackground.darker(by: 0.07).saturated(by: 0.03),
                                    iconBackground.darker(by: 0.15).saturated(by: 0.05),
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 30
                            )
                        )
                        .frame(width: 42, height: 42)
                    
                    Text(displayIcon)
                        .font(.system(size: iconFontSize, weight: isAlphabeticIcon ? .bold : .regular))
                        .foregroundStyle(.black)
                        .frame(width: 42, height: 42)
                    
                    if activeCount > 0 {
                        Text("\(activeCount)")
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundColor(.black)
                            .offset(x: 2, y: -2)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                }
                
                Text(name)
                    .lexendFont(12, weight: .medium)
                    .foregroundStyle(.black)
                    .lineLimit(2)
                
                Spacer()
                
                Button(action: action) {
                    Image(systemName: actionSymbol)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .disabled(!actionEnabled)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? .black : .clear, lineWidth: 2)
            )
            .opacity(hasItems ? 1 : 0.6)
        }
        .buttonStyle(.plain)
    }
}

struct GroceryCategoryScrollRightOverlay: View {
    var backgroundColor: Color = .white
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: backgroundColor.opacity(0.0), location: 0.0),
                        .init(color: backgroundColor.opacity(0.2), location: 0.45),
                        .init(color: backgroundColor.opacity(0.4), location: 0.7),
                        .init(color: backgroundColor.opacity(0.6), location: 0.88),
                        .init(color: backgroundColor, location: 1.0),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 70)
            .allowsHitTesting(false)
    }
}
