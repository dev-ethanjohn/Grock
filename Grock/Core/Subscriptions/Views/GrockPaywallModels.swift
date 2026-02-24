import Foundation

enum GrockPaywallFeatureFocus: String, CaseIterable {
    case categories = "categories"
    case backgrounds = "backgrounds"
    case activeCarts = "active-carts"
    case stores = "stores"
}

struct GrockPaywallFeature: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let body: String
    let systemImage: String
    let videoResourceName: String?
}

struct GrockPaywallPlanCardModel: Identifiable, Hashable {
    enum Plan: String, CaseIterable, Identifiable {
        case monthly
        case yearly

        var id: String { rawValue }
    }

    let id: Plan
    let title: String
    let price: String
    let cadence: String
    let detail: String
    let badge: String?
    let isEnabled: Bool
}

struct GrockPaywallTimelineItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let emoji: String
}
