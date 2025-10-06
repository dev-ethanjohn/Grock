//
//  OnboardingViewModel.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import Foundation
import SwiftData
import Observation

@Observable
class OnboardingViewModel {
    // Screen 2
    var storeName: String = ""

    // Screen 3 (item)
    var itemName: String = ""
    var itemPrice: Double?
    var unit: String = ""
    var categoryName: String = ""
    var portion: Double?

    func saveInitialData(context: ModelContext) {
        // Check if vault exists, if not create one
        let vault: Vault
        if let existingVault = try? context.fetch(FetchDescriptor<Vault>()).first {
            vault = existingVault
        } else {
            vault = Vault()
            context.insert(vault)
        }

        // Create price per unit
        let pricePerUnit = PricePerUnit(
            priceValue: itemPrice ?? 0,
            unit: unit.isEmpty ? "unit" : unit
        )

        // Create price option
        let priceOption = PriceOption(
            store: storeName,
            pricePerUnit: pricePerUnit
        )

        // Create the item
        let item = Item(name: itemName)
        item.priceOptions = [priceOption]

        // Put the item into chosen category
        if let category = vault.categories.first(where: { $0.name == categoryName }) {
            category.items.append(item)
        } else {
            // Create the category if it doesn't exist
            let newCategory = Category(name: categoryName)
            newCategory.items.append(item)
            vault.categories.append(newCategory)
        }

        try? context.save()
    }
}
