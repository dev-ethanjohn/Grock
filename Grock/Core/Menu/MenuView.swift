import SwiftUI

struct MenuView: View {
    @Environment(VaultService.self) private var vaultService
    @State private var currencyManager = CurrencyManager.shared
    @Environment(\.openURL) private var openURL
    
    @State private var isEditingName = false
    @State private var editingName = ""
    @State private var showMailUnavailableAlert = false
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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Menu {
                            Text("Current: \(currencyMenuTitleString(for: currencyManager.selectedCurrency, includeSelection: false))")
                                .lexendFont(14, weight: .bold)
                                .foregroundColor(.black)
                            
                            DashedLine()
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                                .frame(height: 1)
                                .foregroundColor(Color(hex: "ddd"))
                            
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
                                    .fontWeight(.medium)
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
                                menuEmoji("🏬")
                                
                                Text("Manage Stores")
                                    .lexendFont(16)
                                    .fontWeight(.medium)
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
                                    .fontWeight(.medium)
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
        .alert("Change Name", isPresented: $isEditingName) {
            TextField("Name", text: $editingName)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if !editingName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    vaultService.updateUserName(editingName)
                }
            }
        } message: {
            Text("Enter your new username")
        }
        .alert("Mail App Unavailable", isPresented: $showMailUnavailableAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please set up the Mail app to contact support.")
        }
    }
    
    private var stickyHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                HStack {
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
                    let name = vaultService.currentUser?.name ?? ""
                    editingName = name
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
                .fill(.white)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: 0.7),
                            .init(color: .white.opacity(0.9), location: 0.85),
                            .init(color: .white.opacity(0.7), location: 0.95),
                            .init(color: .white.opacity(0), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
    }
    
    private var feedbackSupportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                .frame(height: 1)
                .foregroundColor(Color(hex: "ddd"))
                .padding(.horizontal, rowHorizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, 8)
            
            Button(action: {}) {
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
                .foregroundColor(Color(hex: "ddd"))
                .padding(.horizontal, rowHorizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, 8)
            
            Button(action: {}) {
                HStack(spacing: 8) {
                    menuEmoji("⭐️")
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Rate Grock")
                            .lexendFont(16)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        Text("I value your feedback.")
                            .lexend(.caption2, weight: .regular)
                            .foregroundColor(Color(.systemGray3))
                            .padding(.bottom, 2)
                    }
                    
                    Spacer()
                    
                    trailingForwardIcon()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, rowHorizontalPadding)
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
            
            ShareLink(item: shareAppURL, subject: Text("Grock"), message: Text(shareAppMessage)) {
                HStack(spacing: 8) {
                    menuEmoji("📤")
                    
                    Text("Share Grock")
                        .lexendFont(16)
                        .fontWeight(.medium)
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
    
    private func feedbackRow(title: String, icon: String, isHighlighted: Bool = false) -> some View {
        HStack(spacing: 8) {
            menuEmoji(icon)
            
            Text(title)
                .lexendFont(16)
                .fontWeight(.medium)
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
                            colors: [Color(hex: "FFE08A"), Color(hex: "FFC94A")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "E3AD2B"), lineWidth: 1)
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
        
        I need help with:
        
        
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
}

#Preview {
    MenuView()
}
