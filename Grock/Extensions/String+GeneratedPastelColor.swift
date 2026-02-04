import SwiftUI

extension String {
    var generatedPastelColor: Color {
        let hash = abs(self.unicodeScalars.reduce(0) { ($0 * 31) + Int($1.value) })
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.35, brightness: 0.97)
    }
}

