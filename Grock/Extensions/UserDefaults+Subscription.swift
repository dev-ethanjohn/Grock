import Foundation

extension UserDefaults {
    private enum SubscriptionKeys {
        static let isPro = "isPro"
    }

    var isPro: Bool {
        get { bool(forKey: SubscriptionKeys.isPro) }
        set { set(newValue, forKey: SubscriptionKeys.isPro) }
    }
}
