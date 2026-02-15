import Foundation

enum ActiveItemSelectionKey {
    private static let separator = "||"

    static func make(itemId: String, store: String?) -> String {
        let trimmedStore = (store ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStore.isEmpty else { return itemId }
        return "\(itemId)\(separator)\(trimmedStore)"
    }

    static func parse(_ key: String) -> (itemId: String, store: String?) {
        guard let range = key.range(of: separator) else {
            return (key, nil)
        }

        let itemId = String(key[..<range.lowerBound])
        let rawStore = String(key[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        let store = rawStore.isEmpty ? nil : rawStore
        return (itemId, store)
    }

    static func itemId(from key: String) -> String {
        parse(key).itemId
    }
}
