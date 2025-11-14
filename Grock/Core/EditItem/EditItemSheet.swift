import SwiftUI
import SwiftData

//sa huli palagi,,,  song
struct EditItemSheet: View {
    
    //TODO: Rearrange + put in a veiw model.
    let item: Item
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
                        
                        ItemNameInput(
                            selectedCategoryEmoji: selectedCategoryEmoji,
                            showTooltip:  false,
                            itemNameFieldIsFocused: $itemNameFieldIsFocused,
                            itemName: $itemName,
                            selectedCategory: $selectedCategory
                        )
                        
                        StoreNameComponent(storeName: $storeName)
                        
                        HStack(spacing: 8) {
                            UnitButton(unit: $unit)
                            PricePerUnitField(price: $price)
                        }
                        
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 1)
                            .foregroundColor(Color(hex: "ddd"))
                            .padding(.vertical, 6)
                            .padding(.horizontal)
                        
                        
                        if context == .cart {
                            HStack(spacing: 0) {
                                
                                Text("Remove from Cart")
                                    .lexendFont(14, weight: .medium)
                                    .foregroundStyle(.red)
                                    .padding(.vertical)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text("|")
                                    .lexendFont(16, weight: .thin)
                                
                                Text("Remove from Vault")
                                    .lexendFont(14, weight: .medium)
                                    .foregroundStyle(.red)
                                    .padding(.vertical)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .foregroundStyle(.black)
                            
                            //                            MARK:BUG: AFTER CLICKING SAVE ON EDITSHEET, the row returns a duplicate row.
                        } else {
                            HStack(spacing: 8) {
                                //                                RemoveButton(text: "Remove from Vault")
                                
                                Text("Remove from Vault")
                                    .lexendFont(14, weight: .medium)
                                
                                Image(systemName: "trash")
                                    .lexendFont(12, weight: .bold)
                                
                                
                            }
                            .foregroundStyle(.red)
                            .padding(.vertical)
                            
                        }
                        
                    
                        
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.horizontal)
                }
                
//                HStack {
//                    if context == .cart {
//                        Text("Editing this item will update prices from vault and in all active carts")
//                            .font(.caption)
//                            .foregroundColor(.gray)
//                            .padding(.top, 8)
//                            .multilineTextAlignment(.center)
//                    }
//                    Spacer()
//                    EditItemSaveButton(isEditFormValid: isEditFormValid) {
//                        saveChanges()
//                    }
//                }
//                .padding(.horizontal)
//                .padding(.bottom, 20)
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .onAppear {
            initializeFormValues()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                if context == .cart {
                    Text("Editing this item will update prices from vault and in all active carts")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                EditItemSaveButton(isEditFormValid: isEditFormValid) {
                    saveChanges()
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
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

//import SwiftUI
//import SwiftData
//
//struct EditItemSheet: View {
//    @State private var viewModel: EditItemViewModel
//    var onSave: ((Item) -> Void)?
//    
//    @Environment(\.dismiss) private var dismiss
//    
//    init(item: Item, context: EditContext = .vault, vaultService: VaultService, onSave: ((Item) -> Void)? = nil) {
//        self.onSave = onSave
//        self._viewModel = State(wrappedValue: EditItemViewModel(
//            item: item,
//            context: context,
//            vaultService: vaultService
//        ))
//    }
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                ScrollView {
//                    VStack {
//                        ItemNameInput(
//                            selectedCategoryEmoji: viewModel.selectedCategoryEmoji,
//                            showTooltip: false,
//                            itemNameFieldIsFocused: $viewModel.itemNameFieldIsFocused,
//                            itemName: $viewModel.itemName,
//                            selectedCategory: $viewModel.selectedCategory
//                        )
//                        
//                        StoreNameComponent(
//                            storeName: $viewModel.storeName,
//                            availableStores: viewModel.availableStores,
//                            showAddStoreSheet: $viewModel.showAddStoreSheet,
//                            newStoreName: $viewModel.newStoreName,
//                            onAddStore: { viewModel.addNewStore() }
//                        )
//                        
//                        HStack(spacing: 8) {
//                            UnitButton(unit: $viewModel.unit)
//                            PricePerUnitField(price: $viewModel.price)
//                        }
//                        
//                        DashedLine()
//                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
//                            .frame(height: 1)
//                            .foregroundColor(Color(hex: "ddd"))
//                            .padding(.vertical, 6)
//                            .padding(.horizontal)
//                        
//                        if viewModel.context == .cart {
//                            HStack(spacing: 8) {
//                                RemoveButton(text: "Remove from Cart")
//                                RemoveButton(text: "Remove from Vault")
//                            }
//                            .foregroundStyle(.black)
//                        } else {
//                            RemoveButton(text: "Remove from Vault")
//                        }
//                        
//                        if viewModel.context == .cart {
//                            Text("Editing this item will update prices from vault and in all active carts")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                                .padding(.top, 8)
//                                .multilineTextAlignment(.center)
//                        }
//                        
//                        Spacer()
//                            .frame(height: 80)
//                    }
//                    .padding(.horizontal)
//                }
//                
//                HStack {
//                    Spacer()
//                    EditItemSaveButton(isEditFormValid: viewModel.isFormValid) {
//                        if viewModel.saveChanges() {
//                            onSave?(viewModel.item)
//                            dismiss()
//                        }
//                    }
//                }
//                .padding(.horizontal)
//                .padding(.bottom, 20)
//            }
//            .navigationTitle("Edit Item")
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
//}

struct EditItemSaveButton: View {
    let isEditFormValid: Bool
    let action: () -> Void
    
    @State private var fillAnimation: CGFloat = 0.0
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            Text("Save")
                .fuzzyBubblesFont(16, weight: .bold)
                .foregroundStyle(.white)
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
                                endRadius: fillAnimation * 150
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


