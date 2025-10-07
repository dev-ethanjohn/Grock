//
//  AddItemPopover.swift
//  Grock
//

import SwiftUI

struct AddItemPopover: View {
    @Binding var isPresented: Bool
    var onSave: ((String, GroceryCategory, String, String, Double) -> Void)?
    var onDismiss: (() -> Void)?
    
    @State private var itemName: String = ""
    @State private var storeName: String = ""
    @State private var unit: String = "g"
    @State private var itemPrice: Double?
    @State private var selectedCategory: GroceryCategory?
    
    @FocusState private var itemNameFieldIsFocused: Bool

    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.8
    
    private var selectedCategoryEmoji: String {
        selectedCategory?.emoji ?? "plus.circle.fill"
    }
    
    private var isFormValid: Bool {
        !itemName.isEmpty &&
        itemPrice != nil &&
        !unit.isEmpty &&
        selectedCategory != nil
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.opacity(0.4 * overlayOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPopover()
                }
            
            //MARK: POPOVER container
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
                
                //MARK: FORM
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
                    
                    HStack(spacing: 12) {
                        UnitButton(unit: $unit)
                        PriceInput(itemPrice: $itemPrice)
                    }
                }
                
                Button(action: {
                    if isFormValid,
                       let category = selectedCategory,
                       let priceValue = itemPrice {
                        onSave?(itemName, category, storeName, unit, priceValue)
                        dismissPopover()
                    }
                }) {
                    Text("Done")
                        .font(.fuzzyBold_16)
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(isFormValid ? Color.black : Color.gray.opacity(0.3))
                        )
                }
                .disabled(!isFormValid)
                .padding(.top)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.white)
            .cornerRadius(20)
            .padding(.horizontal, UIScreen.main.bounds.width * 0.038)
            .offset(y: UIScreen.main.bounds.height * 0.15)
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
        itemNameFieldIsFocused = false
        isPresented = false
        onDismiss?()
        
    }
}
