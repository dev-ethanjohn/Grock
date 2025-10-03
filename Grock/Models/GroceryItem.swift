//
//  GroceryItem.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import Foundation
import SwiftData

@Model
class GroceryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var price: Double
    var dateAdded: Date

    @Relationship var store: Store?

    init(name: String, price: Double, store: Store?) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.dateAdded = .now
        self.store = store
    }
}
