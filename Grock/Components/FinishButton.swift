//
//  FinishButton.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/3/25.
//

import SwiftUI

struct FinishButton: View {
    let isFormValid: Bool
    let action: () -> Void
    
    @State private var fillAnimation: CGFloat = 0.0
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                Text("Finish")
                    .font(.fuzzyBold_16)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 24)
                    .background(
                        Capsule()
                            .fill(
                                isFormValid
                                ? RadialGradient(
                                    colors: [Color.black, Color.gray.opacity(0.3)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: fillAnimation * 80
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
            .disabled(!isFormValid)
        }
        .padding(.vertical, 8)
        .onChange(of: isFormValid) { oldValue, newValue in
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
            if isFormValid {
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

