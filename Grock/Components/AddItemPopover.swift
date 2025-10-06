//
//  AddItemPopover.swift
//  Grock
//

import SwiftUI

struct AddItemPopover: View {
    @Binding var isPresented: Bool
    var onSave: ((String, GroceryCategory, String, Double, String, Double) -> Void)?
    var onDismiss: (() -> Void)?
    
    @State private var itemName: String = ""
    @State private var storeName: String = ""
    @State private var portion: Double?
    @State private var unit: String = "g"
    @State private var itemPrice: Double?
    @State private var selectedCategory: GroceryCategory?
    
    @FocusState private var itemNameFieldIsFocused: Bool
    
    // Animation states
    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.8
    
    private var calculatedTotal: Double {
        let portionValue = portion ?? 0
        let priceValue = itemPrice ?? 0
        return portionValue * priceValue
    }
    
    private var selectedCategoryEmoji: String {
        selectedCategory?.emoji ?? "plus.circle.fill"
    }
    
    private var isFormValid: Bool {
        !itemName.isEmpty &&
        itemPrice != nil &&
        portion != nil &&
        !unit.isEmpty &&
        selectedCategory != nil
    }
    
    var body: some View {
        ZStack {
            // Darkened background overlay - only opacity animation
            Color.black.opacity(0.4 * overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopover()
                }
            
            // Popover content - only scale animation
            VStack(spacing: 8) {
                HStack {
                    Text("Add new item to vault")
                        .font(.fuzzyBold_13)
                    
                    Spacer()
                    
                    Button(action: {
                        dismissPopover()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom)
                       
                // Form content
                VStack(spacing: 12) {
                    ItemNameInput(
                        itemName: $itemName,
                        itemNameFieldIsFocused: $itemNameFieldIsFocused,
                        selectedCategory: $selectedCategory,
                        selectedCategoryEmoji: selectedCategoryEmoji
                    )
                    
                    DashedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                        .frame(height: 1)
                        .foregroundColor(Color(hex: "ddd"))
                        .padding(.vertical, 2)
                        .padding(.horizontal)
                    
                    StoreNameDisplayForVault(storeName: $storeName)
                    
                    PortionAndUnitInput(
                        portion: $portion,
                        unit: $unit,
                        showUnitPicker: .constant(false)
                    )
                    
                    PriceInput(itemPrice: $itemPrice)
                }
                
                // Footer with total and done button
                HStack {
                    TotalDisplay(calculatedTotal: calculatedTotal)
                    
                    Spacer()
                    
                    Button(action: {
                        if isFormValid,
                           let category = selectedCategory,
                           let portionValue = portion,
                           let priceValue = itemPrice {
                            onSave?(itemName, category, storeName, portionValue, unit, priceValue)
                            dismissPopover()
                        }
                    }) {
                        Text("Done")
                            .font(.fuzzyBold_16)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .background(
                                Capsule()
                                    .fill(isFormValid ? Color.black : Color.gray.opacity(0.3))
                            )
                    }
                    .disabled(!isFormValid)
                }
                .padding(.top)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, UIScreen.main.bounds.width * 0.04)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .offset(y: 32)
            .scaleEffect(contentScale)
        }
        .onAppear {
            itemNameFieldIsFocused = true
            withAnimation(.easeOut(duration: 0.2)) {
                overlayOpacity = 1
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                contentScale = 1
            }
        }
    }
    
    private func dismissPopover() {
        withAnimation(.easeIn(duration: 0.1)) {
            overlayOpacity = 0
        }
        withAnimation(.easeIn(duration: 0.1)) {
            contentScale = 0.8
        }
        
            isPresented = false
            onDismiss?()
    }
}
