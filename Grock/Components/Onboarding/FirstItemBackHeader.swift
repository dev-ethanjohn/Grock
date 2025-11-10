//
//  FirstItemBackHeader.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/6/25.
//

import SwiftUI

struct FirstItemBackHeader: View {
    
    let onBack: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onBack) {
                Image("back")
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

#Preview {
    FirstItemBackHeader(onBack: {})
}
