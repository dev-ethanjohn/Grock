import SwiftUI
import SwiftData

struct EditItemSheet: View {
    let item: Item
    let cart: Cart?
    let cartItem: CartItem?
    var onSave: ((Item) -> Void)?
    var context: EditContext = .vault
    
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    
    // Create formViewModel based on context
    @State private var formViewModel: ItemFormViewModel
    @State private var showUnitPicker = false
    
    @FocusState private var itemNameFieldIsFocused: Bool
    
    @State private var duplicateError: String?
    @State private var validationTask: Task<Void, Never>?
    
    // MARK: - Initializers for different contexts
    
    // For vault editing (no cart)
    init(item: Item, onSave: ((Item) -> Void)? = nil) {
        self.item = item
        self.cart = nil
        self.cartItem = nil
        self.onSave = onSave
        self.context = .vault
        // Initialize with requiresPortion = false for vault
        _formViewModel = State(initialValue: ItemFormViewModel(requiresPortion: false, requiresStore: true))
    }
    
    // For cart editing
    init(item: Item, cart: Cart, cartItem: CartItem, onSave: ((Item) -> Void)? = nil) {
        self.item = item
        self.cart = cart
        self.cartItem = cartItem
        self.onSave = onSave
        self.context = .cart
        // Initialize with requiresPortion = true for cart
        _formViewModel = State(initialValue: ItemFormViewModel(requiresPortion: true, requiresStore: true))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack {
                        ItemFormContent(
                            formViewModel: formViewModel,
                            itemNameFieldIsFocused: $itemNameFieldIsFocused,
                            showCategoryTooltip: false,
                            duplicateError: duplicateError,
                            onStoreChange: {
                                triggerRealTimeValidation()
                            }
                        )
                        
                        // Show total calculation ONLY for cart context
                        if context == .cart, let portion = formViewModel.portion, let priceValue = Double(formViewModel.itemPrice) {
                            Divider()
                                .padding(.vertical, 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Cart Quantity")
                                        .lexendFont(14, weight: .medium)
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    let total = priceValue * portion
                                    Text("Total: \(formatCurrency(total))")
                                        .lexendFont(16, weight: .bold)
                                        .foregroundColor(.green)
                                }
                                
                                Text("\(formatCurrency(priceValue)) × \(portion.formatted())")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if context == .cart {
                            HStack(spacing: 0) {
                                Text("Remove from Cart")
                                    .lexendFont(14, weight: .medium)
                                    .foregroundStyle(.red)
                                    .padding(.vertical)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .onTapGesture {
                                        removeFromCart()
                                    }
                                
                                Text("|")
                                    .lexendFont(16, weight: .thin)
                                
                                Text("Remove from Vault")
                                    .lexendFont(14, weight: .medium)
                                    .foregroundStyle(.red)
                                    .padding(.vertical)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .onTapGesture {
                                        removeFromVault()
                                    }
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
                                removeFromVault()
                            }
                        }
                        
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
        .onAppear {
            initializeFormValues()
        }
        .onChange(of: formViewModel.itemName) { oldValue, newValue in
            triggerRealTimeValidation()
        }
        .onChange(of: formViewModel.storeName) { oldValue, newValue in
            triggerRealTimeValidation()
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
                EditItemSaveButton(isEditFormValid: formViewModel.isFormValid && duplicateError == nil) {
                    if formViewModel.attemptSubmission() {
                        saveChanges()
                    } else {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.warning)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: formViewModel.firstMissingField)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: duplicateError)
    }
    
    private func initializeFormValues() {
        if context == .cart, let cart = cart, let cartItem = cartItem {
            // For cart editing: load cart quantity into portion
            formViewModel.populateFromItem(item, vaultService: vaultService, cart: cart, cartItem: cartItem)
        } else {
            // For vault editing: just load item data (portion will be nil)
            formViewModel.populateFromItem(item, vaultService: vaultService)
        }
    }
    
    private func saveChanges() {
        guard let priceValue = Double(formViewModel.itemPrice),
              let selectedCategory = formViewModel.selectedCategory else { return }

        // Validate for duplicates (excluding current item)
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
        let oldCategoryName = vaultService.vault?.categories.first(where: { $0.items.contains(where: { $0.id == item.id }) })?.name

        // Update the item in the vault
        let success = vaultService.updateItem(
            item: item,
            newName: formViewModel.itemName.trimmingCharacters(in: .whitespacesAndNewlines),
            newCategory: selectedCategory,
            newStore: formViewModel.storeName.trimmingCharacters(in: .whitespacesAndNewlines),
            newPrice: priceValue,
            newUnit: formViewModel.unit
        )

        if success {
            // ✅ Preserve old store
            if !oldStoreName.isEmpty {
                vaultService.ensureStoreExists(oldStoreName)
            }
            // ✅ Ensure new store exists
            vaultService.ensureStoreExists(formViewModel.storeName)

            // --- Update all CartItems referencing this item ---
            if let vault = vaultService.vault {
                for cart in vault.carts {
                    for cartItem in cart.cartItems where cartItem.itemId == item.id {
                        cartItem.plannedPrice = priceValue
                        cartItem.plannedUnit = formViewModel.unit
                        cartItem.plannedStore = formViewModel.storeName
                    }
                }
            }
            
            // --- UPDATE CART ITEM QUANTITY IF IN CART CONTEXT ---
            if context == .cart, let cart = cart, let cartItem = cartItem, let portion = formViewModel.portion {
                // Update the cart item's quantity with the portion value
                if cart.status == .planning {
                    cartItem.quantity = portion
                } else if cart.status == .shopping {
                    cartItem.actualQuantity = portion
                }
                
                // Update cart totals
                vaultService.updateCartTotals(cart: cart)
            }

            // Call save callback
            onSave?(item)
            dismiss()

            // Notify category change if needed
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
        } else {
            duplicateError = "Failed to update item. Please try again."
        }
    }
    
    private func removeFromCart() {
        guard let cart = cart else { return }
        
        // Remove item from cart
        vaultService.removeItemFromCart(cart: cart, itemId: item.id)
        dismiss()
        
        // Show confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func removeFromVault() {
        // Show confirmation alert
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
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }

    
    private func triggerRealTimeValidation() {
        validationTask?.cancel()
        
        let itemName = formViewModel.itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let storeName = formViewModel.storeName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !itemName.isEmpty && !storeName.isEmpty else {
            duplicateError = nil
            return
        }
        
        validationTask = Task {
            // Debounce the validation
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            if !Task.isCancelled {
                let validation = vaultService.validateItemName(itemName, store: storeName, excluding: item.id)
                await MainActor.run {
                    if !validation.isValid {
                        duplicateError = validation.errorMessage
                    } else {
                        duplicateError = nil
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "PHP"
        formatter.maximumFractionDigits = value == Double(Int(value)) ? 0 : 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

