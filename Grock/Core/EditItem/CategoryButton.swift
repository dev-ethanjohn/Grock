//
//  CategoryButton.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/17/25.
//

import SwiftUI

struct CategoryButton: View {
    @Binding var selectedCategory: GroceryCategory?
    let selectedCategoryEmoji: String
    
    var body: some View {
        HStack {
            Spacer()
            Menu {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(GroceryCategory.allCases) { category in
                        Text("\(category.title) \(category.emoji)")
                            .tag(category as GroceryCategory?)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                ZStack {
                    Circle()
                        .fill(selectedCategory == nil
                              ? Color.gray.opacity(0.2)
                              : selectedCategory!.pastelColor)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedCategory == nil
                                    ? Color.gray
                                    : selectedCategory!.pastelColor.darker(by: 0.2),
                                    lineWidth: 1.5
                                )
                        )
                    
                    if selectedCategory == nil {
                        Image(systemName: "plus")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    } else {
                        Text(selectedCategoryEmoji)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.trailing, 8)
        }
    }
}

