import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class GrockPaywallViewModel {
    let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    let privacyURL = URL(string: "https://grock.app/privacy")!
    private let fallbackTrialDays = 7

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
            videoResourceName: "custom_background"
        ),
        .init(
            id: "active-carts",
            title: "Multiple Active Trips",
            subtitle: "Free: 1 cart only",
            body: "Plan without limits.",
            systemImage: "cart.fill",
            videoResourceName: nil
        ),
        .init(
            id: "stores",
            title: "Unlimited Store Comparison",
            subtitle: "Free: 2 stores max",
            body: "Find the cheapest option fast.",
            systemImage: "storefront.fill",
            videoResourceName: nil
        )
    ]

    var planCards: [GrockPaywallPlanCardModel] {
        [yearlyModel, monthlyModel]
    }

    var isPrimaryActionEnabled: Bool {
        !isProcessingAction && selectedPackage != nil
    }

    var primaryButtonTitle: String {
        if isProcessingAction {
            return "Processing..."
        }

        guard selectedPackage != nil else {
            return "Unavailable"
        }

        let trialDays = selectedTrialDays
        let dayUnit = trialDays == 1 ? "Day" : "Days"
        return "Start \(trialDays)-\(dayUnit) Free Trial"
    }

    var trialTimelineItems: [GrockPaywallTimelineItem] {
        [
            .init(
                id: "today",
                title: "Today",
                subtitle: "Get instant access to all Grock Pro features.",
                systemImage: "lock.fill"
            ),
            .init(
                id: "reminder",
                title: "Day \(reminderDay)",
                subtitle: "We’ll remind you that your trial is ending soon.",
                systemImage: "bell.fill"
            ),
            .init(
                id: "charge",
                title: "Day \(selectedTrialDays)",
                subtitle: "You’ll be charged on \(trialChargeDateString). Cancel anytime before.",
                systemImage: "star.fill"
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
            return "Unlimited free access for \(trialDays) days, then \(price)/mo."
        }
    }

    func refreshAll() async {
        await subscriptionManager.refreshAll()
        alignDefaultPlanToAvailability()
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
        trialDurationDays(for: selectedPackage)
            ?? trialDurationDays(for: subscriptionManager.yearlyPackage)
            ?? trialDurationDays(for: subscriptionManager.monthlyPackage)
            ?? fallbackTrialDays
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

    private func trialDurationDays(for package: Package?) -> Int? {
        guard let discount = package?.storeProduct.introductoryDiscount,
              discount.paymentMode == .freeTrial else {
            return nil
        }

        let period = discount.subscriptionPeriod
        switch period.unit {
        case .day:
            return period.value
        case .week:
            return period.value * 7
        case .month:
            return period.value * 30
        case .year:
            return period.value * 365
        @unknown default:
            return nil
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
