import SwiftUI

struct CartBottomContainer: View {
    
    var cart: Cart
    var manageCartButtonVisible: Bool
    var buttonScale: CGFloat
    var openManageCart: () -> Void
    var namespace: Namespace.ID
    
    @State private var fillAnimation: CGFloat = 1.0
    
    private var activeItemsCount: Int {
        if cart.isShopping {
            return cart.cartItems.filter { !$0.isFulfilled }.count
        }
        return cart.cartItems.count
    }
    
    private var hasActiveItems: Bool {
        activeItemsCount > 0
    }
    
    var body: some View {
        Text("Manage Cart")
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 30)
            .fixedSize()
            .minimumScaleFactor(1)
            // 1. MATCHED GEOMETRY EFFECT FOR TEXT (Source) - EXACT FROM SAMPLE
            .matchedGeometryEffect(id: "headerText", in: namespace)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black)
                    // 2. MATCHED GEOMETRY EFFECT FOR CONTAINER (Source) - EXACT FROM SAMPLE
                    .matchedGeometryEffect(id: "buttonBackground", in: namespace)
            )
            // 3. MATCHED GEOMETRY EFFECT FOR ENTIRE FRAME (Source) - EXACT FROM SAMPLE
            .matchedGeometryEffect(id: "buttonContainer", in: namespace)
            .overlay(alignment: .topLeading, content: {
                if hasActiveItems {
                    Text("\(activeItemsCount)")
                        .fuzzyBubblesFont(16, weight: .bold)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeItemsCount)
                        .foregroundColor(.black)
                        .frame(width: 25, height: 25)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                        )
                        .offset(x: -8, y: -4)
                        .scaleEffect(manageCartButtonVisible ? 1 : 0)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.6),
                            value: manageCartButtonVisible
                        )
                }
            })
            .scaleEffect(manageCartButtonVisible ? buttonScale : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: manageCartButtonVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
            .padding(.bottom, 20)
    }
}
