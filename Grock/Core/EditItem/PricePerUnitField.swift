//
//  PricePerUnit.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/17/25.
//

import SwiftUI

struct PricePerUnitField: View {
    //TODO: Rearrange + put in a veiw model.
    @Binding var price: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Text("Price/unit")
                .font(.footnote)
                .foregroundColor(.gray)
            Spacer()
            
            HStack(spacing: 4) {
                Text("₱")
                    .font(.system(size: 16))
                    .foregroundStyle(price.isEmpty ? .gray : .black)
                
                Text(price.isEmpty ? "0" : price)
                    .foregroundStyle(price.isEmpty ? .gray : .black)
                    .scalableText()
                    .overlay(
                        TextField("0", text: $price)
                            .scalableText()
                            .keyboardType(.decimalPad)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.never)
                            .numbersOnly($price, includeDecimal: true, maxDigits: 5)
                            .focused($isFocused)
                            .opacity(isFocused ? 1 : 0)
                    )
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }
}

//#Preview {
//    PricePerUnit()
//}
