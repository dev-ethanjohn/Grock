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

    // Save onboarding data into SwiftData
    func saveInitialData(context: ModelContext) {
        // Ensure Vault exists with default categories
        let vault = ensureVault(context: context)

        // Create store
        let store = Store(name: storeName)
        context.insert(store)

        // Create price per unit
        let pricePerUnit = PricePerUnit(
            priceValue: itemPrice ?? 0,
            unit: unit.isEmpty ? "unit" : unit
        )

        // Create price option
        let priceOption = PriceOption(
            store: store.name,
            pricePerUnit: pricePerUnit
        )

        // Create the item
        let item = Item(name: itemName)
        item.priceOptions = [priceOption]

        // Put the item into chosen category
        if let category = vault.categories.first(where: { $0.name == categoryName }) {
            category.items.append(item)
        } else {
            vault.categories.first?.items.append(item)
        }

        try? context.save()
    }
}
