import SwiftUI
import UserJot
import WebKit
import Darwin

struct MenuView: View {
    @Environment(VaultService.self) private var vaultService
    @State private var currencyManager = CurrencyManager.shared
    @Environment(\.openURL) private var openURL
    
    @Binding var isEditingName: Bool
    @State private var showingFeedbackSheet = false
    @State private var showMailUnavailableAlert = false
    @State private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    @State private var showingManageSubscriptionSheet = false
    @State private var showingPrivacyPolicySheet = false
    @State private var showingTermsOfServiceSheet = false
    @State private var showingResetLocalCacheAlert = false
    @State private var showingResetLocalCacheSuccessAlert = false
    private let selectedAccent = Color.Grock.budgetSafe
    private let stickyHeaderHeight: CGFloat = 156
    private let listHorizontalPadding: CGFloat = 12
    private let rowHorizontalPadding: CGFloat = 6
    private let sectionGapAfterPrimaryRows: CGFloat = 8
    private let sectionGapBetweenSecondarySections: CGFloat = 6
    
    private struct CurrencyGroup: Identifiable {
        let name: String
        let currencies: [Currency]
        var id: String { name }
    }
    
    // Expanded curated currencies for broader regional coverage.
    private let commonCurrencyCodes: Set<String> = [
        // North America + Caribbean
        "USD", "CAD", "MXN", "CRC", "DOP", "GTQ", "HNL", "JMD", "NIO", "PAB", "TTD",
        // South America
        "ARS", "BOB", "BRL", "CLP", "COP", "GYD", "PEN", "PYG", "SRD", "UYU", "VES",
        // Europe
        "EUR", "GBP", "CHF", "NOK", "SEK", "DKK", "PLN", "CZK", "HUF", "RON", "BGN", "RSD",
        "ALL", "BAM", "MKD", "MDL", "UAH", "BYN", "ISK", "RUB",
        // Middle East
        "AED", "BHD", "EGP", "ILS", "IQD", "IRR", "JOD", "KWD", "LBP", "OMR", "QAR", "SAR", "SYP", "TRY", "YER",
        // Africa
        "ZAR", "NGN", "KES", "GHS", "MAD", "DZD", "TND", "UGX", "TZS", "BWP", "MUR", "NAD", "SCR", "XOF", "XAF",
        // Asia
        "CNY", "HKD", "INR", "JPY", "KRW", "SGD", "TWD", "THB", "MYR", "PHP", "IDR", "VND",
        "BDT", "PKR", "NPR", "LKR", "MMK", "LAK", "KHR", "BND", "MNT", "BTN", "MOP",
        // Central Asia
        "AFN", "KZT", "UZS", "KGS", "TJS", "TMT", "AZN", "AMD", "GEL",
        // Oceania
        "AUD", "NZD", "FJD", "PGK"
    ]
    
    private let currencyRegionOrder: [String] = [
        "North America",
        "South America",
        "Europe",
        "Middle East",
        "Africa",
        "Asia",
        "Oceania"
    ]
    
    private let currencyRegionByCode: [String: String] = [
        // North America + Caribbean
        "USD": "North America", "CAD": "North America", "MXN": "North America", "CRC": "North America", "DOP": "North America",
        "GTQ": "North America", "HNL": "North America", "JMD": "North America", "NIO": "North America", "PAB": "North America", "TTD": "North America",
        // South America
        "ARS": "South America", "BOB": "South America", "BRL": "South America", "CLP": "South America", "COP": "South America",
        "GYD": "South America", "PEN": "South America", "PYG": "South America", "SRD": "South America", "UYU": "South America", "VES": "South America",
        // Europe
        "EUR": "Europe", "GBP": "Europe", "CHF": "Europe", "NOK": "Europe", "SEK": "Europe", "DKK": "Europe", "PLN": "Europe",
        "CZK": "Europe", "HUF": "Europe", "RON": "Europe", "BGN": "Europe", "RSD": "Europe", "ALL": "Europe", "BAM": "Europe",
        "MKD": "Europe", "MDL": "Europe", "UAH": "Europe", "BYN": "Europe", "ISK": "Europe", "RUB": "Europe",
        // Middle East
        "AED": "Middle East", "BHD": "Middle East", "EGP": "Middle East", "ILS": "Middle East", "IQD": "Middle East", "IRR": "Middle East",
        "JOD": "Middle East", "KWD": "Middle East", "LBP": "Middle East", "OMR": "Middle East", "QAR": "Middle East", "SAR": "Middle East",
        "SYP": "Middle East", "TRY": "Middle East", "YER": "Middle East",
        // Central Asia (grouped under Asia)
        "AFN": "Asia", "KZT": "Asia", "UZS": "Asia", "KGS": "Asia", "TJS": "Asia", "TMT": "Asia",
        "AZN": "Asia", "AMD": "Asia", "GEL": "Asia",
        // Africa
        "ZAR": "Africa", "NGN": "Africa", "KES": "Africa", "GHS": "Africa", "MAD": "Africa", "DZD": "Africa", "TND": "Africa",
        "UGX": "Africa", "TZS": "Africa", "BWP": "Africa", "MUR": "Africa", "NAD": "Africa", "SCR": "Africa", "XOF": "Africa", "XAF": "Africa",
        // Asia
        "JPY": "Asia", "CNY": "Asia", "HKD": "Asia", "SGD": "Asia", "INR": "Asia", "KRW": "Asia", "TWD": "Asia",
        "THB": "Asia", "MYR": "Asia", "PHP": "Asia", "IDR": "Asia", "VND": "Asia", "BDT": "Asia", "PKR": "Asia",
        "NPR": "Asia", "LKR": "Asia", "MMK": "Asia", "LAK": "Asia", "KHR": "Asia", "BND": "Asia", "MNT": "Asia", "BTN": "Asia", "MOP": "Asia",
        // Oceania
        "AUD": "Oceania", "NZD": "Oceania", "FJD": "Oceania", "PGK": "Oceania"
    ]
    
    // Replace with your real support inbox.
    private let supportEmailAddress = "support@grock.app"
    private let shareAppURL = URL(string: "https://grock.app")!
    private let shareAppMessage = "Check out Grock for tracking trips, items, and grocery budgets."
    private let onResetLocalCache: () -> Bool
    
    init(
        isEditingName: Binding<Bool> = .constant(false),
        onResetLocalCache: @escaping () -> Bool = { true }
    ) {
        self._isEditingName = isEditingName
        self.onResetLocalCache = onResetLocalCache
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        manageGrockProSection

                        Menu {
                            Text("Current: \(currencyMenuTitleString(for: currencyManager.selectedCurrency, includeSelection: false))")
                                .lexendFont(14, weight: .bold)
                                .foregroundColor(.black)
                            
                            DashedLine()
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                                .frame(height: 1)
                                .foregroundColor(Color.Grock.neutral300)
                            
                            ForEach(groupedMenuCurrencies) { group in
                                Menu {
                                    ForEach(group.currencies) { currency in
                                        Button {
                                            currencyManager.setCurrency(currency)
                                        } label: {
                                            currencyMenuLabel(for: currency)
                                        }
                                    }
                                } label: {
                                    Text(regionMenuTitle(group.name))
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                menuEmoji("💵")
                                
                                Text("Currency")
                                    .lexendFont(16)
                                    .fontWeight(.regular)
                                    .foregroundColor(Color.black)
                                
                                Spacer()
                                
                                Text(displayCurrencyMarker(for: currencyManager.selectedCurrency))
                                    .lexendFont(14)
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, rowHorizontalPadding)
                            .padding(.vertical, 2)
                        }
                        .environment(\.colorScheme, .light)
                        
                        // Store Manager
                        NavigationLink {
                            StoreManagerView()
                        } label: {
                            HStack(spacing: 8) {
                                menuEmoji("🏪")
                                
                                Text("Manage Stores")
                                    .lexendFont(16)
                                    .fontWeight(.regular)
                                    .foregroundColor(Color.black)
                                
                                Spacer()
                                
                                trailingForwardIcon()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, rowHorizontalPadding)
                            .padding(.vertical, 2)
                        }
                        
                        NavigationLink {
                            TrashView()
                        } label: {
                            HStack(spacing: 8) {
                                menuEmoji("🗑️")
                                
                                Text("Trash")
                                    .lexendFont(16)
                                    .fontWeight(.regular)
                                    .foregroundColor(Color.black)
                                
                                Spacer()
                                
                                trailingForwardIcon()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, rowHorizontalPadding)
                            .padding(.vertical, 2)
                        }

                        feedbackSupportSection
                            .padding(.top, sectionGapAfterPrimaryRows)
                        rateAndShareSection
                            .padding(.top, sectionGapBetweenSecondarySections)
                        legalAndVersionSection
                            .padding(.top, sectionGapBetweenSecondarySections)
                        resetSection
                            .padding(.top, sectionGapBetweenSecondarySections)
                    }
                    .padding(.leading, listHorizontalPadding)
                    .padding(.trailing, listHorizontalPadding + 4)
                    .padding(.bottom, 24)
                    .padding(.top, stickyHeaderHeight + 12)
                }
                .frame(width: 300, alignment: .leading)
                
                stickyHeader
            }
            .frame(width: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            await subscriptionManager.refreshAll()
        }
        .alert("Mail App Unavailable", isPresented: $showMailUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please set up the Mail app to contact support.")
        }
        .alert("Reset Local Cache", isPresented: $showingResetLocalCacheAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Local Cache", role: .destructive) {
                if onResetLocalCache() {
                    showingResetLocalCacheSuccessAlert = true
                }
            }
        } message: {
            Text("This will erase local data on this device: vault items, custom categories, stores, carts, trip history, and custom units. This cannot be undone.")
        }
        .alert("Local Cache Reset", isPresented: $showingResetLocalCacheSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your local Grock data was cleared successfully.")
        }
        .sheet(isPresented: $showingFeedbackSheet) {
            MenuUserJotFeedbackScreen()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingManageSubscriptionSheet) {
            ManageSubscriptionSheet()
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingPrivacyPolicySheet) {
            LegalDocumentSheet(document: .privacyPolicy)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTermsOfServiceSheet) {
            LegalDocumentSheet(document: .termsOfService)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showingPaywall) {
            GrockPaywallView {
                showingPaywall = false
            }
        }
    }
    
    private var stickyHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                HStack(spacing: 4) {
                    Image("grock_logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 22, height: 22)
                        .offset(x: -3)
                    
                    Text("Grock")
                        .fuzzyBubblesFont(16, weight: .bold)
                }
                .opacity(0.6)
                
                Spacer()
            }
            .frame(height: 100, alignment: .bottom)
            .padding(.leading, 24)
            
            HStack {
                Text("Hi \(vaultService.currentUser?.name ?? "User")")
                    .shantellSansFont(28)
                    .bold()
                
                Button {
                    isEditingName = true
                } label: {
                    Text("✏️")
                        .lexendFont(14)
                }
                
                Spacer()
            }
            .padding(.leading, 24)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: stickyHeaderHeight, alignment: .top)
        .background(alignment: .topLeading) {
            menuHeaderBackground
                .frame(width: UIScreen.main.bounds.width, height: stickyHeaderHeight, alignment: .topLeading)
        }
    }
    
    private var menuHeaderBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: 0.82),
                            .init(color: .white.opacity(0.8), location: 0.9),
                            .init(color: .white.opacity(0.4), location: 0.96),
                            .init(color: .white.opacity(0), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }

    private var manageGrockProRow: some View {
        let isPro = subscriptionManager.isPro
        let title = isPro ? "Grock Pro Active" : "Unlock Grock Pro"
        let subtitle = isPro
            ? "Everything in Grock is unlocked for you."
            : "Unlimited carts, stores, categories, units, and more..."
        let cardShape = RoundedRectangle(cornerRadius: 16, style: .continuous)

        return Button {
            if isPro {
                showingManageSubscriptionSheet = true
            } else {
                showingPaywall = true
            }
        } label: {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .fuzzyBubblesFont(18, weight: .bold)
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .lexendFont(11, weight: .light)
                        .foregroundStyle(Color.white.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trailingForwardIcon(color: .white.opacity(0.88))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
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
                            .fill(Color.black.opacity(0.2))
                    }
                    .clipShape(cardShape)
            }
            .overlay {
                cardShape
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            }
            .clipShape(cardShape)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, rowHorizontalPadding)
    }

    private var manageGrockProSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            manageGrockProRow
        }
    }

    private var feedbackSupportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 1)
                .foregroundColor(Color.Grock.neutral300)
                .padding(.horizontal, rowHorizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, 8)
            
            Button(action: handleFeedbackTapped) {
                feedbackRow(title: "Give Feedback", icon: "💬")
            }
            .buttonStyle(.plain)
            
            Button(action: contactSupportTapped) {
                feedbackRow(title: "Contact Support", icon: "📧")
            }
            .buttonStyle(.plain)
        }
    }
    
    private var rateAndShareSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 1)
                .foregroundColor(Color.Grock.neutral300)
                .padding(.horizontal, rowHorizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, 8)
            
            Button(action: {}) {
                HStack(spacing: 8) {
                    menuEmoji("⭐️")

                    Text("Rate Grock")
                        .lexendFont(16)
                        .fontWeight(.regular)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    trailingForwardIcon()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, rowHorizontalPadding)
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            // CSV export entry is intentionally disabled for a future update.
            
            ShareLink(item: shareAppURL, subject: Text("Grock"), message: Text(shareAppMessage)) {
                HStack(spacing: 8) {
                    menuEmoji("📤")
                    
                    Text("Share Grock")
                        .lexendFont(16)
                        .fontWeight(.regular)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Image("share")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundColor(.gray)
                        .padding(.trailing, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, rowHorizontalPadding)
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
    }

    private var legalAndVersionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 1)
                .foregroundColor(Color.Grock.neutral300)
                .padding(.horizontal, rowHorizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, 8)

            Button {
                showingPrivacyPolicySheet = true
            } label: {
                legalInfoRow(title: "Privacy Policy", icon: "🔒", showsChevron: true)
            }
            .buttonStyle(.plain)

            Button {
                showingTermsOfServiceSheet = true
            } label: {
                legalInfoRow(title: "Terms of Service", icon: "📄", showsChevron: true)
            }
            .buttonStyle(.plain)

            legalInfoRow(title: "Version", icon: "🏷️", trailingText: appVersionLabel)
        }
    }

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 1)
                .foregroundColor(Color.Grock.neutral300)
                .padding(.horizontal, rowHorizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, 8)

            Button(role: .destructive) {
                showingResetLocalCacheAlert = true
            } label: {
                HStack(spacing: 8) {
                    menuEmoji("♻️")

                    Text("Reset Local Cache")
                        .lexendFont(16)
                        .fontWeight(.regular)
                        .foregroundColor(.red)

                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, rowHorizontalPadding)
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func feedbackRow(title: String, icon: String, isHighlighted: Bool = false) -> some View {
        HStack(spacing: 8) {
            menuEmoji(icon)
            
            Text(title)
                .lexendFont(16)
                .fontWeight(.regular)
                .foregroundColor(.black)
            
            Spacer()
            
            trailingForwardIcon(color: isHighlighted ? .black.opacity(0.7) : .gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, rowHorizontalPadding)
        .padding(.vertical, isHighlighted ? 6 : 2)
        .background {
            if isHighlighted {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [selectedAccent, selectedAccent.darker(by: 0.12)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(selectedAccent.darker(by: 0.32), lineWidth: 1)
                    )
            }
        }
    }
    
    private func menuEmoji(_ emoji: String) -> some View {
        Text(emoji)
            .lexendFont(16)
            .frame(width: 24, height: 24, alignment: .leading)
    }
    
    private func trailingForwardIcon(color: Color = .gray) -> some View {
        Image("forward_arrow")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 18, height: 18)
            .foregroundColor(color)
    }

    private func legalInfoRow(
        title: String,
        icon: String,
        trailingText: String? = nil,
        showsChevron: Bool = false
    ) -> some View {
        HStack(spacing: 8) {
            menuEmoji(icon)

            Text(title)
                .lexendFont(16)
                .fontWeight(.regular)
                .foregroundColor(.black)

            Spacer()

            if let trailingText {
                Text(trailingText)
                    .lexendFont(13)
                    .foregroundColor(.gray)
                    .padding(.trailing, 4)
            } else if showsChevron {
                trailingForwardIcon()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, rowHorizontalPadding)
        .padding(.vertical, 2)
    }

    private var appVersionLabel: String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return appVersion
    }
    
    private var menuCurrencies: [Currency] {
        let filtered = currencyManager.availableCurrencies.filter { commonCurrencyCodes.contains($0.code) }
        guard !filtered.isEmpty else { return currencyManager.availableCurrencies }
        
        if filtered.contains(where: { $0.code == currencyManager.selectedCurrency.code }) {
            return filtered
        }
        
        // Keep currently selected currency visible even if outside curated list.
        return [currencyManager.selectedCurrency] + filtered
    }
    
    private var groupedMenuCurrencies: [CurrencyGroup] {
        let grouped = Dictionary(grouping: menuCurrencies) { currency in
            currencyRegionByCode[currency.code] ?? "Other"
        }
        
        var result: [CurrencyGroup] = currencyRegionOrder.compactMap { region in
            guard let currencies = grouped[region], !currencies.isEmpty else { return nil }
            return CurrencyGroup(name: region, currencies: currencies.sorted { $0.name < $1.name })
        }
        
        if let otherCurrencies = grouped["Other"], !otherCurrencies.isEmpty {
            result.append(CurrencyGroup(name: "Other", currencies: otherCurrencies.sorted { $0.name < $1.name }))
        }
        
        return result
    }
    
    private func displayCurrencyMarker(for currency: Currency) -> String {
        let symbol = currency.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        if symbol.isEmpty || symbol.uppercased() == currency.code.uppercased() {
            return currency.code
        }
        return symbol
    }
    
    private func currencyMenuLabel(for currency: Currency) -> Text {
        let title = currencyMenuTitleString(for: currency, includeSelection: true)
        
        return Text(title)
            .lexend(.subheadline, weight: .regular)
    }
    
    private func currencyMenuTitleString(for currency: Currency, includeSelection: Bool) -> String {
        let checkPrefix: String
        if includeSelection {
            checkPrefix = currency.code == currencyManager.selectedCurrency.code ? "● " : "○ "
        } else {
            checkPrefix = ""
        }
        return "\(checkPrefix)\(currency.name) (\(displayCurrencyMarker(for: currency)))"
    }
    
    private func regionMenuTitle(_ region: String) -> String {
        let isSelectedRegion = (currencyRegionByCode[currencyManager.selectedCurrency.code] ?? "Other") == region
        let dot = isSelectedRegion ? "●" : "○"
        return "\(region)   \(dot)"
    }
    
    private func contactSupportTapped() {
        let userName = vaultService.currentUser?.name ?? "User"
        let subject = "Grock Support Request"
        let body = """
        Hi Grock Support,
        
        Name: \(userName)
        
        What happened?
        
        
        What did you expect?
        
        
        Steps to reproduce:
        1.
        2.
        3.
        
        Additional notes:
        
        
        ---
        Support Diagnostics (please keep)
        \(supportDiagnosticsSummary())
        
        
        """
        
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmailAddress
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        
        guard let emailURL = components.url else {
            showMailUnavailableAlert = true
            return
        }
        
        openURL(emailURL) { accepted in
            if !accepted {
                showMailUnavailableAlert = true
            }
        }
    }
    
    private func handleFeedbackTapped() {
        showingFeedbackSheet = true
    }
    
    private func supportDiagnosticsSummary() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        let deviceType = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let modelIdentifier = UIDevice.current.modelIdentifier
        let osVersion = UIDevice.current.systemVersion
        
        let localeIdentifier = Locale.current.identifier
        let timeZone = TimeZone.current
        let timeZoneSummary: String
        if let abbreviation = timeZone.abbreviation() {
            timeZoneSummary = "\(timeZone.identifier) (\(abbreviation))"
        } else {
            timeZoneSummary = timeZone.identifier
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: Date())
        
        return """
        - App: Grock \(appVersion) (\(buildNumber))
        - Device: \(deviceType) (\(modelIdentifier))
        - OS: iOS \(osVersion)
        - Locale: \(localeIdentifier)
        - Time Zone: \(timeZoneSummary)
        - Timestamp (UTC): \(timestamp)
        """
    }
}

private struct MenuUserJotFeedbackScreen: View {
    @State private var feedbackURL: URL?
    @State private var isLoading = true
    @State private var pollingTask: Task<Void, Never>?
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            if let feedbackURL {
                MenuUserJotWebView(url: feedbackURL, isLoading: $isLoading)
                    .ignoresSafeArea()
            }
            
            if feedbackURL == nil || isLoading {
                Color.white.opacity(0.96)
                    .ignoresSafeArea()
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.black)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .onAppear {
            resolveFeedbackURL()
        }
        .onDisappear {
            pollingTask?.cancel()
        }
        .ignoresSafeArea()
    }
    
    private func resolveFeedbackURL() {
        if feedbackURL != nil {
            return
        }
        
        pollingTask?.cancel()
        
        if let url = UserJot.feedbackURL() {
            feedbackURL = url
            return
        }
        
        pollingTask = Task {
            while !Task.isCancelled {
                if Task.isCancelled { return }
                try? await Task.sleep(nanoseconds: 150_000_000)
                
                if let url = UserJot.feedbackURL() {
                    await MainActor.run {
                        feedbackURL = url
                    }
                    return
                }
            }
        }
    }
}

private struct MenuUserJotWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let deviceInfo = UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
        let osVersion = UIDevice.current.systemVersion
        webView.customUserAgent = "UserJotSDK/1.0 (\(deviceInfo); iOS \(osVersion); AppVersion/\(appVersion))"
        
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        
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
            setLoading(true)
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            setLoading(false)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            setLoading(false)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            setLoading(false)
        }
        
        private func setLoading(_ value: Bool) {
            DispatchQueue.main.async {
                self.isLoading = value
            }
        }
    }
}

#Preview {
    MenuView()
}

private extension UIDevice {
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) { machinePtr in
            machinePtr.withMemoryRebound(to: CChar.self, capacity: 1) { cStringPtr in
                String(cString: cStringPtr)
            }
        }
    }
}
