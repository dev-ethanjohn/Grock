import SwiftUI
import SwiftData

struct EditItemSheet: View {
    let item: Item
//    @Binding var isPresented: Bool
    var onSave: ((Item) -> Void)?
    var context: EditContext = .vault
    
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    
    // Form states
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
    
    private var isEditFormValid: Bool {
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
                        
                        StoreNameComponent(storeName: $storeName)
                        
                        HStack(spacing: 8) {
                            UnitButton(unit: $unit)
                            PricePerUnitField(price: $price)
                        }
                        
                        if context == .cart {
                            Text("Editing this item will update prices in all active carts")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                        
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding()
                }
                
                HStack {
                    Spacer()
                    EditItemSaveButton(isEditFormValid: isEditFormValid) {
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
//                        isPresented = false
                        dismiss()
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
//        isPresented = false
        dismiss()
        
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

struct EditItemSaveButton: View {
    let isEditFormValid: Bool
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
                            isEditFormValid
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
        .disabled(!isEditFormValid)
        .onChange(of: isEditFormValid) { oldValue, newValue in
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
            if isEditFormValid {
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
