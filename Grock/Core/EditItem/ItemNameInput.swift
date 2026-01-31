import SwiftUI

struct ItemNameInput: View {
    let selectedCategoryEmoji: String
    let showTooltip: Bool
    let showItemNameError: Bool
    let showCategoryError: Bool
    let invalidAttemptCount: Int
    let isCheckingDuplicate: Bool
    let duplicateError: String?
    
    var itemNameFieldIsFocused: FocusState<Bool>.Binding
    
    @Binding var itemName: String
    @Binding var selectedCategory: GroceryCategory?
    
    @State private var fillAnimation: CGFloat = 0.0
    @State private var fieldScale: CGFloat = 1.0
    @State private var shakeOffset: CGFloat = 0
    @State private var showCategoryLockedTooltip = false
    
    private var shouldShowErrorStyling: Bool {
        showItemNameError || duplicateError != nil
    }
    
    var isCategoryEditable: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ZStack(alignment: .trailing) {
                
                if showCategoryError && selectedCategory == nil {
                    CategoryErrorPopover()
                        .offset(x: 0, y: -36)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85, anchor: .topTrailing)
                                .combined(with: .opacity)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5)),
                            removal: .scale(scale: 0.95, anchor: .topTrailing)
                                .combined(with: .opacity)
                                .animation(.spring(response: 0.15, dampingFraction: 0.75))
                        ))
                        .zIndex(1)
                }
                else if showTooltip && selectedCategory == nil && !showCategoryError {
                    CategoryTooltipPopover()
                        .offset(x: 0, y: -36)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85, anchor: .topTrailing)
                                .combined(with: .opacity)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5)),
                            removal: .scale(scale: 0.95, anchor: .topTrailing)
                                .combined(with: .opacity)
                                .animation(.spring(response: 0.15, dampingFraction: 0.75))
                        ))
                        .zIndex(1)
                }
                
                // Category Locked Tooltip for Shopping Mode
                else if !isCategoryEditable && showCategoryLockedTooltip {
                    CategoryLockedTooltip()
                        .offset(x: 0, y: -36)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.85, anchor: .topTrailing)
                                .combined(with: .opacity)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5)),
                            removal: .scale(scale: 0.95, anchor: .topTrailing)
                                .combined(with: .opacity)
                                .animation(.spring(response: 0.15, dampingFraction: 0.75))
                        ))
                        .zIndex(1)
                }
                
                HStack {
                    TextField(selectedCategory?.placeholder ?? "e.g. Item name", text: $itemName)
                        .normalizedText($itemName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .lexend(.subheadline)
                        .bold()
                        .padding(12)
                        .padding(.trailing, 42)
                        .background(backgroundView)
                        .cornerRadius(40)
                        .focused(itemNameFieldIsFocused)
                        .scaleEffect(fieldScale)
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(
                                    Color(hex: "#FA003F"),
                                    lineWidth: shouldShowErrorStyling ? 2.0 : 0
                                )
                        )
                        .overlay(
                            CategoryCircularButton(
                                selectedCategory: $selectedCategory,
                                selectedCategoryEmoji: selectedCategoryEmoji,
                                hasError: showCategoryError && selectedCategory == nil,
                                isEditable: isCategoryEditable,
                                onTap: {
                                    if !isCategoryEditable {
                                        showCategoryLockedTooltip = true
                                        let generator = UINotificationFeedbackGenerator()
                                        generator.notificationOccurred(.warning)
                                        
                                        // Auto-hide tooltip after 2 seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation {
                                                showCategoryLockedTooltip = false
                                            }
                                        }
                                    }
                                }
                            )
                            .offset(x: shakeOffset),
                            alignment: .trailing
                        )
                }
            }
            
            if let category = selectedCategory {
                HStack(spacing: 4) {
                    Text(category.title)
                        .lexend(.caption2)
                        .foregroundColor(category.pastelColor.darker(by: 0.3))
                    
                    if !isCategoryEditable {
                        Image(systemName: "lock.fill")
                            .lexendFont(8)
                            .foregroundColor(.gray)
                        
                        Text("From Vault")
                            .lexend(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16)
                .transition(.scale.combined(with: .opacity))
                .id(category.id)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedCategory)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCheckingDuplicate)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: duplicateError)
        .onChange(of: selectedCategory) { oldValue, newValue in
            handleCategoryChange(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: showCategoryError) { oldValue, newValue in
            if newValue && selectedCategory == nil {
                triggerShakeAnimation()
            }
        }
        .onChange(of: invalidAttemptCount) { oldValue, newValue in
            if newValue > oldValue && showCategoryError && selectedCategory == nil {
                triggerShakeAnimation()
            }
        }
    }
    
    private func triggerShakeAnimation() {
        let shakeSequence = [0, -4, 4, -3, 3, -2, 2, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.linear(duration: 0.05)) {
                    self.shakeOffset = CGFloat(offset)
                }
            }
        }
    }
    
    private var backgroundView: some View {
        Group {
            if shouldShowErrorStyling {
                Color(hex: "#FF2C2C").opacity(0.05)
            } else if selectedCategory == nil {
                Color(.systemGray6).brightness(0.03)
            } else {
                RadialGradient(
                    colors: [
                        selectedCategory!.pastelColor.opacity(isCategoryEditable ? 0.4 : 0.2),
                        selectedCategory!.pastelColor.opacity(isCategoryEditable ? 0.35 : 0.15)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: fillAnimation * 100
                )
            }
        }
        .brightness(shouldShowErrorStyling ? 0 : -0.03)
        .opacity(isCategoryEditable ? 1.0 : 0.8)
    }
    
    private func handleCategoryChange(oldValue: GroceryCategory?, newValue: GroceryCategory?) {
        if newValue != nil {
            if oldValue == nil {
                withAnimation(.spring(duration: 0.5)) {
                    fillAnimation = 1.0
                }
                startFieldBounce()
            } else {
                withAnimation(.spring(duration: 0.5)) {
                    fillAnimation = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(duration: 0.5)) {
                        fillAnimation = 1.0
                    }
                    startFieldBounce()
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.4)) {
                fillAnimation = 0.0
                fieldScale = 1.0
            }
        }
    }
    
    private func startFieldBounce() {
        guard isCategoryEditable else { return }
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            fieldScale = 0.985
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                fieldScale = 1.015
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                fieldScale = 1.0
            }
        }
    }
}

// MARK: - Supporting Components
struct CategoryLockedTooltip: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .lexend(.caption)
                    .foregroundColor(.gray)
                
                Text("Category locked in shopping mode")
                    .lexend(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            
            Triangle()
                .fill(Color.white)
                .frame(width: 12, height: 8)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                .offset(y: -1)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
