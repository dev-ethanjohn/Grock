import SwiftUI
import Lottie

extension Notification.Name {
    static let toggleProUnlockedCelebration = Notification.Name("ToggleProUnlockedCelebration")
    static let showProUnlockedCelebration = Notification.Name("ShowProUnlockedCelebration")
}

struct ProUnlockedCelebrationOverlay: View {
    let isPresented: Bool
    var content: ProUnlockedCelebrationContent = .generic
    var playbackToken: UUID = UUID()
    var horizontalPadding: CGFloat = 24
    var topPadding: CGFloat = 60
    var bottomPadding: CGFloat = 44
    
    @State private var shouldRender = false
    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.8

    private var placementIsTop: Bool {
        content.placement == .top
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if shouldRender {
                    LottieView(animation: .named("Celebration"))
                        .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                        .id(playbackToken)
                        .allowsHitTesting(false)
                        .scaleEffect(1.2)
                        .frame(height: 380)
                        .offset(y: UIScreen.main.bounds.height * 0.1)
                        .opacity(overlayOpacity)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    
                    ProUnlockedFloatingSheet(
                        contextualMessage: content.contextualMessage
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: placementIsTop ? .top : .bottom
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(
                        placementIsTop ? .top : .bottom,
                        placementIsTop ? proxy.safeAreaInsets.top + topPadding : bottomPadding
                    )
                    .scaleEffect(contentScale, anchor: placementIsTop ? .top : .bottom)
                    .opacity(overlayOpacity)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.8, anchor: placementIsTop ? .top : .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0.8, anchor: placementIsTop ? .top : .bottom).combined(with: .opacity)
                        )
                    )
                }
            }
        }
        .onAppear {
            syncPresentationState(isPresented)
        }
        .onChange(of: isPresented) { _, newValue in
            syncPresentationState(newValue)
        }
    }
    
    private func syncPresentationState(_ presented: Bool) {
        if presented {
            shouldRender = true
            overlayOpacity = 0
            contentScale = 0.8
            
            withAnimation(.easeOut(duration: 0.2)) {
                overlayOpacity = 1
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                contentScale = 1
            }
            return
        }
        
        guard shouldRender else { return }
        
        withAnimation(.easeOut(duration: 0.2)) {
            overlayOpacity = 0
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            contentScale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            if !isPresented {
                shouldRender = false
            }
        }
    }
}

#Preview("Visible") {
    ZStack(alignment: .bottom) {
        Color(hex: "F7F7F7").ignoresSafeArea()
        ProUnlockedCelebrationOverlay(isPresented: true)
    }
}

#Preview("Interactive") {
    ProUnlockedCelebrationOverlayPreviewHarness()
}

private struct ProUnlockedCelebrationOverlayPreviewHarness: View {
    @State private var isPresented = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "F7F7F7").ignoresSafeArea()

            Button(isPresented ? "Hide Pro Celebration" : "Show Pro Celebration") {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    isPresented.toggle()
                }
            }
            .fuzzyBubblesFont(16, weight: .bold)
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(Capsule().fill(.black))
            .padding(.bottom, 120)

            ProUnlockedCelebrationOverlay(isPresented: isPresented)
        }
    }
}
