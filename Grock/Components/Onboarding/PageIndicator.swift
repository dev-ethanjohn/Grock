//
//  PageIndicator.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/6/25.
//

import SwiftUI

struct PageIndicator: View {
    let currentStep: OnboardingStep
    
    private var currentIndex: Int {
        switch currentStep {
        case .lastStore: return 0
        case .firstItem: return 1
        default: return 0
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.primary : Color.primary.opacity(0.25))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentIndex ? 1.3 : 1.0)
            }
            .padding(.top, 8)
        }
    }
}

#Preview {
    PageIndicator(currentStep: .lastStore)
}

#Preview {
    PageIndicator(currentStep: .firstItem)
}
