import SwiftUI
import SwiftData

struct EditItemSheet: View {
    let item: Item
    @Binding var isPresented: Bool
    var onSave: ((Item) -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    
    // Form state
    @State private var itemName: String = ""
    @State private var selectedCategory: GroceryCategory? = nil
    @State private var storeName: String = ""
    @State private var price: String = ""
    @State private var unit: String = "g"
    @State private var showUnitPicker = false
    
    @FocusState private var itemNameFieldIsFocused: Bool
    
    private var selectedCategoryEmoji: String {
        selectedCategory?.emoji ?? "plus.circle.fill"
    }
    
    private var isFormValid: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedCategory != nil &&
        !storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(price) != nil
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack {
                        Spacer()
                            .frame(height: 20)
                        
                        // Item Name with Category
                        ItemNameInput(
                            itemName: $itemName,
                            itemNameFieldIsFocused: $itemNameFieldIsFocused,
                            selectedCategory: $selectedCategory,
                            selectedCategoryEmoji: selectedCategoryEmoji
                        )
                        
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "ddd"))
                            .padding(.vertical, 2)
                            .padding(.horizontal)
                        
                        // Store
                        StoreNameComponent(storeName: $storeName)
                        
                        // Unit and Price
                        HStack(spacing: 8) {
                            UnitButton(unit: $unit)
                            PriceInputForEdit(price: $price)
                        }
                        
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding()
                }
                
                // Save Button
                HStack {
                    Spacer()
                    SaveButton(isFormValid: isFormValid) {
                        saveChanges()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            initializeFormValues()
        }
    }
    
    private func initializeFormValues() {
        let priceOption = item.priceOptions.first
        
        // Set initial values
        itemName = item.name
        storeName = priceOption?.store ?? ""
        price = String(priceOption?.pricePerUnit.priceValue ?? 0) 
        unit = priceOption?.pricePerUnit.unit ?? "g"
        
        // Find the current category
        if let categoryName = vaultService.vault?.categories.first(where: { $0.items.contains(where: { $0.id == item.id }) })?.name,
           let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == categoryName }) {
            selectedCategory = groceryCategory
        }
    }
    
    private func saveChanges() {
        guard let priceValue = Double(price),
              let selectedCategory = selectedCategory else { return }
        
        // Store the old category for comparison
        let oldCategoryName = vaultService.vault?.categories.first(where: { $0.items.contains(where: { $0.id == item.id }) })?.name
        
        // Update the item in the vault
        vaultService.updateItem(
            item: item,
            newName: itemName.trimmingCharacters(in: .whitespacesAndNewlines),
            newCategory: selectedCategory,
            newStore: storeName.trimmingCharacters(in: .whitespacesAndNewlines),
            newPrice: priceValue,
            newUnit: unit
        )
        
        onSave?(item)
        isPresented = false
        
        // Notify about category change if needed
        if oldCategoryName != selectedCategory.title {
            NotificationCenter.default.post(
                name: NSNotification.Name("ItemCategoryChanged"),
                object: nil,
                userInfo: [
                    "newCategory": selectedCategory,
                    "itemId": item.id
                ]
            )
        }
    }
}

// MARK: - Custom Components for Edit Sheet

struct UnitButtonForEdit: View {
    @Binding var unit: String
    @Binding var showUnitPicker: Bool
    
    var body: some View {
        Button(action: {
            showUnitPicker = true
        }) {
            HStack {
                Text("Unit")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
                Text(unit.isEmpty ? "Select" : unit)
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

struct PriceInputForEdit: View {
    @Binding var price: String
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
                    .foregroundStyle(price.isEmpty ? .gray : .black)
                
                Text(price.isEmpty ? "0" : price)
                    .foregroundStyle(price.isEmpty ? .gray : .black)
                    .font(.subheadline)
                    .bold()
                    .multilineTextAlignment(.trailing)
                    .overlay(
                        TextField("0", text: $price)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .fixedSize(horizontal: true, vertical: false)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .numbersOnly($price, includeDecimal: true, maxDigits: 5)
                            .font(.subheadline)
                            .bold()
                            .focused($isFocused)
                            .opacity(isFocused ? 1 : 0)
                    )
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }
}

struct SaveButton: View {
    let isFormValid: Bool
    let action: () -> Void
    
    @State private var fillAnimation: CGFloat = 0.0
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            Text("Save")
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
        .onChange(of: isFormValid) { oldValue, newValue in
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
                    buttonScale = 1.0
                }
            }
        }
        .onAppear {
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
