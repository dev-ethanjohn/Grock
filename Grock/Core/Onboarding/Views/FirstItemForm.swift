//
//  FirstItemForm.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/6/25.
//

import SwiftUI

struct FirstItemForm: View {
    //TODO: reaarange
    let questionText: String
    @Bindable var viewModel: OnboardingViewModel
    var itemNameFieldIsFocused: FocusState<Bool>.Binding
    @Binding var selectedCategory: GroceryCategory?
    let selectedCategoryEmoji: String
    @Binding var showUnitPicker: Bool
    let calculatedTotal: Double
    @Binding var showCategoryTooltip: Bool
    
    var body: some View {
        VStack {
            Spacer()
                .frame(height: 20)
            
            QuestionTitle(text: questionText)
            
            Spacer()
                .frame(height: 40)
            
            ItemNameInput(
                selectedCategoryEmoji:selectedCategoryEmoji,
                showTooltip: showCategoryTooltip,
                itemNameFieldIsFocused:  itemNameFieldIsFocused,
                itemName:  $viewModel.itemName ,
                selectedCategory: $selectedCategory
            )
            
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 1)
                .foregroundColor(Color(hex: "ddd"))
                .padding(.vertical, 2)
                .padding(.horizontal)
            
            StoreNameComponent(storeName: $viewModel.storeName)
            
            PortionAndUnitInput(
                portion: $viewModel.portion,
                unit: $viewModel.unit,
                showUnitPicker: $showUnitPicker
            )
            
            PricePerUnitField(price: $viewModel.itemPrice)
            
            Spacer()
                .frame(height: 80)
        }
        .padding()
    }
}

//#Preview {
//    FirstItemForm()
//}
