import SwiftUI

struct GrockPaywallFeatureTabsView: View {
    let features: [GrockPaywallFeature]
    @Binding var selectedIndex: Int
    let onManualSelect: () -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        Button {
                            onManualSelect()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                selectedIndex = index
                            }
                        } label: {
                            Text(feature.title)
                                .lexend(.caption, weight: .semibold)
                                .foregroundColor(selectedIndex == index ? .white : .black.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedIndex == index ? Color.black : Color.white.opacity(0.85))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.black.opacity(selectedIndex == index ? 0 : 0.08), lineWidth: 1)
                                        )
                                )
                        }
                        .id(index)
                    }
                }
                .padding(.horizontal, 2)
            }
            .onChange(of: selectedIndex) { _, newIndex in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newIndex, anchor: .center)
                }
            }
        }
    }
}

private struct GrockPaywallFeatureTabsPreview: View {
    @State private var selectedIndex = 0

    var body: some View {
        GrockPaywallFeatureTabsView(
            features: GrockPaywallPreviewFixtures.features,
            selectedIndex: $selectedIndex,
            onManualSelect: {}
        )
    }
}

#Preview {
    GrockPaywallFeatureTabsPreview()
        .padding()
        .background(Color.Grock.surfaceMuted)
}
