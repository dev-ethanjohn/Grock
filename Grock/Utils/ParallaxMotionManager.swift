import SwiftUI
import CoreMotion

final class ParallaxMotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var offset: CGPoint = .zero
    private var lastOffset: CGPoint = .zero
    
    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self = self, let motion = motion else { return }
            let gravity = motion.gravity
            let target = CGPoint(x: CGFloat(gravity.x), y: CGFloat(-gravity.y))
            let filtered = CGPoint(
                x: self.lastOffset.x * 0.85 + target.x * 0.15,
                y: self.lastOffset.y * 0.85 + target.y * 0.15
            )
            self.offset = filtered
            self.lastOffset = filtered
        }
    }
    
    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}

struct ParallaxEffect: ViewModifier {
    @ObservedObject var manager: ParallaxMotionManager
    var intensity: CGFloat
    
    func body(content: Content) -> some View {
        content.offset(x: manager.offset.x * intensity, y: manager.offset.y * intensity)
    }
}

extension View {
    func parallax(_ manager: ParallaxMotionManager, intensity: CGFloat = 8) -> some View {
        modifier(ParallaxEffect(manager: manager, intensity: intensity))
    }
}
