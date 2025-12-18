import SwiftUI

struct UnitButton: View {
    @Binding var unit: String
    let hasError: Bool
    
    @State private var showAddUnit = false
    var shakeOffset: CGFloat = 0
    
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
        ("pack", "pack"),
        ("can", "can"),
        ("bottle", "bottle"),
        ("box", "box"),
        ("wrap", "wrap"),
        ("bag", "bag")
    ]
    
    var body: some View {
        Menu {
            Button(action: { showAddUnit = true }) {
                Label("Add New Unit", systemImage: "plus.circle.fill")
            }
            
            Divider()
            
            // Continuous Units Section
            Section(header: Text("Weight/Volume")) {
                ForEach(continuousUnits, id: \.abbr) { unitOption in
                    unitRow(unitOption: unitOption)
                }
            }
            
            // Discrete Units Section
            Section(header: Text("Discrete/Count")) {
                ForEach(discreteUnits, id: \.abbr) { unitOption in
                    unitRow(unitOption: unitOption)
                }
            }
            
            // Clear selection
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
        .offset(x: shakeOffset)
    }
    
    @ViewBuilder
    private func unitRow(unitOption: (abbr: String, full: String)) -> some View {
        Button(action: { unit = unitOption.abbr }) {
            HStack(spacing: 8) {
                // Display format: "abbr - full" if they're different, or just "full" if they're the same
                if unitOption.abbr != unitOption.full && !unitOption.full.isEmpty {
                    Text("\(unitOption.abbr) - \(unitOption.full)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                } else {
                    Text(unitOption.full.isEmpty ? unitOption.abbr : unitOption.full)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                if unit == unitOption.abbr {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .frame(width: 20, alignment: .center)
                } else {
                    Color.clear
                        .frame(width: 20)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
