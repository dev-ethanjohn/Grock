//
//  VaultCategoryIcon.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/2/25.
//

import SwiftUI

struct VaultCategoryIcon: View {
    let category: GroceryCategory
    let isSelected: Bool
    let itemCount: Int
    let hasItems: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(category.pastelColor.darker(by: 0.1))
                        .frame(width: 42, height: 42)
                    
                    Text(category.emoji)
                        .font(.system(size: 24))
                        .frame(width: 42, height: 42)

                    if itemCount > 0 {
                        Text("\(itemCount)")
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .font(.caption2)
                            .fontWeight(.black)
                            .foregroundColor(.black)
                            .offset(x: 2, y: -2)
                            .background(.white)
                            .clipShape(Capsule())
                    }
                }

                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            isSelected ? Color.black : Color.clear,
                            lineWidth: 2
                        )
                )
            }
        }
    }
}

#Preview {
    HStack(spacing: 4) {
        VaultCategoryIcon(
            category: .meatsSeafood,
            isSelected: true,
            itemCount: 5,
            hasItems: true,
            action: {}
        )
        
        VaultCategoryIcon(
            category: .freshProduce,
            isSelected: false,
            itemCount: 0,
            hasItems: false,
            action: {}
        )
        
        VaultCategoryIcon(
            category: .frozen,
            isSelected: false,
            itemCount: 3,
            hasItems: true,
            action: {}
        )
    }
    .padding()
}

#Preview {
    HStack(spacing: 20) {
        VaultCategoryIcon(
            category: .meatsSeafood,
            isSelected: true,
            itemCount: 52,
            hasItems: true,
            action: {}
        )
        
        VaultCategoryIcon(
            category: .freshProduce,
            isSelected: false,
            itemCount: 0,
            hasItems: false,
            action: {}
        )
        
        VaultCategoryIcon(
            category: .frozen,
            isSelected: false,
            itemCount: 3,
            hasItems: true,
            action: {}
        )
    }
    .padding()
}
