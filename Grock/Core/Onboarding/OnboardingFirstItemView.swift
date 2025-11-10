//
//  OnboardingFirstItemView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//

import SwiftUI
import SwiftData

struct OnboardingFirstItemView: View {
    //TODO: Rearrange
    @Bindable var viewModel: OnboardingViewModel
    @Environment(VaultService.self) private var vaultService
    
    var onFinish: () -> Void
    var onBack: () -> Void
    
    @FocusState private var itemNameFieldIsFocused: Bool
    @State private var showUnitPicker = false
    
    @State private var selectedCategory: GroceryCategory? = nil
    
    @State private var showCategoryTooltip = false
    
    private var questionText: String {
        if viewModel.storeName.isEmpty {
            return "One item you usually buy for grocery"
        } else {
            return "One item you bought from \(viewModel.storeName)"
        }
    }
    
    private var calculatedTotal: Double {
        let portionValue = viewModel.portion ?? 0
        let priceValue = Double(viewModel.itemPrice) ?? 0
        return portionValue * priceValue
    }
    
    private var selectedCategoryEmoji: String {
        selectedCategory?.emoji ?? "plus.circle.fill"
    }
    
    private var isFormValid: Bool {
        !viewModel.itemName.isEmpty &&
        Double(viewModel.itemPrice) != nil &&
        viewModel.portion != nil &&
        !viewModel.unit.isEmpty &&
        selectedCategory != nil
    }
    
    var body: some View {
        VStack {
            FirstItemBackHeader(onBack: onBack)
            
            ScrollView {
                FirstItemForm(
                    questionText: questionText,
                    viewModel: viewModel,
                    itemNameFieldIsFocused: $itemNameFieldIsFocused,
                    selectedCategory: $selectedCategory,
                    selectedCategoryEmoji: selectedCategoryEmoji,
                    showUnitPicker: $showUnitPicker,
                    calculatedTotal: calculatedTotal,
                    showCategoryTooltip: $showCategoryTooltip
                )
            }
            .safeAreaInset(edge: .bottom) {
                //TODO: OWN var view/ viewbuilder
                HStack {
                    TotalDisplay(calculatedTotal: calculatedTotal)
                    
                    Spacer()
                    
                    FinishButton(isFormValid: isFormValid) {
                        if let category = selectedCategory {
                            viewModel.categoryName = category.title
                        }
                        
                        UserDefaults.standard.set(false, forKey: "hasSeenVaultCelebration")
                        print("🎉 OnboardingFirstItemView: Reset celebration flag")
                        
                        saveInitialData()
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
            }
        }
//        .sheet(isPresented: $showUnitPicker) {
//            UnitPickerView(selectedUnit: $viewModel.unit)
//        }
        .onAppear {
            itemNameFieldIsFocused = true
            if viewModel.unit.isEmpty {
                viewModel.unit = "g"
            }
            if !viewModel.categoryName.isEmpty {
                selectedCategory = GroceryCategory.allCases.first { $0.title == viewModel.categoryName }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showCategoryTooltip = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCategoryTooltip = false
                    }
                }
            }
        }
        .onChange(of: selectedCategory) { _, newValue in
            if let category = newValue {
                viewModel.categoryName = category.title
                withAnimation(.easeOut(duration: 0.3)) {
                    showCategoryTooltip = false
                }
            }
        }
    }
    
    private func saveInitialData() {
        guard let category = selectedCategory,
              let price = Double(viewModel.itemPrice) else {
            print("❌ Failed to save item - invalid data")
            return
        }
        
        print("💾 Saving item to vault:")
        print("   Name: \(viewModel.itemName)")
        print("   Category: \(category.title)")
        print("   Store: \(viewModel.storeName)")
        print("   Price: ₱\(price)")
        print("   Unit: \(viewModel.unit)")
        
        vaultService.addItem(
            name: viewModel.itemName,
            to: category,
            store: viewModel.storeName,
            price: price,
            unit: viewModel.unit
        )
        
        print("✅ Item saved successfully!")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("💾 Vault processing complete - proceeding to finish")
            
            UserDefaults.standard.hasCompletedOnboarding = true
            
            onFinish()
        }
    }
}
