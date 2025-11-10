//
//  MenuIcon.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/7/25.
//

import SwiftUI

struct MenuIcon: View {
    var onMenuTap: () -> Void

    var body: some View {
        //TODO: replace with a menu <-> exit icon
        VStack(alignment: .leading, spacing: 3) {
            Capsule()
                .frame(width: 14, height: 2.5)
            Capsule()
                .frame(width: 8, height: 2.5)
            Capsule()
                .frame(width: 14, height: 2.5)
        }
        .foregroundColor(.black)
        .frame(width: 14, height: 14)
        .padding(4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onMenuTap)
        
    }
}

#Preview {
    MenuIcon(onMenuTap: {})
}
