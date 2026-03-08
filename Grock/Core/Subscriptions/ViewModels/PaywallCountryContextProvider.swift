import Foundation

struct PaywallCountryContextCatalog: Decodable {
    let `default`: PaywallCountryContextTemplate
    let countries: [String: PaywallCountryContextOverride]
}

struct PaywallCountryContextTemplate: Decodable {
    let yearlyPrimary: String
    let yearlySecondary: String
    let monthlyPrimary: String
    let monthlySecondary: String
}

struct PaywallCountryContextOverride: Decodable {
    let yearlyPrimary: String?
    let yearlySecondary: String?
    let monthlyPrimary: String?
    let monthlySecondary: String?
}

final class PaywallCountryContextProvider {
    static let shared = PaywallCountryContextProvider()

    private let catalog: PaywallCountryContextCatalog

    init(bundle: Bundle = .main) {
        self.catalog = Self.loadCatalog(from: bundle)
    }

    func template(for countryCode: String?) -> PaywallCountryContextTemplate {
        guard let code = countryCode?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
              !code.isEmpty else {
            return catalog.default
        }

        guard let override = catalog.countries[code] else {
            return catalog.default
        }

        return mergedTemplate(base: catalog.default, override: override)
    }

    private func mergedTemplate(
        base: PaywallCountryContextTemplate,
        override: PaywallCountryContextOverride
    ) -> PaywallCountryContextTemplate {
        PaywallCountryContextTemplate(
            yearlyPrimary: override.yearlyPrimary ?? base.yearlyPrimary,
            yearlySecondary: override.yearlySecondary ?? base.yearlySecondary,
            monthlyPrimary: override.monthlyPrimary ?? base.monthlyPrimary,
            monthlySecondary: override.monthlySecondary ?? base.monthlySecondary
        )
    }

    private static func loadCatalog(from bundle: Bundle) -> PaywallCountryContextCatalog {
        guard let url = bundle.url(forResource: "PaywallCountryContext", withExtension: "json") else {
            print("⚠️ [PaywallContext] Missing PaywallCountryContext.json. Leaving paywall context copy empty.")
            return emptyCatalog
        }

        do {
            let data = try Data(contentsOf: url)
            let rawText = String(decoding: data, as: UTF8.self)
            let sanitizedText = stripJSONComments(from: rawText)
            let sanitizedData = Data(sanitizedText.utf8)
            return try JSONDecoder().decode(PaywallCountryContextCatalog.self, from: sanitizedData)
        } catch {
            print("⚠️ [PaywallContext] Could not decode PaywallCountryContext.json: \(error.localizedDescription). Leaving paywall context copy empty.")
            return emptyCatalog
        }
    }

    private static func stripJSONComments(from text: String) -> String {
        // Support line comments (`// ...`) and block comments (`/* ... */`) in this config file.
        var result = text.replacingOccurrences(
            of: #"/\*[\s\S]*?\*/"#,
            with: "",
            options: .regularExpression
        )

        result = result.replacingOccurrences(
            of: #"(?m)^\s*//.*$"#,
            with: "",
            options: .regularExpression
        )

        return result
    }

    private static var emptyCatalog: PaywallCountryContextCatalog {
        PaywallCountryContextCatalog(
            default: PaywallCountryContextTemplate(
                yearlyPrimary: "",
                yearlySecondary: "",
                monthlyPrimary: "",
                monthlySecondary: ""
            ),
            countries: [:]
        )
    }
}
