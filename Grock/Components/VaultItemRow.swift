import SwiftUI


import SwiftUI

struct MyStepper: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Button {
                handleMinus()
            } label: {
                Image(systemName: "minus")
                    .font(.footnote).bold()
                    .foregroundColor(Color(hex: "1E2A36"))
                    .frame(width: 24, height: 24)
                    .background(Color(hex: "F2F2F2"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .disabled(value <= range.lowerBound)
            .opacity(value <= range.lowerBound ? 0.5 : 1)
            
            TextField("", text: $textValue)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "2C3E50"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                )
                .frame(minWidth: 40)
                .frame(maxWidth: 80)
                .fixedSize(horizontal: true, vertical: false)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .onSubmit { commitTextField() }
                .onChange(of: isFocused) { _, focused in
                    if !focused { commitTextField() }
                }
                .onAppear {
                    textValue = formatValue(value)
                }
                .onChange(of: value) { _, newValue in
                    if !isFocused {
                        textValue = formatValue(newValue)
                    }
                }
                .onChange(of: textValue) {_, newText in
                    if let number = Double(newText), number > 100 {
                        textValue = "100"
                    }
                }
            
            Button {
                handlePlus()
            } label: {
                Image(systemName: "plus")
                    .font(.footnote).bold()
                    .foregroundColor(Color(hex: "1E2A36"))
                    .frame(width: 24, height: 24)
                    .background(Color(hex: "F2F2F2"))
                    .clipShape(Circle())
            }
            .contentShape(Circle())
            .buttonStyle(.plain)
            .disabled(value >= range.upperBound)
            .opacity(value >= range.upperBound ? 0.5 : 1)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isFocused = false
                    commitTextField()
                }
            }
        }
    }
    
    // MARK: - Logic
    private func handlePlus() {
        let newValue: Double
        
        // Check if current value is decimal
        if value.truncatingRemainder(dividingBy: 1) != 0 {
            // If decimal → round up first
            newValue = ceil(value)
        } else {
            // Otherwise just add step
            newValue = value + step
        }
        
        value = min(newValue, range.upperBound)
        textValue = formatValue(value)
    }
    
    private func handleMinus() {
        let newValue: Double
        
        // Check if current value is decimal
        if value.truncatingRemainder(dividingBy: 1) != 0 {
            // If decimal → round down first
            newValue = floor(value)
        } else {
            // Otherwise just subtract step
            newValue = value - step
        }
        
        value = max(newValue, range.lowerBound)
        textValue = formatValue(value)
    }
    
    private func commitTextField() {
        // Convert text to double, using current locale
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        if let number = formatter.number(from: textValue) {
            let doubleValue = number.doubleValue
            let clamped = min(max(doubleValue, range.lowerBound), range.upperBound)
            value = clamped
            
            if doubleValue != clamped {
                textValue = formatValue(clamped)
            } else {
                textValue = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            textValue = formatValue(value)
        }
    }
    
    private func formatValue(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", val)
        } else {
            var result = String(format: "%.2f", val)
            while result.last == "0" { result.removeLast() }
            if result.last == "." { result.removeLast() }
            return result
        }
    }
}


struct VaultItemRow: View {
    let item: Item
    let category: GroceryCategory?
    @Environment(CartViewModel.self) private var cartViewModel
    var onDelete: (() -> Void)?
    
    private var currentQuantity: Double {
        cartViewModel.activeCartItems[item.id] ?? 0
    }
    
    private var isActive: Bool {
        currentQuantity > 0
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Circle()
                .fill(category?.pastelColor.saturated(by: 1).darker(by: 0.2) ?? Color.primary)
                .frame(width: 8, height: 8)
                .padding(.top, 10)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .foregroundColor(Color(hex: "888"))
                + Text(" >")
                    .font(.fuzzyBold_20)
                    .foregroundStyle(Color(hex: "bbb"))
                
                if let priceOption = item.priceOptions.first {
                    HStack(spacing: 4) {
                        Text("₱\(priceOption.pricePerUnit.priceValue, specifier: "%.2f")")
                        Text("/ \(priceOption.pricePerUnit.unit)")
                            .font(.caption)
                        Spacer()
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "888"))
                }
            }
            
            Spacer()
            
            if isActive {
                MyStepper(
                    value: Binding(
                        get: { currentQuantity },
                        set: { newValue in
                            cartViewModel.updateActiveItem(itemId: item.id, quantity: newValue)
                        }
                    ),
                    range: 0...100,
                    step: 1
                )
            } else {
                Button(action: {
                    cartViewModel.updateActiveItem(itemId: item.id, quantity: 1)
                }) {
                    Image(systemName: "plus")
                        .font(.footnote)
                        .bold()
                        .foregroundColor(Color(hex: "888888"))
                }
                .frame(width: 24, height: 24)
                .clipShape(Circle())
                .contentShape(Circle())
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 4)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                print("Edit item: \(item.name)")
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
        .background(.white)
    }
}
