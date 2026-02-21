import SwiftUI

struct GrockPaywallTrialTimelineView: View {
    let items: [GrockPaywallTimelineItem]
    let summaryText: String

    var body: some View {
        let markerHeight = CGFloat(max(188, (items.count - 1) * 72 + 34))

        VStack(alignment: .leading, spacing: 16) {
            Text("How your free trial works")
                .lexend(.title3, weight: .semibold)
                .foregroundColor(.black)

            HStack(alignment: .top, spacing: 14) {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "70D4B8"),
                                    Color(hex: "73B9E5"),
                                    Color(hex: "D5D9FB")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 16, height: markerHeight)

                    VStack(spacing: 42) {
                        ForEach(items) { item in
                            Image(systemName: item.systemImage)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "1F7DBF"))
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.98))
                                        .overlay(
                                            Circle()
                                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.top, 2)
                }
                .frame(width: 32, alignment: .center)

                VStack(alignment: .leading, spacing: 18) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .lexend(.title3, weight: .semibold)
                                .foregroundColor(.black)

                            Text(item.subtitle)
                                .lexend(.body, weight: .regular)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Text(summaryText)
                .lexend(.body, weight: .regular)
                .foregroundColor(.black.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    GrockPaywallTrialTimelineView(
        items: GrockPaywallPreviewFixtures.timelineItems,
        summaryText: "Unlimited free access for 7 days, then $39.99/yr ($3.33/mo)."
    )
    .padding()
    .background(Color.Grock.surfaceMuted)
}
