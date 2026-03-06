import Foundation

enum GrockPaywallFeatureFocus: String, CaseIterable {
    case categories = "categories"
    case backgrounds = "backgrounds"
    case activeCarts = "active-carts"
    case stores = "stores"
}

enum ProUnlockCelebrationContext: String, CaseIterable {
    case customUnits = "custom-units"
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
    let isPriceLoading: Bool

    init(
        id: Plan,
        title: String,
        price: String,
        cadence: String,
        detail: String,
        badge: String?,
        isEnabled: Bool,
        isPriceLoading: Bool = false
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.cadence = cadence
        self.detail = detail
        self.badge = badge
        self.isEnabled = isEnabled
        self.isPriceLoading = isPriceLoading
    }
}

struct GrockPaywallTimelineItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let emoji: String
}
