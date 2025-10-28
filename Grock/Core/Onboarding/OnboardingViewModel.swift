//
//  OnboardingViewModel.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
class OnboardingViewModel {
    //form data
    var storeName: String = ""
    var itemName: String = ""
    var itemPrice: String = "" // Changed from Double? to String
    var unit: String = "g"
    var categoryName: String = ""
    var portion: Double?
    
    func saveInitialData(vaultService: VaultService) {
        guard let category = GroceryCategory.allCases.first(where: { $0.title == categoryName }),
              let price = Double(itemPrice) else { return } // Convert String to Double
        
        vaultService.addItem(
            name: itemName,
            to: category,
            store: storeName,
            price: price,
            unit: unit
        )
    }
    
    
}
