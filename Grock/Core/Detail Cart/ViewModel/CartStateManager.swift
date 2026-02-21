import SwiftUI
import Observation


// MARK: - Cart State Manager
@Observable
final class CartStateManager {
    // Shopping/Planning toggle state
    var anticipationOffset: CGFloat = 0
    var showingStartShoppingAlert = false
    var showingSwitchToPlanningAlert = false
    var headerHeight: CGFloat = 0
    
    // Budget editing
    var showingEditBudget = false
    var localBudget: Double = 0
    var animatedBudget: Double = 0
    var isSavingBudget = false
    
    // Color management
    var selectedColor: ColorOption = .defaultColor
    var showingColorPicker = false
    var hasBackgroundImage: Bool = false
    var backgroundImage: UIImage? = nil
    
    // Mode-specific state
    var showFinishTripButton = false
    var showingCompletedSheet = false
    
    // Shopping/Planning UI state
    var showingCartSheet = false
    var showingFilterSheet = false
    var selectedFilter: FilterOption = .all
    
    // Popover state
    var showingShoppingPopover = false
    var showingFulfillPopover = false
    var showingEditCartName = false
    var selectedItemForPopover: Item? = nil
    var selectedCartItemForPopover: CartItem? = nil
    // Used to force a fresh popover instance (and fresh @State) each presentation.
    var shoppingPopoverPresentationID = UUID()
    var fulfillPopoverPresentationID = UUID()
    
    // Celebration/Animation state
    var showCelebration = false
    var showTripCompletionCelebration = false
    var tripCompletionMessage: String = ""
    var isTripFinishingFromSheet = false
    var manageCartButtonVisible = false
    var buttonScale: CGFloat = 1.0
    var shouldBounceAfterCelebration = false
    
    // Display Preferences
    var showCategoryIcons: Bool {
        didSet {
            UserDefaults.standard.set(showCategoryIcons, forKey: "showCategoryIcons")
        }
    }
    
    var showItemPriceRow: Bool {
        didSet {
            UserDefaults.standard.set(showItemPriceRow, forKey: "showItemPriceRow")
        }
    }
    
    // Drives smooth simplify/show transitions across row content and list height.
    var showItemPriceRowProgress: CGFloat
    
    init() {
        let storedShowCategoryIcons = UserDefaults.standard.object(forKey: "showCategoryIcons") as? Bool ?? false
        let storedShowItemPriceRow = UserDefaults.standard.object(forKey: "showItemPriceRow") as? Bool ?? true
        
        self.showCategoryIcons = storedShowCategoryIcons
        self.showItemPriceRow = storedShowItemPriceRow
        self.showItemPriceRowProgress = storedShowItemPriceRow ? 1 : 0
    }
    
    func setItemPriceRowVisibility(_ isVisible: Bool, animated: Bool = true) {
        let target: CGFloat = isVisible ? 1 : 0
        
        if animated {
            let transitionAnimation: Animation = isVisible
                ? .spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2)
                : .spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.1)
            
            withAnimation(transitionAnimation) {
                showItemPriceRow = isVisible
                showItemPriceRowProgress = target
            }
        } else {
            showItemPriceRow = isVisible
            showItemPriceRowProgress = target
        }
    }
    
    // Computed properties
    var backgroundColor: Color {
        selectedColor.hex == "FFFFFF" ? Color.clear : selectedColor.color.darker(by: 0.02)
    }
    
    var rowBackgroundColor: Color {
        selectedColor.hex == "FFFFFF" ? Color.clear : selectedColor.color.darker(by: 0.02)
    }
    
    var effectiveBackgroundColor: Color {
        if hasBackgroundImage {
            return Color.clear
        } else {
            return backgroundColor
        }
    }
    
    var effectiveRowBackgroundColor: Color {
        if hasBackgroundImage {
            return .clear
        } else {
            return rowBackgroundColor
        }
    }
}

// MARK: - Environment Key
struct CartStateManagerKey: EnvironmentKey {
    static let defaultValue = CartStateManager()
}

extension EnvironmentValues {
    var cartStateManager: CartStateManager {
        get { self[CartStateManagerKey.self] }
        set { self[CartStateManagerKey.self] = newValue }
    }
}
