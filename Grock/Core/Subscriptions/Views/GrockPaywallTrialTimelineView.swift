import SwiftUI

struct GrockPaywallTrialTimelineView: View {
    let items: [GrockPaywallTimelineItem]
    let summaryText: String

    private let markerDiameter: CGFloat = 48
    private let connectorWidth: CGFloat = 3

    private let timelineGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: "F6D95F").opacity(0.95), location: 0.0),
            .init(color: Color(hex: "8BCF5F").opacity(0.90), location: 0.5),
            .init(color: Color(hex: "75B8FF").opacity(0.80), location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    private func markerTint(for index: Int) -> Color {
        switch index {
        case 0:  return Color(hex: "F6D95F")
        case 1:  return Color(hex: "8BCF5F")
        default: return Color(hex: "75B8FF")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("How your free trial works")
                .lexend(.title2, weight: .bold)
                .lineSpacing(1)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .center)

            TimelineBodyView(
                items: items,
                summaryText: summaryText,
                markerDiameter: markerDiameter,
                connectorWidth: connectorWidth,
                timelineGradient: timelineGradient,
                markerTint: markerTint
            )
        }
    }
}

private struct TimelineBodyView: View {
    let items: [GrockPaywallTimelineItem]
    let summaryText: String
    let markerDiameter: CGFloat
    let connectorWidth: CGFloat
    let timelineGradient: LinearGradient
    let markerTint: (Int) -> Color

    @State private var circleCentres: [Int: CGFloat] = [:]

    var body: some View {
        ZStack(alignment: .topLeading) {

            // ── Single continuous gradient line drawn behind all circles ──
            if circleCentres.count == items.count,
               let firstY = circleCentres[0],
               let lastY  = circleCentres[items.count - 1],
               lastY > firstY {

                timelineGradient
                    .frame(width: connectorWidth, height: lastY - firstY - 8)
                    // position: centre of the line segment
                    .position(
                        x: markerDiameter / 2,
                        y: firstY + (lastY - firstY) / 2
                    )
            }

            // ── Row items (circles + text) ────────────────────────────────
            VStack(alignment: .leading, spacing: 28) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    HStack(alignment: .top, spacing: 14) {

                        let tint = markerTint(index)
                        let isReminderStep = items.count > 2 && index == items.count - 2
                        let isChargeStep = index == items.count - 1

                        ZStack {
                            Circle()
                                .fill(Color(hex: "F5F0F0"))
                                .frame(width: markerDiameter, height: markerDiameter)

                            if isChargeStep {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            stops: [
                                                .init(color: tint.opacity(0.2), location: 0.0),
                                                .init(color: tint.opacity(0.16), location: 0.3),
                                                .init(color: tint.opacity(0), location: 1.0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                    )
                                    
                                    .frame(width: markerDiameter, height: markerDiameter)
                            } else {
                                Circle()
                                    .fill(tint.opacity(0.2))
                                    .frame(width: markerDiameter, height: markerDiameter)
                            }

                            //MARK: Stroke ring
                            if isReminderStep {
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            stops: [
                                                .init(color: tint.opacity(1.0), location: 0.0),
                                                .init(color: tint.opacity(0.55), location: 0.55),
                                                .init(color: tint.opacity(0.0), location: 1.0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 1.5
                                    )
                                    .frame(width: markerDiameter, height: markerDiameter)
                            } else if !isChargeStep {
                                Circle()
                                    .stroke(tint.opacity(0.70), lineWidth: 1.5)
                                    .frame(width: markerDiameter, height: markerDiameter)
                            }

                            Text(item.emoji)
                                .font(.system(size: 20))
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        let frame = geo.frame(in: .named("timeline"))
                                        circleCentres[index] = frame.midY
                                    }
                                    .onChange(of: geo.size) {
                                        let frame = geo.frame(in: .named("timeline"))
                                        circleCentres[index] = frame.midY
                                    }
                            }
                        )
                        .zIndex(1)

                        //MARK: Text
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .lexend(.headline, weight: .medium)
                                .foregroundColor(.black)

                            Text(index == 0 ? summaryText : item.subtitle)
                                .lexend(.footnote, weight: .medium)
                                .foregroundColor(Color.black.opacity(0.6))
                                .lineSpacing(1)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, (markerDiameter - 28) / 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .zIndex(0)
            
        }
        .padding(20)
//        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//        .background(
//            RoundedRectangle(cornerRadius: 20, style: .continuous)
//                .fill(.white)
//                .shadow(color: Color.black.opacity(0.16), radius: 4, x: 0, y: 1)
//        )
        .coordinateSpace(name: "timeline")
    }
}

#Preview {
    GrockPaywallTrialTimelineView(
        items: GrockPaywallPreviewFixtures.timelineItems,
        summaryText: "Unlimited free access for 7 days, then ₱5,990.00/year. Cancel anytime."
    )
    .padding()
}
