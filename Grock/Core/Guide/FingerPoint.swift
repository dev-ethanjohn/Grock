//
//  FingerPoint.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/14/25.
//

import SwiftUI

struct FingerPointer: View {
    @State private var animateOffset: CGFloat = 0
    
    var body: some View {
        Text("👉")
            .font(.title2)
            .offset(x: animateOffset)
            .rotationEffect(.degrees(-30))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    animateOffset = 15
                }
            }
    }
}


//#Preview {
//    FingerPoint()
//}
