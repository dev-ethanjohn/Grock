//
//  OnboardingFirstItemView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import SwiftUI
import SwiftData

enum GroceryCategory: String, CaseIterable, Identifiable {
    case freshProduce
    case meatsSeafood
    case dairyEggs
    case frozen
    case condimentsIngredients
    case pantry
    case bakeryBread
    case beverages
    case readyMeals
    case personalCare
    case health
    case cleaningHousehold
    case pets
    case baby
    case homeGarden
    case electronicsHobbies
    case stationery
    
    var id: Self { return self }
    
    var title: String {
        switch self {
        case .freshProduce:
            return "Fresh Produce"
        case .meatsSeafood:
            return "Meats & Seafood"
        case .dairyEggs:
            return "Dairy & Eggs"
        case .frozen:
            return "Frozen"
        case .condimentsIngredients:
            return "Condiments & Ingredients"
        case .pantry:
            return "Pantry"
        case .bakeryBread:
            return "Bakery & Bread"
        case .beverages:
            return "Beverages"
        case .readyMeals:
            return "Ready Meals"
        case .personalCare:
            return "Personal Care"
        case .health:
            return "Health"
        case .cleaningHousehold:
            return "Cleaning & Household"
        case .pets:
            return "Pets"
        case .baby:
            return "Baby"
        case .homeGarden:
            return "Home & Garden"
        case .electronicsHobbies:
            return "Electronics & Hobbies"
        case .stationery:
            return "Stationery"
        }
    }
    
    var emoji: String {
        switch self {
        case .freshProduce:
            return "🍏"
        case .meatsSeafood:
            return "🥩"
        case .dairyEggs:
            return "🧀"
        case .frozen:
            return "🧊"
        case .condimentsIngredients:
            return "🧂"
        case .pantry:
            return "🫙"
        case .bakeryBread:
            return "🥖"
        case .beverages:
            return "🥤"
        case .readyMeals:
            return "🍱"
        case .personalCare:
            return "🧴"
        case .health:
            return "💊"
        case .cleaningHousehold:
            return "🧽"
        case .pets:
            return "🐕"
        case .baby:
            return "👶"
        case .homeGarden:
            return "🏠"
        case .electronicsHobbies:
            return "🎮"
        case .stationery:
            return "📝"
        }
    }
    
    var pastelColor: Color {
        switch self {
        case .freshProduce:
            return Color(hex: "AAFF72")
        case .meatsSeafood:
            return Color(hex: "FFBEBE")
        case .dairyEggs:
            return Color(hex: "FFE481")
        case .frozen:
            return Color(hex: "C5F9FF")
        case .condimentsIngredients:
            return Color(hex: "949494")
        case .pantry:
            return Color(hex: "FFF7AA")
        case .bakeryBread:
            return Color(hex: "F5DEB3")
        case .beverages:
            return Color(hex: "AAB3E0")
        case .readyMeals:
            return Color(hex: "FFDAB9")
        case .personalCare:
            return Color(hex: "FFC0CB")
        case .health:
            return Color(hex: "CBCAFF")
        case .cleaningHousehold:
            return Color(hex: "D8BFD8")
        case .pets:
            return Color(hex: "CAA484")
        case .baby:
            return Color(hex: "B0E0E6")
        case .homeGarden:
            return Color(hex: "AED470")
        case .electronicsHobbies:
            return Color(hex: "FF96CA")
        case .stationery:
            return Color(hex: "F3C7A3")
        }
    }
}


struct OnboardingFirstItemView: View {
    @Bindable var viewModel: OnboardingViewModel
    var onFinish: () -> Void
    var onBack: () -> Void
    
    @FocusState private var itemNameFieldIsFocused: Bool
    @State private var showUnitPicker = false
    @State private var selectedCategory: GroceryCategory? = nil
    
    private var questionText: String {
        if viewModel.storeName.isEmpty {
            return "One item you usually buy for grocery"
        } else {
            return "One item you bought from \(viewModel.storeName)"
        }
    }
    
    private var calculatedTotal: Double {
        let portionValue = viewModel.portion ?? 0
        let priceValue = viewModel.itemPrice ?? 0
        return portionValue * priceValue
    }
    
    private var selectedCategoryEmoji: String {
        selectedCategory?.emoji ?? "plus.circle.fill"
    }
    
    private var isFormValid: Bool {
        !viewModel.itemName.isEmpty &&
        viewModel.itemPrice != nil &&
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
                    calculatedTotal: calculatedTotal
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
                        UserDefaults.standard.hasCompletedOnboarding = true
                        onFinish()
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
        }
        .onChange(of: selectedCategory) { _, newValue in
            if let category = newValue {
                viewModel.categoryName = category.title
            }
        }
    }
}

// MARK: - Subviews
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
                selectedCategoryEmoji: selectedCategoryEmoji
            )
            
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 1)
                .foregroundColor(Color(hex: "ddd"))
                .padding(.vertical, 2)
                .padding(.horizontal)
            
            StoreNameDisplay(storeName: $viewModel.storeName)
            
            PortionAndUnitInput(
                portion: $viewModel.portion,
                unit: $viewModel.unit,
                showUnitPicker: $showUnitPicker
            )
            
            PriceInput(itemPrice: $viewModel.itemPrice)
            
            
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

struct ItemNameInput: View {
    @Binding var itemName: String
    var itemNameFieldIsFocused: FocusState<Bool>.Binding
    @Binding var selectedCategory: GroceryCategory?
    let selectedCategoryEmoji: String
    
    @State private var fillAnimation: CGFloat = 0.0
    @State private var fieldScale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("e.g. Tapa", text: $itemName)
                    .font(.subheadline)
                    .bold()
                    .padding(12)
                    .padding(.trailing, 44)
                    .background(
                        Group {
                            if selectedCategory == nil {
                                Color(.systemGray6)
                                    .brightness(0.03)
                            } else {
                                RadialGradient(
                                    colors: [
                                        selectedCategory!.pastelColor.opacity(0.4),
                                        selectedCategory!.pastelColor.opacity(0.35)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: fillAnimation * 100
                                )
                            }
                        }
                            .brightness(-0.03)
                    )
                    .cornerRadius(40)
                    .focused(itemNameFieldIsFocused)
                    .scaleEffect(fieldScale)
                    .overlay(
                        CategoryButton(
                            selectedCategory: $selectedCategory,
                            selectedCategoryEmoji: selectedCategoryEmoji
                        )
                    )
            }
            
            if let category = selectedCategory {
                Text(category.title)
                    .font(.caption2)
                    .foregroundColor(category.pastelColor.darker(by: 0.3))
                    .padding(.horizontal, 16)
                    .transition(.scale.combined(with: .opacity))
                    .id(category.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedCategory)
        .onChange(of: selectedCategory) { oldValue, newValue in
            if newValue != nil {
                if oldValue == nil {
                    // Just selected a category for the first time
                    withAnimation(.spring(duration: 0.5)) {
                        fillAnimation = 1.0
                    }
                    startFieldBounce()
                } else {
                    // Changed from one category to another - reset and refill
                    withAnimation(.spring(duration: 0.5)) {
                        fillAnimation = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(duration: 0.5)) {
                            fillAnimation = 1.0
                        }
                        startFieldBounce()
                    }
                }
            } else {
                // Deselected category
                withAnimation(.easeInOut(duration: 0.4)) {
                    fillAnimation = 0.0
                    fieldScale = 1.0
                }
            }
        }
    }
    
    private func startFieldBounce() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            fieldScale = 0.985
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                fieldScale = 1.015
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                fieldScale = 1.0
            }
        }
    }
}

struct CategoryButton: View {
    @Binding var selectedCategory: GroceryCategory?
    let selectedCategoryEmoji: String
    
    var body: some View {
        HStack {
            Spacer()
            Menu {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(GroceryCategory.allCases) { category in
                        Text("\(category.title) \(category.emoji)")
                            .tag(category as GroceryCategory?)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                ZStack {
                    Circle()
                        .fill(selectedCategory == nil
                              ? Color.gray.opacity(0.2)
                              : selectedCategory!.pastelColor)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedCategory == nil
                                    ? Color.gray
                                    : selectedCategory!.pastelColor.darker(by: 0.2),
                                    lineWidth: 1.5
                                )
                        )
                    
                    
                    
                    if selectedCategory == nil {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    } else {
                        Text(selectedCategoryEmoji)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.trailing, 8)
        }
    }
}

struct StoreNameDisplay: View {
    @Binding var storeName: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Text("Store")
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
            
            // Display text that looks like the input
            Text(storeName.isEmpty ? "Enter store name" : storeName)
                .font(.subheadline)
                .bold()
                .foregroundColor(storeName.isEmpty ? .gray : .primary)
                .multilineTextAlignment(.trailing)
                .overlay(
                    // Hidden TextField that becomes visible when focused
                    TextField("Enter store name", text: $storeName)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.black)
                        .multilineTextAlignment(.trailing)
                        .focused($isFocused)
                        .opacity(isFocused ? 1 : 0) // Only show when focused
                )
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle()) // Makes entire area tappable
        .onTapGesture {
            isFocused = true // Focus the TextField when tapped anywhere
        }
    }
}

struct PortionAndUnitInput: View {
    @Binding var portion: Double?
    @Binding var unit: String
    @Binding var showUnitPicker: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            PortionInput(portion: $portion)
            UnitButton(unit: $unit)
        }
    }
}
struct PortionInput: View {
    @Binding var portion: Double?
    @State private var portionString: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Text("Portion")
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
            TextField("0", text: $portionString)
                .multilineTextAlignment(.trailing)
                .numbersOnly($portionString, includeDecimal: true)
                .font(.subheadline)
                .bold()
                .fixedSize(horizontal: true, vertical: false)
                .focused($isFocused)
                .onChange(of: portionString) { _, newValue in
                    let numberString = newValue.replacingOccurrences(
                        of: Locale.current.decimalSeparator ?? ".",
                        with: "."
                    )
                    portion = Double(numberString)
                }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle()) // Makes entire area tappable
        .onTapGesture {
            isFocused = true // Focus the TextField when tapped anywhere
        }
    }
}

struct UnitButton: View {
    @Binding var unit: String
    
    let continuousUnits: [(abbr: String, full: String)] = [
        ("g", "grams"),
        ("kg", "kilograms"),
        ("lb", "pounds"),
        ("oz", "ounces"),
        ("L", "liters"),
        ("mL", "milliliters")
    ]
    
    let discreteUnits: [(abbr: String, full: String)] = [
        ("pc", "piece"),
        ("pack", ""),
        ("can", ""),
        ("bottle", ""),
        ("box", ""),
        ("bag", "")
    ]
    
    var body: some View {
        Menu {
            Section(header: Text("Weight/Volume")) {
                ForEach(continuousUnits, id: \.abbr) { unitOption in
                    Button(action: {
                        unit = unitOption.abbr
                    }) {
                        
                        if unitOption.full.isEmpty {
                            Text(unitOption.abbr)
                        } else {
                            Text("\(unitOption.abbr) - \(unitOption.full)")
                        }
                        
                    }
                }
            }
            
            Section(header: Text("Discrete")) {
                ForEach(discreteUnits, id: \.abbr) { unitOption in
                    Button(action: {
                        unit = unitOption.abbr
                    }) {
                        if unitOption.full.isEmpty {
                            Text(unitOption.abbr)
                        } else {
                            Text("\(unitOption.abbr) - \(unitOption.full)")
                        }
                    }
                }
            }
            
            Button("Clear Selection") {
                unit = ""
            }
        } label: {
            HStack {
                Text("Unit")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
                Text(unit.isEmpty ? "" : unit) // Show "Select" when empty
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(unit.isEmpty ? .gray : .black)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}
struct PriceInput: View {
    @Binding var itemPrice: Double?
    @State private var priceString: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Text("Price/unit")
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
            
            HStack(spacing: 4) {
                Text("₱")
                    .font(.system(size: 16))
                    .foregroundStyle(priceString.isEmpty ? .gray : .black)
                
                // Display text that looks like the input
                Text(priceString.isEmpty ? "0" : priceString)
                    .foregroundStyle(priceString.isEmpty ? .gray : .black)
                    .font(.subheadline)
                    .bold()
                    .multilineTextAlignment(.trailing)
                    .overlay(
                        // Hidden TextField that becomes visible when focused
                        TextField("0", text: $priceString)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .fixedSize(horizontal: true, vertical: false)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .numbersOnly($priceString, includeDecimal: true)
                            .font(.subheadline)
                            .bold()
                            .focused($isFocused)
                            .opacity(isFocused ? 1 : 0) // Only show when focused
                            .onChange(of: priceString) { _, newValue in
                                // Convert to Double for SwiftData
                                let numberString = newValue.replacingOccurrences(
                                    of: Locale.current.decimalSeparator ?? ".",
                                    with: "."
                                )
                                itemPrice = Double(numberString)
                            }
                            .onAppear {
                                // Initialize with current value
                                if let price = itemPrice {
                                    let formatter = NumberFormatter()
                                    formatter.numberStyle = .decimal
                                    formatter.maximumFractionDigits = 2
                                    formatter.minimumFractionDigits = 0
                                    priceString = formatter.string(from: NSNumber(value: price)) ?? ""
                                }
                            }
                    )
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle()) // Makes entire area tappable
        .onTapGesture {
            isFocused = true // Focus the TextField when tapped anywhere
        }
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


struct FinishButton: View {
    let isFormValid: Bool
    let action: () -> Void
    
    @State private var fillAnimation: CGFloat = 0.0
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                Text("Finish")
                    .font(.fuzzyBold_16)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .fill(
                                isFormValid
                                ? RadialGradient(
                                    colors: [Color.black, Color.gray.opacity(0.3)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: fillAnimation * 80
                                )
                                : RadialGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 0
                                )
                            )
                    )
                    .scaleEffect(buttonScale)
            }
            .disabled(!isFormValid)
        }
        .padding(.vertical, 8)
        .onChange(of: isFormValid) { oldValue, newValue in
            if newValue {
                if !oldValue {
                    // Just became valid
                    withAnimation(.spring(duration: 0.4)) {
                        fillAnimation = 1.0
                    }
                    startButtonBounce()
                }
            } else {
                // Became invalid
                withAnimation(.easeInOut(duration: 0.3)) {
                    fillAnimation = 0.0
                    buttonScale = 1.0
                }
            }
        }
        .onAppear {
            // Check if already valid on appear
            if isFormValid {
                fillAnimation = 1.0
                buttonScale = 1.0
            }
        }
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
}

// Unit Picker Sheet
struct UnitPickerView: View {
    @Binding var selectedUnit: String
    @Environment(\.dismiss) private var dismiss
    
    let units = ["g", "kg", "lb", "oz", "pc", "pack", "L", "mL"]
    
    var body: some View {
        NavigationView {
            List(units, id: \.self) { unit in
                Button(action: {
                    selectedUnit = unit
                    dismiss()
                }) {
                    HStack {
                        Text(unit)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedUnit == unit {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    OnboardingFirstItemView(
        viewModel: OnboardingViewModel(),
        onFinish: {},
        onBack: {}
    )
}


import Combine

struct NumbersOnlyViewModifier: ViewModifier {
    @Binding var text: String
    var includeDecimal: Bool
    
    func body(content: Content) -> some View {
        content
            .keyboardType(includeDecimal ? .decimalPad : .numberPad)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .onReceive(Just(text)) { newValue in
                var numbers = "0123456789"
                let decimalSeparator: String = Locale.current.decimalSeparator ?? "."
                
                if includeDecimal {
                    numbers += decimalSeparator
                }
                
                // Check for multiple decimal separators
                if newValue.components(separatedBy: decimalSeparator).count - 1 > 1 {
                    // Remove the last character if multiple decimal separators
                    let filtered = newValue
                    self.text = String(filtered.dropLast())
                }
                // Check decimal places limit
                else if let decimalIndex = newValue.firstIndex(of: Character(decimalSeparator)) {
                    let decimalPart = newValue[decimalIndex...].dropFirst()
                    if decimalPart.count > 2 {
                        // Remove last character if more than 2 decimal places
                        let filtered = newValue
                        self.text = String(filtered.dropLast())
                    } else {
                        // Filter out non-numeric characters
                        let filtered = newValue.filter { numbers.contains($0) }
                        if filtered != newValue {
                            self.text = filtered
                        }
                    }
                } else {
                    // Filter out non-numeric characters
                    let filtered = newValue.filter { numbers.contains($0) }
                    if filtered != newValue {
                        self.text = filtered
                    }
                }
            }
    }
}

extension View {
    func numbersOnly(_ text: Binding<String>, includeDecimal: Bool = false) -> some View {
        self.modifier(NumbersOnlyViewModifier(text: text, includeDecimal: includeDecimal))
    }
}


struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
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
    
    // Get the first store to use as default display
    private var defaultStoreDisplay: String {
        availableStores.first ?? ""
    }
    
    var body: some View {
        Menu {
            // Add New Store option
            Button(action: {
                newStoreName = ""
                showAddStoreSheet = true
            }) {
                Label("Add New Store", systemImage: "plus.circle.fill")
            }
            
            // Only show divider if there are existing stores
            if !availableStores.isEmpty {
                Divider()
            }
            
            // Existing stores
            ForEach(availableStores, id: \.self) { store in
                Button(action: {
                    storeName = store
                }) {
                    HStack {
                        Text(store)
                        if storeName == store || (storeName.isEmpty && store == availableStores.first) {
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
                Text(storeName.isEmpty ? defaultStoreDisplay : storeName)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(.black)
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
    }
}

// Add this to your OnboardingFirstItemView.swift file, at the end before the #Preview

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
