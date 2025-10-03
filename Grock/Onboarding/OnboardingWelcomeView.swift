//
//  OnboardingWelcomeView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 9/28/25.
//


import SwiftUI

struct OnboardingWelcomeView: View {
    var onNext: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                Image("grock_logo")
                    .resizable()
                    .frame(width: 125, height: 125)
                Text("Grock")
                    .font(.fuzzyBold_40)
                    .bold()
            }
            
            Spacer()
                .frame(height: 60)
            
            VStack(spacing: 8) {
                Text("⟢   see your true costs   ⟣")
                Text("⟢   stop leaks, save more   ⟣")
                Text("⟢   forget paper & Excel   ⟣")
                Text("⟢   SHOP SMARTER!   ⟣")
            }
            .font(.fuzzyRegular_18)
            .foregroundStyle(.gray)
            .multilineTextAlignment(.center)
      

            
            Spacer()
            
            Button("Get Started") {
                onNext()
            }
            .font(.fuzzyBold_16)
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
        }
        .padding()
        
    }
}


#Preview {
    OnboardingWelcomeView(onNext: {})
}
