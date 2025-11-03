//
//  OnboardingFirstItemView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import SwiftUI
import SwiftData




import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

struct OnboardingFirstItemView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(VaultService.self) private var vaultService
    
    var onFinish: () -> Void
    var onBack: () -> Void
    
    @FocusState private var itemNameFieldIsFocused: Bool
    @State private var showUnitPicker = false
    
    @State private var selectedCategory: GroceryCategory? = nil
    
    @State private var showCategoryTooltip = false
    
    private var questionText: String {
        if viewModel.storeName.isEmpty {
            return "One item you usually buy for grocery"
        } else {
            return "One item you bought from \(viewModel.storeName)"
        }
    }
    
    private var calculatedTotal: Double {
        let portionValue = viewModel.portion ?? 0
        let priceValue = Double(viewModel.itemPrice) ?? 0
        return portionValue * priceValue
    }
    
    private var selectedCategoryEmoji: String {
        selectedCategory?.emoji ?? "plus.circle.fill"
    }
    
    private var isFormValid: Bool {
        !viewModel.itemName.isEmpty &&
        Double(viewModel.itemPrice) != nil &&
        viewModel.portion != nil &&
        !viewModel.unit.isEmpty &&
        selectedCategory != nil
    }
    
    var body: some View {
        VStack {
            NavigationHeader(onBack: onBack)
            
            ScrollView {
                FormContent(
                    questionText: questionText,
                    viewModel: viewModel,
                    itemNameFieldIsFocused: $itemNameFieldIsFocused,
                    selectedCategory: $selectedCategory,
                    selectedCategoryEmoji: selectedCategoryEmoji,
                    showUnitPicker: $showUnitPicker,
                    calculatedTotal: calculatedTotal,
                    showCategoryTooltip: $showCategoryTooltip
                )
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TotalDisplay(calculatedTotal: calculatedTotal)
                    
                    Spacer()
                    
                    FinishButton(isFormValid: isFormValid) {
                        if let category = selectedCategory {
                            viewModel.categoryName = category.title
                        }
                        
                        UserDefaults.standard.set(false, forKey: "hasSeenVaultCelebration")
                        print("🎉 OnboardingFirstItemView: Reset celebration flag")
                        
                        saveInitialData()
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showUnitPicker) {
            UnitPickerView(selectedUnit: $viewModel.unit)
        }
        .onAppear {
            itemNameFieldIsFocused = true
            if viewModel.unit.isEmpty {
                viewModel.unit = "g"
            }
            if !viewModel.categoryName.isEmpty {
                selectedCategory = GroceryCategory.allCases.first { $0.title == viewModel.categoryName }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showCategoryTooltip = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCategoryTooltip = false
                    }
                }
            }
        }
        .onChange(of: selectedCategory) { _, newValue in
            if let category = newValue {
                viewModel.categoryName = category.title
                withAnimation(.easeOut(duration: 0.3)) {
                    showCategoryTooltip = false
                }
            }
        }
    }
    
    private func saveInitialData() {
        guard let category = selectedCategory,
              let price = Double(viewModel.itemPrice) else {
            print("❌ Failed to save item - invalid data")
            return
        }
        
        print("💾 Saving item to vault:")
        print("   Name: \(viewModel.itemName)")
        print("   Category: \(category.title)")
        print("   Store: \(viewModel.storeName)")
        print("   Price: ₱\(price)")
        print("   Unit: \(viewModel.unit)")
        
        vaultService.addItem(
            name: viewModel.itemName,
            to: category,
            store: viewModel.storeName,
            price: price,
            unit: viewModel.unit
        )
        
        print("✅ Item saved successfully!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("💾 Vault processing complete - proceeding to finish")
            
            UserDefaults.standard.hasCompletedOnboarding = true
            
            onFinish()
        }
    }
}


struct NavigationHeader: View {
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image("back")
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

struct FormContent: View {
    let questionText: String
    @Bindable var viewModel: OnboardingViewModel
    var itemNameFieldIsFocused: FocusState<Bool>.Binding
    @Binding var selectedCategory: GroceryCategory?
    let selectedCategoryEmoji: String
    @Binding var showUnitPicker: Bool
    let calculatedTotal: Double
    @Binding var showCategoryTooltip: Bool
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 20)
            
            QuestionTitle(text: questionText)
            
            Spacer()
                .frame(height: 40)
            
            ItemNameInput(
                itemName: $viewModel.itemName,
                itemNameFieldIsFocused: itemNameFieldIsFocused,
                selectedCategory: $selectedCategory,
                selectedCategoryEmoji: selectedCategoryEmoji,
                showTooltip: showCategoryTooltip
            )
            
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 1)
                .foregroundColor(Color(hex: "ddd"))
                .padding(.vertical, 2)
                .padding(.horizontal)
            
            StoreNameComponent(storeName: $viewModel.storeName)
            
            PortionAndUnitInput(
                portion: $viewModel.portion,
                unit: $viewModel.unit,
                showUnitPicker: $showUnitPicker
            )
            
            PricePerUnitField(price: $viewModel.itemPrice)
            
            Spacer()
                .frame(height: 80)
        }
        .padding()
    }
}

struct QuestionTitle: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.fuzzyBold_24)
            .bold()
            .multilineTextAlignment(.center)
    }
}

struct TotalDisplay: View {
    let calculatedTotal: Double
    
    var body: some View {
        HStack(spacing: 2) {
            Text("Total: ₱")
                .font(.fuzzyBold_16)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text(calculatedTotal, format: .number.precision(.fractionLength(2)))
                .font(.fuzzyBold_16)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .contentTransition(.numericText(value: calculatedTotal))
                .animation(.spring(duration: 0.1), value: calculatedTotal)
        }
        .padding(.top, 4)
    }
}




import Combine

extension View {
    func numbersOnly(_ text: Binding<String>, includeDecimal: Bool, maxDigits: Int) -> some View {
        self
            .keyboardType(includeDecimal ? .decimalPad : .numberPad)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .onChange(of: text.wrappedValue) { oldValue, newValue in
                var filtered = newValue.filter { "0123456789".contains($0) }
                
                if includeDecimal {
                    // Allow decimal point - use unique variable name
                    let initialComponents = newValue.components(separatedBy: ".")
                    if initialComponents.count > 1 {
                        filtered = initialComponents[0] + "." + initialComponents[1...].joined()
                    }
                    
                    // Ensure only one decimal point exists
                    let decimalCount = newValue.components(separatedBy: ".").count - 1
                    if decimalCount > 1 {
                        let parts = newValue.split(separator: ".")
                        filtered = String(parts[0]) + "." + parts.dropFirst().joined()
                    }
                    
                    // Apply digit limit to integer part - use unique variable name
                    let filteredComponents = filtered.components(separatedBy: ".")
                    if filteredComponents[0].count > maxDigits {
                        let limitedInteger = String(filteredComponents[0].prefix(maxDigits))
                        filtered = filteredComponents.count > 1 ? limitedInteger + "." + filteredComponents[1] : limitedInteger
                    }
                    
                    // Apply 2-digit limit to decimal part
                    if filteredComponents.count > 1 && filteredComponents[1].count > 2 {
                        let limitedDecimal = String(filteredComponents[1].prefix(2))
                        filtered = filteredComponents[0] + "." + limitedDecimal
                    }
                } else {
                    // No decimals allowed - just limit digits
                    if filtered.count > maxDigits {
                        filtered = String(filtered.prefix(maxDigits))
                    }
                }
                
                if filtered != newValue {
                    text.wrappedValue = filtered
                }
            }
    }
}

// MARK: - StoreNameDisplay for Vault/AddItemPopover (Dropdown with SwiftData)
struct StoreNameDisplayForVault: View {
    @Binding var storeName: String
    @State private var showAddStoreSheet = false
    @State private var newStoreName = ""
    
    // Fetch ALL items from vault to get unique store names
    @Query private var vaults: [Vault]
    @Environment(\.modelContext) private var modelContext
    
    // Get unique store names from ALL items in the vault
    private var availableStores: [String] {
        guard let vault = vaults.first else { return [] }
        
        let allStores = vault.categories.flatMap { category in
            category.items.flatMap { item in
                item.priceOptions.map { $0.store }
            }
        }
        
        return Array(Set(allStores)).sorted()
    }
    
    var body: some View {
        Menu {
            Button(action: {
                newStoreName = ""
                showAddStoreSheet = true
            }) {
                Label("Add New Store", systemImage: "plus.circle.fill")
            }

            if !availableStores.isEmpty {
                Divider()
            }
            
            ForEach(availableStores, id: \.self) { store in
                Button(action: {
                    storeName = store
                }) {
                    HStack {
                        Text(store)
                        if storeName == store {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text("Store")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
                Text(storeName.isEmpty ? "Select Store" : storeName)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(storeName.isEmpty ? .gray : .black)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .sheet(isPresented: $showAddStoreSheet) {
            AddStoreSheet(
                storeName: $newStoreName,
                isPresented: $showAddStoreSheet,
                onSave: { newStore in
                    storeName = newStore
                    showAddStoreSheet = false
                }
            )
        }
        .onAppear {
            if storeName.isEmpty, let firstStore = availableStores.first {
                storeName = firstStore
            }
        }
        .onChange(of: availableStores) { oldStores, newStores in
            if storeName.isEmpty, let firstStore = newStores.first {
                storeName = firstStore
            }
        }
    }
}


// MARK: - AddStoreSheet (for Vault version)
struct AddStoreSheet: View {
    @Binding var storeName: String
    @Binding var isPresented: Bool
    var onSave: ((String) -> Void)?
    
    @FocusState private var isFocused: Bool
    
    private var isSaveDisabled: Bool {
        storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter store name", text: $storeName)
                    .font(.subheadline)
                    .bold()
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isFocused)
                    .onAppear {
                        isFocused = true
                    }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add New Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let trimmedName = storeName.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave?(trimmedName)
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
}
