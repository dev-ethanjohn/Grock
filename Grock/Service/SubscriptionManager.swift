import SwiftUI
import Observation

@Observable
class SubscriptionManager {
    static let shared = SubscriptionManager()
    
    var isPro: Bool = false
    
    private init() {
        self.isPro = UserDefaults.standard.isPro
    }
    
    func setProStatus(_ status: Bool) {
        UserDefaults.standard.isPro = status
        self.isPro = status
    }
    
    func togglePro() {
        setProStatus(!isPro)
    }
}
