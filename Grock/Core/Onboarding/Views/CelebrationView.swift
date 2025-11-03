import SwiftUI
import Lottie

struct CelebrationView: View {
    @Binding var isPresented: Bool
    let title: String
    let subtitle: String?
    
    @State private var showing = false
    @State private var opacity: Double = 0
    
    init(isPresented: Binding<Bool>, title: String, subtitle: String? = nil) {
        self._isPresented = isPresented
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Spacer()
                
                LottieView(animation: .named("Celebration"))
                    .playbackMode(.playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce)))
                    .scaleEffect(1.1)
                    .allowsHitTesting(false)
                    .frame(height: 400)
                    .offset(y: 200)
                
                VStack(alignment: .center, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, subtitle != nil ? 12 : 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black)
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                )
                .padding(.bottom, 100)
                .scaleEffect(showing ? 1 : 0)
                .opacity(opacity)
            }
            .padding(.horizontal, 40)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                showing = true
                opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
    VStack {
        CelebrationView(
            isPresented: .constant(true),
            title: "Your First Shopping Cart!",
            subtitle: "Start adding items and manage your budget"
        )
        
        CelebrationView(
            isPresented: .constant(true),
            title: "Welcome to Your Vault!",
            subtitle: nil
        )
    }
}
