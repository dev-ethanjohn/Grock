import SwiftUI
import RevenueCat
import StoreKit

struct ManageSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var activePlanStorefrontPrice: String?
    @State private var isRestoringPurchases = false
    @State private var showRestoreResultAlert = false
    @State private var restoreResultMessage = ""
    @State private var showRestoreWarningToast = false
    @State private var restoreWarningToastTask: Task<Void, Never>?
    private let currentPlanCardCornerRadius: CGFloat = 18

    private static let renewalDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    private var activeProEntitlement: EntitlementInfo? {
        subscriptionManager.customerInfo?.entitlements
            .activeInCurrentEnvironment[SubscriptionManager.grockProEntitlementID]
    }

    private var activeProductIdentifier: String? {
        activeProEntitlement?.productIdentifier
    }

    private var currentPlanName: String {
        guard subscriptionManager.isPro else { return "Free" }
        switch resolvedPlanKind {
        case .monthly:
            return "Pro (Monthly) 💎"
        case .yearly:
            return "Pro (Yearly) 💎"
        case .unknown:
            return "Pro"
        }
    }

    private var currentPlanDescription: String {
        if subscriptionManager.isPro {
            return "Pro - Unlimited stores, custom units, and advanced planning features."
        }
        return "Free Plan - Upgrade anytime."
    }

    private var currentPlanPriceLine: String? {
        guard subscriptionManager.isPro else { return nil }
        guard let activePlanStorefrontPrice, !activePlanStorefrontPrice.isEmpty else { return nil }

        switch resolvedPlanKind {
        case .monthly:
            return "\(activePlanStorefrontPrice)/month"
        case .yearly:
            return "\(activePlanStorefrontPrice)/year"
        case .unknown:
            return activePlanStorefrontPrice
        }
    }

    private var renewalPrimaryLine: String {
        guard subscriptionManager.isPro else { return "No renewal required" }
        guard let entitlement = activeProEntitlement else { return "Renewal date unavailable" }

        if let expirationDate = entitlement.expirationDate {
            let formatted = Self.renewalDateFormatter.string(from: expirationDate)
            if entitlement.periodType == .trial {
                return entitlement.willRenew
                    ? "Free trial ends on \(formatted)"
                    : "Free trial ends on \(formatted)"
            }
            return entitlement.willRenew
                ? "Renews automatically on \(formatted)"
                : "Access ends on \(formatted)"
        }

        return entitlement.willRenew ? "Renews automatically." : "Auto-renew is off"
    }

    private var renewalSecondaryLine: String? {
        guard subscriptionManager.isPro else { return nil }
        guard let entitlement = activeProEntitlement else { return nil }

        if entitlement.periodType == .trial {
            if entitlement.willRenew, let currentPlanPriceLine, !currentPlanPriceLine.isEmpty {
                return "Then starts at \(currentPlanPriceLine)."
            }

            return "Auto-renew: Off"
        }

        return entitlement.willRenew ? nil : "Auto-renew: Off"
    }

    private var appStoreManageURL: URL? {
        URL(string: "https://apps.apple.com/account/subscriptions")
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    currentPlanSection

                    DashedLine()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                        .frame(height: 1)
                        .foregroundStyle(Color.Grock.neutral300)
                        .padding(.horizontal)

                    detailSection(
                        title: "Renewal Date",
                        primary: renewalPrimaryLine,
                        secondary: renewalSecondaryLine,
                        tertiary: nil
                    )
                    
                    VStack(spacing: 8) {
                        FormCompletionButton(
                            title: "Manage in App Store",
                            isEnabled: true,
                            cornerRadius: 100,
                            verticalPadding: 12,
                            maxRadius: 1000,
                            bounceScale: (0.98, 1.05, 1.0),
                            bounceTiming: (0.1, 0.3, 0.3),
                            maxWidth: true
                        ) {
                            guard let appStoreManageURL else { return }
                            openURL(appStoreManageURL)
                        }

                        Button {
                            guard !isRestoringPurchases else { return }
                            isRestoringPurchases = true

                            Task {
                                let wasProBeforeRestore = subscriptionManager.isPro
                                let result = await subscriptionManager.restorePurchases()
                                await subscriptionManager.refreshCustomerInfo()

                                await MainActor.run {
                                    switch result {
                                    case .success:
                                        if subscriptionManager.isPro {
                                            if wasProBeforeRestore {
                                                restoreResultMessage = "Subscription is already active."
                                                showRestoreResultAlert = true
                                            } else {
                                                ProUnlockedCelebrationPresenter.shared.show()
                                            }
                                        } else {
                                            presentRestoreWarningToast()
                                        }
                                    case .cancelled:
                                        restoreResultMessage = "Restore was cancelled."
                                        showRestoreResultAlert = true
                                    case .failure(let message):
                                        restoreResultMessage = message
                                        showRestoreResultAlert = true
                                    }

                                    isRestoringPurchases = false
                                }
                            }
                        } label: {
                            Text(isRestoringPurchases ? "Restoring..." : "Restore Purchases")
                                .fuzzyBubblesFont(16, weight: .bold)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(
                                    Capsule()
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isRestoringPurchases)
                    }
                    .padding(.top, 24)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(Color.Grock.surfaceSoft.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .title) {
                    Text("Manage Subscriptions")
                        .fuzzyBubblesFont(20, weight: .bold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .lexend(.subheadline, weight: .semibold)
                }
            }
            .overlay(alignment: .top) {
                if showRestoreWarningToast {
                    restoreWarningToastView
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .task {
            await subscriptionManager.refreshAll()
        }
        .task(id: activeProductIdentifier) {
            await refreshActivePlanStorefrontPrice()
        }
        .alert("Restore Purchases", isPresented: $showRestoreResultAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreResultMessage)
        }
        .onDisappear {
            restoreWarningToastTask?.cancel()
            restoreWarningToastTask = nil
        }
    }

    private func detailSection(
        title: String,
        primary: String,
        secondary: String?,
        tertiary: String?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .lexend(.caption, weight: .semibold)
                .foregroundStyle(.black.opacity(0.5))

            Text(primary)
                .lexend(.subheadline, weight: .medium)
                .foregroundStyle(.black)

            if let secondary, !secondary.isEmpty {
                Text(secondary)
                    .lexend(.subheadline, weight: .medium)
                    .foregroundStyle(.black.opacity(0.78))
            }

            if let tertiary, !tertiary.isEmpty {
                Text(tertiary)
                    .lexend(.footnote, weight: .regular)
                    .foregroundStyle(.black.opacity(0.64))
            }
        }
        .padding(.horizontal)
    }

    private var currentPlanSection: some View {
        let cardShape = RoundedRectangle(cornerRadius: currentPlanCardCornerRadius, style: .continuous)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Current Plan")
                .lexend(.caption, weight: .semibold)
                .foregroundStyle(Color.white.opacity(0.82))
            
            VStack(alignment: .leading, spacing: 2){
                
                HStack {
                    Text(currentPlanName)
                        .lexend(.headline, weight: .semibold)
                        .foregroundStyle(.white)
                    
                    Spacer()

                    if let currentPlanPriceLine, !currentPlanPriceLine.isEmpty {
                        Text(currentPlanPriceLine)
                            .lexend(.subheadline, weight: .medium)
                            .foregroundStyle(Color.white.opacity(0.9))
                    }
                }

                Text(currentPlanDescription)
                    .lexend(.footnote, weight: .light)
                    .foregroundStyle(subscriptionManager.isPro ? Color.white.opacity(0.72) : Color.white.opacity(0.86))
            }

        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            cardShape
                .fill(Color.Grock.budgetSafe)
                .overlay {
                    Image("selected_sub")
                        .resizable()
                        .scaledToFill()
                }
                .overlay {
                    cardShape
                        .fill(Color.black.opacity(0.16))
                }
                .clipShape(cardShape)
        }
        .overlay {
            cardShape
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .clipShape(cardShape)
    }

    private enum PlanKind {
        case monthly
        case yearly
        case unknown
    }

    private var resolvedPlanKind: PlanKind {
        guard let activeProductIdentifier else { return .unknown }
        let normalized = activeProductIdentifier.lowercased()

        if normalized.contains("month") {
            return .monthly
        }
        if normalized.contains("year") || normalized.contains("annual") {
            return .yearly
        }
        return .unknown
    }

    private var restoreWarningToastView: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            Text("No previous purchases were found for this account.")
                .lexend(.subheadline, weight: .medium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)

            Button {
                dismissRestoreWarningToast()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.red.opacity(0.9))
        )
        .shadow(color: .black.opacity(0.16), radius: 8, x: 0, y: 4)
    }

    private func presentRestoreWarningToast() {
        restoreWarningToastTask?.cancel()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            showRestoreWarningToast = true
        }

        restoreWarningToastTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                dismissRestoreWarningToast()
            }
        }
    }

    private func dismissRestoreWarningToast() {
        restoreWarningToastTask?.cancel()
        restoreWarningToastTask = nil

        withAnimation(.easeInOut(duration: 0.2)) {
            showRestoreWarningToast = false
        }
    }

    @MainActor
    private func refreshActivePlanStorefrontPrice() async {
        guard subscriptionManager.isPro, let activeProductIdentifier else {
            activePlanStorefrontPrice = nil
            return
        }

        do {
            let products = try await StoreKit.Product.products(for: [activeProductIdentifier])
            let activeProduct = products.first(where: { $0.id == activeProductIdentifier })
            activePlanStorefrontPrice = activeProduct?.displayPrice
        } catch {
            activePlanStorefrontPrice = nil
            print("⚠️ [Manage Subscription] Failed to load StoreKit price for \(activeProductIdentifier): \(error.localizedDescription)")
        }
    }
}

#Preview {
    ManageSubscriptionSheet()
}
