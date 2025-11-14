//
//  CartTabsModel.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/14/25.
//

import Foundation

struct CartTabsModel: Identifiable {
    private(set) var id: Tab
    var size: CGSize = .zero
    var minX: CGFloat = .zero
    
    enum Tab: String, CaseIterable {
        case active = "Active"
        case completed = "Completed"
        case statistics = "Statistics"
    }
}
