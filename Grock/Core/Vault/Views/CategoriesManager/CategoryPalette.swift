import UIKit

enum CategoryPalette {
    // 7 columns x 3 rows = 21 colors per page.
    static let sunny: [String] = [
        "FFF06B", // punchy lemon
        "FFE84F", // bright dandelion
        "FFDF3C", // golden yellow
        "FFD633", // marigold
        "FFCC2B", // sunflower
        "FFC024", // warm yellow
        "FFB61F", // amber yellow
        "FFB24A", // tangerine
        "FFAA3A", // orange yellow
        "FFA030", // orange
        "FF962D", // soft orange
        "FF8D2A", // vibrant orange
        "FF8430", // orange coral
        "FF7B3A", // coral orange
        "FF7347", // coral
        "FF6C55", // coral pink
        "FF7A6A", // salmon
        "FF8A7B", // pink coral
        "FF9B8A", // peach pink
        "FFAD9A", // warm peach
        "FFBCA8"  // soft peach
    ]

    static let warm: [String] = [
        "FFF9D4", // pale butter yellow
        "FFF4C8", // soft cream
        "FFF0BD", // light honey
        "FFEAB2", // pastel mango
        "FFE3A8", // soft apricot
        "FFDC9E", // light tangerine
        "FFD596", // peach
        "FFCF8F", // soft peach
        "FFC988", // light coral
        "FFC282", // warm peach
        "FFBC7D", // soft tangerine
        "FFB679", // apricot
        "FFB076", // peachy coral
        "FFAA73", // soft coral
        "FFA571", // warm coral
        "FF9F6F", // light terracotta
        "FFE2B0", // golden peach
        "FFEAC0", // pale marigold
        "FFF1D0", // vanilla cream
        "FFF6DB", // porcelain cream
        "FFE1A4"  // soft gold
    ]

    static let pinks: [String] = [
        "FFE3F0", // pale pink
        "FFD6E9", // soft blush
        "FFC9E2", // light rose
        "FFBCDA", // pastel pink
        "FFB0D2", // cotton candy
        "FFA4CB", // soft bubblegum
        "FF99C3", // light fuchsia
        "FF8FBD", // rosy pink
        "FF9FCC", // blush pink
        "FFB1D8", // pastel rose
        "FFC1E2", // light blush
        "FFD0EB", // pale rose
        "FFE0F2", // powder pink
        "F9D4E8", // soft peony
        "F2C6E0", // pale mauve
        "FFE3C6", // pale apricot
        "FFD9B8", // light apricot
        "FFD0AA", // soft peach
        "FFC79E", // pastel orange
        "FFBE94", // light tangerine
        "FFB58B"  // soft orange
    ]

    static let greens: [String] = [
        "E8F8D0", // pale lime
        "DEF4C2", // soft lime
        "D3F0B7", // light sage
        "E7F6B8", // yellow green
        "DDF0A8", // spring yellow green
        "C9E38D", // mellow yellow green
        "C8ECAD", // mint
        "BFE8A4", // soft mint
        "B5E49B", // seafoam
        "ABDF92", // pale green
        "A3DA96", // light seafoam
        "9BD59B", // mint green
        "98D1A8", // muted mint
        "8CCA9F", // light moss
        "87C99A", // soft moss
        "7FC194", // deeper moss
        "B9D98A", // yellow green
        "A8CF7B", // olive green
        "76C9C5", // soft aqua
        "DCCB8F", // golden olive
        "D2B77C"  // warm olive
    ]

    static let blues: [String] = [
        "E2FBF7", // pale aqua
        "D6F7F2", // soft aqua
        "CAF3ED", // light seafoam
        "BEEFE8", // pale teal
        "DDF6FF", // icy sky
        "D0F0FF", // pale sky
        "C3EAFF", // light azure
        "B6E3FF", // soft blue
        "A9D3FF", // sky blue
        "9AC4FF", // bright sky blue
        "8BB6FF", // clear blue
        "7EA8F7", // cobalt light
        "729AF0", // cobalt
        "678CE8", // deep cobalt
        "7C8CFF", // berry indigo
        "6F7FF0", // indigo
        "6272E2", // deep indigo
        "A8B0FF", // pale berry
        "9CA3FF", // soft berry
        "9096FF", // lavender blue
        "A4ADFF"  // pastel indigo
    ]

    static let purples: [String] = [
        "F5E4FF", // pale lavender
        "EFD9FF", // soft lilac
        "E2C3FF", // pastel violet
        "D6ADFF", // soft purple
        "D0A2FF", // lavender blue
        "F7D9EF", // soft pink
        "E9BDDF", // mauve
        "DBA1CF", // purple pink
        "CD87BF", // soft plum
        "F3E0C2", // pale gold
        "E9D3A8", // soft gold
        "D6B57F", // warm tan
        "CCAA72", // caramel gold
        "C19F68", // light brown
        "B68F5C", // warm brown
        "A77D4F", // chestnut
        "B7A0D8", // lavender taupe
        "9A88C5", // muted violet
        "8B7BBB", // soft violet brown
        "7D6FB2", // dusty violet
        "6F63A9"  // deep muted violet
    ]

    static let earths: [String] = [
        "F7EBDD", // oat cream
        "F0E0CE", // sand
        "E9D5BF", // wheat
        "E2CAB2", // tan
        "DCC0A6", // camel
        "D5B59B", // khaki
        "CEAB91", // toffee
        "C7A388", // caramel
        "C09A7E", // light cocoa
        "B99375", // latte
        "CFB8A1", // almond
        "D8C2AE", // biscuit
        "B0B8C4", // blue gray
        "9FA8B5", // slate gray blue
        "8C96A6", // steel blue gray
        "8C8AA1", // violet gray
        "837A94", // mauve gray
        "7A8A80", // green gray
        "6F8076", // dark sage gray
        "66707E", // deep blue gray
        "6B6B6B"  // dark neutral gray
    ]

    static let basePages: [[String]] = [
        sunny,
        warm,
        pinks,
        greens,
        blues,
        purples,
        earths
    ]

    static let defaultHexes: [String] = GroceryCategory.allCases.map { $0.pastelHex.normalizedHex }

    static var pages: [[String]] {
        mixedPages()
    }

    private static func mixedPages() -> [[String]] {
        var pages = basePages.map { $0.map { $0.normalizedHex } }
        let grouped = Dictionary(grouping: defaultHexes) { pageIndex(for: $0) }

        for (pageIndex, defaults) in grouped {
            guard pages.indices.contains(pageIndex) else { continue }
            var page = pages[pageIndex]
            var occupiedSlots = Set<Int>()
            var slotComponents = page.map { colorComponents(for: $0) }

            for hex in defaults {
                if page.contains(hex) { continue }
                guard let target = colorComponents(for: hex) else { continue }
                var bestIndex: Int?
                var bestScore = CGFloat.greatestFiniteMagnitude
                for (index, candidate) in slotComponents.enumerated() {
                    if occupiedSlots.contains(index) { continue }
                    guard let candidate else { continue }
                    let score = colorDistance(target, candidate)
                    if score < bestScore {
                        bestScore = score
                        bestIndex = index
                    }
                }
                guard let bestIndex else { continue }
                page[bestIndex] = hex
                occupiedSlots.insert(bestIndex)
                slotComponents[bestIndex] = target
            }

            pages[pageIndex] = page
        }

        return pages
    }

    private static func pageIndex(for hex: String) -> Int {
        guard let components = colorComponents(for: hex) else { return 5 }
        if components.s < 0.12 { return 5 }
        let hue = components.h
        if hue < 0.16 || hue >= 0.97 { return 0 }
        if hue >= 0.85 { return 1 }
        if hue < 0.38 { return 2 }
        if hue < 0.72 { return 3 }
        return 4
    }

    private static func colorComponents(for hex: String) -> (h: CGFloat, s: CGFloat, b: CGFloat)? {
        guard let rgb = rgbComponents(for: hex) else { return nil }
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        let color = UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
        guard color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return nil }
        return (h, s, b)
    }

    private static func colorDistance(
        _ a: (h: CGFloat, s: CGFloat, b: CGFloat),
        _ b: (h: CGFloat, s: CGFloat, b: CGFloat)
    ) -> CGFloat {
        let hueDiff = min(abs(a.h - b.h), 1 - abs(a.h - b.h))
        let satDiff = abs(a.s - b.s)
        let briDiff = abs(a.b - b.b)
        return (hueDiff * 1.2) + (satDiff * 0.6) + (briDiff * 0.8)
    }

    private static func rgbComponents(for hex: String) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard !cleaned.isEmpty else { return nil }
        var int: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&int) else { return nil }

        let r, g, b: UInt64
        switch cleaned.count {
        case 3:
            (r, g, b) = (
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17
            )
        case 6:
            (r, g, b) = (
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        case 8:
            (r, g, b) = (
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            return nil
        }

        return (
            r: CGFloat(r) / 255.0,
            g: CGFloat(g) / 255.0,
            b: CGFloat(b) / 255.0
        )
    }
}

private extension String {
    var normalizedHex: String {
        trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
    }
}
