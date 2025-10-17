//
//  UnitButton.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/17/25.
//

import SwiftUI

struct UnitButton: View {
    @Binding var unit: String
    
    let continuousUnits: [(abbr: String, full: String)] = [
        ("g", "grams"),
        ("kg", "kilograms"),
        ("lb", "pounds"),
        ("oz", "ounces"),
        ("L", "liters"),
        ("mL", "milliliters")
    ]
    
    let discreteUnits: [(abbr: String, full: String)] = [
        ("pc", "piece"),
        ("pack", ""),
        ("can", ""),
        ("bottle", ""),
        ("box", ""),
        ("bag", "")
    ]
    
    var body: some View {
        Menu {
            Section(header: Text("Weight/Volume")) {
                ForEach(continuousUnits, id: \.abbr) { unitOption in
                    Button(action: {
                        unit = unitOption.abbr
                    }) {
                        if unitOption.full.isEmpty {
                            Text(unitOption.abbr)
                        } else {
                            Text("\(unitOption.abbr) - \(unitOption.full)")
                        }
                    }
                }
            }
            
            Section(header: Text("Discrete")) {
                ForEach(discreteUnits, id: \.abbr) { unitOption in
                    Button(action: {
                        unit = unitOption.abbr
                    }) {
                        if unitOption.full.isEmpty {
                            Text(unitOption.abbr)
                        } else {
                            Text("\(unitOption.abbr) - \(unitOption.full)")
                        }
                    }
                }
            }
            
            Button("Clear Selection") {
                unit = ""
            }
        } label: {
            HStack {
                Text("Unit")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
                Text(unit.isEmpty ? "" : unit)
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(unit.isEmpty ? .gray : .black)
                Image(systemName: "chevron.down")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

//#Preview {
//    UnitButton()
//}
