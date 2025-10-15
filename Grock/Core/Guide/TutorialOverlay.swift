//
//  TutorialOverlay.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/14/25.
//

import SwiftUI

struct TutorialOverlay: View {
    let onVaultTapped: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea(.all)
                .allowsHitTesting(false)
            
            VStack {
                Spacer()
                VStack(spacing: 16) {
                    Text("👆 Tap the vault button to continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("This is where you'll manage your saved items")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 100)
                
                Spacer()
            }
        }
    }
}

//#Preview {
//    TutorialOverlay()
//}
