import Foundation
import SwiftUI
import Lottie

struct TripCompletionCelebrationOverlay: View {
    @Binding var isPresented: Bool
    let message: String
    var autoDismissAfter: TimeInterval = 3.0
    var onDismiss: (() -> Void)? = nil
    
    @State private var showing = false
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black
                .opacity(showing ? 0.72 : 0)
                .ignoresSafeArea()
            
            VStack(spacing: 14) {
                LottieView(animation: .named("Celebration"))
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                    .scaleEffect(1.05)
                    .allowsHitTesting(false)
                    .frame(height: 320)
                
                Text(message)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.75))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 22)
            }
            .scaleEffect(showing ? 1 : 0.96)
            .opacity(opacity)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissNow()
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                showing = true
                opacity = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) {
                dismissNow()
            }
        }
    }
    
    private func dismissNow() {
        guard isPresented else { return }
        
        withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
            showing = false
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            isPresented = false
            onDismiss?()
        }
    }
}
