//
//  ItemNameInput.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/17/25.
//

import SwiftUI

struct ItemNameInput: View {
    
    let selectedCategoryEmoji: String
    let showTooltip: Bool
    
    var itemNameFieldIsFocused: FocusState<Bool>.Binding
    
    @Binding var itemName: String
    @Binding var selectedCategory: GroceryCategory?
    
    @State private var fillAnimation: CGFloat = 0.0
    @State private var fieldScale: CGFloat = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .trailing) {
                
                // as a var view / viewbuilder
                if showTooltip && selectedCategory == nil {
                    CategoryTooltipPopover()
                        .offset(x: -10, y: -32)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .offset(y: -10)),
                            removal: .scale(scale: 0.9).combined(with: .opacity).combined(with: .offset(y: -5))
                        ))
                        .zIndex(1)
                }
                
                // as a var view / viewbuilder
                HStack {
                    TextField("e.g. canned tuna", text: $itemName)
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
                            CategoryCircularButton(
                                selectedCategory: $selectedCategory,
                                selectedCategoryEmoji: selectedCategoryEmoji
                            )
                        )
                }
            }
            
            // as a var view / viewbuilder
            if let category = selectedCategory {
                Text(category.title)
                    .font(.caption2)
                    .foregroundColor(category.pastelColor.darker(by: 0.3))
                    .padding(.horizontal, 16)
                    .transition(.scale.combined(with: .opacity))
                    .id(category.id)
            }
        }
        .padding(.bottom, 8)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedCategory)
        .onChange(of: selectedCategory) { oldValue, newValue in
            if newValue != nil {
                if oldValue == nil {
                    withAnimation(.spring(duration: 0.5)) {
                        fillAnimation = 1.0
                    }
                    startFieldBounce()
                } else {
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
                withAnimation(.easeInOut(duration: 0.4)) {
                    fillAnimation = 0.0
                    fieldScale = 1.0
                }
            }
            
        }
    }
    
    //sub Views
    
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
