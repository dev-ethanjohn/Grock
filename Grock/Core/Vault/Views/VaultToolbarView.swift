import SwiftUI

struct VaultToolbarView: View {
    
    @Binding var toolbarAppeared: Bool
    var onAddTapped: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {}) {
                Image("search")
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            .scaleEffect(toolbarAppeared ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0).delay(0.15), value: toolbarAppeared)
            
            Spacer()
            
            Text("vault")
                .lexendFont(18, weight: .bold)
            
            Spacer()
            
            Text("Add")
                .fuzzyBubblesFont(13, weight: .bold)
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.black)
                .cornerRadius(20)
                .onTapGesture {
                    // NOTE: Add scale animate / any better animate interaction on tap of the "add button"
                    onAddTapped()
                }
                .scaleEffect(toolbarAppeared ? 1 : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0).delay(0.2), value: toolbarAppeared)

        }
        .padding()
    }
}

//#Preview {
//    VaultToolbarView()
//}
