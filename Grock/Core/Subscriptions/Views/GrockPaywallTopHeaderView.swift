import SwiftUI

struct GrockPaywallTopHeaderView: View {
    var body: some View {
            Text("Grock Pro")
                .fuzzyBubblesFont(38, weight: .bold)
                .foregroundStyle(.black)
    }
}

#Preview {
    GrockPaywallTopHeaderView()
        .padding()
        .background(Color.Grock.surfaceMuted)
}
