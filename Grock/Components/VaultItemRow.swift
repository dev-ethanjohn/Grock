import SwiftUI

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
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Circle()
                .fill(isActive ? (category?.pastelColor.saturated(by: 1).darker(by: 0.2) ?? Color.primary) : .clear)
                .frame(width: 8, height: 8)
                .padding(.top, 10)
                .scaleEffect(isActive ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .foregroundColor(isActive ? .black : Color(hex: "999"))
                + Text(" >")
                    .font(.fuzzyBold_20)
                    .foregroundStyle(Color(hex: "CCCCCC"))
                
                if let priceOption = item.priceOptions.first {
                    HStack(spacing: 4) {
                        Text("₱\(priceOption.pricePerUnit.priceValue, specifier: "%.2f")")
                        Text("/ \(priceOption.pricePerUnit.unit)")
                            .font(.lexendMedium_12)
                        Spacer()
                    }
                    .font(.lexendMedium_12)
                    .foregroundColor(isActive ? .black : Color(hex: "999"))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            
            Spacer()
            
            // Smooth transition between plus button and stepper
            HStack(spacing: 8) {
                // Minus button (scales individually)
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
                .disabled(currentQuantity <= 0)
                .opacity(currentQuantity <= 0 ? 0.5 : 1)
                .scaleEffect(isActive ? 1 : 0)
                .frame(width: isActive ? 24 : 0)
                
                ZStack {
                    Text(textValue)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "2C3E50"))
                        .multilineTextAlignment(.center)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: textValue)
                    
                    // hidden
                    TextField("", text: $textValue)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.clear)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .focused($isFocused)
                        .onChange(of: isFocused) { _, focused in
                            if !focused { commitTextField() }
                        }
                        .onChange(of: textValue) { _, newText in
                            if let number = Double(newText), number > 100 {
                                textValue = "100"
                            }
                        }
                }
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "F2F2F2").darker(by: 0.1), lineWidth: 1)
                )
                .frame(minWidth: 40)
                .frame(maxWidth: 80)
                .fixedSize(horizontal: true, vertical: false)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        if isFocused {
                            Spacer()
                            Button("Done") {
                                isFocused = false
                            }
                        }
                    }
                }
                .scaleEffect(isActive ? 1 : 0)
                .frame(width: isActive ? nil : 0)
                .onAppear {
                    textValue = formatValue(currentQuantity)
                }
                .onChange(of: currentQuantity) { _, newValue in
                    if !isFocused {
                        textValue = formatValue(newValue)
                    }
                }
                
                Button(action: {
                    if isActive {
                        handlePlus()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            cartViewModel.updateActiveItem(itemId: item.id, quantity: 1)
                        }
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.footnote)
                        .bold()
                        .foregroundColor(isActive ? Color(hex: "1E2A36") : Color(hex: "888888"))
                }
                .frame(width: 24, height: 24)
                .background(isActive ? Color(hex: "F2F2F2") : .clear)
                .clipShape(Circle())
                .contentShape(Circle())
                .buttonStyle(.plain)
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActive)
        }
        .padding(.bottom, 4)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.white)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onDelete?()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onDelete?()
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                print("Edit item: \(item.name)")
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
        .onChange(of: currentQuantity) { _, newValue in
            if !isFocused {
                textValue = formatValue(newValue)
            }
        }
    }
    
    private func handlePlus() {
        let newValue: Double
        
        // Check if current value is decimal
        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
            // If decimal → round up first
            newValue = ceil(currentQuantity)
        } else {
            // Otherwise just add step
            newValue = currentQuantity + 1
        }
        
        let clamped = min(newValue, 100)
        cartViewModel.updateActiveItem(itemId: item.id, quantity: clamped)
        textValue = formatValue(clamped)
    }
    
    private func handleMinus() {
        let newValue: Double
        
        // Check if current value is decimal
        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
            // If decimal → round down first
            newValue = floor(currentQuantity)
        } else {
            // Otherwise just subtract step
            newValue = currentQuantity - 1
        }
        
        let clamped = max(newValue, 0)
        cartViewModel.updateActiveItem(itemId: item.id, quantity: clamped)
        textValue = formatValue(clamped)
    }
    
    private func commitTextField() {
        // Convert text to double, using current locale (from MyStepper)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        if let number = formatter.number(from: textValue) {
            let doubleValue = number.doubleValue
            let clamped = min(max(doubleValue, 0), 100)
            cartViewModel.updateActiveItem(itemId: item.id, quantity: clamped)
            
            if doubleValue != clamped {
                textValue = formatValue(clamped)
            } else {
                textValue = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else {
            textValue = formatValue(currentQuantity)
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
