import SwiftUI

// struct ScrollOffsetPreferenceKey: PreferenceKey {
//    static var defaultValue: CGPoint = .zero
//    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
// }

struct BlurScroll: ViewModifier {
    
    let blur: CGFloat
    let bottomBlurScale: CGFloat
    let coordinateSpaceName = "scroll"
    
    @State private var scrollPosition: CGPoint = .zero
    
    func body(content: Content) -> some View {
        
        let gradient = LinearGradient(stops: [
            .init(color: .black, location: 0.04 * bottomBlurScale),
            .init(color: .clear, location: 0.10 * bottomBlurScale)],
                                      startPoint: .bottom,
                                      endPoint: .top)
        
        let invertedGradient = LinearGradient(stops: [
            .init(color: .clear, location: 0.04 * bottomBlurScale),
            .init(color: .black, location: 0.12 * bottomBlurScale)],
                                              startPoint: .bottom,
                                              endPoint: .top)
        
        GeometryReader { topGeo in
            ScrollView {
                ZStack(alignment: .top) {
                    content
                        .mask(
                            VStack {
                                invertedGradient
                                    .frame(height: topGeo.size.height, alignment: .top)
                                    .offset(y: -scrollPosition.y)
                                Spacer()
                            }
                        )
                    
                    content
                        .blur(radius: blur)
                        .frame(height: topGeo.size.height, alignment: .top)
                        .mask(gradient
                            .frame(height: topGeo.size.height)
                            .offset(y: -scrollPosition.y)
                        )
                        .ignoresSafeArea()
                }
                .padding(.bottom, topGeo.size.height * 0.12 * bottomBlurScale)
                .background(GeometryReader { geo in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named(coordinateSpaceName)).origin)
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    self.scrollPosition = value
                }
            }
            .coordinateSpace(name: coordinateSpaceName)
        }
        .ignoresSafeArea()
    }
}

extension View {
    func blurScroll(blur: CGFloat = 12, scale: CGFloat = 1.0) -> some View {
        modifier(BlurScroll(blur: blur, bottomBlurScale: scale))
    }
}
