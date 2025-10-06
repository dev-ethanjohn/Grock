//
//  StoreFilterButton.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/5/25.
//

import SwiftUI

struct StoreFilterButton: View {
    let storeName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(storeName)
                .foregroundColor(isSelected ? .black : .gray)
        }
    }
}

//#Preview {
//    StoreFilterButton()
//}
