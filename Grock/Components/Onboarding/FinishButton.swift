import SwiftUI

struct FinishButton: View {
    let isFormValid: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            FormCompletionButton.finishButton(isEnabled: isFormValid,  cornerRadius: 50, action: action)
        }
    }
}
