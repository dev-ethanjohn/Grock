//
//  UnitPickerView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/17/25.
//

import SwiftUI

struct UnitPickerView: View {
    @Binding var selectedUnit: String
    @Environment(\.dismiss) private var dismiss
    
    let units = ["g", "kg", "lb", "oz", "pc", "pack", "L", "mL"]
    
    var body: some View {
        NavigationView {
            List(units, id: \.self) { unit in
                Button(action: {
                    selectedUnit = unit
                    dismiss()
                }) {
                    HStack {
                        Text(unit)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedUnit == unit {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Select Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

//#Preview {
//    UnitPickerView()
//}
