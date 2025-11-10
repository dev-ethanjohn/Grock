//
//  RemoveButton.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/6/25.
//

import SwiftUI

struct RemoveButton : View {
    let text: String
    // add action
    var body: some View {
        Button {
            
        } label: {
            Text(text)
                .font(.subheadline)
                .bold()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.black)
    }
}

#Preview {
    RemoveButton(text: "Remove from Vault")
        .padding()
        
}
