//
//  CelebrationView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/3/25.
//

import SwiftUI
import Lottie


struct CelebrationView: View {
    @Binding var isPresented: Bool
    @State private var showing = false
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissCelebration()
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                LottieView(animation: .named("Celebration"))
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                    .scaleEffect(1.1)
                    .allowsHitTesting(false)
                    .frame(height: 400)
                    .offset(y: 200)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Your Vault!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black)
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .padding(.bottom, 100)
                .scaleEffect(showing ? 1 : 0)
                .opacity(opacity)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                showing = true
                opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismissCelebration()
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            showing = false
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

#Preview {
    struct CelebrationViewPreview: View {
        @State private var isPresented = true
        
        var body: some View {
            CelebrationView(isPresented: $isPresented)
        }
    }
    
    return CelebrationViewPreview()
}
