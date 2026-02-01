import SwiftUI

struct CompletionActionsView: View {
    let onFinish: () -> Void
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            FormCompletionButton(
                title: "Finish and Save Trip",
                isEnabled: true,
                cornerRadius: 100,
                verticalPadding: 12,
                maxRadius: 1000,
                bounceScale: (0.98, 1.05, 1.0),
                bounceTiming: (0.1, 0.3, 0.3),
                maxWidth: true,
                action: onFinish
            )
            .frame(maxWidth: .infinity)
            
            Button(action: onContinue, label: {
                Text("Continue Shopping")
                    .fuzzyBubblesFont(14, weight: .bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(100)
                    .overlay {
                        Capsule()
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    }
            })
        }
        .background(Color.clear)
    }
}

#Preview("CompletionActionsView") {
    CompletionActionsView(
        onFinish: {},
        onContinue: {}
    )
    .padding()
    .background(Color.white)
}
