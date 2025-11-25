import SwiftUI

//struct VaultItemRow: View {
//    let item: Item
//    let category: GroceryCategory?
//    @Environment(CartViewModel.self) private var cartViewModel
//    @Environment(VaultService.self) private var vaultService
//    let onDelete: () -> Void
//   
//    @State private var showEditSheet = false
//    @State private var dragPosition: CGFloat = 0
//    @GestureState private var dragOffset: CGFloat = 0
//    @State private var isSwiped = false
//    @State private var isDeleting: Bool = false
//    @State private var isNewlyAdded: Bool = true
//    @State private var deletionCompleted = false
//   
//    private var currentQuantity: Double {
//        cartViewModel.activeCartItems[item.id] ?? 0
//    }
//   
//    private var isActive: Bool {
//        currentQuantity > 0
//    }
//   
//    @State private var textValue: String = ""
//    @FocusState private var isFocused: Bool
//   
//    private var totalOffset: CGFloat {
//        if isDeleting {
//            return -400
//        } else {
//            let proposed = dragPosition + dragOffset
//            return max(proposed, -80)
//        }
//    }
//   
//    var body: some View {
//        ZStack(alignment: .trailing) {
//            // Delete background
//            deleteItemBackRow
//                .offset(x: isDeleting ? totalOffset : 0)
//           
//            // Main content
//            itemFrontRow
//        }
//        .contentShape(Rectangle())
//        .onTapGesture {
//            if isSwiped {
//                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                    dragPosition = 0
//                    isSwiped = false
//                }
//            } else {
//                showEditSheet = true
//            }
//        }
//        .sheet(isPresented: $showEditSheet) {
//            EditItemSheet(
//                item: item,
//                onSave: { updatedItem in
//                    print("✅ Updated item: \(updatedItem.name)")
//                }
//            )
//            .environment(vaultService)
//            .presentationDetents([.medium, .fraction(0.75)])
//            .presentationCornerRadius(24)
//        }
//        .contextMenu {
//            Button(role: .destructive) {
//                triggerDeletion()
//            } label: {
//                Label("Remove", systemImage: "trash")
//            }
//           
//            Button {
//                showEditSheet = true
//            } label: {
//                Label("Edit", systemImage: "pencil")
//            }
//        }
//        .onChange(of: currentQuantity) { _, newValue in
//            if !isFocused {
//                textValue = formatValue(newValue)
//            }
//        }
//        .onChange(of: isDeleting) { _, newValue in
//            if newValue && !deletionCompleted {
//                deletionCompleted = true
//                
//                //Remove from active items BEFORE calling onDelete
//                cartViewModel.activeCartItems.removeValue(forKey: item.id)
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                    onDelete()
//                }
//            }
//        }
//        .onAppear {
//            dragPosition = 0
//            isSwiped = false
//            isDeleting = false
//            deletionCompleted = false
//           
//            if isNewlyAdded {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                    withAnimation(.easeIn(duration: 0.2)) {
//                        isNewlyAdded = false
//                    }
//                }
//            }
//        }
//        .onDisappear {
//            isNewlyAdded = true
//        }
//        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: totalOffset)
//        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDeleting)
//    }
//   
//    private func triggerDeletion() {
//        guard !isDeleting && !deletionCompleted else { return }
//       
//        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//            isDeleting = true
//        }
//    }
//   
//    private func handlePlus() {
//        let newValue: Double
//        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
//            newValue = ceil(currentQuantity)
//        } else {
//            newValue = currentQuantity + 1
//        }
//       
//        let clamped = min(newValue, 100)
//        cartViewModel.updateActiveItem(itemId: item.id, quantity: clamped)
//        textValue = formatValue(clamped)
//    }
//   
//    private func handleMinus() {
//        let newValue: Double
//        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
//            newValue = floor(currentQuantity)
//        } else {
//            newValue = currentQuantity - 1
//        }
//       
//        let clamped = max(newValue, 0)
//        cartViewModel.updateActiveItem(itemId: item.id, quantity: clamped)
//        textValue = formatValue(clamped)
//    }
//   
//    private func commitTextField() {
//        let formatter = NumberFormatter()
//        formatter.numberStyle = .decimal
//       
//        if let number = formatter.number(from: textValue) {
//            let doubleValue = number.doubleValue
//            let clamped = min(max(doubleValue, 0), 100)
//            cartViewModel.updateActiveItem(itemId: item.id, quantity: clamped)
//           
//            if doubleValue != clamped {
//                textValue = formatValue(clamped)
//            } else {
//                textValue = textValue.trimmingCharacters(in: .whitespacesAndNewlines)
//            }
//        } else {
//            textValue = formatValue(currentQuantity)
//        }
//    }
//   
//    private func formatValue(_ val: Double) -> String {
//        if val.truncatingRemainder(dividingBy: 1) == 0 {
//            return String(format: "%.0f", val)
//        } else {
//            var result = String(format: "%.2f", val)
//            while result.last == "0" { result.removeLast() }
//            if result.last == "." { result.removeLast() }
//            return result
//        }
//    }
//   
//    private var deleteItemBackRow: some View {
//        HStack {
//            Spacer()
//            Button(action: {
//                triggerDeletion() // Use centralized deletion
//            }) {
//                ZStack {
//                    Rectangle()
//                        .fill(Color.red)
//                        .frame(width: 80)
//                   
//                    VStack {
//                        Image(systemName: "trash")
//                            .font(.subheadline)
//                            .foregroundColor(.white)
//                        Text("Remove")
//                            .font(.footnote)
//                            .foregroundColor(.white)
//                    }
//                }
//                .frame(width: 80)
//            }
//            .buttonStyle(.plain)
//            .opacity(isNewlyAdded ? 0 : 1)
//        }
//    }
//   
//    private var itemFrontRow: some View {
//        HStack(alignment: .top, spacing: 4) {
//            Circle()
//                .fill(isActive ? (category?.pastelColor.saturated(by: 0.3).darker(by: 0.5) ?? Color.primary) : .clear)
//                .frame(width: 9, height: 9)
//                .padding(.top, 8)
//                .scaleEffect(isActive ? 1 : 0)
//                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isActive)
//           
//            VStack(alignment: .leading, spacing: 0) {
//                Text(item.name)
//                    .foregroundColor(isActive ? .black : Color(hex: "999"))
//               
//                if let priceOption = item.priceOptions.first {
//                    HStack(spacing: 0) {
//                        Text("₱\(priceOption.pricePerUnit.priceValue, specifier: "%g")")
//                        Text("/\(priceOption.pricePerUnit.unit)")
//                            .lexendFont(12, weight: .medium)
//                        Spacer()
//                    }
//                    .lexendFont(12, weight: .medium)
//                    .foregroundColor(isActive ? .black : Color(hex: "999"))
//                }
//            }
//            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
//           
//            Spacer()
//           
//            HStack(spacing: 8) {
//                if isActive {
//                    Button {
//                        handleMinus()
//                    } label: {
//                        Image(systemName: "minus")
//                            .font(.footnote).bold()
//                            .foregroundColor(Color(hex: "1E2A36"))
//                            .frame(width: 24, height: 24)
//                            .background(.white)
//                            .clipShape(Circle())
//                    }
//                    .buttonStyle(.plain)
//                    .contentShape(Rectangle())
//                    .disabled(currentQuantity <= 0)
//                    .opacity(currentQuantity <= 0 ? 0.5 : 1)
//                }
//               
//                if isActive {
//                    ZStack {
//                        Text(textValue)
//                            .font(.system(size: 15, weight: .bold))
//                            .foregroundColor(Color(hex: "2C3E50"))
//                            .multilineTextAlignment(.center)
//                            .contentTransition(.numericText())
//                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: textValue)
//                       
//                        TextField("", text: $textValue)
//                            .normalizedNumber($textValue)
//                            .font(.system(size: 15, weight: .bold))
//                            .foregroundColor(.clear)
//                            .multilineTextAlignment(.center)
//                            .keyboardType(.decimalPad)
//                            .focused($isFocused)
//                            .onChange(of: isFocused) { _, focused in
//                                if !focused { commitTextField() }
//                            }
//                            .onChange(of: textValue) { _, newText in
//                                if let number = Double(newText), number > 100 {
//                                    textValue = "100"
//                                }
//                            }
//                    }
//                    .padding(.horizontal, 6)
//                    .background(
//                        RoundedRectangle(cornerRadius: 6)
//                            .stroke(Color(hex: "F2F2F2").darker(by: 0.1), lineWidth: 1)
//                    )
//                    .frame(minWidth: 40)
//                    .frame(maxWidth: 80)
//                    .fixedSize(horizontal: true, vertical: false)
//                    .onAppear {
//                        textValue = formatValue(currentQuantity)
//                    }
//                    .onChange(of: currentQuantity) { _, newValue in
//                        if !isFocused {
//                            textValue = formatValue(newValue)
//                        }
//                    }
//                }
//               
//                Button(action: {
//                    if isActive {
//                        handlePlus()
//                    } else {
//                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                            cartViewModel.updateActiveItem(itemId: item.id, quantity: 1)
//                        }
//                    }
//                }) {
//                    Image(systemName: "plus")
//                        .font(.footnote)
//                        .bold()
//                        .foregroundColor(isActive ? Color(hex: "1E2A36") : Color(hex: "888888"))
//                }
//                .frame(width: 24, height: 24)
//                .background(.white)
//                .clipShape(Circle())
//                .contentShape(Circle())
//                .buttonStyle(.plain)
//            }
//            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isActive)
//            .padding(.top, 6)
//        }
//        .padding(.bottom, 4)
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//        .background(.white)
//        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isActive)
//        .offset(x: totalOffset)
//        .gesture(
//            DragGesture()
//                .updating($dragOffset) { value, state, _ in
//                    let translation = value.translation.width
//                    if translation < 0 {
//                        let proposed = dragPosition + translation
//                        if proposed < -80 {
//                            let excess = proposed + 80
//                            state = -80 - dragPosition + (excess * 0.3)
//                        } else {
//                            state = translation
//                        }
//                    } else if dragPosition < 0 {
//                        state = translation * 0.5
//                    }
//                }
//                .onEnded { value in
//                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                        if value.translation.width < -50 {
//                            dragPosition = -80
//                            isSwiped = true
//                        } else {
//                            dragPosition = 0
//                            isSwiped = false
//                        }
//                    }
//                }
//        )
//        .disabled(isDeleting)
//    }
//}

struct VaultItemRow: View {
    let item: Item
    let category: GroceryCategory?
    @Environment(CartViewModel.self) private var cartViewModel
    @Environment(VaultService.self) private var vaultService
    let onDelete: () -> Void
   
    @State private var showEditSheet = false
    @State private var dragPosition: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isSwiped = false
    @State private var isDeleting: Bool = false
    @State private var isNewlyAdded: Bool = true
    @State private var deletionCompleted = false
   
    private var currentQuantity: Double {
        cartViewModel.activeCartItems[item.id] ?? 0
    }
   
    private var isActive: Bool {
        currentQuantity > 0
    }
   
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
   
    private var totalOffset: CGFloat {
        if isDeleting {
            return -400
        } else {
            let proposed = dragPosition + dragOffset
            return max(proposed, -80)
        }
    }

    // Add this state to track if we're in a vertical scroll
    @State private var isVerticalScroll = false
   
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            deleteItemBackRow
                .offset(x: isDeleting ? totalOffset : 0)
           
            // Main content
            itemFrontRow
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isSwiped {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dragPosition = 0
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
                triggerDeletion()
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
        .onChange(of: isDeleting) { _, newValue in
            if newValue && !deletionCompleted {
                deletionCompleted = true
                
                //Remove from active items BEFORE calling onDelete
                cartViewModel.activeCartItems.removeValue(forKey: item.id)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDelete()
                }
            }
        }
        .onAppear {
            dragPosition = 0
            isSwiped = false
            isDeleting = false
            deletionCompleted = false
           
            if isNewlyAdded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeIn(duration: 0.2)) {
                        isNewlyAdded = false
                    }
                }
            }
        }
        .onDisappear {
            isNewlyAdded = true
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: totalOffset)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDeleting)
    }
   
    private func triggerDeletion() {
        guard !isDeleting && !deletionCompleted else { return }
       
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isDeleting = true
        }
    }
   
    private func handlePlus() {
        let newValue: Double
        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
            newValue = ceil(currentQuantity)
        } else {
            newValue = currentQuantity + 1
        }
       
        let clamped = min(newValue, 100)
        cartViewModel.updateActiveItem(itemId: item.id, quantity: clamped)
        textValue = formatValue(clamped)
    }
   
    private func handleMinus() {
        let newValue: Double
        if currentQuantity.truncatingRemainder(dividingBy: 1) != 0 {
            newValue = floor(currentQuantity)
        } else {
            newValue = currentQuantity - 1
        }
       
        let clamped = max(newValue, 0)
        cartViewModel.updateActiveItem(itemId: item.id, quantity: clamped)
        textValue = formatValue(clamped)
    }
   
    private func commitTextField() {
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
                triggerDeletion() // Use centralized deletion
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
            .opacity(isNewlyAdded ? 0 : 1)
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
                if isActive {
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
                }
               
                if isActive {
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
                    .onAppear {
                        textValue = formatValue(currentQuantity)
                    }
                    .onChange(of: currentQuantity) { _, newValue in
                        if !isFocused {
                            textValue = formatValue(newValue)
                        }
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
        .offset(x: totalOffset)
        // In your VaultItemRow, replace the gesture with this more restrictive version:
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .updating($dragOffset) { value, state, _ in
                    // Only process if it's clearly a horizontal swipe
                    let horizontalAmount = abs(value.translation.width)
                    let verticalAmount = abs(value.translation.height)
                    
                    // Require horizontal movement to be at least 2x vertical movement
                    if horizontalAmount > verticalAmount * 2 {
                        let translation = value.translation.width
                        let proposed = dragPosition + translation
                        
                        if translation < 0 { // Only allow left swipes
                            if proposed < -80 {
                                let excess = proposed + 80
                                state = -80 - dragPosition + (excess * 0.3)
                            } else {
                                state = translation
                            }
                        } else if dragPosition < 0 { // Allow right swipe to close
                            state = translation * 0.5
                        }
                    }
                    // If it's mostly vertical, do nothing - let the List handle it
                }
                .onEnded { value in
                    let horizontalAmount = abs(value.translation.width)
                    let verticalAmount = abs(value.translation.height)
                    
                    // Only process swipe if it's clearly horizontal
                    if horizontalAmount > verticalAmount * 2 {
                        if value.translation.width < -50 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragPosition = -80
                                isSwiped = true
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                dragPosition = 0
                                isSwiped = false
                            }
                        }
                    }
                }
        )
        .disabled(isDeleting)
    }
}
