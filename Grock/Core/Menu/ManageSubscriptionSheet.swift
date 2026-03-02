import SwiftUI
import RevenueCat

struct ManageSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var subscriptionManager = SubscriptionManager.shared
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

        if let product = resolvedStoreProduct {
            switch resolvedPlanKind {
            case .monthly:
                return "\(product.localizedPriceString)/month"
            case .yearly:
                return "\(product.localizedPriceString)/year"
            case .unknown:
                return product.localizedPriceString
            }
        }

        return nil
    }

    private var renewalPrimaryLine: String {
        guard subscriptionManager.isPro else { return "No renewal required" }
        guard let entitlement = activeProEntitlement else { return "Renewal date unavailable" }

        if let expirationDate = entitlement.expirationDate {
            let formatted = Self.renewalDateFormatter.string(from: expirationDate)
            return entitlement.willRenew
                ? "Renews automatically on \(formatted)"
                : "Access ends on \(formatted)"
        }

        return entitlement.willRenew ? "Renews automatically." : "Auto-renew is off"
    }

    private var renewalSecondaryLine: String? {
        guard subscriptionManager.isPro else { return nil }
        guard let entitlement = activeProEntitlement else { return nil }
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
        }
        .task {
            await subscriptionManager.refreshAll()
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

    private var resolvedStoreProduct: StoreProduct? {
        guard let activeProductIdentifier else { return nil }
        if subscriptionManager.monthlyPackage?.storeProduct.productIdentifier == activeProductIdentifier {
            return subscriptionManager.monthlyPackage?.storeProduct
        }
        if subscriptionManager.yearlyPackage?.storeProduct.productIdentifier == activeProductIdentifier {
            return subscriptionManager.yearlyPackage?.storeProduct
        }
        return nil
    }
}

#Preview {
    ManageSubscriptionSheet()
}
