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
    var showRestoreWarningToast = false
    var restoreWarningToastMessage = ""

    private let subscriptionManager: SubscriptionManager
    private let countryContextProvider: PaywallCountryContextProvider
    private var lastLoggedStorefrontSignature: String?

    private static let chargeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    init(
        subscriptionManager: SubscriptionManager = .shared,
        countryContextProvider: PaywallCountryContextProvider = .shared
    ) {
        self.subscriptionManager = subscriptionManager
        self.countryContextProvider = countryContextProvider
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
        !isProcessingAction && selectedPackage != nil && selectedPriceSnapshot != nil
    }

    var isSelectedPlanPriceLoading: Bool {
        selectedPackage != nil && selectedPriceSnapshot == nil
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

        guard selectedPriceSnapshot != nil else {
            return "Loading Price..."
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

        guard let selectedSnapshot = selectedPriceSnapshot else {
            return "Fetching your App Store price..."
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
            return "Unlock all Grock Pro features for \(selectedSnapshot.localizedPriceString)/mo."
        }
    }

    var stickyPanelPrimaryLine: String {
        if isSelectedPlanPriceLoading {
            return "Loading App Store price..."
        }

        logStorefrontSource(reason: "before-sticky-render")
        let template = contextTemplateForCurrentCountry
        switch selectedPlan {
        case .yearly:
            guard let values = yearlyStickyContextValues else {
                return "Loading App Store price..."
            }
            return renderTemplate(template.yearlyPrimary, values: values)
        case .monthly:
            return renderTemplate(template.monthlyPrimary, values: monthlyStickyContextValues)
        }
    }

    var stickyPanelSecondaryLine: String {
        if isSelectedPlanPriceLoading {
            return "Checking your storefront currency."
        }

        logStorefrontSource(reason: "before-sticky-render")
        let template = contextTemplateForCurrentCountry
        switch selectedPlan {
        case .yearly:
            guard let values = yearlyStickyContextValues else {
                return "Checking your storefront currency."
            }
            return renderTemplate(template.yearlySecondary, values: values)
        case .monthly:
            return renderTemplate(template.monthlySecondary, values: monthlyStickyContextValues)
        }
    }

    var isProUser: Bool {
        subscriptionManager.isPro
    }

    func prepareForPresentation() {
        alignDefaultPlanToAvailability()
        logStorefrontSource(reason: "paywall-presented")
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
            presentRestoreWarningToast("No previous purchases were found for this account.")
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
        let isLoadingPrice = subscriptionManager.monthlyPackage != nil && monthlyPriceSnapshot == nil
        let monthlyPrice = monthlyPriceSnapshot?.localizedPriceString ?? "..."
        let detail = monthlyWeeklyEquivalentText.map { "About \($0)/week" } ?? (isLoadingPrice ? "Fetching App Store price..." : "Billed monthly.")

        return .init(
            id: .monthly,
            title: "Monthly",
            price: monthlyPrice,
            cadence: "/mo",
            detail: detail,
            badge: nil,
            isEnabled: subscriptionManager.monthlyPackage != nil,
            isPriceLoading: isLoadingPrice
        )
    }

    private var yearlyModel: GrockPaywallPlanCardModel {
        let isLoadingPrice = subscriptionManager.yearlyPackage != nil && yearlyPriceSnapshot == nil
        let yearlyPrice = yearlyPriceSnapshot?.localizedPriceString ?? "..."
        let detail = yearlyMonthlyEquivalentText.map { "Only \($0)/mo" } ?? (isLoadingPrice ? "Fetching App Store price..." : "Billed yearly.")

        return .init(
            id: .yearly,
            title: "Yearly",
            price: yearlyPrice,
            cadence: "/yr",
            detail: detail,
            badge: yearlyBadgeText,
            isEnabled: subscriptionManager.yearlyPackage != nil,
            isPriceLoading: isLoadingPrice
        )
    }

    private var yearlyMonthlyEquivalentText: String? {
        guard let yearlySnapshot = yearlyPriceSnapshot else {
            return nil
        }

        let monthsPerYear = NSDecimalNumber(value: 12)
        let pricePerMonth = yearlySnapshot.priceDecimalNumber.dividing(by: monthsPerYear)
        return formattedPrice(pricePerMonth, formatter: yearlySnapshot.priceFormatter)
    }

    private var monthlyWeeklyEquivalentText: String? {
        guard let monthlySnapshot = monthlyPriceSnapshot else {
            return nil
        }

        let weeksPerMonth = NSDecimalNumber(value: 4)
        let pricePerWeek = monthlySnapshot.priceDecimalNumber.dividing(by: weeksPerMonth)
        return formattedPrice(pricePerWeek, formatter: monthlySnapshot.priceFormatter)
    }

    private var yearlyBadgeText: String? {
        guard let yearlyPrice = yearlyPriceSnapshot?.priceDecimalNumber,
              let monthlyPrice = monthlyPriceSnapshot?.priceDecimalNumber else {
            return nil
        }

        let monthlyYearCost = monthlyPrice.multiplying(by: NSDecimalNumber(value: 12))
        guard monthlyYearCost.doubleValue > 0 else { return nil }

        let savingsRatio = max(0, (monthlyYearCost.doubleValue - yearlyPrice.doubleValue) / monthlyYearCost.doubleValue)
        let percent = Int((savingsRatio * 100).rounded())
        guard percent >= 5 else { return nil }

        return "SAVE \(percent)%"
    }

    private var yearlyDailyCostText: String? {
        guard let yearlySnapshot = yearlyPriceSnapshot else {
            return nil
        }

        let daysPerYear = NSDecimalNumber(value: 365)
        let dailyCost = yearlySnapshot.priceDecimalNumber.dividing(by: daysPerYear)

        if let formattedDailyCost = formattedPrice(dailyCost, formatter: yearlySnapshot.priceFormatter) {
            return formattedDailyCost
        }

        return nil
    }

    private var yearlyDailyPesoWordText: String? {
        guard let yearlySnapshot = yearlyPriceSnapshot else {
            return nil
        }

        guard yearlySnapshot.currencyCode?.uppercased() == "PHP" else {
            return nil
        }

        let daysPerYear = NSDecimalNumber(value: 365)
        let dailyCost = yearlySnapshot.priceDecimalNumber.dividing(by: daysPerYear)
        let roundedDailyPeso = max(1, Int(dailyCost.doubleValue.rounded()))
        let unitLabel = roundedDailyPeso == 1 ? "peso" : "pesos"
        return "\(roundedDailyPeso) \(unitLabel)"
    }

    private var contextTemplateForCurrentCountry: PaywallCountryContextTemplate {
        countryContextProvider.template(for: detectedStorefrontCountryCode)
    }

    private var detectedStorefrontCountryCode: String? {
        selectedPriceSnapshot?.storefrontCountryCode
            ?? yearlyPriceSnapshot?.storefrontCountryCode
            ?? monthlyPriceSnapshot?.storefrontCountryCode
            ?? Locale.autoupdatingCurrent.region?.identifier.uppercased()
    }

    private var monthlyStickyContextValues: [String: String] {
        let monthlyPrice = monthlyPriceSnapshot?.localizedPriceString ?? "--"
        let yearlyPrice = yearlyPriceSnapshot?.localizedPriceString ?? "--"
        let monthlyWeekly = monthlyWeeklyEquivalentText ?? monthlyPrice

        return [
            "monthly_price": monthlyPrice,
            "monthly_weekly": monthlyWeekly,
            "yearly_price": yearlyPrice
        ]
    }

    private var yearlyStickyContextValues: [String: String]? {
        guard let yearlyPrice = yearlyPriceSnapshot?.localizedPriceString,
              let yearlyMonthly = yearlyMonthlyEquivalentText,
              let yearlyDaily = yearlyDailyCostText else {
            return nil
        }

        var values: [String: String] = [
            "yearly_price": yearlyPrice,
            "monthly": yearlyMonthly,
            "daily": yearlyDaily
        ]

        if let yearlyDailyPesoWord = yearlyDailyPesoWordText {
            values["daily_peso_word"] = yearlyDailyPesoWord
        }

        return values
    }

    private func renderTemplate(_ template: String, values: [String: String]) -> String {
        var rendered = template
        for (token, value) in values {
            rendered = rendered.replacingOccurrences(of: "{{\(token)}}", with: value)
        }

        rendered = rendered.replacingOccurrences(
            of: #"\{\{[A-Za-z0-9_]+\}\}"#,
            with: "",
            options: .regularExpression
        )
        rendered = rendered.replacingOccurrences(
            of: #"\s{2,}"#,
            with: " ",
            options: .regularExpression
        )

        return rendered.trimmingCharacters(in: .whitespacesAndNewlines)
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

    func dismissRestoreWarningToast() {
        showRestoreWarningToast = false
    }

    private func presentRestoreWarningToast(_ message: String) {
        restoreWarningToastMessage = message
        showRestoreWarningToast = true
    }

    private func formattedPrice(_ value: NSDecimalNumber, formatter: NumberFormatter?) -> String? {
        guard let formatter else { return nil }
        guard let formattedPrice = formatter.string(from: value) else { return nil }
        return formattedPrice
    }

    private func formattedWholeCurrencyAmount(
        _ amount: Int,
        formatter: NumberFormatter?,
        currencyCode: String?
    ) -> String? {
        let wholeFormatter = NumberFormatter()
        wholeFormatter.numberStyle = .currency
        wholeFormatter.minimumFractionDigits = 0
        wholeFormatter.maximumFractionDigits = 0
        wholeFormatter.locale = formatter?.locale
        wholeFormatter.currencyCode = formatter?.currencyCode ?? currencyCode

        guard let value = wholeFormatter.string(from: NSNumber(value: amount)) else {
            return nil
        }

        return value
    }

    private func displayedPrice(for package: Package?) -> String {
        guard let snapshot = directPriceSnapshot(for: package) else { return "..." }
        return snapshot.localizedPriceString
    }

    private func logStorefrontSource(reason: String) {
        guard let monthlySnapshot = monthlyPriceSnapshot else { return }
        let signature = "\(monthlySnapshot.localizedPriceString)|\(monthlySnapshot.localeIdentifier)|\(monthlySnapshot.storefrontCountryCode ?? "unknown")|\(monthlySnapshot.source)"

        guard signature != lastLoggedStorefrontSignature else { return }
        lastLoggedStorefrontSignature = signature

        print("ℹ️ [Paywall][\(reason)] monthly localizedPriceString=\(monthlySnapshot.localizedPriceString), priceFormatter.locale=\(monthlySnapshot.localeIdentifier), storefrontRegion=\(monthlySnapshot.storefrontCountryCode ?? "unknown"), source=\(monthlySnapshot.source)")
    }

    private var monthlyPriceSnapshot: PriceSnapshot? {
        directPriceSnapshot(for: subscriptionManager.monthlyPackage)
    }

    private var yearlyPriceSnapshot: PriceSnapshot? {
        directPriceSnapshot(for: subscriptionManager.yearlyPackage)
    }

    private var selectedPriceSnapshot: PriceSnapshot? {
        switch selectedPlan {
        case .monthly:
            return monthlyPriceSnapshot
        case .yearly:
            return yearlyPriceSnapshot
        }
    }

    private func directPriceSnapshot(for package: Package?) -> PriceSnapshot? {
        guard let package else { return nil }
        return priceSnapshot(from: package)
    }

    private func priceSnapshot(from package: Package) -> PriceSnapshot {
        let storeProduct = package.storeProduct
        // RevenueCat's StoreProduct is backed by App Store / StoreKit pricing data.
        let formatter = makePriceFormatter(
            currencyCode: storeProduct.currencyCode,
            localizedPriceString: storeProduct.localizedPriceString
        )

        return PriceSnapshot(
            localizedPriceString: storeProduct.localizedPriceString,
            priceDecimalNumber: NSDecimalNumber(decimal: storeProduct.price),
            priceFormatter: formatter,
            currencyCode: storeProduct.currencyCode,
            storefrontCountryCode: formatter?.locale.region?.identifier.uppercased()
                ?? Locale.autoupdatingCurrent.region?.identifier.uppercased(),
            localeIdentifier: formatter?.locale.identifier ?? Locale.autoupdatingCurrent.identifier,
            source: "storekit-backed-package"
        )
    }

    private func makePriceFormatter(
        currencyCode: String?,
        localizedPriceString: String
    ) -> NumberFormatter? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = preferredLocale(
            currencyCode: currencyCode,
            localizedPriceString: localizedPriceString
        )

        if let currencyCode {
            formatter.currencyCode = currencyCode
        }

        if let symbol = extractedCurrencySymbol(
            from: localizedPriceString,
            currencyCode: currencyCode
        ) {
            formatter.currencySymbol = symbol
        }

        return formatter
    }

    private func preferredLocale(
        currencyCode: String?,
        localizedPriceString: String
    ) -> Locale {
        guard let currencyCode, !currencyCode.isEmpty else {
            return .autoupdatingCurrent
        }

        let extractedSymbol = extractedCurrencySymbol(
            from: localizedPriceString,
            currencyCode: currencyCode
        )

        let preferredCurrentLocales = [
            Locale.autoupdatingCurrent,
            Locale.current
        ]

        if let match = preferredCurrentLocales.first(where: { locale in
            localeCurrencyIdentifier(locale)?.caseInsensitiveCompare(currencyCode) == .orderedSame
            && (extractedSymbol == nil || locale.currencySymbol == extractedSymbol)
        }) {
            return match
        }

        if let extractedSymbol,
           let symbolMatch = Locale.availableIdentifiers.lazy
            .map(Locale.init(identifier:))
            .first(where: { locale in
                localeCurrencyIdentifier(locale)?.caseInsensitiveCompare(currencyCode) == .orderedSame
                && locale.currencySymbol == extractedSymbol
            }) {
            return symbolMatch
        }

        if let currencyMatch = Locale.availableIdentifiers.lazy
            .map(Locale.init(identifier:))
            .first(where: { locale in
                localeCurrencyIdentifier(locale)?.caseInsensitiveCompare(currencyCode) == .orderedSame
            }) {
            return currencyMatch
        }

        return .autoupdatingCurrent
    }

    private func localeCurrencyIdentifier(_ locale: Locale) -> String? {
        locale.currency?.identifier
    }

    private func extractedCurrencySymbol(
        from localizedPriceString: String,
        currencyCode: String?
    ) -> String? {
        let removableScalars = CharacterSet.decimalDigits
            .union(.whitespacesAndNewlines)
            .union(.punctuationCharacters)
            .union(.controlCharacters)

        var symbol = String(
            localizedPriceString.unicodeScalars.filter { scalar in
                !removableScalars.contains(scalar)
            }
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        if let currencyCode, !currencyCode.isEmpty {
            symbol = symbol.replacingOccurrences(of: currencyCode, with: "")
            symbol = symbol.replacingOccurrences(of: currencyCode.lowercased(), with: "")
        }

        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private struct PriceSnapshot {
        let localizedPriceString: String
        let priceDecimalNumber: NSDecimalNumber
        let priceFormatter: NumberFormatter?
        let currencyCode: String?
        let storefrontCountryCode: String?
        let localeIdentifier: String
        let source: String
    }
}
