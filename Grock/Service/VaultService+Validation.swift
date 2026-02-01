import Foundation

/// VaultService validation rules for user-entered names.
///
/// Goals:
/// - Keep rules consistent across all entry points (vault, cart sheets, popovers).
/// - Keep “duplicate checking” in one place so behavior is always the same.
extension VaultService {
    /// Returns true if another item exists with the same (name + store), case-insensitive.
    ///
    /// Parameters:
    /// - excluding: When editing an existing item, pass its id to avoid self-collision.
    func isItemNameDuplicate(_ name: String, store: String, excluding itemId: String? = nil) -> Bool {
        guard let vault = vault else { return false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedStore = store.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        for category in vault.categories {
            for item in category.items {
                if let excludedId = itemId, item.id == excludedId {
                    continue
                }

                let existingName = item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                let hasSameStore = item.priceOptions.contains { priceOption in
                    priceOption.store.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedStore
                }

                if existingName == trimmedName && hasSameStore {
                    return true
                }
            }
        }

        return false
    }

    /// Validates the item name for creation/edit flows.
    ///
    /// Current rules:
    /// - Name must be non-empty.
    /// - (Name + Store) must be unique in the vault.
    func validateItemName(_ name: String, store: String, excluding itemId: String? = nil) -> (isValid: Bool, errorMessage: String?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return (false, "Item name cannot be empty")
        }

        if isItemNameDuplicate(trimmedName, store: store, excluding: itemId) {
            return (false, "An item with name '\(trimmedName)' already exists at \(store)")
        }

        return (true, nil)
    }
}

extension VaultService {
    /// Returns true if another cart exists with the same name, case-insensitive.
    func isCartNameDuplicate(_ name: String, excluding cartId: String? = nil) -> Bool {
        guard let vault = vault else { return false }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        for cart in vault.carts {
            if let excludedId = cartId, cart.id == excludedId {
                continue
            }

            let existingName = cart.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            if existingName == trimmedName {
                return true
            }
        }

        return false
    }

    /// Validates the cart name for creation/edit flows.
    func validateCartName(_ name: String, excluding cartId: String? = nil) -> (isValid: Bool, errorMessage: String?) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedName.isEmpty {
            return (false, "Cart name cannot be empty")
        }

        if isCartNameDuplicate(trimmedName, excluding: cartId) {
            return (false, "A cart with this name already exists")
        }

        return (true, nil)
    }
}
