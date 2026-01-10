import Foundation

struct Currency: Identifiable, Equatable, Hashable {
    var id: String { code }
    let code: String
    let symbol: String
    let name: String
    
    static let `default` = Currency(code: "USD", symbol: "$", name: "US Dollar")
}

@Observable
final class CurrencyManager {
    static let shared = CurrencyManager()
    
    private init() {
        loadAvailableCurrencies()
        loadSelectedCurrency()
    }
    
    private(set) var selectedCurrency: Currency = .default
    private(set) var availableCurrencies: [Currency] = []
    
    func setCurrency(_ currency: Currency) {
        selectedCurrency = currency
        saveSelectedCurrency()
    }
    
    private func loadAvailableCurrencies() {
        let locale = Locale.current
        let codes = Locale.commonISOCurrencyCodes
        
        var currencies: [Currency] = []
        
        for code in codes {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = code
            let symbol = formatter.currencySymbol ?? code
            let name = locale.localizedString(forCurrencyCode: code) ?? code
            
            currencies.append(Currency(code: code, symbol: symbol, name: name))
        }
        
        // Sort alphabetically by code
        currencies.sort { $0.code < $1.code }
        
        // Move local currency to top
        let currentCode = locale.currency?.identifier ?? "USD"
        if let index = currencies.firstIndex(where: { $0.code == currentCode }) {
            let local = currencies.remove(at: index)
            currencies.insert(local, at: 0)
        }
        
        self.availableCurrencies = currencies
    }
    
    private func loadSelectedCurrency() {
        if let savedCode = UserDefaults.standard.string(forKey: "selectedCurrencyCode"),
           let savedSymbol = UserDefaults.standard.string(forKey: "selectedCurrencySymbol"),
           let currency = availableCurrencies.first(where: { $0.code == savedCode }) {
            selectedCurrency = currency
        } else {
            // Default to locale currency (which should be first in list)
            if let first = availableCurrencies.first {
                selectedCurrency = first
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