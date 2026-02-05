//
//  RectKey.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/14/25.
//

import SwiftUI

import SwiftUI

struct RectKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension View {
    @ViewBuilder
    func rect(completion: @escaping (CGRect) -> ()) -> some View {
        self
            .overlay {
                GeometryReader {
                    let rect = $0.frame(in: .scrollView(axis: .horizontal))
                    
                    Color.clear
                        .preference(key: RectKey.self, value: rect)
                        .onPreferenceChange(RectKey.self, perform: completion)
                }
            }
    }

    @ViewBuilder
    func rect(in coordinateSpace: CoordinateSpace, completion: @escaping (CGRect) -> ()) -> some View {
        self
            .overlay {
                GeometryReader {
                    let rect = $0.frame(in: coordinateSpace)

                    Color.clear
                        .preference(key: RectKey.self, value: rect)
                        .onPreferenceChange(RectKey.self, perform: completion)
                }
            }
    }
}
