import SwiftUI

struct ProWelcomeSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    
                    Text("Hello friend,")
                    
                    Text("If managing grocery spending ever feels confusing, overwhelming, or just tiring — there’s nothing wrong with you.")
                    Text("I used to shop carefully, but still leave wondering if I spent too much. Prices change, some items are out of stock, and I often have to adjust my plans or budget on the spot. Most of the time, I was just trying my best while figuring out what things would actually cost.")
                    
                    Text("I built Grock because I needed a calmer, clearer way to understand my own spending — not to be perfect, but to notice patterns, remember what really costs what, and feel a little more confident each time I shopped.")
                    
                    Text("I wanted to share something with you: 2 days of Grock Pro — a small gift from me. No strings, no pressure, just a chance to see if it makes shopping feel a little lighter, the way it did for me.")
                    
                    Text("Thank you for being here.")

                }
                .multilineTextAlignment(.center)
                .fuzzyBubblesFont(14, weight: .bold)
                .padding(.horizontal)
                .padding(.top, 32)
            }
            
            Button {
                isPresented = false
            } label: {
                Text("Thanks!")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .presentationDetents([.large])
        .presentationCornerRadius(24)
        .onDisappear {
            UserDefaults.standard.hasSeenProWelcome = true
        }
    }
}

#Preview {
    Color.gray.sheet(isPresented: .constant(true)) {
        ProWelcomeSheet(isPresented: .constant(true))
    }
}
