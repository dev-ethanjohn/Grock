import SwiftUI

struct UnitButton: View {
    @Binding var unit: String
    let hasError: Bool
    
    @State private var showAddUnit = false
    
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
        ("wrap", ""),
        ("bag", ""),
    ]
    
    var body: some View {
        Menu {
            Button(action: {
                showAddUnit = true
            }) {
                Label("Add New Unit", systemImage: "plus.circle.fill")
            }
            
            Divider()
            
            Section(header: Text("Weight/Volume")) {
                ForEach(continuousUnits, id: \.abbr) { unitOption in
                    Button(action: {
                        unit = unitOption.abbr
                    }) {
                        if unitOption.full.isEmpty {
                            HStack {
                                Text(unitOption.abbr)
                                if unit == unitOption.abbr {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        } else {
                            Text("\(unitOption.abbr) - \(unitOption.full)")
                            if unit == unitOption.abbr {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Discrete/Count")) {
                ForEach(discreteUnits, id: \.abbr) { unitOption in
                    Button(action: {
                        unit = unitOption.abbr
                    }) {
                        if unitOption.full.isEmpty {
                            HStack {
                                Text(unitOption.abbr)
                                if unit == unitOption.abbr {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        } else {
                            Text("\(unitOption.abbr) - \(unitOption.full)")
                            if unit == unitOption.abbr {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }

            Button("Clear Selection 😶") {
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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color(hex: "#FA003F"),
                        lineWidth: hasError ? 2.0 : 0
                    )
            )
        }
    }
}
