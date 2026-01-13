import SwiftUI
import Lottie

struct ProWelcomeSheet: View {
    @Binding var isPresented: Bool
    @State private var playAnimation = false
    @State private var hasPlayed = false

    var body: some View {
        VStack(spacing: 24) {

            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .center, spacing: 20) {

                        Text("Hello friend,")
                            .padding(.bottom, 40)

                        Text("Grocery shopping can feel confusing, overwhelming, or just tiring — you're not alone.")

                        Text("I used to plan carefully and still leave wondering if I spent too much. Prices change, items run out, and plans shift.")

                        Text("Keeping track of prices and noticing patterns didn't make shopping perfect, but it made it calmer and easier to feel in control.")

                        Text("Here's a small gift — the next ")
                        + Text("2 days")
                            .lexendFont(14, weight: .bold)
                            .foregroundStyle(.black)
                        + Text(" everything is unlocked. No pressure, just a chance to feel a little lighter and more confident.")

                        Text("- Ethan :)")
                            .padding(.top, 40)
                    }
                    .foregroundStyle(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fuzzyBubblesFont(14, weight: .light)
                    .padding(.horizontal, 32)
                    .padding(.top, 32)
                    .frame(minHeight: geometry.size.height)
                }
            }

            Button {
                guard !hasPlayed else { return }
                hasPlayed = true
                playAnimation = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    isPresented = false
                }
            } label: {
                LottieView(animation: .named("thanks"))
                    .playing(
                        playAnimation
                        ? .fromProgress(0, toProgress: 1, loopMode: .playOnce)
                        : .fromProgress(0, toProgress: 0, loopMode: .playOnce)
                    )
            }
            .buttonStyle(.plain)
            .frame(width: 200, height: 200)
            .offset(y: 50)
        }
        .presentationDetents([.large])
        .presentationCornerRadius(24)
        .onDisappear {
            UserDefaults.standard.hasSeenProWelcome = true
        }
    }
}

#Preview {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    @State private var isPresented = true

    var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                ProWelcomeSheet(isPresented: $isPresented)
            }
    }
}
