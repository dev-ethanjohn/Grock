//
//  Grocery+Enums.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/17/25.
//

import Foundation



enum EditContext {
    case vault
    case cart
}

enum FilterOption: String, CaseIterable {
    case all = "All"
    case fulfilled = "Fulfilled"
    case unfulfilled = "Unfulfilled"
}
