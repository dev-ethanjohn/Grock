//
//  EmptyCartView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 12/9/25.
//

import SwiftUI
import Lottie

struct EmptyCartView: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Add items to your cart")
                    .lexendFont(20, weight: .medium)
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                Text("via 'Manage Cart' below")
                    .lexendFont(16, weight: .regular)
                    .foregroundColor(.gray.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
            }
            
            LottieView(animation: .named("Arrow"))
                .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .loop)))
                .animationSpeed(0.6)
                .scaleEffect(x: -0.8, y: 0.8)
                .allowsHitTesting(false)
                .frame(height: 100)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.5)
                .rotationEffect(.degrees(-90))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#Preview {
    EmptyCartView()
}
