import SwiftUI
import SwiftData

struct EditItemRemoveOptionsView: View {
    let context: EditContext
    let onRemoveFromCart: () -> Void
    let onRemoveFromVault: () -> Void
    
    var body: some View {
        if context == .cart {
            HStack(spacing: 0) {
                removeOption(
                    text: "Remove from Cart",
                    action: onRemoveFromCart
                )
                
                Text("|")
                    .lexendFont(16, weight: .thin)
                
                removeOption(
                    text: "Remove from Vault",
                    action: onRemoveFromVault
                )
            }
            .foregroundStyle(.black)
        } else {
            HStack(spacing: 8) {
                Text("Remove from Vault")
                    .lexendFont(14, weight: .medium)
                
                Image(systemName: "trash")
                    .lexendFont(12, weight: .bold)
            }
            .foregroundStyle(.red)
            .padding(.vertical)
            .onTapGesture {
                onRemoveFromVault()
            }
        }
    }
    
    private func removeOption(text: String, action: @escaping () -> Void) -> some View {
        Text(text)
            .lexendFont(14, weight: .medium)
            .foregroundStyle(.red)
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .center)
            .onTapGesture {
                action()
            }
    }
}

struct EditItemBottomBarView: View {
    let context: EditContext
    let isEditFormValid: Bool
    let formViewModel: ItemFormViewModel
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            EditItemSaveButton(
                isEditFormValid: isEditFormValid,
                buttonTitle: formViewModel.getSaveButtonTitle(),
                buttonColor: formViewModel.getSaveButtonColor()
            ) {
                print("🔄 EditItemBottomBarView onSave called")
                onSave()
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 12)
    }
}

class EditItemValidationHandler {
    @MainActor
    static func triggerRealTimeValidation(
        formViewModel: ItemFormViewModel,
        item: Item,
        vaultService: VaultService,
        duplicateError: Binding<String?>,
        validationTask: inout Task<Void, Never>?
    ) {
        validationTask?.cancel()
        
        let itemName = formViewModel.itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let storeName = formViewModel.storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !itemName.isEmpty && !storeName.isEmpty else {
            duplicateError.wrappedValue = nil
            return
        }
        
        validationTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            if !Task.isCancelled {
                let validation = vaultService.validateItemName(itemName, store: storeName, excluding: item.id)
                await MainActor.run {
                    if !validation.isValid {
                        duplicateError.wrappedValue = validation.errorMessage
                    } else {
                        duplicateError.wrappedValue = nil
                    }
                }
            }
        }
    }
}

struct EditItemSheet: View {
    let item: Item
    let cart: Cart?
    let cartItem: CartItem?
    var onSave: ((Item) -> Void)?
    var context: EditContext = .vault
    
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    
    @State private var formViewModel: ItemFormViewModel
    @State private var duplicateError: String?
    @State private var validationTask: Task<Void, Never>?
    @FocusState private var itemNameFieldIsFocused: Bool
    
    // MARK: - Initializers
    
    init(
        item: Item,
        cart: Cart? = nil,
        cartItem: CartItem? = nil,
        onSave: ((Item) -> Void)? = nil,
        context: EditContext? = nil
    ) {
        self.item = item
        self.cart = cart
        self.cartItem = cartItem
        self.onSave = onSave
        
        // Determine context
        if cart != nil && cartItem != nil {
            self.context = .cart
            _formViewModel = State(initialValue: ItemFormViewModel(
                requiresPortion: true,
                requiresStore: true,
                context: .cart
            ))
        } else {
            self.context = context ?? .vault
            _formViewModel = State(initialValue: ItemFormViewModel(
                requiresPortion: false,
                requiresStore: true,
                context: context ?? .vault
            ))
        }
        
        print("🔵 EditItemSheet INIT called - context: \(self.context)")
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack {
                        // Form Content
                        ItemFormContent(
                            formViewModel: formViewModel,
                            itemNameFieldIsFocused: $itemNameFieldIsFocused,
                            showCategoryTooltip: false,
                            duplicateError: duplicateError,
                            isCheckingDuplicate: false,
                            onStoreChange: {
                                triggerRealTimeValidation()
                            },
                            isCategoryEditable: true
                        )
                        
                        
                        // Remove Options
                        EditItemRemoveOptionsView(
                            context: context,
                            onRemoveFromCart: removeFromCart,
                            onRemoveFromVault: removeFromVault
                        )
                        
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            print("🟢 EditItemSheet appeared - context: \(context)")
            initializeFormValues()
        }
        .onChange(of: formViewModel.itemName) { oldValue, newValue in
            triggerRealTimeValidation()
        }
        .onChange(of: formViewModel.storeName) { oldValue, newValue in
            triggerRealTimeValidation()
        }
        .safeAreaInset(edge: .bottom) {
            EditItemBottomBarView(
                context: context,
                isEditFormValid: formViewModel.isFormValid && duplicateError == nil,
                formViewModel: formViewModel,
                onSave: saveChanges
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: formViewModel.firstMissingField)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: duplicateError)
    }
    
    // MARK: - Helper Methods
    
    private func initializeFormValues() {
        print("🟢 initializeFormValues called - Context: \(context)")
        
        if context == .cart, let cart = cart, let cartItem = cartItem {
            print("🛒 Loading cart item data")
            print("🛒 Cart status: \(cart.status)")
            
            // For cart context (planning mode only)
            formViewModel.itemName = item.name
            formViewModel.storeName = cartItem.plannedStore
            
            // Get price from planned price or vault
            if let plannedPrice = cartItem.plannedPrice {
                formViewModel.itemPrice = String(plannedPrice)
                print("   Using plannedPrice: \(plannedPrice)")
            } else {
                // Fallback to vault price
                let priceOption = item.priceOptions.first
                formViewModel.itemPrice = String(priceOption?.pricePerUnit.priceValue ?? 0)
                print("   Using vault price")
            }
            
            formViewModel.unit = cartItem.plannedUnit ?? "piece"
            formViewModel.portion = cartItem.quantity
            
            // Category from vault
            if let categoryName = vaultService.getCategory(for: item.id)?.name,
               let groceryCategory = GroceryCategory.allCases.first(where: { $0.title == categoryName }) {
                formViewModel.selectedCategory = groceryCategory
                print("   Category: \(groceryCategory.title)")
            }
            
            // REMOVED: modeDescription assignment
            // formViewModel.modeDescription = "Editing item"
            
        } else {
            // Vault editing
            print("🏦 Loading vault item data")
            formViewModel.populateFromItem(item, vaultService: vaultService)
            // REMOVED: modeDescription assignment
            // formViewModel.modeDescription = "Editing vault item"
        }
        
        print("🟢 After initialize:")
        print("   itemName: \(formViewModel.itemName)")
        print("   itemPrice: \(formViewModel.itemPrice)")
        print("   unit: \(formViewModel.unit)")
        print("   portion: \(formViewModel.portion ?? -1)")
    }
    
    private func triggerRealTimeValidation() {
        EditItemValidationHandler.triggerRealTimeValidation(
            formViewModel: formViewModel,
            item: item,
            vaultService: vaultService,
            duplicateError: $duplicateError,
            validationTask: &validationTask
        )
    }
    
    private func saveChanges() {
        if formViewModel.attemptSubmission() {
            executeSave()
        } else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
    }
    
    private func executeSave() {
        guard let priceValue = Double(formViewModel.itemPrice) else { return }
        
        // Validate for duplicates
        let validation = vaultService.validateItemName(
            formViewModel.itemName,
            store: formViewModel.storeName,
            excluding: item.id
        )
        if !validation.isValid {
            duplicateError = validation.errorMessage
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        // Store old values
        let oldStoreName = item.priceOptions.first?.store ?? ""
        let oldCategoryName = vaultService.vault?.categories.first(where: {
            $0.items.contains(where: { $0.id == item.id })
        })?.name
        
        var success = false
        
        if context == .cart, let cart = cart, let cartItem = cartItem {
            // Cart context - planning mode only
            success = saveCartItemChanges(
                cart: cart,
                cartItem: cartItem,
                priceValue: priceValue,
                oldStoreName: oldStoreName,
                oldCategoryName: oldCategoryName
            )
        } else {
            success = saveVaultItemChanges(
                priceValue: priceValue,
                oldStoreName: oldStoreName,
                oldCategoryName: oldCategoryName
            )
        }
        
        handleSaveResult(
            success: success,
            oldStoreName: oldStoreName,
            oldCategoryName: oldCategoryName
        )
    }
    
    private func saveCartItemChanges(
        cart: Cart,
        cartItem: CartItem,
        priceValue: Double,
        oldStoreName: String,
        oldCategoryName: String?
    ) -> Bool {
        print("💾 Saving in cart context - Cart status: \(cart.status)")
        
        // Only allow editing in planning mode
        guard cart.status == .planning else {
            print("⚠️ ERROR: Can only edit items in planning mode")
            return false
        }
        
        return saveCartItem(
            cart: cart,
            cartItem: cartItem,
            priceValue: priceValue,
            oldCategoryName: oldCategoryName
        )
    }
    
    private func saveCartItem(
        cart: Cart,
        cartItem: CartItem,
        priceValue: Double,
        oldCategoryName: String?
    ) -> Bool {
        print("📝 Updating Vault and cart")
        guard let selectedCategory = formViewModel.selectedCategory else {
            duplicateError = "Category is required"
            return false
        }
        
        let success = vaultService.updateItem(
            item: item,
            newName: formViewModel.itemName.trimmingCharacters(in: .whitespacesAndNewlines),
            newCategory: selectedCategory,
            newStore: formViewModel.storeName.trimmingCharacters(in: .whitespacesAndNewlines),
            newPrice: priceValue,
            newUnit: formViewModel.unit
        )
        
        if success {
            updateAllCartsWithItem(
                itemId: item.id,
                price: priceValue,
                unit: formViewModel.unit,
                store: formViewModel.storeName
            )
            updateCartItemQuantity(cart: cart, cartItem: cartItem, portion: formViewModel.portion)
            vaultService.updateCartTotals(cart: cart)
        }
        
        return success
    }
    
    private func saveVaultItemChanges(
        priceValue: Double,
        oldStoreName: String,
        oldCategoryName: String?
    ) -> Bool {
        print("🏦 Vault editing - updating Vault")
        guard let selectedCategory = formViewModel.selectedCategory else {
            duplicateError = "Category is required"
            return false
        }
        
        return vaultService.updateItem(
            item: item,
            newName: formViewModel.itemName.trimmingCharacters(in: .whitespacesAndNewlines),
            newCategory: selectedCategory,
            newStore: formViewModel.storeName.trimmingCharacters(in: .whitespacesAndNewlines),
            newPrice: priceValue,
            newUnit: formViewModel.unit
        )
    }
    
    private func handleSaveResult(
        success: Bool,
        oldStoreName: String,
        oldCategoryName: String?
    ) {
        if success {
            // ✅ Preserve old store
            if !oldStoreName.isEmpty {
                vaultService.ensureStoreExists(oldStoreName)
            }
            // ✅ Ensure new store exists
            vaultService.ensureStoreExists(formViewModel.storeName)
            
            // Call save callback
            onSave?(item)
            dismiss()
            
            // Notify category change if needed
            if let selectedCategory = formViewModel.selectedCategory,
               oldCategoryName != selectedCategory.title {
                NotificationCenter.default.post(
                    name: NSNotification.Name("ItemCategoryChanged"),
                    object: nil,
                    userInfo: [
                        "newCategory": selectedCategory,
                        "itemId": item.id
                    ]
                )
            }
        } else {
            duplicateError = "Failed to update item. Please try again."
        }
    }
    
    private func updateAllCartsWithItem(
        itemId: String,
        price: Double,
        unit: String,
        store: String
    ) {
        if let vault = vaultService.vault {
            for cart in vault.carts where cart.status == .planning {
                for cartItem in cart.cartItems where cartItem.itemId == itemId {
                    cartItem.plannedPrice = price
                    cartItem.plannedUnit = unit
                    cartItem.plannedStore = store
                }
            }
        }
    }
    
    private func updateCartItemQuantity(
        cart: Cart,
        cartItem: CartItem,
        portion: Double?
    ) {
        guard let portion = portion else { return }
        cartItem.quantity = portion
    }
    
    private func removeFromCart() {
        guard let cart = cart else { return }
        
        vaultService.removeItemFromCart(cart: cart, itemId: item.id)
        dismiss()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func removeFromVault() {
        let alert = UIAlertController(
            title: "Remove Item",
            message: "Are you sure you want to remove this item from your vault? This will also remove it from all carts.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
            vaultService.deleteItem(item)
            dismiss()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}
