//
//  FirstItemForm.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/6/25.
//

import SwiftUI

struct FirstItemForm: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var itemNameFieldIsFocused: Bool
    
    var body: some View {
        VStack {
            Spacer().frame(height: 20)
            
            QuestionTitle(text: viewModel.questionText)
            
            Spacer().frame(height: 40)
            
            ItemNameInput(
                selectedCategoryEmoji: viewModel.selectedCategoryEmoji,
                showTooltip: viewModel.showCategoryTooltip,
                itemNameFieldIsFocused: $itemNameFieldIsFocused,
                itemName: $viewModel.itemName,
                selectedCategory: $viewModel.selectedCategory
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
                showUnitPicker: $viewModel.showUnitPicker
            )
            
            PricePerUnitField(price: $viewModel.itemPrice)
            
            Spacer().frame(height: 80)
        }
        .padding()
    }
}
