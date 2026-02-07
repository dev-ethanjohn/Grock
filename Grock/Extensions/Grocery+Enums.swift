import Foundation
import SwiftUI

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
    
    var placeholder: String {
        switch self {
        case .freshProduce: return "e.g. Apples, Bananas"
        case .meatsSeafood: return "e.g. Chicken, Salmon"
        case .dairyEggs: return "e.g. Milk, Eggs, Cheese"
        case .frozen: return "e.g. Ice Cream, Pizza"
        case .condimentsIngredients: return "e.g. Olive Oil, Spices"
        case .pantry: return "e.g. Rice, Pasta, Canned Goods"
        case .bakeryBread: return "e.g. Bread, Bagels"
        case .beverages: return "e.g. Water, Juice, Soda"
        case .readyMeals: return "e.g. Salad Kit, Sushi"
        case .personalCare: return "e.g. Shampoo, Toothpaste"
        case .health: return "e.g. Vitamins, Pain Relief"
        case .cleaningHousehold: return "e.g. Paper Towels, Detergent"
        case .pets: return "e.g. Dog Food, Cat Litter"
        case .baby: return "e.g. Diapers, Wipes"
        case .homeGarden: return "e.g. Light Bulbs, Batteries"
        case .electronicsHobbies: return "e.g. Charger, Headphones"
        case .stationery: return "e.g. Pens, Notebooks"
        }
    }
    
    var pastelHex: String {
        switch self {
        case .freshProduce: return "AAFF72"
        case .meatsSeafood: return "FFBEBE"
        case .dairyEggs: return "FFE481"
        case .frozen: return "C5F9FF"
        case .condimentsIngredients: return "949494"
        case .pantry: return "FFF7AA"
        case .bakeryBread: return "F5DEB3"
        case .beverages: return "AAB3E0"
        case .readyMeals: return "FFDAB9"
        case .personalCare: return "FFC0CB"
        case .health: return "CBCAFF"
        case .cleaningHousehold: return "D8BFD8"
        case .pets: return "CAA484"
        case .baby: return "B0E0E6"
        case .homeGarden: return "AED470"
        case .electronicsHobbies: return "FF96CA"
        case .stationery: return "F3C7A3"
        }
    }

    var pastelColor: Color {
        return Color(hex: pastelHex)
    }
}


//CART
// MARK: - CartStatus Extension
extension CartStatus {
    var displayName: String {
        switch self {
        case .planning: return "Planning"
        case .shopping: return "Shopping"
        case .completed: return "Completed"
        }
    }
    
    var color: Color {
        switch self {
        case .planning: return .blue
        case .shopping: return .orange
        case .completed: return .green
        }
    }
}

// MARK: - GroceryCategory Helper Extension
extension GroceryCategory {
    static func fromTitle(_ title: String) -> GroceryCategory {
        return GroceryCategory.allCases.first { $0.title == title } ?? .freshProduce
    }
}
