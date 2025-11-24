import SwiftUI

struct FormCompletionButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    let maxWidth: Bool
    let cornerRadius: CGFloat
    let verticalPadding: CGFloat
    
    // Animation parameters
    let maxRadius: CGFloat
    let bounceScale: (min: CGFloat, mid: CGFloat, max: CGFloat)
    let bounceTiming: (initial: Double, mid: Double, final: Double)
    
    let appearanceScale: CGFloat
    let shakeOffset: CGFloat
    
    @State private var fillAnimation: CGFloat = 0.0
    @State private var buttonScale: CGFloat = 1.0
    
    init(
        title: String,
        isEnabled: Bool,
        cornerRadius: CGFloat = 50,
        verticalPadding: CGFloat = 6,
        maxRadius: CGFloat = 150,
        bounceScale: (min: CGFloat, mid: CGFloat, max: CGFloat) = (0.95, 1.1, 1.0),
        bounceTiming: (initial: Double, mid: Double, final: Double) = (0.1, 0.3, 0.3),
        maxWidth: Bool = false,
        appearanceScale: CGFloat = 1.0,
        shakeOffset: CGFloat = 0,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.cornerRadius = cornerRadius
        self.verticalPadding = verticalPadding
        self.maxRadius = maxRadius
        self.bounceScale = bounceScale
        self.bounceTiming = bounceTiming
        self.maxWidth = maxWidth
        self.appearanceScale = appearanceScale
        self.shakeOffset = shakeOffset
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fuzzyBubblesFont(16, weight: .bold)
                .foregroundStyle(isEnabled ? .white : Color(.systemGray3))
                .padding(.vertical, verticalPadding)
                .padding(.horizontal, 20)
                .frame(maxWidth: maxWidth ? .infinity : nil)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            isEnabled
                            ? RadialGradient(
                                colors: [Color.black, Color(.systemGray6)],
                                center: .center,
                                startRadius: 0,
                                endRadius: fillAnimation * maxRadius
                            )
                            : RadialGradient(
                                colors: [Color(.systemGray5), Color(.systemGray6)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 0
                            )
                        )
                )
                .scaleEffect(buttonScale)
                .overlay(
                    !isEnabled ?
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                    : nil
                )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: maxWidth ? .infinity : nil)
        .scaleEffect(appearanceScale)
        .offset(x: shakeOffset)
        .onChange(of: isEnabled) { oldValue, newValue in
            handleEnabledStateChange(oldValue: oldValue, newValue: newValue)
        }
        .onAppear {
            if isEnabled {
                fillAnimation = 1.0
                buttonScale = 1.0
            }
        }
    }
    
    private func handleEnabledStateChange(oldValue: Bool, newValue: Bool) {
        if newValue {
            if !oldValue {
                withAnimation(.spring(duration: 0.6)) {
                    fillAnimation = 1.0
                }
                startButtonBounce()
            }
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                fillAnimation = 0.0
                buttonScale = 1.0
            }
        }
    }
    
    private func startButtonBounce() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            buttonScale = bounceScale.min
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + bounceTiming.initial) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                buttonScale = bounceScale.mid
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + bounceTiming.mid) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                buttonScale = bounceScale.max
            }
        }
    }
}

extension FormCompletionButton {
    static func finishButton(
        isEnabled: Bool,
        cornerRadius: CGFloat = 10,
        verticalPadding: CGFloat = 6,
        action: @escaping () -> Void
    ) -> FormCompletionButton {
        FormCompletionButton(
            title: "Finish",
            isEnabled: isEnabled,
            cornerRadius: cornerRadius,
            verticalPadding: verticalPadding,
            maxRadius: 150,
            bounceScale: (0.95, 1.1, 1.0),
            bounceTiming: (0.1, 0.3, 0.3),
            action: action
        )
    }
    
    static func doneButton(
        isEnabled: Bool,
        cornerRadius: CGFloat = 10,
        verticalPadding: CGFloat = 6,
        maxWidth: Bool = false,
        action: @escaping () -> Void
    ) -> FormCompletionButton {
        FormCompletionButton(
            title: "Done",
            isEnabled: isEnabled,
            cornerRadius: cornerRadius,
            verticalPadding: verticalPadding,
            maxRadius: 1000,
            bounceScale: (0.98, 1.05, 1.0),
            bounceTiming: (0.1, 0.3, 0.3),
            maxWidth: maxWidth,
            action: action
        )
    }
    
    static func nextButton(
        isEnabled: Bool,
        cornerRadius: CGFloat = 10,
        verticalPadding: CGFloat = 6,
        appearanceScale: CGFloat = 1.0,
        shakeOffset: CGFloat = 0,
        action: @escaping () -> Void
    ) -> FormCompletionButton {
        FormCompletionButton(
            title: "Next",
            isEnabled: isEnabled,
            cornerRadius: cornerRadius,
            verticalPadding: verticalPadding,
            maxRadius: 150,
            bounceScale: (0.95, 1.1, 1.0),
            bounceTiming: (0.1, 0.3, 0.3),
            appearanceScale: appearanceScale,
            shakeOffset: shakeOffset,
            action: action
        )
    }
    
    static func createEmptyCartButton(
        isEnabled: Bool,
        cornerRadius: CGFloat = 10,
        verticalPadding: CGFloat = 6,
        maxWidth: Bool = false,
        action: @escaping () -> Void
    ) -> FormCompletionButton {
        FormCompletionButton(
            title: "Create",
            isEnabled: isEnabled,
            cornerRadius: cornerRadius,
            verticalPadding: verticalPadding,
            maxRadius: 1000,
            bounceScale: (0.98, 1.05, 1.0),
            bounceTiming: (0.1, 0.3, 0.3),
            maxWidth: maxWidth,
            action: action
        )
    }
    
    
    static func createCartButton(
        isEnabled: Bool,
        cornerRadius: CGFloat = 10,
        verticalPadding: CGFloat = 6,
        maxWidth: Bool = false,
        action: @escaping () -> Void
    ) -> FormCompletionButton {
        FormCompletionButton(
            title: "Create",
            isEnabled: isEnabled,
            cornerRadius: cornerRadius,
            verticalPadding: verticalPadding,
            maxRadius: 1000,
            bounceScale: (0.98, 1.05, 1.0),
            bounceTiming: (0.1, 0.3, 0.3),
            maxWidth: maxWidth,
            action: action
        )
    }

}


