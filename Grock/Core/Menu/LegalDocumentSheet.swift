import SwiftUI
import WebKit

enum LegalDocumentType: String, Identifiable {
    case privacyPolicy
    case termsOfService

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacyPolicy:
            return "Privacy Policy"
        case .termsOfService:
            return "Terms of Service"
        }
    }

    var lastUpdated: String {
        "March 1, 2026"
    }

    var sections: [LegalDocumentSection] {
        switch self {
        case .privacyPolicy:
            return [
                .init(
                    title: "1. Overview",
                    body: "Grock helps you plan grocery trips, track item prices, and compare stores. This policy explains what data we handle and how we use it."
                ),
                .init(
                    title: "2. Data You Provide",
                    body: """
                    Data you enter in Grock is stored locally on your device, including:
                    - Your display name
                    - Stores, custom categories, units, and item details
                    - Cart/trip content, prices, quantities, and history
                    - Preferences like currency and feature settings

                    Grock currently does not sync this vault data to iCloud.
                    """
                ),
                .init(
                    title: "3. Subscription and Purchase Data",
                    body: """
                    For Grock Pro billing and subscription status, Grock relies on Apple and RevenueCat.
                    We only use the subscription and purchase information needed to unlock Pro features and restore purchases.
                    """
                ),
                .init(
                    title: "4. Support and Feedback Data",
                    body: """
                    If you contact support or submit feedback, we may receive:
                    - Your message and submitted feedback
                    - When you use Contact Support, the email draft includes diagnostics: app version, build, device model, iOS version, locale, timezone, and timestamp
                    """
                ),
                .init(
                    title: "5. How We Use Data",
                    body: """
                    We use data to:
                    - Operate core app features (vault, carts, history, store/category management)
                    - Process subscriptions and restore purchases
                    - Respond to support and improve reliability
                    - Enforce Free vs Pro feature limits
                    """
                ),
                .init(
                    title: "6. Sharing and Processors",
                    body: """
                    We do not sell your personal data. Grock does not operate its own server for your vault/cart content. We share limited data only with service providers needed to run specific features:
                    - Apple App Store (billing/subscription)
                    - RevenueCat (subscription entitlement and purchase infrastructure)
                    - UserJot (in-app feedback submission)
                    """
                ),
                .init(
                    title: "7. Storage, Retention, and Deletion",
                    body: """
                    Your grocery vault and related records are stored in app storage on your device. You can delete data in-app (including permanent delete from Trash) and use Reset Local Cache to clear local app data.

                    If you submit feedback or contact support, that submitted content may be retained by the relevant provider (for example, UserJot or your email provider) under their own policies.
                    """
                ),
                .init(
                    title: "8. Children",
                    body: "Grock is not directed to children under 13. If you believe a child submitted personal data, contact us so we can review and remove it where appropriate."
                ),
                .init(
                    title: "9. Contact",
                    body: "Questions about privacy: grocksupport@proton.me"
                )
            ]
        case .termsOfService:
            return []
        }
    }
}

struct LegalDocumentSection: Identifiable {
    let title: String
    let body: String

    var id: String { title }
}

struct LegalDocumentSheet: View {
    @Environment(\.dismiss) private var dismiss

    let document: LegalDocumentType
    @State private var showingAppleEULASheet = false

    private var appleEULAURL: URL {
        URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    }

    var body: some View {
        NavigationStack {
            Group {
                if document == .termsOfService {
                    termsContent
                } else {
                    privacyContent
                }
            }
            .background(Color.Grock.surfaceSoft.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .lexend(.subheadline, weight: .semibold)
                }
            }
            .sheet(isPresented: $showingAppleEULASheet) {
                AppleEULASheet(url: appleEULAURL)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private var privacyContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text(document.title)
                    .fuzzyBubblesFont(28, weight: .bold)
                    .foregroundStyle(.black)
                    .padding(.top, 2)

                Text("Last updated: \(document.lastUpdated)")
                    .lexend(.footnote, weight: .regular)
                    .foregroundStyle(.black.opacity(0.56))

                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                    .frame(height: 1)
                    .foregroundStyle(Color.Grock.neutral300)

                ForEach(Array(document.sections.enumerated()), id: \.element.id) { index, section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title)
                            .lexend(.headline, weight: .semibold)
                            .foregroundStyle(.black.opacity(0.9))

                        Text(section.body)
                            .lexend(.subheadline, weight: .regular)
                            .foregroundStyle(.black.opacity(0.72))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }

                    if index < document.sections.count - 1 {
                        DashedLine()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                            .frame(height: 1)
                            .foregroundStyle(Color.Grock.neutral300.opacity(0.86))
                            .padding(.top, 2)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
        }
    }

    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Terms of Service")
                    .fuzzyBubblesFont(28, weight: .bold)
                    .foregroundStyle(.black)
                    .padding(.top, 2)

                Text("""
                Grock Pro is enabled via an auto-renewing subscription. Subscription automatically renews and will be charged unless auto-renew is turned off at least 24 hours before the end of the current period. Payment will be charged to your Apple Account (App Store billing account) at confirmation of purchase. Auto-renewal may be turned off by going to your Apple Account Settings after purchase. The duration and price of each subscription is shown on the purchase screen and confirmed at checkout.
                """)
                    .lexend(.subheadline, weight: .regular)
                    .foregroundStyle(.black.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)

                Text("For full legal terms, review Apple's Licensed Application End User License Agreement (EULA).")
                    .lexend(.caption, weight: .regular)
                    .foregroundStyle(.black.opacity(0.54))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 1)
                .foregroundStyle(Color.Grock.neutral300)
                .padding(.horizontal, 16)

            Button {
                showingAppleEULASheet = true
            } label: {
                Text("Read Full Apple EULA")
                    .fuzzyBubblesFont(16, weight: .bold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.88))
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 14)

            Text("Source: apple.com/legal/internet-services/itunes/dev/stdeula")
                .lexend(.caption2, weight: .regular)
                .foregroundStyle(.black.opacity(0.5))
                .padding(.horizontal, 16)
                .padding(.top, 10)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct AppleEULASheet: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppleEULAWebView(url: url, isLoading: $isLoading)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.black)
                }
            }
            .background(Color.Grock.surfaceSoft.ignoresSafeArea())
            .navigationTitle("Apple EULA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .lexend(.subheadline, weight: .semibold)
                }
            }
        }
    }
}

private struct AppleEULAWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard context.coordinator.loadedURL != url else { return }
        context.coordinator.loadedURL = url
        uiView.load(URLRequest(url: url))
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        var loadedURL: URL?

        init(isLoading: Binding<Bool>) {
            self._isLoading = isLoading
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }
    }
}

#Preview("Privacy") {
    LegalDocumentSheet(document: .privacyPolicy)
}

#Preview("Terms") {
    LegalDocumentSheet(document: .termsOfService)
}
