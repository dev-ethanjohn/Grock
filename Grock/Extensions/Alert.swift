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

import SwiftUI
import Observation

// Create a global or shared alert state manager using Observation
@Observable
class AlertManager {
    static let shared = AlertManager()
    
    var showAlert = false
    var alertTitle = ""
    var alertMessage = ""
    var confirmAction: (() -> Void)?
    
     init() {}
    
    func showDeleteAlert(for itemName: String, confirmAction: @escaping () -> Void) {
        alertTitle = "Remove Item"
        alertMessage = "Remove '\(itemName)' from your shopping list?"
        self.confirmAction = confirmAction
        showAlert = true
    }
    
    func confirm() {
        confirmAction?()
        reset()
    }
    
    func cancel() {
        reset()
    }
    
    func reset() {
        confirmAction = nil
        showAlert = false
        alertTitle = ""
        alertMessage = ""
    }
}
