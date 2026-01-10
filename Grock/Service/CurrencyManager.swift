import Foundation

struct Currency: Identifiable, Equatable, Hashable {
    var id: String { code }
    let code: String
    let symbol: String
    
    static let `default` = Currency(code: "USD", symbol: "$")
}

@Observable
final class CurrencyManager {
    static let shared = CurrencyManager()
    
    private init() {
        loadSelectedCurrency()
    }
    
    private(set) var selectedCurrency: Currency = .default
    
    var availableCurrencies: [Currency] {
        [
            Currency(code: "USD", symbol: "$"),
            Currency(code: "EUR", symbol: "€"),
            Currency(code: "GBP", symbol: "£"),
            Currency(code: "JPY", symbol: "¥"),
            Currency(code: "AUD", symbol: "A$"),
            Currency(code: "CAD", symbol: "C$"),
            Currency(code: "CHF", symbol: "Fr"),
            Currency(code: "CNY", symbol: "¥"),
            Currency(code: "INR", symbol: "₹"),
            Currency(code: "KRW", symbol: "₩"),
            Currency(code: "PHP", symbol: "₱"),
            Currency(code: "SGD", symbol: "S$"),
            Currency(code: "THB", symbol: "฿")
        ]
    }
    
    func setCurrency(_ currency: Currency) {
        selectedCurrency = currency
        saveSelectedCurrency()
    }
    
    private func loadSelectedCurrency() {
        if let savedCode = UserDefaults.standard.string(forKey: "selectedCurrencyCode"),
           let savedSymbol = UserDefaults.standard.string(forKey: "selectedCurrencySymbol"),
           let currency = availableCurrencies.first(where: { $0.code == savedCode && $0.symbol == savedSymbol }) {
            selectedCurrency = currency
        } else {
            // Default to locale currency
            let locale = Locale.current
            let currencyCode = locale.currency?.identifier ?? "USD"
            let currencySymbol = locale.currencySymbol ?? "$"
            
            if let localeCurrency = availableCurrencies.first(where: { $0.code == currencyCode }) {
                selectedCurrency = localeCurrency
            } else if let symbolMatch = availableCurrencies.first(where: { $0.symbol == currencySymbol }) {
                selectedCurrency = symbolMatch
            } else {
                selectedCurrency = .default
            }
            saveSelectedCurrency()
        }
    }
    
    private func saveSelectedCurrency() {
        UserDefaults.standard.set(selectedCurrency.code, forKey: "selectedCurrencyCode")
        UserDefaults.standard.set(selectedCurrency.symbol, forKey: "selectedCurrencySymbol")
    }
}