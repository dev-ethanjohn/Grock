//
//  Store.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import Foundation
import SwiftData

@Model
class Store {
    @Attribute(.unique) var id: UUID
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \GroceryItem.store) var items: [GroceryItem] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
