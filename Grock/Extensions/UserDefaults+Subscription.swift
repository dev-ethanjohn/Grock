import Foundation

extension UserDefaults {
    private enum SubscriptionKeys {
        static let isPro = "isPro"
        static let freeEditableStoreKeys = "freeEditableStoreKeys"
        static let freePrimaryEditableCartId = "freePrimaryEditableCartId"
        static let grandfatheredLockedPlanningSelectionKeysByCartId = "grandfatheredLockedPlanningSelectionKeysByCartId"
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

    var grandfatheredLockedPlanningSelectionKeysByCartId: [String: [String]] {
        get {
            dictionary(forKey: SubscriptionKeys.grandfatheredLockedPlanningSelectionKeysByCartId) as? [String: [String]] ?? [:]
        }
        set {
            if newValue.isEmpty {
                removeObject(forKey: SubscriptionKeys.grandfatheredLockedPlanningSelectionKeysByCartId)
            } else {
                set(newValue, forKey: SubscriptionKeys.grandfatheredLockedPlanningSelectionKeysByCartId)
            }
        }
    }
}
