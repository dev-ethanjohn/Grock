//
//  ButtonStyles.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/24/25.
//

import SwiftUI

extension ButtonStyle where Self == SolidButtonStyle {
    static var solid: SolidButtonStyle { SolidButtonStyle() }
}

struct SolidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.interactiveSpring(), value: configuration.isPressed)
    }
}

