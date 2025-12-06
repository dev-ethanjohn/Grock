import SwiftUI

struct PortionAndUnitInput: View {
    @Binding var portion: Double?
    @Binding var unit: String
    @Binding var showUnitPicker: Bool
    let hasPortionError: Bool
    let hasUnitError: Bool
    let portionShakeOffset: CGFloat
    let unitShakeOffset: CGFloat
    
    var body: some View {
        HStack(spacing: 8) {
            PortionInput(portion: $portion, hasError: hasPortionError)
                .offset(x: portionShakeOffset)
            
            UnitButton(unit: $unit, hasError: hasUnitError)
                .offset(x: unitShakeOffset)
        }
    }
}
