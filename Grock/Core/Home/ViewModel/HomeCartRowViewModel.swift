import SwiftUI
import Observation

@Observable
class HomeCartRowViewModel {
    var animatedBudget: Double = 0
    private var cartId: String
    private var lastUpdateTime: Date = Date()
    private var updateWorkItem: DispatchWorkItem?
    
    init(cart: Cart) {
        self.cartId = cart.id
        self.animatedBudget = cart.budget
    }
    
    func updateBudget(_ newBudget: Double, animated: Bool = true) {
        // Cancel any pending updates
        updateWorkItem?.cancel()
        
        if animated {
            // Use linear animation for smoother transition
            let workItem = DispatchWorkItem { [weak self] in
                Task { @MainActor in
                    withAnimation(.linear(duration: 0.3)) {
                        self?.animatedBudget = newBudget
                    }
                }
            }
            
            updateWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
        } else {
            // Update immediately without animation
            animatedBudget = newBudget
        }
        
        lastUpdateTime = Date()
    }
}
