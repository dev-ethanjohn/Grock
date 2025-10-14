//
//  CustomPopView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/13/25.
//

import SwiftUI

struct CustomPopView<ModalContent: View>: ViewModifier {
    
    @Binding var isPresented: Bool
    let modalContent: ModalContent
    @State private var isAnimate = false
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                if isAnimate {
                    modalContent
                        .transition(.scale)
                } else {
                    ZStack {}
                        .presentationBackground(.clear)
                }
            }
            .transaction { transaction in
                transaction.disablesAnimations = true
            }
            .onChange(of: isPresented) { _, newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    withAnimation(.bouncy) {
                        isAnimate = newValue
                    }
                }
            }
    }
}

extension View {
    func popView<ModalContent: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> ModalContent
    ) -> some View {
        self.modifier(CustomPopView(isPresented: isPresented, modalContent: content()))
    }
}

