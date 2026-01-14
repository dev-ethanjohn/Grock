import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(Color.black.opacity(0.15))
                
                Text("Insights are on the way!")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text("""
                We’re building a place where you can see your spending trends, store patterns, and item memories. It’ll be ready soon!
                """)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                
                Text("In the meantime, your price memory and shopping cart features are still hard at work!")
                    .font(.subheadline)
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.headline.bold())
                        .padding(.horizontal, 48)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                
                Spacer().frame(height: 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "#F9F9F9"))
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
