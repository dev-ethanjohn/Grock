import SwiftUI
import UIKit

enum CategoryPickerSource {
    case myBar
    case defaultsOnly
}

struct CategoryCircularButton: View {
    @Binding var selectedCategoryName: String?
    let selectedCategoryEmoji: String
    let hasError: Bool
    var categoryPickerSource: CategoryPickerSource = .myBar
    var isEditable: Bool = true
    var onTap: (() -> Void)? = nil
    
    @Environment(VaultService.self) private var vaultService
    @AppStorage("visibleCategoryNames") private var visibleCategoryNamesData: Data = Data()
    @State private var showLockTooltip = false
    @State private var showCreateCategorySheet = false
    @State private var createCategoryViewModel = CategoriesManagerViewModel(startOnHiddenTab: true)
    
    var body: some View {
        HStack {
            Spacer()
            
            if isEditable {
                // Editable category button (Menu)
                Menu {
                    Section {
                        Text(categoryPickerSource == .defaultsOnly ? "Grocery Categories" : "Your Categories")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Picker("Category", selection: $selectedCategoryName) {
                        ForEach(availableCategoryNames, id: \.self) { categoryName in
                            Text("\(categoryName) \(emojiForCategoryName(categoryName))")
                                .tag(categoryName as String?)
                        }
                    }
                    .pickerStyle(.inline)

                    if categoryPickerSource == .myBar {
                        Divider()
                        Button {
                            presentCreateCategorySheet()
                        } label: {
                            Label("Add New Category", systemImage: "plus.circle")
                        }
                    }
                } label: {
                    categoryButtonContent
                }
                .offset(x: -4)
            } else {
                // Non-editable category button (Button with lock action)
                Button(action: {
                    onTap?()
                    showLockTooltip = true
                    
                    // Auto-hide tooltip
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showLockTooltip = false
                        }
                    }
                }) {
                    categoryButtonContent
                        .overlay(
                            // Lock overlay
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 34, height: 34)
                                
                                // Lock icon
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                        )
                }
                .buttonStyle(.plain)
                .offset(x: -4)
                .overlay(
                    // Lock tooltip
                    Group {
                        if showLockTooltip {
                            CategoryLockTooltipView()
                                .offset(y: -45)
                        }
                    },
                    alignment: .top
                )
            }
        }
        .sheet(isPresented: $showCreateCategorySheet, onDismiss: resetCreateCategoryForm) {
            CreateCategorySheet(
                viewModel: createCategoryViewModel,
                usedColorNamesByHex: usedColorNamesByHex,
                usedEmojis: usedEmojiSet,
                usedEmojiNamesByEmoji: usedEmojiNamesByEmoji,
                existingCategoryKeys: existingCategoryKeys,
                editingCategoryName: nil,
                deleteMessage: nil,
                onSave: saveCategoryFromQuickCreateSheet,
                onDelete: nil
            )
            .presentationDragIndicator(.visible)
            .ignoresSafeArea(.keyboard)
        }
    }
    
    private var categoryButtonContent: some View {
        ZStack {
            // Main circle that morphs
            Circle()
                .fill(selectedCategoryName == nil
                      ? .gray.opacity(0.2)
                      : (selectedCategoryColor ?? .gray))
                .frame(width: 34, height: 34)
                .opacity(isEditable ? 1.0 : 0.8) // Dim when not editable
            
            // Outer stroke (non-animating)
            Circle()
                .stroke(
                    selectedCategoryName == nil
                    ? Color.gray
                    : (selectedCategoryColor ?? Color.gray).darker(by: 0.2),
                    lineWidth: 1.5
                )
                .frame(width: 34, height: 34)
                .opacity(isEditable ? 1.0 : 0.6) // Dim stroke when not editable
            
            // Error stroke
            if hasError {
                Circle()
                    .stroke(Color(hex: "#FA003F"), lineWidth: 2)
                    .frame(width: 34 + 8, height: 34 + 8)
            }
            
            // Content
            if selectedCategoryName == nil {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.gray)
                    .opacity(isEditable ? 1.0 : 0.6)
            } else {
                Text(selectedCategoryEmoji)
                    .font(.system(size: 18))
                    .opacity(isEditable ? 1.0 : 0.8)
            }
        }
        .frame(width: 40, height: 40)
        .contentShape(Circle())
    }

    private var availableCategoryNames: [String] {
        let defaultCategoryNames = GroceryCategory.allCases.map(\.title)
        guard categoryPickerSource == .myBar else {
            return defaultCategoryNames
        }

        let decoded = (try? JSONDecoder().decode([String].self, from: visibleCategoryNamesData)) ?? []
        let customCategoryNames = (vaultService.vault?.categories ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.name)
        let allCategoryNames = defaultCategoryNames + customCategoryNames

        var canonicalByKey: [String: String] = [:]
        for name in allCategoryNames {
            let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !key.isEmpty, canonicalByKey[key] == nil {
                canonicalByKey[key] = name
            }
        }

        let myBarConfigured = decoded.isEmpty ? defaultCategoryNames : decoded
        var seen = Set<String>()
        var myBarNames: [String] = []

        // My Bar categories first, preserving configured order.
        for name in myBarConfigured {
            let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard let canonical = canonicalByKey[key], !seen.contains(key) else { continue }
            seen.insert(key)
            myBarNames.append(canonical)
        }

        // Then append More categories in canonical full-order.
        var moreNames: [String] = []
        for name in allCategoryNames {
            let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !key.isEmpty, !seen.contains(key) else { continue }
            guard let canonical = canonicalByKey[key] else { continue }
            seen.insert(key)
            moreNames.append(canonical)
        }

        var result = myBarNames + moreNames

        if let selected = selectedCategoryName {
            let selectedKey = selected.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !selectedKey.isEmpty && !seen.contains(selectedKey) {
                result.append(canonicalByKey[selectedKey] ?? selected)
            }
        }

        return result
    }

    private var selectedCategoryColor: Color? {
        guard let name = selectedCategoryName else { return nil }
        if let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == name }) {
            return groceryCategory.pastelColor
        }
        if let customCategory = vaultService.getCategory(named: name),
           let hex = customCategory.colorHex,
           !hex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Color(hex: hex)
        }
        return name.generatedPastelColor
    }

    private func emojiForCategoryName(_ name: String) -> String {
        vaultService.displayEmoji(forCategoryName: name)
    }

    private func presentCreateCategorySheet() {
        dismissKeyboard()
        // Wait for the Menu to close before presenting the sheet.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showCreateCategorySheet = true
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private var decodedVisibleCategoryNames: [String] {
        let decoded = (try? JSONDecoder().decode([String].self, from: visibleCategoryNamesData)) ?? []
        if decoded.isEmpty {
            return GroceryCategory.allCases.map(\.title)
        }
        return normalizedVisibleNames(from: decoded)
    }

    private var customCategoryNames: [String] {
        let defaultNameKeys = Set(GroceryCategory.allCases.map { normalizedKey($0.title) })
        return (vaultService.vault?.categories ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.name)
            .filter { !defaultNameKeys.contains(normalizedKey($0)) }
    }

    private var allCategoryNames: [String] {
        GroceryCategory.allCases.map(\.title) + customCategoryNames
    }

    private var existingCategoryKeys: Set<String> {
        Set(allCategoryNames.map(normalizedKey))
    }

    private var usedColorNamesByHex: [String: [String]] {
        var result: [String: [String]] = [:]
        for categoryName in customCategoryNames {
            guard let category = vaultService.getCategory(named: categoryName) else { continue }
            let hex = normalizedHex(category.colorHex)
            guard !hex.isEmpty else { continue }
            result[hex, default: []].append(category.name)
        }
        return result
    }

    private var usedEmojiNamesByEmoji: [String: [String]] {
        var result: [String: [String]] = [:]
        for categoryName in customCategoryNames {
            let emoji = vaultService.displayEmoji(forCategoryName: categoryName)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !emoji.isEmpty else { continue }
            result[emoji, default: []].append(categoryName)
        }
        return result
    }

    private var usedEmojiSet: Set<String> {
        Set(usedEmojiNamesByEmoji.keys)
    }

    private func saveCategoryFromQuickCreateSheet() {
        createCategoryViewModel.createCategoryError = nil

        let trimmedName = createCategoryViewModel.newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let key = normalizedKey(trimmedName)
        if existingCategoryKeys.contains(key) {
            createCategoryViewModel.createCategoryError = "That category already exists."
            HapticManager.shared.playMedium()
            return
        }

        let emoji = createCategoryViewModel.newCategoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmoji = emoji.isEmpty ? nil : String(emoji.prefix(1))

        guard let createdCategory = vaultService.createCustomCategory(
            named: trimmedName,
            emoji: normalizedEmoji,
            colorHex: createCategoryViewModel.selectedColorHex
        ) else {
            createCategoryViewModel.createCategoryError = "Couldn’t create that category."
            HapticManager.shared.playMedium()
            return
        }

        let createdKey = normalizedKey(createdCategory.name)
        var visibleNames = decodedVisibleCategoryNames
        visibleNames.removeAll { normalizedKey($0) == createdKey }
        visibleNames.insert(createdCategory.name, at: 0)
        visibleCategoryNamesData = (try? JSONEncoder().encode(normalizedVisibleNames(from: visibleNames))) ?? Data()

        selectedCategoryName = createdCategory.name
        HapticManager.shared.playSuccess()
        showCreateCategorySheet = false
    }

    private func resetCreateCategoryForm() {
        createCategoryViewModel.newCategoryName = ""
        createCategoryViewModel.newCategoryEmoji = ""
        createCategoryViewModel.selectedEmoji = nil
        createCategoryViewModel.selectedColorHex = nil
        createCategoryViewModel.createCategoryError = nil
    }

    private func normalizedKey(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func normalizedHex(_ hex: String?) -> String {
        guard let hex else { return "" }
        return hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
    }

    private func normalizedVisibleNames(from names: [String]) -> [String] {
        let defaultCategoryNames = GroceryCategory.allCases.map(\.title)
        let customCategoryNames = (vaultService.vault?.categories ?? [])
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.name)
        let allCategoryNames = defaultCategoryNames + customCategoryNames

        var canonicalByKey: [String: String] = [:]
        for name in allCategoryNames {
            let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !key.isEmpty, canonicalByKey[key] == nil {
                canonicalByKey[key] = name
            }
        }

        var seen = Set<String>()
        var result: [String] = []
        for name in names {
            let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard let canonical = canonicalByKey[key], !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(canonical)
        }
        return result
    }
}

// Lock tooltip view
struct CategoryLockTooltipView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Category Locked")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("Can only change in planning mode")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
            
            // Tooltip arrow
            Triangle()
                .fill(Color.white)
                .frame(width: 12, height: 8)
                .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                .offset(y: -1)
        }
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .opacity
            )
        )
        .zIndex(1000)
    }
}

struct SimpleLockBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
            Text("Locked")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
