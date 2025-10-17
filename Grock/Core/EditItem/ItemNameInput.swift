//
//  ItemNameInput.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/17/25.
//

import SwiftUI

struct ItemNameInput: View {
    @Binding var itemName: String
    var itemNameFieldIsFocused: FocusState<Bool>.Binding
    @Binding var selectedCategory: GroceryCategory?
    let selectedCategoryEmoji: String
    
    @State private var fillAnimation: CGFloat = 0.0
    @State private var fieldScale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("e.g. Tapa", text: $itemName)
                    .font(.subheadline)
                    .bold()
                    .padding(12)
                    .padding(.trailing, 44)
                    .background(
                        Group {
                            if selectedCategory == nil {
                                Color(.systemGray6)
                                    .brightness(0.03)
                            } else {
                                RadialGradient(
                                    colors: [
                                        selectedCategory!.pastelColor.opacity(0.4),
                                        selectedCategory!.pastelColor.opacity(0.35)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: fillAnimation * 100
                                )
                            }
                        }
                            .brightness(-0.03)
                    )
                    .cornerRadius(40)
                    .focused(itemNameFieldIsFocused)
                    .scaleEffect(fieldScale)
                    .overlay(
                        CategoryButton(
                            selectedCategory: $selectedCategory,
                            selectedCategoryEmoji: selectedCategoryEmoji
                        )
                    )
            }
            
            if let category = selectedCategory {
                Text(category.title)
                    .font(.caption2)
                    .foregroundColor(category.pastelColor.darker(by: 0.3))
                    .padding(.horizontal, 16)
                    .transition(.scale.combined(with: .opacity))
                    .id(category.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedCategory)
        .onChange(of: selectedCategory) { oldValue, newValue in
            if newValue != nil {
                if oldValue == nil {
                    // Just selected a category for the first time
                    withAnimation(.spring(duration: 0.5)) {
                        fillAnimation = 1.0
                    }
                    startFieldBounce()
                } else {
                    // Changed from one category to another - reset and refill
                    withAnimation(.spring(duration: 0.5)) {
                        fillAnimation = 0.0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(duration: 0.5)) {
                            fillAnimation = 1.0
                        }
                        startFieldBounce()
                    }
                }
            } else {
                // Deselected category
                withAnimation(.easeInOut(duration: 0.4)) {
                    fillAnimation = 0.0
                    fieldScale = 1.0
                }
            }
        }
    }
    
    private func startFieldBounce() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            fieldScale = 0.985
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                fieldScale = 1.015
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                fieldScale = 1.0
            }
        }
    }
}

