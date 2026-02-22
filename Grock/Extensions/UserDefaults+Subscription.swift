import Foundation

extension UserDefaults {
    private enum SubscriptionKeys {
        static let isPro = "isPro"
        static let freeEditableStoreKeys = "freeEditableStoreKeys"
    }

    var isPro: Bool {
        get { bool(forKey: SubscriptionKeys.isPro) }
        set { set(newValue, forKey: SubscriptionKeys.isPro) }
    }

    var freeEditableStoreKeys: [String] {
        get { array(forKey: SubscriptionKeys.freeEditableStoreKeys) as? [String] ?? [] }
        set { set(newValue, forKey: SubscriptionKeys.freeEditableStoreKeys) }
    }
}
