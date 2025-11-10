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

struct FuzzyBubblesFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    
    private var fontName: String {
        switch weight {
        case .bold, .semibold, .heavy, .black:
            return "FuzzyBubbles-Bold"
        default:
            return "FuzzyBubbles-Regular"
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(.custom(fontName, size: size))
    }
}

extension View {
    func fuzzyBubblesFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.modifier(FuzzyBubblesFont(size: size, weight: weight))
    }
}


extension View {
    func lexendFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.modifier(LexendFont(size: size, weight: weight))
    }
}


