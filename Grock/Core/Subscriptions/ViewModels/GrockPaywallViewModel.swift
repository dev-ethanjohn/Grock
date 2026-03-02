import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class GrockPaywallViewModel {
    private let yearlyTrialDays = 7

    var selectedPlan: GrockPaywallPlanCardModel.Plan = .yearly
    var isProcessingAction = false
    var showAlert = false
    var alertMessage = ""

    private let subscriptionManager: SubscriptionManager

    private static let chargeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    init(subscriptionManager: SubscriptionManager = .shared) {
        self.subscriptionManager = subscriptionManager
    }

    // Ordered by strongest user demand/pain first.
    let features: [GrockPaywallFeature] = [
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

    var planCards: [GrockPaywallPlanCardModel] {
        [yearlyModel, monthlyModel]
    }

    var isPrimaryActionEnabled: Bool {
        !isProcessingAction && selectedPackage != nil
    }

    var showsTrialMessaging: Bool {
        selectedPlan == .yearly
    }

    var primaryButtonTitle: String {
        if isProcessingAction {
            return "Processing..."
        }

        guard selectedPackage != nil else {
            return "Unavailable"
        }

        if !showsTrialMessaging {
            return "Get Grock Pro"
        }

        let trialDays = selectedTrialDays
        let dayUnit = trialDays == 1 ? "Day" : "Days"
        return "Start \(trialDays)-\(dayUnit) Free Trial"
    }

    var shouldShowOfferingsLoadingState: Bool {
        subscriptionManager.isLoadingOfferings && !hasAnyAvailablePackage
    }

    var shouldShowOfferingsUnavailableState: Bool {
        !subscriptionManager.isLoadingOfferings
        && !hasAnyAvailablePackage
        && subscriptionManager.hasLoadedAtLeastOnce
    }

    var offeringsUnavailableTitle: String {
        isLikelyNetworkIssue ? "No internet connection" : "Unable to load plans"
    }

    var offeringsUnavailableMessage: String {
        if isLikelyNetworkIssue {
            return "We couldn't load Grock Pro plans. Check your connection and try again."
        }

        if let message = subscriptionManager.lastErrorMessage,
           !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message
        }

        return "We couldn't load Grock Pro plans right now. Please try again."
    }

    var shouldShowConnectionWarningBanner: Bool {
        hasAnyAvailablePackage && isLikelyNetworkIssue
    }

    var connectionWarningMessage: String {
        "You're offline. Showing last available plans."
    }

    var trialTimelineItems: [GrockPaywallTimelineItem] {
        [
            .init(
                id: "today",
                title: "Today",
                subtitle: "Unlimited free access to all Grock Pro features.",
                emoji: "💎"
            ),
            .init(
                id: "reminder",
                title: "Day \(reminderDay)",
                subtitle: "Get a reminder that your \(selectedTrialDays)-day trial is about to end.",
                emoji: "📬"
            ),
            .init(
                id: "charge",
                title: "Day \(selectedTrialDays)",
                subtitle: "You’ll be charged on \(trialChargeDateString). Cancel anytime before Day \(selectedTrialDays).",
                emoji: "💳"
            )
        ]
    }

    var selectedPlanSummaryText: String {
        guard let package = selectedPackage else {
            return "Products are loading. Please wait a moment."
        }

        let price = displayedPrice(for: package)
        let trialDays = selectedTrialDays

        switch selectedPlan {
        case .yearly:
            if let monthlyEquivalent = yearlyMonthlyEquivalentText {
                return "Unlimited free access for \(trialDays) days, then \(price)/yr (\(monthlyEquivalent)/mo)."
            }
            return "Unlimited free access for \(trialDays) days, then \(price)/yr."

        case .monthly:
            return "Unlock all Grock Pro features for \(price)/mo."
        }
    }

    func refreshAll() async {
        await subscriptionManager.refreshAll()
        alignDefaultPlanToAvailability()
    }

    func retryOfferingsLoad() async {
        await refreshAll()
    }

    func purchaseSelectedPlan() async -> Bool {
        if isProcessingAction {
            return false
        }

        guard let selectedPackage else {
            setAlert("Products are not available yet. Please try again shortly.")
            return false
        }

        isProcessingAction = true
        defer { isProcessingAction = false }

        let result = await subscriptionManager.purchase(package: selectedPackage)

        switch result {
        case .success:
            if subscriptionManager.isPro {
                return true
            }
            setAlert("Purchase finished, but Grock Pro entitlement is not active yet.")
            return false

        case .cancelled:
            return false

        case .failure(let message):
            if message.localizedCaseInsensitiveContains("already in progress") {
                return false
            }
            setAlert(message)
            return false
        }
    }
    
    func restorePurchases() async -> Bool {
        if isProcessingAction {
            return false
        }

        isProcessingAction = true
        defer { isProcessingAction = false }

        let result = await subscriptionManager.restorePurchases()

        switch result {
        case .success:
            if subscriptionManager.isPro {
                return true
            }
            setAlert("Restore completed, but no active Grock Pro entitlement was found.")
            return false

        case .cancelled:
            return false

        case .failure(let message):
            if message.localizedCaseInsensitiveContains("already in progress") {
                return false
            }
            setAlert(message)
            return false
        }
    }

    private var selectedPackage: Package? {
        switch selectedPlan {
        case .monthly:
            return subscriptionManager.monthlyPackage
        case .yearly:
            return subscriptionManager.yearlyPackage
        }
    }

    private var hasAnyAvailablePackage: Bool {
        subscriptionManager.monthlyPackage != nil || subscriptionManager.yearlyPackage != nil
    }

    private var isLikelyNetworkIssue: Bool {
        let message = (subscriptionManager.lastErrorMessage ?? "").lowercased()
        guard !message.isEmpty else { return false }

        let offlineMarkers = [
            "internet",
            "offline",
            "network",
            "timed out",
            "timeout",
            "could not connect",
            "not connected"
        ]

        return offlineMarkers.contains(where: { message.contains($0) })
    }

    private var monthlyModel: GrockPaywallPlanCardModel {
        let monthlyPrice = displayedPrice(for: subscriptionManager.monthlyPackage)
        let detail = monthlyWeeklyEquivalentText.map { "About \($0)/week" } ?? "Billed monthly."

        return .init(
            id: .monthly,
            title: "Monthly",
            price: monthlyPrice,
            cadence: "/mo",
            detail: detail,
            badge: nil,
            isEnabled: subscriptionManager.monthlyPackage != nil
        )
    }

    private var yearlyModel: GrockPaywallPlanCardModel {
        let yearlyPrice = displayedPrice(for: subscriptionManager.yearlyPackage)
        let detail = yearlyMonthlyEquivalentText.map { "Only \($0)/mo" } ?? "Billed yearly."

        return .init(
            id: .yearly,
            title: "Yearly",
            price: yearlyPrice,
            cadence: "/yr",
            detail: detail,
            badge: yearlyBadgeText,
            isEnabled: subscriptionManager.yearlyPackage != nil
        )
    }

    private var yearlyMonthlyEquivalentText: String? {
        guard let yearlyProduct = subscriptionManager.yearlyPackage?.storeProduct,
              let pricePerMonth = yearlyProduct.pricePerMonth else {
            return nil
        }

        return formattedPrice(pricePerMonth, formatter: yearlyProduct.priceFormatter)
    }

    private var monthlyWeeklyEquivalentText: String? {
        guard let monthlyProduct = subscriptionManager.monthlyPackage?.storeProduct else {
            return nil
        }

        // Convert monthly subscription cost to an approximate weekly spend for clearer shopper context.
        let weeksPerMonth = NSDecimalNumber(value: 52.0 / 12.0)
        let pricePerWeek = monthlyProduct.priceDecimalNumber.dividing(by: weeksPerMonth)
        return formattedPrice(pricePerWeek, formatter: monthlyProduct.priceFormatter)
    }

    private var yearlyBadgeText: String? {
        guard let yearlyPrice = subscriptionManager.yearlyPackage?.storeProduct.priceDecimalNumber,
              let monthlyPrice = subscriptionManager.monthlyPackage?.storeProduct.priceDecimalNumber else {
            return nil
        }

        let monthlyYearCost = monthlyPrice.multiplying(by: NSDecimalNumber(value: 12))
        guard monthlyYearCost.doubleValue > 0 else { return nil }

        let savingsRatio = max(0, (monthlyYearCost.doubleValue - yearlyPrice.doubleValue) / monthlyYearCost.doubleValue)
        let percent = Int((savingsRatio * 100).rounded())
        guard percent >= 5 else { return nil }

        return "SAVE \(percent)%"
    }

    private var selectedTrialDays: Int {
        yearlyTrialDays
    }

    private var reminderDay: Int {
        max(2, selectedTrialDays - 2)
    }

    private var trialChargeDate: Date {
        Calendar.current.date(byAdding: .day, value: selectedTrialDays, to: Date()) ?? Date()
    }

    private var trialChargeDateString: String {
        Self.chargeDateFormatter.string(from: trialChargeDate)
    }

    private func alignDefaultPlanToAvailability() {
        if selectedPlan == .yearly, subscriptionManager.yearlyPackage == nil, subscriptionManager.monthlyPackage != nil {
            selectedPlan = .monthly
        } else if selectedPlan == .monthly, subscriptionManager.monthlyPackage == nil, subscriptionManager.yearlyPackage != nil {
            selectedPlan = .yearly
        }
    }

    private func setAlert(_ message: String) {
        alertMessage = message
        if !showAlert {
            showAlert = true
        }
    }

    private func formattedPrice(_ value: NSDecimalNumber, formatter: NumberFormatter?) -> String? {
        guard let formatter else { return nil }
        guard let formattedPrice = formatter.string(from: value) else { return nil }
        return stripCurrencyAbbreviationPrefix(from: formattedPrice)
    }

    private func displayedPrice(for package: Package?) -> String {
        guard let package else { return "--" }
        return stripCurrencyAbbreviationPrefix(from: package.storeProduct.localizedPriceString)
    }

    private func stripCurrencyAbbreviationPrefix(from price: String) -> String {
        // Convert values like "US$79.99" to "$79.99" while preserving symbols like "€" or "R$".
        price.replacingOccurrences(
            of: #"^[A-Z]{2,3}\s*(?=\p{Sc})"#,
            with: "",
            options: .regularExpression
        )
    }
}
