//
//  OnboardingWelcomeView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/6/25.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                Image("grock_logo")
                    .resizable()
                    .frame(width: 125, height: 125)
                Text("Grock")
                    .fuzzyBubblesFont(40, weight: .bold)
            }
            
            Spacer()
                .frame(height: 60)
            
            VStack(spacing: 8) {
                Text("⟢   see your true costs   ⟣")
                Text("⟢   stop leaks, save more   ⟣")
                Text("⟢   forget paper & Excel   ⟣")
                Text("⟢   SHOP SMARTER!   ⟣")
            }
            .fuzzyBubblesFont(18, weight: .regular)
            .foregroundStyle(.black.opacity(0.7))
            .multilineTextAlignment(.center)
      
            Spacer()
            
            Button("Get Started") {
                viewModel.navigateToLastStore()
            }
            .fuzzyBubblesFont(16, weight: .bold)
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding()
    }
}
