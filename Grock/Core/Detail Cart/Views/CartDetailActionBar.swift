import SwiftUI

struct CartDetailActionBar: View {
    let showFinishTrip: Bool
    let onManageCart: () -> Void
    let onFinishTrip: () -> Void
    let namespace: Namespace.ID
    
    @State private var buttonScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 6) {
            if showFinishTrip {
                Spacer()
                    .frame(width: 44)
                    .opacity(0)
            }
            
            if showFinishTrip {
                Button(action: {
                    animateButtonTap()
                    onFinishTrip()
                }) {
                    Text("Finish Trip")
                        .fuzzyBubblesFont(16, weight: .bold)
                        .foregroundColor(.white)
                        .fixedSize()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color.black)
                )
                .transition(
                    .scale(scale: 0.5, anchor: .center)
//                    .combined(with: .opacity)
                )
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showFinishTrip)
            }
            
            Button(action: {
                animateButtonTap()
                onManageCart()
            }) {
                ZStack {
                    if !showFinishTrip {
                        Text("Manage Cart")
                            .fuzzyBubblesFont(16, weight: .bold)
                            .foregroundColor(.white)
                            .fixedSize()
                            .matchedGeometryEffect(id: "buttonContent", in: namespace)
                            .transition(.opacity)
                    } else {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                            .matchedGeometryEffect(id: "buttonContent", in: namespace)
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, showFinishTrip ? 2 : 24)
                .frame(width: showFinishTrip ? 44 : nil, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: showFinishTrip ? 100 : 25)
                        .fill(showFinishTrip ? Color.black.opacity(0.1) : Color.black)
                        .matchedGeometryEffect(id: "buttonBackground", in: namespace)
                )
                .scaleEffect(buttonScale)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.65), value: showFinishTrip)
        }
    }
    
    private func animateButtonTap() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            buttonScale = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                buttonScale = 1.0
            }
        }
    }
}


