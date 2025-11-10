//
//  VaultToolbarView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/5/25.
//

import SwiftUI

struct VaultToolbarView: View {
    @Binding var toolbarAppeared: Bool
    var onAddTapped: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {}) {
                Image("search")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            .scaleEffect(toolbarAppeared ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0).delay(0.15), value: toolbarAppeared)
            
            Spacer()
            
            Text("vault")
                .lexendFont(18, weight: .bold)
            
            Spacer()
            
            Button(action: onAddTapped) {
                Text("Add")
                    .fuzzyBubblesFont(13, weight: .bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black)
                    .cornerRadius(20)
            }
            .scaleEffect(toolbarAppeared ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0).delay(0.2), value: toolbarAppeared)
        }
        .padding()
    }
}

//#Preview {
//    VaultToolbarView()
//}
