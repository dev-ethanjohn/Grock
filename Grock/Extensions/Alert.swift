//
//  Alert.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 1/3/26.
//

import SwiftUI

// Add this extension somewhere in your utility files
//extension View {
//    func confirmationAlert(
//        title: String,
//        message: String,
//        isPresented: Binding<Bool>,
//        confirmAction: @escaping () -> Void,
//        cancelAction: (() -> Void)? = nil
//    ) -> some View {
//        self.alert(title, isPresented: isPresented) {
//            Button("Cancel", role: .cancel) {
//                cancelAction?()
//            }
//            Button("Remove", role: .destructive) {
//                confirmAction()
//            }
//        } message: {
//            Text(message)
//        }
//    }
//}

extension View {
    func confirmationAlert<T: Identifiable>(
        title: String,
        message: @escaping (T) -> String,
        item: Binding<T?>,
        confirmAction: @escaping (T) -> Void,
        cancelAction: (() -> Void)? = nil
    ) -> some View {
        self.alert(
            title,
            isPresented: .constant(item.wrappedValue != nil),
            presenting: item.wrappedValue
        ) { value in
            Button("Remove", role: .destructive) {
                confirmAction(value)
                item.wrappedValue = nil
            }
            Button("Cancel", role: .cancel) {
                cancelAction?()
                item.wrappedValue = nil
            }
        } message: { value in
            Text(message(value))
        }
    }
}
