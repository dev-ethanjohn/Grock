import SwiftUI

struct VaultCategoryIcon: View {
    let category: GroceryCategory
    let isSelected: Bool
    let itemCount: Int
    let hasItems: Bool
    let action: () -> Void
    
    @State private var opacityBounce: Double = 1.0
    @State private var fillAnimation: CGFloat = 0.0
    @State private var iconScale: Double = 1.0
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        RadialGradient(
                            colors: [
                                category.pastelColor.darker(by: 0.07).saturated(by: 0.03),
                                category.pastelColor.darker(by: 0.15).saturated(by: 0.05)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: fillAnimation * 30
                        )
                    )
                    .frame(width: 42, height: 42)
                    .scaleEffect(iconScale)
                
                Text(category.emoji)
                    .font(.system(size: 24))
                    .frame(width: 42, height: 42)
                    .scaleEffect(iconScale)
                
                if itemCount > 0 {
                    Text("\(itemCount)")
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundColor(.black)
                        .offset(x: 2, y: -2)
                        .background(.white)
                        .clipShape(Capsule())
                        .scaleEffect(itemCount > 0 ? 1 : 0)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: itemCount)
                }
            }
            .padding(4)
        }
        .opacity(hasItems ? opacityBounce : 0.4)
        .onChange(of: hasItems) { oldValue, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    opacityBounce = 0.9
                    fillAnimation = 0.3
                    iconScale = 0.95
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        opacityBounce = 1.08
                        fillAnimation = 1.1
                        iconScale = 1.06
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        opacityBounce = 1.0
                        fillAnimation = 1.0
                        iconScale = 1.0
                    }
                }
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    opacityBounce = 0.4
                    fillAnimation = 0.0
                    iconScale = 0.97
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        iconScale = 1.0
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
