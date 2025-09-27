//
//  Item.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/27/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
