import Foundation
import Observation
import RevenueCat

enum SubscriptionActionResult {
    case success
    case cancelled
    case failure(String)
}

@Observable
final class SubscriptionManager {
    static let shared = SubscriptionManager()

    static let grockProEntitlementID = "pro"
    static let monthlyPackageID = "monthly"
    static let yearlyPackageID = "yearly"

    private(set) var isPro: Bool = false
    private(set) var customerInfo: CustomerInfo?
    private(set) var currentOffering: Offering?
    private(set) var isLoadingOfferings = false
    private(set) var isLoadingCustomerInfo = false
    private(set) var hasLoadedAtLeastOnce = false
    private(set) var lastErrorMessage: String?

    private var customerInfoStreamTask: Task<Void, Never>?

    private init() {
        self.isPro = UserDefaults.standard.isPro
    }

    func start() {
        guard Purchases.isConfigured else {
            setError("RevenueCat is not configured.")
            return
        }

        if customerInfoStreamTask == nil {
            customerInfoStreamTask = Task {
                for await updatedInfo in Purchases.shared.customerInfoStream {
                    await MainActor.run {
                        self.apply(customerInfo: updatedInfo)
                    }
                }
            }
        }

        Task {
            await refreshAll()
        }
    }

    func refreshAll() async {
        await refreshOfferings()
        await refreshCustomerInfo()
    }

    func refreshOfferings() async {
        guard Purchases.isConfigured else { return }

        isLoadingOfferings = true
        defer { isLoadingOfferings = false }

        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            clearError()
        } catch {
            setError("Could not load offerings: \(error.localizedDescription)")
        }
    }

    func refreshCustomerInfo() async {
        guard Purchases.isConfigured else { return }

        isLoadingCustomerInfo = true
        defer {
            isLoadingCustomerInfo = false
            hasLoadedAtLeastOnce = true
        }

        do {
            let info = try await Purchases.shared.customerInfo()
            apply(customerInfo: info)
            clearError()
        } catch {
            setError("Could not refresh subscription status: \(error.localizedDescription)")
        }
    }

    func purchase(package: Package) async -> SubscriptionActionResult {
        guard Purchases.isConfigured else {
            let message = "RevenueCat is not configured."
            setError(message)
            return .failure(message)
        }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            apply(customerInfo: result.customerInfo)

            if result.userCancelled {
                return .cancelled
            }

            clearError()
            return .success
        } catch ErrorCode.purchaseCancelledError {
            return .cancelled
        } catch {
            let message = "Purchase failed: \(error.localizedDescription)"
            setError(message)
            return .failure(message)
        }
    }

    func purchaseMonthly() async -> SubscriptionActionResult {
        guard let monthlyPackage else {
            let message = "Monthly package not found in the current offering."
            setError(message)
            return .failure(message)
        }

        return await purchase(package: monthlyPackage)
    }

    func purchaseYearly() async -> SubscriptionActionResult {
        guard let yearlyPackage else {
            let message = "Yearly package not found in the current offering."
            setError(message)
            return .failure(message)
        }

        return await purchase(package: yearlyPackage)
    }

    func restorePurchases() async -> SubscriptionActionResult {
        guard Purchases.isConfigured else {
            let message = "RevenueCat is not configured."
            setError(message)
            return .failure(message)
        }

        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(customerInfo: info)
            clearError()
            return .success
        } catch {
            let message = "Restore failed: \(error.localizedDescription)"
            setError(message)
            return .failure(message)
        }
    }

    func syncPurchases() async -> SubscriptionActionResult {
        guard Purchases.isConfigured else {
            let message = "RevenueCat is not configured."
            setError(message)
            return .failure(message)
        }

        do {
            let info = try await Purchases.shared.syncPurchases()
            apply(customerInfo: info)
            clearError()
            return .success
        } catch {
            let message = "Sync purchases failed: \(error.localizedDescription)"
            setError(message)
            return .failure(message)
        }
    }

    func hasActiveEntitlement(_ identifier: String = SubscriptionManager.grockProEntitlementID) -> Bool {
        customerInfo?.entitlements.activeInCurrentEnvironment[identifier] != nil
    }

    var monthlyPackage: Package? {
        guard let offering = currentOffering else { return nil }
        return offering.package(identifier: SubscriptionManager.monthlyPackageID)
            ?? offering.package(identifier: "$rc_monthly")
            ?? offering.monthly
    }

    var yearlyPackage: Package? {
        guard let offering = currentOffering else { return nil }
        return offering.package(identifier: SubscriptionManager.yearlyPackageID)
            ?? offering.package(identifier: "$rc_annual")
            ?? offering.annual
    }

    private func apply(customerInfo: CustomerInfo) {
        self.customerInfo = customerInfo

        let proIsActive = customerInfo.entitlements
            .activeInCurrentEnvironment[SubscriptionManager.grockProEntitlementID] != nil

        self.isPro = proIsActive
        UserDefaults.standard.isPro = proIsActive
    }

    private func setError(_ message: String) {
        lastErrorMessage = message
        print("⚠️ [Subscription] \(message)")
    }

    private func clearError() {
        lastErrorMessage = nil
    }
}
