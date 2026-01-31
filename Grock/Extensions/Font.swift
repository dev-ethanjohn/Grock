//
//  Font.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/29/25.
//

import Foundation
import SwiftUI

// MARK: - Lexend (Variable – weight axis only)

struct LexendFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight

    private var fontName: String {
        switch weight {
        case .ultraLight: return "Lexend-ExtraLight"
        case .thin:       return "Lexend-Thin"
        case .light:      return "Lexend-Light"
        case .regular:    return "Lexend-Regular"
        case .medium:     return "Lexend-Medium"
        case .semibold:   return "Lexend-SemiBold"
        case .bold:       return "Lexend-Bold"
        case .heavy:      return "Lexend-ExtraBold"
        case .black:      return "Lexend-Black"
        default:          return "Lexend-Regular"
        }
    }

    func body(content: Content) -> some View {
        content.font(.custom(fontName, size: size))
    }
}

// MARK: - Fuzzy Bubbles (Static)

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
        content.font(.custom(fontName, size: size))
    }
}

// MARK: - Shantell Sans (Static – Bold only)

struct ShantellSansFont: ViewModifier {
    let size: CGFloat

    func body(content: Content) -> some View {
        content.font(.custom("ShantellSans-Bold", size: size))
    }
}

// MARK: - View Extensions

extension View {
    func lexendFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.modifier(LexendFont(size: size, weight: weight))
    }

    func lexend(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> some View {
        let size: CGFloat
        let defaultWeight: Font.Weight
        
        switch style {
        case .largeTitle:  size = 34; defaultWeight = .regular
        case .title:       size = 28; defaultWeight = .regular
        case .title2:      size = 22; defaultWeight = .regular
        case .title3:      size = 20; defaultWeight = .regular
        case .headline:    size = 17; defaultWeight = .semibold
        case .body:        size = 17; defaultWeight = .regular
        case .callout:     size = 16; defaultWeight = .regular
        case .subheadline: size = 15; defaultWeight = .regular
        case .footnote:    size = 13; defaultWeight = .regular
        case .caption:     size = 12; defaultWeight = .regular
        case .caption2:    size = 11; defaultWeight = .regular
        @unknown default:  size = 17; defaultWeight = .regular
        }
        
        return self.lexendFont(size, weight: weight ?? defaultWeight)
    }

    func fuzzyBubblesFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.modifier(FuzzyBubblesFont(size: size, weight: weight))
    }

    func shantellSansFont(_ size: CGFloat) -> some View {
        self.modifier(ShantellSansFont(size: size))
    }
}

// MARK: - Text Extensions (for Text + Text concatenation)

extension Text {

    func lexendFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Text {
        let fontName: String = {
            switch weight {
            case .ultraLight: return "Lexend-ExtraLight"
            case .thin:       return "Lexend-Thin"
            case .light:      return "Lexend-Light"
            case .regular:    return "Lexend-Regular"
            case .medium:     return "Lexend-Medium"
            case .semibold:   return "Lexend-SemiBold"
            case .bold:       return "Lexend-Bold"
            case .heavy:      return "Lexend-ExtraBold"
            case .black:      return "Lexend-Black"
            default:          return "Lexend-Regular"
            }
        }()

        return self.font(.custom(fontName, size: size))
    }

    func lexend(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> Text {
        let size: CGFloat
        let defaultWeight: Font.Weight
        
        switch style {
        case .largeTitle:  size = 34; defaultWeight = .regular
        case .title:       size = 28; defaultWeight = .regular
        case .title2:      size = 22; defaultWeight = .regular
        case .title3:      size = 20; defaultWeight = .regular
        case .headline:    size = 17; defaultWeight = .semibold
        case .body:        size = 17; defaultWeight = .regular
        case .callout:     size = 16; defaultWeight = .regular
        case .subheadline: size = 15; defaultWeight = .regular
        case .footnote:    size = 13; defaultWeight = .regular
        case .caption:     size = 12; defaultWeight = .regular
        case .caption2:    size = 11; defaultWeight = .regular
        @unknown default:  size = 17; defaultWeight = .regular
        }
        
        return self.lexendFont(size, weight: weight ?? defaultWeight)
    }

    func fuzzyBubblesFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Text {
        let fontName =
            (weight == .bold || weight == .semibold || weight == .heavy || weight == .black)
            ? "FuzzyBubbles-Bold"
            : "FuzzyBubbles-Regular"

        return self.font(.custom(fontName, size: size))
    }

    func shantellSansFont(_ size: CGFloat) -> Text {
        self.font(.custom("ShantellSans-Bold", size: size))
    }
}
