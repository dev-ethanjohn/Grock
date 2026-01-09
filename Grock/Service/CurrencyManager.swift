import Foundation

struct Currency: Identifiable, Equatable, Hashable {
    var id: String { code }
    let code: String
    let symbol: String
    let name: String
    
    static let `default` = Currency(code: "USD", symbol: "$", name: "United States Dollar")
}

@Observable
final class CurrencyManager {
    static let shared = CurrencyManager()
    
    private init() {
        loadSelectedCurrency()
    }
    
    private(set) var selectedCurrency: Currency = .default
    
    var availableCurrencies: [Currency] {
        let currencies = [
            Currency(code: "USD", symbol: "$", name: "United States Dollar"),
            Currency(code: "EUR", symbol: "€", name: "Euro"),
            Currency(code: "GBP", symbol: "£", name: "British Pound Sterling"),
            Currency(code: "JPY", symbol: "¥", name: "Japanese Yen"),
            Currency(code: "AUD", symbol: "A$", name: "Australian Dollar"),
            Currency(code: "CAD", symbol: "C$", name: "Canadian Dollar"),
            Currency(code: "CHF", symbol: "Fr", name: "Swiss Franc"),
            Currency(code: "CNY", symbol: "¥", name: "Chinese Yuan"),
            Currency(code: "INR", symbol: "₹", name: "Indian Rupee"),
            Currency(code: "KRW", symbol: "₩", name: "South Korean Won"),
            Currency(code: "PHP", symbol: "₱", name: "Philippine Peso"),
            Currency(code: "SGD", symbol: "S$", name: "Singapore Dollar"),
            Currency(code: "THB", symbol: "฿", name: "Thai Baht"),
            
            // Added Currencies
            Currency(code: "BRL", symbol: "R$", name: "Brazilian Real"),
            Currency(code: "ZAR", symbol: "R", name: "South African Rand"),
            Currency(code: "MXN", symbol: "$", name: "Mexican Peso"),
            Currency(code: "RUB", symbol: "₽", name: "Russian Ruble"),
            Currency(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar"),
            Currency(code: "NZD", symbol: "NZ$", name: "New Zealand Dollar"),
            Currency(code: "SEK", symbol: "kr", name: "Swedish Krona"),
            Currency(code: "NOK", symbol: "kr", name: "Norwegian Krone"),
            Currency(code: "DKK", symbol: "kr", name: "Danish Krone"),
            Currency(code: "IDR", symbol: "Rp", name: "Indonesian Rupiah"),
            Currency(code: "MYR", symbol: "RM", name: "Malaysian Ringgit"),
            Currency(code: "TRY", symbol: "₺", name: "Turkish Lira")
        ]
        
        return currencies.sorted { $0.name < $1.name }
    }
    
    // Add computed property for local currency
    var localCurrency: Currency? {
        let locale = Locale.current
        let currencyCode = locale.currency?.identifier ?? "USD"
        
        // Find if this currency exists in our available list
        if let existing = availableCurrencies.first(where: { $0.code == currencyCode }) {
            return existing
        }
        
        // Otherwise create it dynamically
        let currencySymbol = locale.currencySymbol ?? "$"
        let currencyName = locale.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
        return Currency(code: currencyCode, symbol: currencySymbol, name: currencyName)
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
                // Use device locale currency if not in available list
                // For the fallback, try to get a localized name or default to code
                let currencyName = locale.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
                selectedCurrency = Currency(code: currencyCode, symbol: currencySymbol, name: currencyName)
            }
            saveSelectedCurrency()
        }
    }
    
    func resetCurrency() {
        UserDefaults.standard.removeObject(forKey: "selectedCurrencyCode")
        UserDefaults.standard.removeObject(forKey: "selectedCurrencySymbol")
        loadSelectedCurrency()
    }
    
    private func saveSelectedCurrency() {
        UserDefaults.standard.set(selectedCurrency.code, forKey: "selectedCurrencyCode")
        UserDefaults.standard.set(selectedCurrency.symbol, forKey: "selectedCurrencySymbol")
    }
}