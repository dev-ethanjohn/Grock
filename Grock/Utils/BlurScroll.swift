import SwiftUI

struct BlurScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

struct BlurScroll: ViewModifier {
    let blur: CGFloat
    let bottomBlurScale: CGFloat
    let coordinateSpaceName = "scroll"
    
    // NOTE: Removed preferenceKey tracking to prevent stuttering
    
    func body(content: Content) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                ScrollView {
                    content
                        // Add padding at bottom to allow content to scroll fully above the blur
                        .padding(.bottom, proxy.size.height * 0.15 * bottomBlurScale)
                }
                .scrollIndicators(.hidden)
                .coordinateSpace(name: coordinateSpaceName)
                
                // Bottom Blur Overlay
                // Using Material for O(1) performance (no duplication, no tracking)
                Rectangle()
                    .fill(Material.regular)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: proxy.size.height * 0.15 * bottomBlurScale)
                    .allowsHitTesting(false) // Let touches pass through to scroll
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func blurScroll(blur: CGFloat = 8, scale: CGFloat = 1.0) -> some View {
        modifier(BlurScroll(blur: blur, bottomBlurScale: scale))
    }
}
