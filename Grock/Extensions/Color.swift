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
    static let cartChangedDeep = Color(hex: "4F00B5")
    static let cartChangedBackground = Color(hex: "F8EBFF")
    static let cartAddedDeep = Color(hex: "3A3A3A")
    static let cartAddedBackground = Color(hex: "EFEFEF")
    static let cartSkippedDeep = Color(hex: "D85C2E")
    static let cartSkippedBackground = Color(hex: "FFE7D8")
    static let cartNewDeep = Color(hex: "FFB300")
    static let cartNewBackground = Color(hex: "FFF9E6")
    static let cartVaultDeep = Color(hex: "888888")
    
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
