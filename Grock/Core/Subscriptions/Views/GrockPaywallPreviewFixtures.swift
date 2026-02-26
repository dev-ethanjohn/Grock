import Foundation

enum GrockPaywallPreviewFixtures {
    static let features: [GrockPaywallFeature] = [
        .init(
            id: "categories",
            title: "Unlimited Categories",
            subtitle: "Free: Default only",
            body: "Organize groceries your way.",
            systemImage: "square.grid.2x2.fill",
            videoResourceName: "custom_categories"
        ),
        .init(
            id: "backgrounds",
            title: "Photo Backgrounds",
            subtitle: "Free: Basic colors",
            body: "Make every cart feel personal.",
            systemImage: "photo.on.rectangle.angled",
            videoResourceName: "photo_backgrounds"
        ),
        .init(
            id: "active-carts",
            title: "Multiple Active Carts",
            subtitle: "Free: 1 cart only",
            body: "Plan without limits.",
            systemImage: "cart.fill",
            videoResourceName: "multi_active_carts"
        ),
        .init(
            id: "stores",
            title: "Unlimited Store Comparison",
            subtitle: "Free: 1 store max",
            body: "Find the cheapest option fast.",
            systemImage: "storefront.fill",
            videoResourceName: "unlimited_stores"
        )
    ]

    static let timelineItems: [GrockPaywallTimelineItem] = [
        .init(
            id: "today",
            title: "Today",
            subtitle: "Unlimited free access to all Grock Pro features.",
            emoji: "🎁"
        ),
        .init(
            id: "day-5",
            title: "Day 5",
            subtitle: "Get a reminder that your 7-day trial is about to end.",
            emoji: "📬"
        ),
        .init(
            id: "day-7",
            title: "Day 7",
            subtitle: "You’ll be charged on May 17, 2026. Cancel anytime before Day 7.",
            emoji: "💳"
        )
    ]

    static let yearlyPlan = GrockPaywallPlanCardModel(
        id: .yearly,
        title: "Yearly",
        price: "$39.99",
        cadence: "/yr",
        detail: "Only $3.33/mo",
        badge: "SAVE 40%",
        isEnabled: true
    )

    static let monthlyPlan = GrockPaywallPlanCardModel(
        id: .monthly,
        title: "Monthly",
        price: "$6.99",
        cadence: "/mo",
        detail: "About $1.61/week",
        badge: nil,
        isEnabled: true
    )
}
