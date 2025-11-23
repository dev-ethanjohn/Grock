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
    
    private var shouldShowErrorStyling: Bool {
        showItemNameError || duplicateError != nil
    }
    
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
                
                HStack {
                    TextField("e.g. canned tuna", text: $itemName)
                        .normalizedText($itemName)
                        .font(.subheadline)
                        .bold()
                        .padding(12)
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
                                hasError: showCategoryError && selectedCategory == nil
                            )
                            .offset(x: shakeOffset),
                            alignment: .trailing
                        )
                }
            }
            
            if let category = selectedCategory {
                Text(category.title)
                    .font(.caption2)
                    .foregroundColor(category.pastelColor.darker(by: 0.3))
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
                        selectedCategory!.pastelColor.opacity(0.4),
                        selectedCategory!.pastelColor.opacity(0.35)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: fillAnimation * 100
                )
            }
        }
        .brightness(shouldShowErrorStyling ? 0 : -0.03)
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
