import SwiftUI

struct UnitButton: View {
    @Binding var unit: String
    let hasError: Bool
    var bypassPlanLocks: Bool = false
    
    @State private var showAddUnit = false
    @State private var newCustomUnit = ""
    @State private var showPaywall = false
    @State private var paywallFeatureFocus: GrockPaywallFeatureFocus?
    @AppStorage("customUnitAbbreviationsJSON") private var customUnitAbbreviationsJSON: String = "[]"
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
        ("sachet", "sachet"),
        ("can", "can"),
        ("roll", "roll"),
        ("bar", "bar"),
        ("stick", "stick"),
        ("bottle", "bottle"),
        ("carton", "carton"),
        ("box", "box"),
        ("tray", "tray"),
        ("bunch", "bunch"),
        ("dozen", "dozen"),
        ("bundle", "bundle"),
        ("wrap", "wrap"),
        ("bag", "bag")
    ]

    private var customUnitOptions: [(abbr: String, full: String)] {
        decodedCustomUnits.map { ($0, $0) }
    }

    private var isProUser: Bool {
        UserDefaults.standard.isPro
    }

    private var canManageCustomUnits: Bool {
        isProUser || bypassPlanLocks
    }

    private var allUnitOptions: [(abbr: String, full: String)] {
        continuousUnits + discreteUnits + customUnitOptions
    }

    private var decodedCustomUnits: [String] {
        guard let data = customUnitAbbreviationsJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }

        var seen = Set<String>()
        var result: [String] = []

        for value in decoded {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.lowercased()
            guard !trimmed.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(trimmed)
        }

        return result
    }
    
    var body: some View {
        Menu {
            Button(action: handleAddUnitTap) {
                Label("Add New Unit", systemImage: canManageCustomUnits ? "plus.circle.fill" : "lock.fill")
                    .foregroundStyle(canManageCustomUnits ? Color.primary : Color.gray)
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

            if !customUnitOptions.isEmpty {
                Section(header: Text("My units")) {
                    ForEach(customUnitOptions, id: \.abbr) { unitOption in
                        if canManageCustomUnits {
                            unitRow(unitOption: unitOption)
                        } else {
                            lockedUnitRow(unitOption: unitOption)
                        }
                    }
                }
            }
            
            // Clear selection
            Button("Clear Selection 😶") {
                unit = ""
            }
            
        } label: {
            HStack {
                Text("Unit")
                    .lexend(.footnote)
                    .foregroundColor(.gray)
                Spacer()
                Text(unit.isEmpty ? "" : unit)
                    .lexend(.subheadline)
                    .bold()
                    .foregroundStyle(unit.isEmpty ? Color.gray : Color.black)
                Image(systemName: "chevron.down")
                    .lexendFont(12)
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.Grock.accentDanger,
                        lineWidth: hasError ? 2.0 : 0
                    )
            )
        }
        .offset(x: shakeOffset)
        .sheet(isPresented: $showAddUnit) {
            AddUnitSheet(
                unitName: $newCustomUnit,
                isPresented: $showAddUnit,
                onSave: handleAddUnitSave
            )
        }
        .fullScreenCover(isPresented: $showPaywall) {
            GrockPaywallView(initialFeatureFocus: paywallFeatureFocus) {
                paywallFeatureFocus = nil
                showPaywall = false
            }
        }
    }
    
    @ViewBuilder
    private func unitRow(unitOption: (abbr: String, full: String)) -> some View {
        Button(action: { unit = unitOption.abbr }) {
            HStack(spacing: 8) {
                Text(unitDisplayText(for: unitOption))
                    .lexend(.subheadline)
                    .foregroundColor(.primary)
                
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

    @ViewBuilder
    private func lockedUnitRow(unitOption: (abbr: String, full: String)) -> some View {
        Button(action: {
            presentPaywall(for: .categories)
        }) {
            Label(unitDisplayText(for: unitOption), systemImage: "lock.fill")
                .lexend(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private func handleAddUnitTap() {
        guard canManageCustomUnits else {
            presentPaywall(for: .categories)
            return
        }

        newCustomUnit = ""
        showAddUnit = true
    }

    private func handleAddUnitSave(_ rawUnit: String) {
        let trimmed = rawUnit.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        guard canManageCustomUnits else {
            showAddUnit = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                presentPaywall(for: .categories)
            }
            return
        }

        let normalizedKey = trimmed.lowercased()
        if let existing = allUnitOptions.first(where: {
            $0.abbr.lowercased() == normalizedKey || $0.full.lowercased() == normalizedKey
        }) {
            unit = existing.abbr
            showAddUnit = false
            return
        }

        var updatedCustomUnits = decodedCustomUnits
        updatedCustomUnits.append(trimmed)
        persistCustomUnits(updatedCustomUnits)
        unit = trimmed
        showAddUnit = false
    }

    private func persistCustomUnits(_ units: [String]) {
        guard let data = try? JSONEncoder().encode(units),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        customUnitAbbreviationsJSON = json
    }

    private func unitDisplayText(for unitOption: (abbr: String, full: String)) -> String {
        if unitOption.abbr != unitOption.full && !unitOption.full.isEmpty {
            return "\(unitOption.abbr) - \(unitOption.full)"
        }
        return unitOption.full.isEmpty ? unitOption.abbr : unitOption.full
    }

    private func presentPaywall(for featureFocus: GrockPaywallFeatureFocus) {
        guard !bypassPlanLocks else { return }
        paywallFeatureFocus = featureFocus
        showPaywall = true
    }
}
