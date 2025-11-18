import SwiftUI

struct PortionAndUnitInput: View {
    @Binding var portion: Double?
    @Binding var unit: String
    @Binding var showUnitPicker: Bool
    let hasPortionError: Bool
    let hasUnitError: Bool
    let portionShakeOffset: CGFloat // Add individual shake offsets
    let unitShakeOffset: CGFloat
    
    var body: some View {
        HStack(spacing: 8) {
            PortionInput(portion: $portion, hasError: hasPortionError)
                .offset(x: portionShakeOffset) // Apply shake to Portion only
            
            UnitButton(unit: $unit, hasError: hasUnitError)
                .offset(x: unitShakeOffset) // Apply shake to Unit only
        }
    }
}
