import SwiftUI

struct VaultItemRow: View {
    let item: Item
    let category: GroceryCategory?
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(VaultService.self) private var vaultService
    var onDelete: (() -> Void)?
    
    @State private var showEditSheet = false
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    private var currentQuantity: Double {
        cartViewModel.activeCartItems[item.id] ?? 0
    }
    
    private var isActive: Bool {
        currentQuantity > 0
    }
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .trailing) {
            
            //delete
            deleteItemBackRow
            
            itemFrontRow
         
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSwiped {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    offset = 0
                    isSwiped = false
                }
            } else {
                showEditSheet = true
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditItemSheet(
                item: item,
                onSave: { updatedItem in
                    print("✅ Updated item: \(updatedItem.name)")
                }
            )
            .environment(vaultService)
            .presentationDetents([.medium, .fraction(0.75)])
            .presentationCornerRadius(24)
        }
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onDelete?()
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
            
            Button {
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
        .onChange(of: currentQuantity) { _, newValue in
            if !isFocused {
                textValue = formatValue(newValue)
            }
        }
        // for reset (remove unnecessary x offset changes during display)
        .onAppear {
            offset = 0
            isSwiped = false
        }
        .onChange(of: item.id) { oldId, newId in
            offset = 0
            isSwiped = false
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
    
    private var deleteItemBackRow: some View {
        HStack {
            Spacer()
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onDelete?()
                }
            }) {
                ZStack {
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 80)
                    
                    VStack {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("Remove")
                            .font(.footnote)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 80)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var itemFrontRow: some View {
        HStack(alignment: .top, spacing: 4) {
            Circle()
                .fill(isActive ? (category?.pastelColor.saturated(by: 0.3).darker(by: 0.5) ?? Color.primary) : .clear)
                .frame(width: 9, height: 9)
                .padding(.top, 8)
                .scaleEffect(isActive ? 1 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(item.name)
                    .foregroundColor(isActive ? .black : Color(hex: "999"))
                //TODO: fix
//                + Text(" >")
//                    .fuzzyBubblesFont(20, weight: .bold)
//                    .foregroundStyle(Color(hex: "CCCCCC"))
                
                if let priceOption = item.priceOptions.first {
                    HStack(spacing: 0) {
                        Text("₱\(priceOption.pricePerUnit.priceValue, specifier: "%g")")
                        Text("/\(priceOption.pricePerUnit.unit)")
                            .lexendFont(12, weight: .medium)
                        Spacer()
                    }
                    .lexendFont(12, weight: .medium)
                    .foregroundColor(isActive ? .black : Color(hex: "999"))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button {
                    handleMinus()
                } label: {
                    Image(systemName: "minus")
                        .font(.footnote).bold()
                        .foregroundColor(Color(hex: "1E2A36"))
                        .frame(width: 24, height: 24)
                        .background(.white)
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
                    
                    TextField("", text: $textValue)
                        .normalizedNumber($textValue)
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
                .background(.white)
                .clipShape(Circle())
                .contentShape(Circle())
                .buttonStyle(.plain)
            }
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActive)
            .padding(.top, 6)
        }
        .padding(.bottom, 4)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.white)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
        .offset(x: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.width < 0 {
                        offset = value.translation.width
                    }
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if value.translation.width < -100 {
                            offset = -80
                            isSwiped = true
                        } else {
                            offset = 0
                            isSwiped = false
                        }
                    }
                }
        )
    }
}

