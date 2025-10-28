//
//  FilterSheet.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/28/25.
//

import SwiftUI

enum FilterOption: String, CaseIterable {
    case all = "All"
    case fulfilled = "Fulfilled"
    case unfulfilled = "Unfulfilled"
}

struct FilterSheet: View {
    @Binding var selectedFilter: FilterOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Button(action: {
                        selectedFilter = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .foregroundColor(.black)
                            Spacer()
                            if selectedFilter == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filter Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
//#Preview {
//    FilterSheet()
//}
