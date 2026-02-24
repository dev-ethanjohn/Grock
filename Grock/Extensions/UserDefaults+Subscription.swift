import Foundation

extension UserDefaults {
    private enum SubscriptionKeys {
        static let isPro = "isPro"
        static let freeEditableStoreKeys = "freeEditableStoreKeys"
        static let freePrimaryEditableCartId = "freePrimaryEditableCartId"
    }

    var isPro: Bool {
        get { bool(forKey: SubscriptionKeys.isPro) }
        set { set(newValue, forKey: SubscriptionKeys.isPro) }
    }

    var freeEditableStoreKeys: [String] {
        get { array(forKey: SubscriptionKeys.freeEditableStoreKeys) as? [String] ?? [] }
        set { set(newValue, forKey: SubscriptionKeys.freeEditableStoreKeys) }
    }

    var freePrimaryEditableCartId: String? {
        get { string(forKey: SubscriptionKeys.freePrimaryEditableCartId) }
        set {
            if let newValue, !newValue.isEmpty {
                set(newValue, forKey: SubscriptionKeys.freePrimaryEditableCartId)
            } else {
                removeObject(forKey: SubscriptionKeys.freePrimaryEditableCartId)
            }
        }
    }
}
