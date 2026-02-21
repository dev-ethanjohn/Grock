import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Color {
    enum Grock {
        private static func token(_ assetName: String, fallbackHex: String) -> Color {
            if let uiColor = UIColor(named: assetName) {
                return Color(uiColor)
            }
            return Color(hex: fallbackHex)
        }

        // Brand & status
        static let accentDanger = token("AccentDanger", fallbackHex: "FA003F")
        static let accentBlue = token("AccentBlue", fallbackHex: "278DD9")
        static let subscriptionAccent = token("SubscriptionAccent", fallbackHex: "6EBC59")
        static let success = token("Success", fallbackHex: "4CAF50")
        static let budgetSafe = token("BudgetSafe", fallbackHex: "98F476")
        static let budgetWarning = token("BudgetWarning", fallbackHex: "F4B576")
        static let budgetOver = token("BudgetOver", fallbackHex: "F47676")

        // Text colors
        static let textPrimary = token("TextPrimary", fallbackHex: "231F30")
        static let textSecondary = token("TextSecondary", fallbackHex: "666")
        static let textMuted = token("TextMuted", fallbackHex: "999")
        static let textMutedAlt = token("TextMutedAlt", fallbackHex: "999999")
        static let textSubtle = token("TextSubtle", fallbackHex: "717171")
        static let textDeep = token("TextDeep", fallbackHex: "1E2A36")
        static let textDeepAlt = token("TextDeepAlt", fallbackHex: "2C3E50")

        // Neutrals
        static let neutral500 = token("Neutral500", fallbackHex: "888888")
        static let neutral300 = token("Neutral300", fallbackHex: "DDD")
        static let borderSubtle = token("BorderSubtle", fallbackHex: "F2F2F2")

        // Surfaces
        static let surfaceMuted = token("SurfaceMuted", fallbackHex: "F7F7F7")
        static let surfaceSoft = token("SurfaceSoft", fallbackHex: "F9F9F9")
        static let surfaceLight = token("SurfaceLight", fallbackHex: "F5F5F5")
        static let surfaceElevated = token("SurfaceElevated", fallbackHex: "EEEEEE")
    }

    static let cartChangedDeep = Color(hex: "4F00B5")
    static let cartChangedBackground = Color(hex: "F8EBFF")
    static let cartAddedDeep = Color(hex: "3A3A3A")
    static let cartAddedBackground = Color(hex: "EFEFEF")
    static let cartSkippedDeep = Color(hex: "D85C2E")
    static let cartSkippedBackground = Color(hex: "FFE7D8")
    static let cartNewDeep = Color(hex: "FFB300")
    static let cartNewBackground = Color(hex: "FFF9E6")
    static let cartVaultDeep = Color.Grock.neutral500
    
    func saturated(by percentage: Double) -> Color {
        UIColor(self).saturated(by: percentage).map(Color.init) ?? self
    }
    
    func darker(by percentage: Double) -> Color {
        UIColor(self).darker(by: percentage).map(Color.init) ?? self
    }
}

extension UIColor {
    func saturated(by percentage: Double) -> UIColor? {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return nil }
        return UIColor(hue: h, saturation: min(s + CGFloat(percentage), 1.0), brightness: b, alpha: a)
    }
    
    func darker(by percentage: Double) -> UIColor? {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return nil }
        return UIColor(hue: h, saturation: s, brightness: max(b - CGFloat(percentage), 0.0), alpha: a)
    }
}
