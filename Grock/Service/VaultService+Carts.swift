import Foundation

/// Everything about carts and shopping trips.
///
/// In plain terms:
/// - Create a cart (a “trip”)
/// - Start shopping
/// - Mark what you actually paid
/// - Finish the trip and save results
extension VaultService {
    /// Creates a planning cart and persists it to the vault.
    func createCart(name: String, budget: Double) -> Cart {
        let newCart = Cart(name: name, budget: budget, status: .planning)
        vault?.carts.append(newCart)
        saveContext()
        return newCart
    }

    /// Creates a cart and pre-populates it using `activeItems` (itemId -> quantity).
    func createCartWithActiveItems(name: String, budget: Double, activeItems: [String: Double]) -> Cart {
        let newCart = createCart(name: name, budget: budget)

        for (itemId, quantity) in activeItems {
            if let item = findItemById(itemId) {
                addVaultItemToCart(item: item, cart: newCart, quantity: quantity)
            }
        }

        updateCartTotals(cart: newCart)
        saveContext()

        return newCart
    }

    func deleteCart(_ cart: Cart) {
        guard let vault else { return }
        
        if cart.isCompleted {
            if vault.deletedCarts.contains(where: { $0.id == cart.id }) {
                return
            }
            
            vault.carts.removeAll { $0.id == cart.id }
            cart.isDeleted = true
            cart.deletedAt = Date()
            vault.deletedCarts.append(cart)
            saveContext()
            NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
            print("🗑️ Moved completed cart to Trash: \(cart.name)")
            return
        }
        
        vault.carts.removeAll { $0.id == cart.id }
        modelContext.delete(cart)
        saveContext()
        NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
        CartBackgroundImageManager.shared.deleteImage(forCartId: cart.id)
        UserDefaults.standard.removeObject(forKey: "cartBackgroundColor_\(cart.id)")
        print("🗑️ Deleted cart: \(cart.name)")
    }
}

extension VaultService {
    func restoreDeletedCart(cartId: String) {
        guard let vault else { return }
        guard let index = vault.deletedCarts.firstIndex(where: { $0.id == cartId }) else { return }
        
        let cart = vault.deletedCarts.remove(at: index)
        cart.isDeleted = false
        cart.deletedAt = nil
        if !vault.carts.contains(where: { $0.id == cartId }) {
            vault.carts.append(cart)
        }
        saveContext()
        NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
    }
    
    func permanentlyDeleteCartFromTrash(cartId: String) {
        guard let vault else { return }
        guard let index = vault.deletedCarts.firstIndex(where: { $0.id == cartId }) else { return }
        
        let cart = vault.deletedCarts.remove(at: index)
        modelContext.delete(cart)
        saveContext()
        NotificationCenter.default.post(name: NSNotification.Name("DataUpdated"), object: nil)
        CartBackgroundImageManager.shared.deleteImage(forCartId: cartId)
        UserDefaults.standard.removeObject(forKey: "cartBackgroundColor_\(cartId)")
    }
}

extension VaultService {
    /// Transitions a cart from planning → shopping and snapshots planned data.
    ///
    /// Implications:
    /// - Removes any leftover shopping-only items from prior sessions.
    /// - Saves `originalPlanningQuantity` for vault items to support “changed quantity” reporting.
    func startShopping(cart: Cart) {
        guard cart.status == .planning else { return }

        cleanupShoppingOnlyItems(cart: cart)

        for cartItem in cart.cartItems where !cartItem.isShoppingOnlyItem {
            cartItem.originalPlanningQuantity = cartItem.quantity
            print("💾 Saved original planning quantity: \(cartItem.itemId) = \(cartItem.quantity)")
        }

        for cartItem in cart.cartItems {
            cartItem.capturePlannedData(from: vault!)
        }

        cart.status = .shopping
        cart.startedAt = Date()
        cart.updatedAt = Date()
        updateCartTotals(cart: cart)
        saveContext()
        print("🛒 Started shopping for: \(cart.name)")
    }

    func completeShopping(cart: Cart) {
        guard cart.status == .shopping else { return }

        print("🔄 Completing shopping for cart: \(cart.name)")

        for cartItem in cart.cartItems {
            cartItem.captureActualData()
            if !cartItem.isShoppingOnlyItem {
                if cartItem.vaultItemNameSnapshot == nil {
                    cartItem.vaultItemNameSnapshot = findItemById(cartItem.itemId)?.name
                }
                if cartItem.vaultItemCategorySnapshot == nil {
                    cartItem.vaultItemCategorySnapshot = getCategoryName(for: cartItem.itemId)
                }
            }
            updateVaultWithActualData(cartItem: cartItem)
        }

        cart.status = .completed
        cart.completedAt = Date()
        cart.updatedAt = Date()
        updateCartTotals(cart: cart)
        saveContext()

        print("🎉 Shopping completed! Vault prices updated.")
    }

    /// Writes fulfilled cart item actuals back into the vault price options.
    ///
    /// Important:
    /// - Shopping-only items are intentionally excluded (they are not stored in the vault).
    private func updateVaultWithActualData(cartItem: CartItem) {
        if cartItem.isShoppingOnlyItem {
            print("🛍️ Skipping vault update for shopping-only item: \(cartItem.shoppingOnlyName ?? "Unknown")")
            return
        }

        guard let item = findItemById(cartItem.itemId) else {
            print("❌ Item not found for cartItem: \(cartItem.itemId)")
            return
        }

        guard let actualPrice = cartItem.actualPrice,
              let actualUnit = cartItem.actualUnit,
              let actualStore = cartItem.actualStore else {
            print("⚠️ No actual data to update vault for item: \(item.name)")
            return
        }

        print("💾 Updating vault for item: \(item.name)")
        print("   Store: \(actualStore)")
        print("   Price: \(actualPrice)")
        print("   Unit: \(actualUnit)")

        if let existingPriceOption = item.priceOptions.first(where: { $0.store == actualStore }) {
            existingPriceOption.pricePerUnit = PricePerUnit(
                priceValue: actualPrice,
                unit: actualUnit
            )
            print("   ✅ Updated existing price option")
        } else {
            let newPriceOption = PriceOption(
                store: actualStore,
                pricePerUnit: PricePerUnit(
                    priceValue: actualPrice,
                    unit: actualUnit
                )
            )
            item.priceOptions.append(newPriceOption)
            print("   ✅ Added new price option")
        }

        ensureStoreExists(actualStore)
    }

    /// Reopens a completed cart back into shopping mode by clearing actual fields.
    ///
    /// Implications:
    /// - The cart will behave like an active shopping trip again.
    /// - All items are marked unfulfilled and need to be re-confirmed.
    func reopenCart(cart: Cart) {
        guard cart.status == .completed else { return }

        cart.status = .shopping
        cart.completedAt = nil
        cart.updatedAt = Date()

        for cartItem in cart.cartItems {
            cartItem.actualPrice = nil
            cartItem.actualQuantity = nil
            cartItem.actualUnit = nil
            cartItem.actualStore = nil
            cartItem.isFulfilled = false
        }

        updateCartTotals(cart: cart)
        saveContext()
        print("🔄 Reopened cart: \(cart.name) - Now using current prices")
    }

    func updateCartName(cart: Cart, newName: String) {
        cart.name = newName
        cart.updatedAt = Date()
        saveContext()
    }

    /// Updates a cart budget and recomputes totals.
    func updateCartBudget(cart: Cart, newBudget: Double) {
        cart.budget = newBudget
        cart.updatedAt = Date()
        updateCartTotals(cart: cart)
        saveContext()
    }
}

extension VaultService {
    /// Adds a vault item to a cart (planning or shopping). If already present, increments quantity.
    func addVaultItemToCart(item: Item, cart: Cart, quantity: Double, selectedStore: String? = nil) {
        let store = selectedStore ?? item.priceOptions.first?.store ?? "Unknown Store"
        let priceOption = item.priceOptions.first(where: { $0.store == store })

        if let existingCartItem = cart.cartItems.first(where: {
            !$0.isShoppingOnlyItem && $0.itemId == item.id
        }) {
            existingCartItem.quantity += quantity
            existingCartItem.addedAt = Date()
            print("🔄 Updated existing vault item quantity: \(item.name)")
        } else {
            let categoryName = getCategoryName(for: item.id)
            let cartItem = CartItem(
                itemId: item.id,
                quantity: quantity,
                plannedStore: store,
                plannedPrice: priceOption?.pricePerUnit.priceValue,
                plannedUnit: priceOption?.pricePerUnit.unit,
                actualStore: cart.isShopping ? store : nil,
                actualPrice: cart.isShopping ? priceOption?.pricePerUnit.priceValue : nil,
                actualQuantity: cart.isShopping ? quantity : nil,
                actualUnit: cart.isShopping ? priceOption?.pricePerUnit.unit : nil,
                isShoppingOnlyItem: false,
                shoppingOnlyName: nil,
                shoppingOnlyStore: nil,
                shoppingOnlyPrice: nil,
                shoppingOnlyUnit: nil,
                vaultItemNameSnapshot: item.name,
                vaultItemCategorySnapshot: categoryName,
                originalPlanningQuantity: nil,
                addedDuringShopping: cart.isShopping
            )

            cart.cartItems.append(cartItem)
        }

        updateCartTotals(cart: cart)
        saveContext()
        print("📋 Added Vault item to cart: \(item.name) ×\(quantity)")
    }

    /// Adds a shopping-only item to the cart (not persisted to the vault).
    ///
    /// Implications:
    /// - These items show up in the cart UI and can be fulfilled.
    /// - They are ignored when finishing shopping for “update vault prices”.
    func addShoppingItemToCart(
        name: String,
        store: String,
        price: Double,
        unit: String,
        cart: Cart,
        quantity: Double = 1,
        category: GroceryCategory? = nil
    ) {
        print("🛍️ Adding shopping-only item: \(name)")

        let cartItem = CartItem.createShoppingOnlyItem(
            name: name,
            store: store,
            price: price,
            unit: unit,
            quantity: quantity,
            category: category
        )

        cart.cartItems.append(cartItem)
        updateCartTotals(cart: cart)

        saveContext()

        NotificationCenter.default.post(
            name: NSNotification.Name("ShoppingDataUpdated"),
            object: nil,
            userInfo: ["cartItemId": cart.id]
        )

        print("✅ Added Shopping-only item to cart: \(name) ×\(quantity)")
        print("   Cart now has \(cart.cartItems.count) items")
        print("   Shopping-only items: \(cart.cartItems.filter { $0.isShoppingOnlyItem }.count)")
    }

    /// Removes or skips an item depending on cart status and item type.
    ///
    /// Rules:
    /// - Shopping + shopping-only: remove immediately.
    /// - Shopping + vault item: mark skipped (so it can be restored).
    /// - Planning: remove from cart.
    func removeItemFromCart(cart: Cart, itemId: String) {
        guard let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }) else {
            print("⚠️ Item not found in cart")
            return
        }

        let itemName = findItemById(itemId)?.name ?? "Unknown Item"

        if cart.status == .shopping {
            if cartItem.isShoppingOnlyItem {
                if let index = cart.cartItems.firstIndex(where: { $0.itemId == itemId }) {
                    cart.cartItems.remove(at: index)
                    print("🗑️ Removed shopping-only item \(itemName) during shopping")
                }
            } else {
                cartItem.isSkippedDuringShopping = true
                cartItem.isFulfilled = false
                print("⏸️ Skipped vault item \(itemName) during shopping")
            }
        } else {
            if let index = cart.cartItems.firstIndex(where: { $0.itemId == itemId }) {
                cart.cartItems.remove(at: index)
                print("🗑️ Removed \(itemName) from cart: \(cart.name)")
            }
        }

        updateCartTotals(cart: cart)
        saveContext()
    }

    /// Updates the cart item’s actual fields during shopping and recomputes totals.
    func updateCartItemActualData(
        cart: Cart,
        itemId: String,
        actualPrice: Double? = nil,
        actualQuantity: Double? = nil,
        actualUnit: String? = nil,
        actualStore: String? = nil
    ) {
        guard let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }),
              cart.status == .shopping else { return }

        if let actualPrice = actualPrice {
            cartItem.actualPrice = actualPrice
        }
        if let actualQuantity = actualQuantity {
            cartItem.actualQuantity = actualQuantity
        }
        if let actualUnit = actualUnit {
            cartItem.actualUnit = actualUnit
        }
        if let actualStore = actualStore {
            cartItem.actualStore = actualStore
        }

        updateCartTotals(cart: cart)
        saveContext()
        print("💰 Updated cart item actual data")
    }

    func updateCartItemPrice(
        cart: Cart,
        itemId: String,
        newPrice: Double?,
        newQuantity: Double?,
        newUnit: String? = nil
    ) {
        updateCartItemActualData(
            cart: cart,
            itemId: itemId,
            actualPrice: newPrice,
            actualQuantity: newQuantity,
            actualUnit: newUnit
        )
    }

    func changeCartItemStore(cart: Cart, itemId: String, newStore: String) {
        guard let vault = vault else { return }

        if let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }) {
            switch cart.status {
            case .planning:
                cartItem.plannedStore = newStore
                if let newPrice = cartItem.getCurrentPrice(from: vault, store: newStore) {
                    cartItem.plannedPrice = newPrice
                }
                if let newUnit = cartItem.getCurrentUnit(from: vault, store: newStore) {
                    cartItem.plannedUnit = newUnit
                }

            case .shopping:
                cartItem.actualStore = newStore
                if let newPrice = cartItem.getCurrentPrice(from: vault, store: newStore) {
                    cartItem.actualPrice = newPrice
                }
                if let newUnit = cartItem.getCurrentUnit(from: vault, store: newStore) {
                    cartItem.actualUnit = newUnit
                }

            case .completed:
                return
            }

            updateCartTotals(cart: cart)
            saveContext()
            print("🏪 Updated cart item store to: \(newStore)")
        }
    }

    func toggleItemFulfillment(cart: Cart, itemId: String) {
        guard let cartItem = cart.cartItems.first(where: { $0.itemId == itemId }),
              cart.status == .shopping else { return }

        cartItem.isFulfilled.toggle()
        updateCartTotals(cart: cart)
        saveContext()
        print(cartItem.isFulfilled ? "✅ Fulfilled item" : "❌ Unfulfilled item")

        NotificationCenter.default.post(
            name: NSNotification.Name("CartItemFulfillmentToggled"),
            object: nil,
            userInfo: [
                "cartId": cart.id,
                "itemId": itemId,
                "isFulfilled": cartItem.isFulfilled
            ]
        )

        NotificationCenter.default.post(
            name: NSNotification.Name("ShoppingDataUpdated"),
            object: nil,
            userInfo: [
                "cartItemId": cart.id
            ]
        )
    }
}

extension VaultService {
    /// Recomputes derived cart values (totals and fulfillmentStatus) based on cart status.
    ///
    /// Implications:
    /// - Persists changes via `saveContext()`.
    /// - Ensures planned data is captured for shopping items that are still unfulfilled.
    func updateCartTotals(cart: Cart) {
        guard let vault = vault else { return }

        for cartItem in cart.cartItems {
            if cart.status == .shopping && !cartItem.isFulfilled && cartItem.plannedPrice == nil {
                cartItem.capturePlannedData(from: vault)
            }
        }

        switch cart.status {
        case .planning:
            if cart.budget > 0 {
                cart.fulfillmentStatus = min(cart.totalSpent / cart.budget, 1.0)
            }
        case .shopping:
            let fulfilledCount = cart.cartItems.filter { $0.isFulfilled }.count
            let totalCount = cart.cartItems.count
            cart.fulfillmentStatus = totalCount > 0 ? Double(fulfilledCount) / Double(totalCount) : 0.0
        case .completed:
            cart.fulfillmentStatus = 1.0
        }

        saveContext()
    }

    /// Computes a lightweight “plan vs actual” summary for a cart.
    func getCartInsights(cart: Cart) -> CartInsights {
        guard let vault = vault else { return CartInsights() }

        var insights = CartInsights()

        for cartItem in cart.cartItems {
            let plannedPrice = cartItem.plannedPrice ?? 0.0
            let actualPrice = cartItem.actualPrice ?? plannedPrice
            let plannedQty = cartItem.originalPlanningQuantity ?? cartItem.quantity
            let actualQty = cartItem.actualQuantity ?? cartItem.quantity

            let plannedTotal = plannedPrice * plannedQty
            let actualTotal = actualPrice * actualQty
            let difference = actualTotal - plannedTotal

            insights.plannedTotal += plannedTotal
            insights.actualTotal += actualTotal
            insights.totalDifference += difference

            if difference != 0 {
                insights.priceChanges.append(PriceChange(
                    itemName: cartItem.getItem(from: vault)?.name ?? "Unknown",
                    plannedPrice: plannedPrice,
                    actualPrice: actualPrice,
                    difference: difference
                ))
            }
        }

        return insights
    }

    func getTotalFulfilledAmount(for cart: Cart) -> Double {
        guard let vault = vault else { return 0.0 }
        return cart.cartItems
            .filter { $0.isFulfilled }
            .reduce(0.0) { result, cartItem in
                result + cartItem.getTotalPrice(from: vault, cart: cart)
            }
    }

    func getTotalCartValue(for cart: Cart) -> Double {
        guard let vault = vault else { return 0.0 }
        return cart.cartItems.reduce(0.0) { result, cartItem in
            result + cartItem.getTotalPrice(from: vault, cart: cart)
        }
    }

    func getCurrentFulfillmentPercentage(for cart: Cart) -> Double {
        let totalValue = getTotalCartValue(for: cart)
        guard totalValue > 0 else { return 0 }
        return (getTotalFulfilledAmount(for: cart) / totalValue) * 100
    }
}

extension VaultService {
    /// Removes all shopping-only items from a cart.
    ///
    /// Used as a cleanup step when leaving shopping mode.
    func cleanupShoppingOnlyItems(cart: Cart) {
        let shoppingOnlyItems = cart.cartItems.filter { $0.isShoppingOnlyItem }

        if !shoppingOnlyItems.isEmpty {
            print("🧹 Cleaning up \(shoppingOnlyItems.count) shopping-only items")

            cart.cartItems.removeAll { $0.isShoppingOnlyItem }

            updateCartTotals(cart: cart)
            saveContext()

            print("✅ Removed shopping-only items")
        }
    }

    func cleanupCompletedCart(cart: Cart) {
        guard cart.status == .completed else { return }

        print("🧹 Cleaning up completed cart: \(cart.name)")
    }

    /// Adds a vault item during shopping and marks it as `addedDuringShopping`.
    ///
    /// This flag is used by the UI and finish-trip reporting to distinguish “planned” vs “added during trip”.
    func addVaultItemToCartDuringShopping(
        item: Item,
        store: String,
        price: Double,
        unit: String,
        cart: Cart,
        quantity: Double = 1
    ) {
        print("🛍️ Adding vault item during shopping: \(item.name)")

        if let existingCartItem = cart.cartItems.first(where: {
            !$0.isShoppingOnlyItem && $0.itemId == item.id
        }) {
            existingCartItem.quantity += quantity
            existingCartItem.isSkippedDuringShopping = false
            existingCartItem.addedAt = Date()
            existingCartItem.addedDuringShopping = true
            print("🔄 Updated existing vault item during shopping: \(item.name)")
        } else {
            let cartItem = CartItem(
                itemId: item.id,
                quantity: quantity,
                plannedStore: store,
                plannedPrice: price,
                plannedUnit: unit,
                actualStore: store,
                actualPrice: price,
                actualQuantity: quantity,
                actualUnit: unit,
                isShoppingOnlyItem: false,
                shoppingOnlyName: nil,
                shoppingOnlyStore: nil,
                shoppingOnlyPrice: nil,
                shoppingOnlyUnit: nil,
                originalPlanningQuantity: nil,
                addedDuringShopping: true
            )
            cart.cartItems.append(cartItem)
        }

        updateCartTotals(cart: cart)
        saveContext()
        print("📋 Added Vault item during shopping: \(item.name) ×\(quantity)")
    }

    /// Returns a cart from shopping → planning by removing trip-added items and clearing actual fields.
    ///
    /// Implications:
    /// - Removes both `addedDuringShopping` items and shopping-only items.
    /// - Restores original planning quantities when available.
    func returnToPlanning(cart: Cart) {
        guard cart.status == .shopping else { return }

        print("🔄 Returning cart '\(cart.name)' to planning mode")

        let shoppingAddedItems = cart.cartItems.filter {
            $0.addedDuringShopping || $0.isShoppingOnlyItem
        }

        cart.cartItems.removeAll { cartItem in
            cartItem.addedDuringShopping || cartItem.isShoppingOnlyItem
        }

        print("   Removed \(shoppingAddedItems.count) items added during shopping")

        for cartItem in cart.cartItems {
            cartItem.isFulfilled = false
            cartItem.isSkippedDuringShopping = false
            cartItem.wasEditedDuringShopping = false
            cartItem.addedDuringShopping = false

            cartItem.actualPrice = nil
            cartItem.actualQuantity = nil
            cartItem.actualUnit = nil
            cartItem.actualStore = nil

            if let originalQty = cartItem.originalPlanningQuantity {
                cartItem.quantity = originalQty
                print("   ↳ Restored \(cartItem.itemId) to original quantity: \(originalQty)")
                cartItem.originalPlanningQuantity = nil
            }

            if let vault = vault {
                cartItem.plannedPrice = cartItem.getCurrentPrice(from: vault, store: cartItem.plannedStore)
                cartItem.plannedUnit = cartItem.getCurrentUnit(from: vault, store: cartItem.plannedStore)
            }
        }

        cart.status = .planning
        cart.startedAt = nil
        cart.updatedAt = Date()

        updateCartTotals(cart: cart)
        saveContext()

        print("✅ Cart '\(cart.name)' reset to planning mode")
        print("   Kept \(cart.cartItems.count) planned vault items")
    }
}
