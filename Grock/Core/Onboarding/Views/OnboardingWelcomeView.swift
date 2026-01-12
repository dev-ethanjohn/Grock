import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    
    private init() {
        prepareAll()
    }
    
    private func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
    }
    
    
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func playLight() {
        lightImpact.impactOccurred()
        lightImpact.prepare() // Prepare for next use
    }
    
    func playMedium() {
        mediumImpact.impactOccurred()
        mediumImpact.prepare()
    }
    
    func playHeavy() {
        heavyImpact.impactOccurred()
        heavyImpact.prepare()
    }
    
    // Convenience method specifically for buttons
    func playButtonTap() {
        playLight()
    }
}
// Then in your view:
struct OnboardingWelcomeView: View {
    @Bindable var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                Image("grock_logo")
                    .resizable()
                    .frame(width: 125, height: 125)
                Text("Grock")
                    .fuzzyBubblesFont(40, weight: .bold)
            }
            
            Spacer()
                .frame(height: 60)
            
            VStack(spacing: 8) {
                Text("⟢   see your true costs   ⟣")
                Text("⟢   stop leaks, save more   ⟣")
                Text("⟢   forget paper & Excel   ⟣")
                Text("⟢   SHOP SMARTER!   ⟣")
            }
            .fuzzyBubblesFont(18, weight: .regular)
            .foregroundStyle(.black.opacity(0.7))
            .multilineTextAlignment(.center)
      
            Spacer()
            
            Button("Get Started") {
                // Use the shared haptic manager
                HapticManager.shared.playButtonTap()
                viewModel.navigateToLastStore()
            }
            .fuzzyBubblesFont(16, weight: .bold)
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
            .background(.black)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .padding()
    }
}
