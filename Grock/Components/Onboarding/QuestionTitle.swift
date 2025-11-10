//
//  QuestionTitle.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/6/25.
//

import SwiftUI

struct QuestionTitle: View {
    let text: String
    
    var body: some View {
        Text(text)
            .fuzzyBubblesFont(22, weight: .bold)
            .frame(maxWidth: UIScreen.main.bounds.width * 0.8)
            .multilineTextAlignment(.center)
            
    }
}

#Preview {
    QuestionTitle(text: "Where was your last grocery trip?")
}
