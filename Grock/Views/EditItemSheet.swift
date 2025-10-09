//
//  EditItemSheet.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/9/25.
//

import SwiftUI

struct EditItemSheet: View {
    let item: Item
    @Binding var isPresented: Bool
    var onSave: ((Item) -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    
    // Form state - initialize with default values first
    @State private var itemName: String = ""
    @State private var selectedCategory: GroceryCategory = .freshProduce
    @State private var storeName: String = ""
    @State private var price: String = ""
    @State private var unit: String = "g"
    @State private var showUnitPicker = false
    
    // Remove the custom initializer and use onAppear instead
    init(item: Item, isPresented: Binding<Bool>, onSave: ((Item) -> Void)? = nil) {
        self.item = item
        self._isPresented = isPresented
        self.onSave = onSave
    }
    
    private var isFormValid: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !storeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(price) != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item Name", text: $itemName)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(GroceryCategory.allCases) { category in
                            HStack {
                                Text(category.emoji)
                                Text(category.title)
                            }
                            .tag(category)
                        }
                    }
                }
                
                Section(header: Text("Pricing")) {
                    TextField("Store", text: $storeName)
                    
                    HStack {
                        Text("Price")
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Button(action: {
                        showUnitPicker = true
                    }) {
                        HStack {
                            Text("Unit")
                            Spacer()
                            Text(unit)
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Initialize form values here, when environment is available
                initializeFormValues()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showUnitPicker) {
            UnitPickerView(selectedUnit: $unit)
        }
    }
    
    private func initializeFormValues() {
        let priceOption = item.priceOptions.first
        
        // Set initial values
        itemName = item.name
        storeName = priceOption?.store ?? ""
        price = String(format: "%.2f", priceOption?.pricePerUnit.priceValue ?? 0)
        unit = priceOption?.pricePerUnit.unit ?? "g"
        
        // Find the current category
        if let categoryName = vaultService.vault?.categories.first(where: { $0.items.contains(where: { $0.id == item.id }) })?.name,
           let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == categoryName }) {
            selectedCategory = groceryCategory
        }
    }
    
//    private func saveChanges() {
//        guard let priceValue = Double(price) else { return }
//        
//        // Update the item in the vault
//        vaultService.updateItem(
//            item: item,
//            newName: itemName.trimmingCharacters(in: .whitespacesAndNewlines),
//            newCategory: selectedCategory,
//            newStore: storeName.trimmingCharacters(in: .whitespacesAndNewlines),
//            newPrice: priceValue,
//            newUnit: unit
//        )
//        
//        onSave?(item)
//        isPresented = false
//    }
    private func saveChanges() {
        guard let priceValue = Double(price) else { return }
        
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
            // Send notification that category changed
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
