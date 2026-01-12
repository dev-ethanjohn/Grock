import SwiftUI

struct ProWelcomeSheet: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("If managing grocery spending ever feels confusing, overwhelming, or just tiring — there’s nothing wrong with you.")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text("I used to shop carefully, but still leave wondering if I spent too much. Prices change, some items are out of stock, and I often have to adjust my plans or budget on the spot. Most of the time, I was just trying my best while figuring out what things would actually cost.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Text("I built Grock because I needed a calmer, clearer way to understand my own spending — not to be perfect, but to notice patterns, remember what really costs what, and feel a little more confident each time I shopped.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Text("I wanted to share something with you: 2 days of Grock Pro — a small gift from me. No strings, no pressure, just a chance to see if it makes shopping feel a little lighter, the way it did for me.")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(12)
                    
                    Text("Thank you for being here.")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal)
                .padding(.top, 32)
            }
            
            Button {
                isPresented = false
            } label: {
                Text("Continue")
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
        .presentationDetents([.medium, .large])
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
