import SwiftUI

struct EditItemSaveButton: View {
    let isEditFormValid: Bool
    var buttonTitle: String = "Save"
    var buttonColor: Color = .black
    let action: () -> Void
    
    @State private var fillAnimation: CGFloat = 0.0
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            Text(buttonTitle)  // Use parameter
                .fuzzyBubblesFont(16, weight: .bold)
                .foregroundStyle(.white)
                .padding(.vertical, 4)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(
                            isEditFormValid
                            ? RadialGradient(
                                colors: [buttonColor, buttonColor.opacity(0.7)],  
                                center: .center,
                                startRadius: 0,
                                endRadius: fillAnimation * 150
                            )
                            : RadialGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 0
                            )
                        )
                )
                .scaleEffect(buttonScale)
        }
        .disabled(!isEditFormValid)
        .onChange(of: isEditFormValid) { oldValue, newValue in
            if newValue {
                if !oldValue {
                    withAnimation(.spring(duration: 0.4)) {
                        fillAnimation = 1.0
                    }
                    startButtonBounce()
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    fillAnimation = 0.0
                    buttonScale = 1.0
                }
            }
        }
        .onAppear {
            if isEditFormValid {
                fillAnimation = 1.0
                buttonScale = 1.0
            }
        }
    }
    
    private func startButtonBounce() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            buttonScale = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                buttonScale = 1.1
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                buttonScale = 1.0
            }
        }
    }
}
