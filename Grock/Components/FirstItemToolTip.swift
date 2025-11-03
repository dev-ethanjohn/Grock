//
//  FirstItemToolTip.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/3/25.
//

import SwiftUI
import Lottie

struct FirstItemTooltip: View {
    let itemId: String
    @Binding var isPresented: Bool
    @Environment(VaultService.self) private var vaultService
    
    @State private var showing = false
    
    private var item: Item? {
        vaultService.findItemById(itemId)
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissTooltip()
                }
            
            if showing {
                VStack(spacing: 8) {
                    LottieView(animation: .named("Arrow"))
                        .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                        .animationSpeed(0.6)
                        .scaleEffect(0.8)
                        .allowsHitTesting(false)
                        .frame(height: 80)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.5)
                        .rotationEffect(.degrees(-90))
                        
                    Text("Your first item! 🎉")
                        .lexendFont(16, weight: .bold)
                        .foregroundColor(.black)
                    
                    Text("Grow your vault as you shop and it will remember prices, portions, and stores to make your next trip easier.")
                        .lexendFont(14, weight: .medium)
                        .foregroundColor(.black.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
                .offset(y: -40)
                .opacity(showing ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showing) // Combined animation
            }
        }
        .onTapGesture {
            dismissTooltip()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showing = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                dismissTooltip()
            }
        }
    }
    
    private func dismissTooltip() {
        withAnimation(.easeOut(duration: 0.3)) {
            showing = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

//#Preview {
//    FirstItemToolTip()
//}
