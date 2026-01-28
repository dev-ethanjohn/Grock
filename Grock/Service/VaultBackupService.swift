import Foundation
import SwiftData
import SwiftUI

// MARK: - Backup Models
struct VaultBackup: Codable {
    let timestamp: Date
    let version: Int
    let categories: [BackupCategory]
    let items: [BackupItem]
    let carts: [BackupCart]
    let stores: [BackupStore]
}

struct BackupCategory: Codable {
    let name: String
    let sortOrder: Int
}

struct BackupItem: Codable {
    let id: String
    let name: String
    let priceOptions: [BackupPriceOption]
    let categoryName: String // To link back to category
    let createdAt: Date
}

struct BackupPriceOption: Codable {
    let store: String
    let price: Double
    let unit: String
}

struct BackupStore: Codable {
    let name: String
    let createdAt: Date
}

struct BackupCart: Codable {
    let id: String
    let name: String
    let budget: Double
    let status: Int
    let createdAt: Date
    let updatedAt: Date
    let startedAt: Date?
    let completedAt: Date?
    let items: [BackupCartItem]
}

struct BackupCartItem: Codable {
    let itemId: String
    let quantity: Double
    let isFulfilled: Bool
    let isSkippedDuringShopping: Bool
    let plannedStore: String
    let plannedPrice: Double?
    let plannedUnit: String?
    let actualStore: String?
    let actualPrice: Double?
    let actualQuantity: Double?
    let actualUnit: String?
    
    // Shopping-only properties
    let isShoppingOnlyItem: Bool
    let shoppingOnlyName: String?
    let shoppingOnlyStore: String?
    let shoppingOnlyPrice: Double?
    let shoppingOnlyUnit: String?
    let shoppingOnlyCategory: String?
    
    let originalPlanningQuantity: Double?
    let addedDuringShopping: Bool
    let addedAt: Date?
}

// MARK: - Service
@MainActor
class VaultBackupService {
    private let modelContext: ModelContext
    private let vaultService: VaultService
    
    init(modelContext: ModelContext, vaultService: VaultService) {
        self.modelContext = modelContext
        self.vaultService = vaultService
    }
    
    private var backupURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("grock_vault_backup.json")
    }
    
    func backup(includeCarts: Bool = false) throws {
        guard let vault = vaultService.vault else { return }
        
        // 1. Prepare Data
        let categories = vault.categories.map { 
            BackupCategory(name: $0.name, sortOrder: $0.sortOrder) 
        }
        
        let allItems = vaultService.getAllItems()
        let items = allItems.map { item -> BackupItem in
            let categoryName = vaultService.getCategory(for: item.id)?.name ?? "Unknown"
            return BackupItem(
                id: item.id,
                name: item.name,
                priceOptions: item.priceOptions.map {
                    BackupPriceOption(store: $0.store, price: $0.pricePerUnit.priceValue, unit: $0.pricePerUnit.unit)
                },
                categoryName: categoryName,
                createdAt: item.createdAt
            )
        }
        
        let stores = vault.stores.map {
            BackupStore(name: $0.name, createdAt: $0.createdAt)
        }
        
        let carts: [BackupCart]
        if includeCarts {
            carts = vault.carts.map { cart in
                BackupCart(
                    id: cart.id,
                    name: cart.name,
                    budget: cart.budget,
                    status: cart.status.rawValue,
                    createdAt: cart.createdAt,
                    updatedAt: cart.updatedAt,
                    startedAt: cart.startedAt,
                    completedAt: cart.completedAt,
                    items: cart.cartItems.map { item in
                        BackupCartItem(
                            itemId: item.itemId,
                            quantity: item.quantity,
                            isFulfilled: item.isFulfilled,
                            isSkippedDuringShopping: item.isSkippedDuringShopping,
                            plannedStore: item.plannedStore,
                            plannedPrice: item.plannedPrice,
                            plannedUnit: item.plannedUnit,
                            actualStore: item.actualStore,
                            actualPrice: item.actualPrice,
                            actualQuantity: item.actualQuantity,
                            actualUnit: item.actualUnit,
                            isShoppingOnlyItem: item.isShoppingOnlyItem,
                            shoppingOnlyName: item.shoppingOnlyName,
                            shoppingOnlyStore: item.shoppingOnlyStore,
                            shoppingOnlyPrice: item.shoppingOnlyPrice,
                            shoppingOnlyUnit: item.shoppingOnlyUnit,
                            shoppingOnlyCategory: item.shoppingOnlyCategory,
                            originalPlanningQuantity: item.originalPlanningQuantity,
                            addedDuringShopping: item.addedDuringShopping,
                            addedAt: item.addedAt
                        )
                    }
                )
            }
        } else {
            carts = []
        }
        
        let backup = VaultBackup(
            timestamp: Date(),
            version: 2,
            categories: categories,
            items: items,
            carts: carts,
            stores: stores
        )
        
        // 2. Encode and Save
        let data = try JSONEncoder().encode(backup)
        try data.write(to: backupURL)
        print("✅ Vault backed up to \(backupURL.path)")
    }
    
    func restore(includeCarts: Bool = false) throws {
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            print("⚠️ No backup file found")
            return
        }
        
        let data = try Data(contentsOf: backupURL)
        let backup = try JSONDecoder().decode(VaultBackup.self, from: data)
        
        guard let vault = vaultService.vault else { return }
        
        vaultService.clearCaches()
        
        print("🔄 Starting Vault Merge...")

        restoreWithMerge(backup: backup, vault: vault, includeCarts: includeCarts)
    }
    
    private func restoreWithMerge(backup: VaultBackup, vault: Vault, includeCarts: Bool) {
        // ID Mapping: BackupItemID -> ActiveVaultItemID
        var itemIdMap: [String: String] = [:]
        
        // 1. Merge Stores
        var existingStores = Set(vault.stores.map { $0.name.lowercased() })
        for storeData in backup.stores {
            if !existingStores.contains(storeData.name.lowercased()) {
                let store = Store(name: storeData.name)
                store.createdAt = storeData.createdAt
                vault.stores.append(store)
                existingStores.insert(storeData.name.lowercased())
            }
        }
        
        // 2. Merge Categories
        var categoryMap: [String: Category] = [:]
        for category in vault.categories {
            categoryMap[category.name] = category
        }
        
        for catData in backup.categories {
            if categoryMap[catData.name] == nil {
                let newCategory = Category(name: catData.name)
                newCategory.sortOrder = catData.sortOrder
                vault.categories.append(newCategory)
                categoryMap[catData.name] = newCategory
            }
        }
        
        // 3. Merge Items
        for itemData in backup.items {
            let categoryName = itemData.categoryName
            guard let targetCategory = categoryMap[categoryName] ?? vault.categories.first else { continue }
            
            // Try to find existing item by Name
            if let existingItem = targetCategory.items.first(where: { $0.name.lowercased() == itemData.name.lowercased() }) {
                // MATCH: Map backup ID to existing ID
                itemIdMap[itemData.id] = existingItem.id
                
                // Merge prices
                for priceData in itemData.priceOptions {
                    if !existingItem.priceOptions.contains(where: { $0.store.lowercased() == priceData.store.lowercased() }) {
                        let newPrice = PriceOption(
                            store: priceData.store,
                            pricePerUnit: PricePerUnit(priceValue: priceData.price, unit: priceData.unit)
                        )
                        existingItem.priceOptions.append(newPrice)
                    }
                }
            } else {
                // NO MATCH: Create new item
                // Use original ID if possible, but if it conflicts with a different item (unlikely), generate new?
                // Safest to generate new ID or use backup ID if unique.
                // Let's use backup ID. If it conflicts, SwiftData might throw if @Attribute(.unique) is enforced.
                // Check if ID exists globally?
                // To be safe, let's keep the backup ID. If the user reset, the ID shouldn't exist.
                // But wait, if they have "fresh" data, that fresh data has random IDs. Collision probability is near zero.
                // However, let's stick to the pattern: "Use backup ID" for restored items.
                
                let newItem = Item(
                    id: itemData.id, // Try to preserve ID
                    name: itemData.name,
                    createdAt: itemData.createdAt
                )
                
                for priceData in itemData.priceOptions {
                    let priceOption = PriceOption(
                        store: priceData.store,
                        pricePerUnit: PricePerUnit(priceValue: priceData.price, unit: priceData.unit)
                    )
                    newItem.priceOptions.append(priceOption)
                }
                
                targetCategory.items.append(newItem)
                itemIdMap[itemData.id] = newItem.id
            }
        }
        
        if !includeCarts {
            do {
                try modelContext.save()
                print("✅ Vault merged successfully")
                vaultService.clearCaches()
            } catch {
                print("❌ Merge failed: \(error)")
            }
            return
        }
        
        // 4. Merge Carts
        // Check ALL existing carts in the database to avoid ID collisions
        var backupItemById: [String: BackupItem] = [:]
        for item in backup.items {
            if backupItemById[item.id] == nil {
                backupItemById[item.id] = item
            }
        }
        
        let vaultItems = vault.categories.flatMap { $0.items }
        let vaultItemById = Dictionary(uniqueKeysWithValues: vaultItems.map { ($0.id, $0) })
        let vaultItemIdSet = Set(vaultItems.map(\.id))
        var existingCartsMap: [String: Cart] = [:]
        do {
            let descriptor = FetchDescriptor<Cart>()
            let allCarts = try modelContext.fetch(descriptor)
            for cart in allCarts {
                existingCartsMap[cart.id] = cart
            }
        } catch {
            print("⚠️ Failed to fetch existing carts for duplicate check: \(error)")
            // Fallback to vault carts if fetch fails
            for cart in vault.carts {
                existingCartsMap[cart.id] = cart
            }
        }
        
        for cartData in backup.carts {
            if existingCartsMap[cartData.id] == nil {
                print("   🆕 Restoring cart: \(cartData.name) (ID: \(cartData.id))")
                
                // 1. Create Cart Object
                let cart = Cart(
                    id: cartData.id,
                    name: cartData.name,
                    budget: cartData.budget,
                    fulfillmentStatus: 0.0, // Explicitly init
                    createdAt: cartData.createdAt,
                    startedAt: cartData.startedAt,
                    completedAt: cartData.completedAt,
                    status: CartStatus(rawValue: cartData.status) ?? .planning
                )
                
                // 2. Explicitly set properties (Defensive coding against SwiftData bugs)
                cart.updatedAt = cartData.updatedAt
                cart.name = cartData.name
                cart.budget = cartData.budget
                cart.fulfillmentStatus = 0.0
                
                // 3. Register with Context immediately
                modelContext.insert(cart)
                
                // 4. Reconstruct Items
                for itemData in cartData.items {
                    // Resolve Item ID
                    // If the item was merged/restored, we have it in itemIdMap.
                    // If not found, fallback to original ID.
                    var resolvedItemId = itemIdMap[itemData.itemId] ?? itemData.itemId
                    
                    // CHECK: Does this item ID actually exist in our vault?
                    // If not, we have a broken link (cart item pointing to deleted item).
                    // We must convert it to a "Shopping Only" item to preserve the data.
                    
                    // We can check if resolvedItemId is in our restored items list (itemIdMap values)
                    // or do a quick lookup if we had a set of all item IDs.
                    // For now, let's assume if it wasn't in itemIdMap AND not in backup items, it's likely missing.
                    
                    // Better approach: Check if resolvedItemId exists in the Vault.
                    // Since we just restored items, we can check our itemIdMap.
                    // If itemData.itemId is in itemIdMap keys, we have a valid new ID.
                    // If not, we might be pointing to an existing item that wasn't in backup (unlikely for full backup)
                    // OR it's a deleted item.
                    
                    // Let's create the CartItem. The UI handles "Unknown Item" gracefully, 
                    // but converting to ShoppingOnly is better UX.
                    
                    var isShoppingOnly = itemData.isShoppingOnlyItem
                    var shoppingName = itemData.shoppingOnlyName
                    var shoppingStore = itemData.shoppingOnlyStore
                    var shoppingPrice = itemData.shoppingOnlyPrice
                    var shoppingUnit = itemData.shoppingOnlyUnit
                    
                    if shoppingName == nil {
                        shoppingName = vaultItemById[resolvedItemId]?.name ?? backupItemById[itemData.itemId]?.name
                    }
                    if shoppingStore == nil {
                        shoppingStore = itemData.plannedStore
                    }
                    if shoppingPrice == nil {
                        shoppingPrice = itemData.plannedPrice ?? itemData.actualPrice
                    }
                    if shoppingUnit == nil {
                        shoppingUnit = itemData.plannedUnit ?? itemData.actualUnit
                    }
                    
                    // If we can't resolve the item, convert to Shopping Only
                    // We know it's missing if it's NOT in itemIdMap (meaning not restored) 
                    // AND we can't find it in the vault (we can't easily check vault here without fetching).
                    // BUT, if the backup was complete, any item in a cart *should* be in items list.
                    // If it's not in backup.items, it was deleted.
                    
                    let isItemInBackup = backup.items.contains(where: { $0.id == itemData.itemId })
                    
                    if !isItemInBackup && !isShoppingOnly {
                        print("   ⚠️ Item \(itemData.itemId) missing from backup. Converting to Shopping Item.")
                        isShoppingOnly = true
                        if shoppingName == nil {
                            shoppingName = "Unknown Item (\(itemData.plannedStore))"
                        }
                        resolvedItemId = itemData.itemId
                    } else if !vaultItemIdSet.contains(resolvedItemId) && !isShoppingOnly {
                        isShoppingOnly = true
                        if let backupItem = backupItemById[itemData.itemId] {
                            shoppingName = backupItem.name
                            if shoppingStore == nil { shoppingStore = itemData.plannedStore }
                        } else if shoppingName == nil {
                            shoppingName = "Unknown Item (\(itemData.plannedStore))"
                            shoppingStore = itemData.plannedStore
                        }
                        resolvedItemId = itemData.itemId
                    }

                    let cartItem = CartItem(
                        itemId: resolvedItemId, // USE RESOLVED ID
                        quantity: itemData.quantity,
                        plannedStore: itemData.plannedStore,
                        isFulfilled: itemData.isFulfilled,
                        isSkippedDuringShopping: itemData.isSkippedDuringShopping,
                        plannedPrice: itemData.plannedPrice,
                        plannedUnit: itemData.plannedUnit,
                        actualStore: itemData.actualStore,
                        actualPrice: itemData.actualPrice,
                        actualQuantity: itemData.actualQuantity,
                        actualUnit: itemData.actualUnit,
                        isShoppingOnlyItem: isShoppingOnly,
                        shoppingOnlyName: shoppingName,
                        shoppingOnlyStore: shoppingStore,
                        shoppingOnlyPrice: shoppingPrice,
                        shoppingOnlyUnit: shoppingUnit,
                        shoppingOnlyCategory: itemData.shoppingOnlyCategory,
                        originalPlanningQuantity: itemData.originalPlanningQuantity,
                        addedDuringShopping: itemData.addedDuringShopping
                    )
                    cartItem.addedAt = itemData.addedAt
                    cart.cartItems.append(cartItem)
                }
                
                // 5. Link to Vault
                vault.carts.append(cart)
                print("      ✅ Cart appended to vault")
            } else {
                print("   ⚠️ Cart \(cartData.name) (ID: \(cartData.id)) already exists. Checking if it needs linking...")
                
                // Check if existing cart is linked to current vault
                if let existingCart = existingCartsMap[cartData.id] {
                    // Check if vault already contains this cart instance
                    if !vault.carts.contains(where: { $0.id == existingCart.id }) {
                        print("   🔗 Linking orphan cart to vault: \(existingCart.name)")
                        vault.carts.append(existingCart)
                    } else {
                        print("   ✅ Cart already linked to vault. Skipping.")
                    }
                }
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Vault merged successfully")
            vaultService.clearCaches()
        } catch {
            print("❌ Merge failed: \(error)")
        }
    }
}
