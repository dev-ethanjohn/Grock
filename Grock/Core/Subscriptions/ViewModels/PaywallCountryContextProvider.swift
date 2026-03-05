import Foundation

struct PaywallCountryContextCatalog: Decodable {
    let `default`: PaywallCountryContextTemplate
    let countries: [String: PaywallCountryContextTemplate]
}

struct PaywallCountryContextTemplate: Decodable {
    let note: String?
    let yearlyPrimary: String
    let yearlySecondary: String
    let monthlyPrimary: String
    let monthlySecondary: String
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

        return catalog.countries[code] ?? catalog.default
    }

    private static func loadCatalog(from bundle: Bundle) -> PaywallCountryContextCatalog {
        guard let url = bundle.url(forResource: "PaywallCountryContext", withExtension: "json") else {
            print("⚠️ [PaywallContext] Missing PaywallCountryContext.json. Using fallback templates.")
            return fallbackCatalog
        }

        do {
            let data = try Data(contentsOf: url)
            let rawText = String(decoding: data, as: UTF8.self)
            let sanitizedText = stripJSONComments(from: rawText)
            let sanitizedData = Data(sanitizedText.utf8)
            return try JSONDecoder().decode(PaywallCountryContextCatalog.self, from: sanitizedData)
        } catch {
            print("⚠️ [PaywallContext] Could not decode PaywallCountryContext.json: \(error.localizedDescription). Using fallback templates.")
            return fallbackCatalog
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

    private static var fallbackCatalog: PaywallCountryContextCatalog {
        PaywallCountryContextCatalog(
            default: PaywallCountryContextTemplate(
                note: "Fallback template.",
                yearlyPrimary: "Free trial, then just {{yearly_monthly}}/month ✨",
                yearlySecondary: "Less than a coffee a month.",
                monthlyPrimary: "About {{monthly_weekly}} /week ✨",
                monthlySecondary: "Save more every tme you shop"
            ),
            countries: [:]
        )
    }
}
