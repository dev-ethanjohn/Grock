//
//  Grocery+Enums.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/17/25.
//

import Foundation
import SwiftUI



enum EditContext {
    case vault
    case cart
}

//enum FilterOption: String, CaseIterable {
//    case all = "All"
//    case fulfilled = "Fulfilled"
//    case unfulfilled = "Unfulfilled"
//}

//MARK: Categories
enum GroceryCategory: String, CaseIterable, Identifiable {
    case freshProduce
    case meatsSeafood
    case dairyEggs
    case frozen
    case condimentsIngredients
    case pantry
    case bakeryBread
    case beverages
    case readyMeals
    case personalCare
    case health
    case cleaningHousehold
    case pets
    case baby
    case homeGarden
    case electronicsHobbies
    case stationery
    
    var id: Self { return self }
    
    var title: String {
        switch self {
        case .freshProduce:
            return "Fresh Produce"
        case .meatsSeafood:
            return "Meats & Seafood"
        case .dairyEggs:
            return "Dairy & Eggs"
        case .frozen:
            return "Frozen"
        case .condimentsIngredients:
            return "Condiments & Ingredients"
        case .pantry:
            return "Pantry"
        case .bakeryBread:
            return "Bakery & Bread"
        case .beverages:
            return "Beverages"
        case .readyMeals:
            return "Ready Meals"
        case .personalCare:
            return "Personal Care"
        case .health:
            return "Health"
        case .cleaningHousehold:
            return "Cleaning & Household"
        case .pets:
            return "Pets"
        case .baby:
            return "Baby"
        case .homeGarden:
            return "Home & Garden"
        case .electronicsHobbies:
            return "Electronics & Hobbies"
        case .stationery:
            return "Stationery"
        }
    }
    
    var emoji: String {
        switch self {
        case .freshProduce:
            return "🍏"
        case .meatsSeafood:
            return "🥩"
        case .dairyEggs:
            return "🧀"
        case .frozen:
            return "🧊"
        case .condimentsIngredients:
            return "🧂"
        case .pantry:
            return "🫙"
        case .bakeryBread:
            return "🥖"
        case .beverages:
            return "🥤"
        case .readyMeals:
            return "🍱"
        case .personalCare:
            return "🧴"
        case .health:
            return "💊"
        case .cleaningHousehold:
            return "🧽"
        case .pets:
            return "🐕"
        case .baby:
            return "👶"
        case .homeGarden:
            return "🏠"
        case .electronicsHobbies:
            return "🎮"
        case .stationery:
            return "📝"
        }
    }
    
    var pastelColor: Color {
        switch self {
        case .freshProduce:
            return Color(hex: "AAFF72")
        case .meatsSeafood:
            return Color(hex: "FFBEBE")
        case .dairyEggs:
            return Color(hex: "FFE481")
        case .frozen:
            return Color(hex: "C5F9FF")
        case .condimentsIngredients:
            return Color(hex: "949494")
        case .pantry:
            return Color(hex: "FFF7AA")
        case .bakeryBread:
            return Color(hex: "F5DEB3")
        case .beverages:
            return Color(hex: "AAB3E0")
        case .readyMeals:
            return Color(hex: "FFDAB9")
        case .personalCare:
            return Color(hex: "FFC0CB")
        case .health:
            return Color(hex: "CBCAFF")
        case .cleaningHousehold:
            return Color(hex: "D8BFD8")
        case .pets:
            return Color(hex: "CAA484")
        case .baby:
            return Color(hex: "B0E0E6")
        case .homeGarden:
            return Color(hex: "AED470")
        case .electronicsHobbies:
            return Color(hex: "FF96CA")
        case .stationery:
            return Color(hex: "F3C7A3")
        }
    }
}


//MARK: Onboarding
enum OnboardingStep {
    case welcome
    case lastStore
    case firstItem
    case done
}
