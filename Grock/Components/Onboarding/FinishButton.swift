//import SwiftUI
//
//struct FinishButton: View {
//    let isFormValid: Bool
//    let action: () -> Void
//
//    var body: some View {
//        HStack {
//            Spacer()
//            FormCompletionButton.finishButton(isEnabled: isFormValid, action: action)
//        }
//    }
//}

import SwiftUI

struct FinishButton: View {
    let isFormValid: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            FormCompletionButton.finishButton(isEnabled: isFormValid, action: action)
        }
//        .opacity(isFormValid ? 1.0 : 0.7) // Visual feedback when invalid
    }
}
