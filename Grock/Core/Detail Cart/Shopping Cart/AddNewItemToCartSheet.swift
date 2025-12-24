import SwiftUI

struct AddNewItemToCartSheet: View {
    @Binding var isPresented: Bool
    let cart: Cart
    var onItemAdded: (() -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    
    @State private var currentPage: AddItemPage = .addNew
    @State private var formViewModel = ItemFormViewModel(requiresPortion: false, requiresStore: true)
    @FocusState private var itemNameFieldIsFocused: Bool
    
    @State private var selectedCategory: GroceryCategory?
    @State private var showAddItemPopoverInVault = false
    
    enum AddItemPage {
        case addNew
        case browseVault
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if currentPage == .addNew {
                    AddNewItemView(
                        cart: cart,
                        formViewModel: $formViewModel,
                        itemNameFieldIsFocused: $itemNameFieldIsFocused,
                        onAddToCart: {
                            // FIXED: Handle add to cart and dismiss
                            handleAddToCart()
                        },
                        onBrowseVault: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage = .browseVault
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
                } else {
                    BrowseVaultView(
                        cart: cart,
                        selectedCategory: $selectedCategory,
                        onItemSelected: { item in
                            // FIXED: Handle vault item selection
                            handleVaultItemSelection(item)
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage = .addNew
                            }
                        },
                        onAddNewItem: {
                            showAddItemPopoverInVault = true
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
            .navigationTitle(currentPage == .addNew ? "Add Item" : "Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetAndClose()
                    }
                }
                
                if currentPage == .browseVault {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(currentPage == .addNew ? Color.black : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                            
                            Circle()
                                .fill(currentPage == .browseVault ? Color.black : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .presentationDetents(currentPage == .addNew ? [.height(500)] : [.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .sheet(isPresented: $showAddItemPopoverInVault) {
            AddItemPopover(
                isPresented: $showAddItemPopoverInVault,
                createCartButtonVisible: .constant(false),
                onSave: { itemName, category, store, unit, price in
                    // FIXED: Handle save from popover and dismiss
                    if cart.isShopping {
                        vaultService.addShoppingItemToCart(
                            name: itemName,
                            store: store,
                            price: price,
                            unit: unit,
                            cart: cart,
                            quantity: 1
                        )
                        // IMPORTANT: Call onItemAdded and dismiss
                        onItemAdded?()
                        resetAndClose()
                    } else {
                        let success = addNewItemToVaultAndCart(
                            name: itemName,
                            category: category,
                            store: store,
                            unit: unit,
                            price: price
                        )
                        
                        if success {
                            // IMPORTANT: Call onItemAdded and dismiss
                            onItemAdded?()
                            showAddItemPopoverInVault = false
                            resetAndClose()
                        }
                    }
                }
            )
        }
    }
    
    private func handleAddToCart() {
        guard formViewModel.attemptSubmission(),
              let category = formViewModel.selectedCategory,
              let priceValue = Double(formViewModel.itemPrice) else {
            return
        }
        
        if cart.isShopping {
            // Shopping mode: Add shopping-only item
            vaultService.addShoppingItemToCart(
                name: formViewModel.itemName,
                store: formViewModel.storeName,
                price: priceValue,
                unit: formViewModel.unit,
                cart: cart,
                quantity: 1
            )
            print("🛍️ Added shopping-only item: \(formViewModel.itemName)")
            
            // FIXED: Force immediate update
            vaultService.updateCartTotals(cart: cart)
            
            // Send notification for shopping data update
            NotificationCenter.default.post(
                name: NSNotification.Name("ShoppingDataUpdated"),
                object: nil,
                userInfo: ["cartItemId": cart.id] // Use cart ID instead of item ID
            )
            
        } else {
            // Planning mode: Add to vault first
            let success = addNewItemToVaultAndCart(
                name: formViewModel.itemName,
                category: category,
                store: formViewModel.storeName,
                unit: formViewModel.unit,
                price: priceValue
            )
            
            if success {
                print("📋 Added vault item: \(formViewModel.itemName)")
            }
        }
        
        // IMPORTANT: Call the callback AND dismiss
        onItemAdded?()
        resetAndClose()
    }
    
    private func handleVaultItemSelection(_ item: Item) {
        guard let priceOption = item.priceOptions.first else { return }
        
        if cart.isShopping {
            // Shopping mode: Use shopping item method
            vaultService.addShoppingItemToCart(
                name: item.name,
                store: priceOption.store,
                price: priceOption.pricePerUnit.priceValue,
                unit: priceOption.pricePerUnit.unit,
                cart: cart,
                quantity: 1
            )
            print("🛍️ Selected vault item for shopping: \(item.name)")
        } else {
            // Planning mode: Use vault item method
            vaultService.addVaultItemToCart(
                item: item,
                cart: cart,
                quantity: 1,
                selectedStore: priceOption.store
            )
            print("📋 Selected vault item for planning: \(item.name)")
        }
        
        // IMPORTANT: Call the callback AND dismiss
        onItemAdded?()
        resetAndClose()
    }
    
    private func addNewItemToVaultAndCart(name: String, category: GroceryCategory, store: String, unit: String, price: Double) -> Bool {
        // Create item in vault
        let success = vaultService.addItem(
            name: name,
            to: category,
            store: store,
            price: price,
            unit: unit
        )
        
        if success {
            // Find the newly created item
            let newItems = vaultService.findItemsByName(name)
            if let newItem = newItems.first(where: { item in
                item.priceOptions.contains { $0.store == store }
            }) {
                // Add to cart using vault item
                vaultService.addVaultItemToCart(
                    item: newItem,
                    cart: cart,
                    quantity: 1,
                    selectedStore: store
                )
                return true
            }
        }
        return false
    }
    
    private func resetAndClose() {
        formViewModel.resetForm()
        currentPage = .addNew
        isPresented = false // FIXED: This dismisses the sheet
    }
}

// MARK: - Add New Item View (Page 1)
struct AddNewItemView: View {
    let cart: Cart
    @Binding var formViewModel: ItemFormViewModel
    @FocusState.Binding var itemNameFieldIsFocused: Bool
    let onAddToCart: () -> Void
    let onBrowseVault: () -> Void
    
    @State private var duplicateError: String?
    @State private var isCheckingDuplicate = false
    
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        VStack(spacing: 0) {
            // Context header
            VStack(alignment: .leading, spacing: 8) {
                Text(cart.isShopping ? "🛍️ Add to Shopping Trip" : "📋 Add to Plan")
                    .lexendFont(18, weight: .bold)
                    .foregroundColor(cart.isShopping ? .orange : .blue)
                
                Text(cart.isShopping ?
                     "This item will only exist in this shopping trip." :
                     "This item will be saved to your Vault for future use.")
                    .lexendFont(12)
                    .foregroundColor(.gray)
                    .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.top)
            
            // Main form content
            ScrollView {
                VStack(spacing: 20) {
                    ItemFormContent(
                        formViewModel: formViewModel,
                        itemNameFieldIsFocused: _itemNameFieldIsFocused,
                        showCategoryTooltip: false,
                        duplicateError: duplicateError,
                        isCheckingDuplicate: isCheckingDuplicate,
                        onStoreChange: {
                            performRealTimeDuplicateCheck(formViewModel.itemName)
                        }
                    )
                    .padding(.top)
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            
            // Action bar at bottom
            VStack(spacing: 16) {
                // Add to Cart button - FIXED: Added explicit action
                Button(action: {
                    if formViewModel.isFormValid && duplicateError == nil {
                        onAddToCart()
                    }
                }) {
                    Text("Add to Cart")
                        .lexendFont(16, weight: .bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(formViewModel.isFormValid && duplicateError == nil ? Color.black : Color.gray)
                        )
                }
                .disabled(!formViewModel.isFormValid || duplicateError != nil)
                .padding(.horizontal)
                
                // Browse Vault option
                Button(action: onBrowseVault) {
                    HStack {
                        Image(systemName: "archivebox")
                            .font(.system(size: 14))
                        Text("Browse Vault")
                            .lexendFont(14, weight: .medium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.5),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                itemNameFieldIsFocused = true
            }
        }
        .onChange(of: formViewModel.itemName) { oldValue, newValue in
            performRealTimeDuplicateCheck(newValue)
        }
        .onChange(of: formViewModel.storeName) { oldValue, newValue in
            performRealTimeDuplicateCheck(formViewModel.itemName)
        }
    }
    
    private func performRealTimeDuplicateCheck(_ itemName: String) {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let storeName = formViewModel.storeName
        
        guard !trimmedName.isEmpty else {
            duplicateError = nil
            isCheckingDuplicate = false
            return
        }
        
        let validation = vaultService.validateItemName(trimmedName, store: storeName)
        if validation.isValid {
            duplicateError = nil
        } else {
            duplicateError = validation.errorMessage
        }
    }
}

// MARK: - Browse Vault View (Page 2)
struct BrowseVaultView: View {
    let cart: Cart
    @Binding var selectedCategory: GroceryCategory?
    let onItemSelected: (Item) -> Void
    let onBack: () -> Void
    let onAddNewItem: () -> Void
    
    @Environment(VaultService.self) private var vaultService
    @State private var searchText = ""
    
    private var firstCategoryWithItems: GroceryCategory? {
        guard let vault = vaultService.vault else { return nil }
        
        for groceryCategory in GroceryCategory.allCases {
            if let vaultCategory = vault.categories.first(where: { $0.name == groceryCategory.title }),
               !vaultCategory.items.isEmpty {
                return groceryCategory
            }
        }
        return nil
    }
    
    private var filteredItems: [Item] {
        guard let vault = vaultService.vault,
              let category = selectedCategory ?? firstCategoryWithItems,
              let vaultCategory = vault.categories.first(where: { $0.name == category.title })
        else { return [] }
        
        if searchText.isEmpty {
            return vaultCategory.items.sorted { $0.createdAt > $1.createdAt }
        } else {
            return vaultCategory.items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.createdAt > $1.createdAt }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search vault", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top)
            
            // Category Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GroceryCategory.allCases, id: \.self) { category in
                        let hasItems = hasItems(in: category)
                        let itemCount = getItemCount(for: category)
                        
                        CategoryChip(
                            category: category,
                            isSelected: selectedCategory == category,
                            hasItems: hasItems,
                            itemCount: itemCount,
                            action: {
                                selectedCategory = category
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            
            // Items List
            if filteredItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text(searchText.isEmpty ? "No items in this category" : "No items found")
                        .foregroundColor(.gray)
                    
                    if searchText.isEmpty {
                        Button(action: onAddNewItem) {
                            Label("Add New Item", systemImage: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                List(filteredItems) { item in
                    CartVaultItemRow(
                        item: item,
                        action: {
                            onItemSelected(item)
                        }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            
            // Add New Item Button at bottom
            Button(action: onAddNewItem) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add New Item to Vault")
                        .lexendFont(14, weight: .medium)
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
        }
        .onAppear {
            if selectedCategory == nil {
                selectedCategory = firstCategoryWithItems ?? GroceryCategory.allCases.first
            }
        }
    }
    
    private func hasItems(in category: GroceryCategory) -> Bool {
        guard let vault = vaultService.vault else { return false }
        return vault.categories.first(where: { $0.name == category.title })?.items.isEmpty == false
    }
    
    private func getItemCount(for category: GroceryCategory) -> Int {
        guard let vault = vaultService.vault else { return 0 }
        return vault.categories.first(where: { $0.name == category.title })?.items.count ?? 0
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let category: GroceryCategory
    let isSelected: Bool
    let hasItems: Bool
    let itemCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(category.emoji)
                    .font(.system(size: 20))
                Text(category.title)
                    .lexendFont(10, weight: .medium)
                    .lineLimit(1)
            }
            .frame(width: 60, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.black : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.black : Color.clear, lineWidth: 2)
            )
            .foregroundColor(isSelected ? .white : .black)
            .overlay(alignment: .topTrailing) {
                if hasItems && itemCount > 0 && !isSelected {
                    Text("\(itemCount)")
                        .lexendFont(9, weight: .bold)
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .offset(x: 4, y: -4)
                }
            }
        }
    }
}

struct CartVaultItemRow: View {
    let item: Item
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .lexendFont(15, weight: .medium)
                        .foregroundColor(.black)
                    
                    HStack(spacing: 8) {
                        if let priceOption = item.priceOptions.first {
                            Text("$\(priceOption.pricePerUnit.priceValue, specifier: "%.2f")")
                                .lexendFont(13)
                                .foregroundColor(.gray)
                            
                            Text("•")
                                .lexendFont(13)
                                .foregroundColor(.gray)
                            
                            Text(priceOption.store)
                                .lexendFont(13)
                                .foregroundColor(.gray)
                            
                            Text("•")
                                .lexendFont(13)
                                .foregroundColor(.gray)
                            
                            Text(priceOption.pricePerUnit.unit)
                                .lexendFont(13)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
