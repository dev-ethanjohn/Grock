//
//  Font.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/29/25.
//

import Foundation
import SwiftUI


struct LexendFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    
    private var fontName: String {
        switch weight {
        case .ultraLight:
            return "Lexend-ExtraLight"
        case .thin:
            return "Lexend-Thin"
        case .light:
            return "Lexend-Light"
        case .regular:
            return "Lexend-Regular"
        case .medium:
            return "Lexend-Medium"
        case .semibold:
            return "Lexend-SemiBold"
        case .bold:
            return "Lexend-Bold"
        case .heavy:
            return "Lexend-ExtraBold"
        case .black:
            return "Lexend-Black"
        default:
            return "Lexend-Regular"
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(.custom(fontName, size: size))
    }
}

extension View {
    func lexendFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.modifier(LexendFont(size: size, weight: weight))
    }
}

extension Font {
    static let fuzzyBold_40 = Font.custom("FuzzyBubbles-Bold", size: 40)
    static let fuzzyBold_24 = Font.custom("FuzzyBubbles-Bold", size: 24)
    static let fuzzyBold_20 = Font.custom("FuzzyBubbles-Bold", size: 20)
    static let fuzzyBold_18 = Font.custom("FuzzyBubbles-Bold", size: 18)
    static let fuzzyBold_16 = Font.custom("FuzzyBubbles-Bold", size: 16)
    static let fuzzyBold_15 = Font.custom("FuzzyBubbles-Bold", size: 15)
    static let fuzzyBold_13 = Font.custom("FuzzyBubbles-Bold", size: 13)
    static let fuzzyBold_11 = Font.custom("FuzzyBubbles-Bold", size: 11)
    static let fuzzyRegular_18 = Font.custom("FuzzyBubbles-Regular", size: 18)
    
    static let lexendMedium_12 = Font.custom("Lexend-Medium", size: 12)
    static let lexendRegular_15 = Font.custom("Lexend-Regular", size: 15)
    static let lexendRegular_16 = Font.custom("Lexend-Light", size: 16)
    
}
