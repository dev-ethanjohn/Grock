import Foundation
import SwiftUI
import Lottie

struct TripCompletionCelebrationOverlay: View {
    @Binding var isPresented: Bool
    let message: String
    var autoDismissAfter: TimeInterval = 3.0
    var onDismiss: (() -> Void)? = nil

    @State private var overlayOpacity: Double = 0
    @State private var contentScale: CGFloat = 0.8
    @State private var lockShoppingAnimationAtEnd = false

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.52 * overlayOpacity)
                .ignoresSafeArea()

            LottieView(animation: .named("Celebration"))
                .playing(.fromProgress(0, toProgress: 1, loopMode: .playOnce))
                .allowsHitTesting(false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(overlayOpacity)

            TripCompletionMessageView(
                message: message,
                lockShoppingAnimationAtEnd: lockShoppingAnimationAtEnd
            )
            .scaleEffect(contentScale)
            .opacity(overlayOpacity)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            dismissNow()
        }
        .onAppear {
            lockShoppingAnimationAtEnd = false

            withAnimation(.easeOut(duration: 0.2)) {
                overlayOpacity = 1
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                contentScale = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                lockShoppingAnimationAtEnd = true
            }


            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) {
                dismissNow()
            }
        }
    }

    private func dismissNow() {
        guard isPresented else { return }

        withAnimation(.easeOut(duration: 0.2)) {
            overlayOpacity = 0
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            contentScale = 0.8
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
            onDismiss?()
        }
    }
}

struct TripCompletionMessageView: View {
    let message: String
    let lockShoppingAnimationAtEnd: Bool

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(proxy.size.width - 32, 350)

            VStack(spacing: 30) {
                LottieView(animation: .named("CompleteShopping"))
                    .playing(.fromProgress(0, toProgress: 0.9, loopMode: .playOnce))
                    .allowsHitTesting(false)
                    .frame(width: 160, height: 160)

                Text(message)
                    .fuzzyBubblesFont(22, weight: .bold)
                    .foregroundStyle(Color.black.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .minimumScaleFactor(0.85)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
            .padding(.vertical, 24)
            .frame(width: cardWidth)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 10)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview("Trip Completion Overlay") {
    TripCompletionCelebrationOverlayPreview()
}

#Preview("Trip Completion Message") {
    ZStack {
        Color.black.opacity(0.72).ignoresSafeArea()
        TripCompletionMessageView(
            message: "Great job! $85 spent, $15 saved - smart decisions made the difference.",
            lockShoppingAnimationAtEnd: true
        )
    }
}

private struct TripCompletionCelebrationOverlayPreview: View {
    @State private var isPresented = true

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            if isPresented {
                TripCompletionCelebrationOverlay(
                    isPresented: $isPresented,
                    message: "Great job! $85 spent, $15 saved - smart decisions made the difference.",
                    autoDismissAfter: 5000
                )
            }
        }
    }
}
