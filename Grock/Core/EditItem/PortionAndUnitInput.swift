//
//  PortionUnitInput.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/17/25.
//

import SwiftUI

struct PortionAndUnitInput: View {
    @Binding var portion: Double?
    @Binding var unit: String
    @Binding var showUnitPicker: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            PortionInput(portion: $portion)
            UnitButton(unit: $unit)
        }
    }
}
//#Preview {
//    PortionAndUnitInput()
//}
