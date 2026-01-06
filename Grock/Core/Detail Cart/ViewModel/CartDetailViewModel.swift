//import Foundation
//import SwiftUI
//
//@MainActor
//class CartDetailViewModel: ObservableObject {
//    private let vaultService: VaultService
//    private let cartViewModel: CartViewModel
//    let cart: Cart
//    
//    @Published var showingDeleteAlert = false
//    @Published var editingItem: CartItem?
//    @Published var showingCompleteAlert = false
//    @Published var showingStartShoppingAlert = false
//    @Published var showingSwitchToPlanningAlert = false
//    @Published var anticipationOffset: CGFloat = 0
//    @Published var selectedFilter: FilterOption = .all
//    @Published var showingFilterSheet = false
//    @Published var headerHeight: CGFloat = 0
//    @Published var animatedFulfilledAmount: Double = 0
//    @Published var animatedFulfilledPercentage: Double = 0
//    @Published var itemToEdit: Item?
//    @Published var showingAddItemSheet = false
//    @Published var previousHasItems = false
//    @Published var showCelebration = false
//    @Published var manageCartButtonVisible = false
//    @Published var buttonScale: CGFloat = 1.0
//    @Published var shouldBounceAfterCelebration = false
//    @Published var cartReady = false
//    @Published var refreshTrigger = UUID()
//    @Published var showFinishTripButton = false
//    @Published var bottomSheetDetent: PresentationDetent = .fraction(0.08)
//    @Published var showingCompletedSheet = false
//    @Published var showingShoppingPopover = false
//    @Published var selectedCartItemForPopover: CartItem?
//    @Published var selectedItemForPopover: Item?
//    @Published var showingFulfillPopover = false
//    @Published var showingEditCartName = false
//    
//    // MARK: - Computed Properties
//    var cartInsights: CartInsights {
//        vaultService.getCartInsights(cart: cart)
//    }
//    
//    var itemsByStore: [String: [(cartItem: CartItem, item: Item?)]] {
//        let sortedCartItems = cart.cartItems.sorted { $0.itemId < $1.itemId }
//        let cartItemsWithDetails = sortedCartItems.map { cartItem in
//            (cartItem, vaultService.findItemById(cartItem.itemId))
//        }
//        let grouped = Dictionary(grouping: cartItemsWithDetails) { cartItem, item in
//            cartItem.getStore(cart: cart)
//        }
//        return grouped.filter { !$0.key.isEmpty && !$0.value.isEmpty }
//    }
//    
//    var itemsByStoreWithRefresh: [String: [(cartItem: CartItem, item: Item?)]] {
//        _ = refreshTrigger
//        let sortedCartItems = cart.cartItems.sorted { $0.addedAt > $1.addedAt }
//        let cartItemsWithDetails = sortedCartItems.map { cartItem in
//            (cartItem, vaultService.findItemById(cartItem.itemId))
//        }
//        let grouped = Dictionary(grouping: cartItemsWithDetails) { cartItem, item in
//            cartItem.getStore(cart: cart)
//        }
//        return grouped.filter { !$0.key.isEmpty && !$0.value.isEmpty }
//    }
//    
//    var sortedStores: [String] {
//        Array(itemsByStore.keys).sorted()
//    }
//    
//    var sortedStoresWithRefresh: [String] {
//        Array(itemsByStoreWithRefresh.keys).sorted()
//    }
//    
//    var totalItemCount: Int {
//        cart.cartItems.count
//    }
//    
//    var hasItems: Bool {
//        totalItemCount > 0 && !sortedStores.isEmpty
//    }
//    
//    var shouldAnimateTransition: Bool {
//        previousHasItems != hasItems
//    }
//    
//    func storeItems(for store: String) -> [(cartItem: CartItem, item: Item?)] {
//        itemsByStore[store] ?? []
//    }
//    
//    func storeItemsWithRefresh(for store: String) -> [(cartItem: CartItem, item: Item?)] {
//        itemsByStoreWithRefresh[store] ?? []
//    }
//    
//    var currentFulfilledCount: Int {
//        cart.cartItems.filter { $0.isFulfilled }.count
//    }
//    
//    // MARK: - Initializer
//    init(cart: Cart, vaultService: VaultService, cartViewModel: CartViewModel) {
//        self.cart = cart
//        self.vaultService = vaultService
//        self.cartViewModel = cartViewModel
//    }
//    
//    // MARK: - Actions
//    
//    func checkAndShowCelebration() {
//        let hasSeenCelebration = UserDefaults.standard.bool(forKey: "hasSeenFirstShoppingCartCelebration")
//        
//        print("🎉 Cart Celebration Debug:")
//        print(" - hasSeenCelebration: \(hasSeenCelebration)")
//        print(" - Total carts: \(cartViewModel.carts.count)")
//        print(" - Current cart name: \(cart.name)")
//        print(" - Current cart ID: \(cart.id)")
//        
//        guard !hasSeenCelebration else {
//            print("⏭️ Skipping first cart celebration - already seen")
//            manageCartButtonVisible = true
//            return
//        }
//        
//        let isFirstCart = cartViewModel.carts.count == 1 || cartViewModel.isFirstCart(cart)
//        print(" - Is first cart: \(isFirstCart)")
//        
//        if isFirstCart {
//            print("🎉 First cart celebration triggered!")
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                self.showCelebration = true
//                
//                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
//                    withAnimation {
//                        self.manageCartButtonVisible = true
//                    }
//                }
//            }
//            UserDefaults.standard.set(true, forKey: "hasSeenFirstShoppingCartCelebration")
//        } else {
//            print("⏭️ Not the first cart - no celebration")
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                withAnimation {
//                    self.manageCartButtonVisible = true
//                }
//            }
//        }
//    }
//    
//    func startShopping() {
//        vaultService.startShopping(cart: cart)
//        refreshTrigger = UUID()
//    }
//    
//    func returnToPlanning() {
//        vaultService.returnToPlanning(cart: cart)
//        refreshTrigger = UUID()
//    }
//    
//    func completeShopping() {
//        vaultService.completeShopping(cart: cart)
//        refreshTrigger = UUID()
//        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//            showingCompletedSheet = false
//        }
//    }
//    
//    func deleteCart(dismiss: DismissAction) {
//        vaultService.deleteCart(cart)
//        dismiss()
//    }
//    
//    // REMOVED: The addItemToCart method since CartAddItemSheet now handles everything internally
//    
//    func updateCartName(_ newName: String) {
//        cart.name = newName
//        vaultService.updateCartTotals(cart: cart)
//        refreshTrigger = UUID()
//    }
//    
//    func updateCartTotals() {
//        vaultService.updateCartTotals(cart: cart)
//        refreshTrigger = UUID()
//    }
//    
//    func handleCartStatusChange(oldValue: CartStatus, newValue: CartStatus) {
//        print("🛒 Cart status changed: \(oldValue) -> \(newValue)")
//        
//        if oldValue != newValue {
//            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                if newValue == .shopping && hasItems {
//                    showFinishTripButton = true
//                } else if newValue == .planning {
//                    showFinishTripButton = false
//                }
//            }
//        }
//        
//        if newValue == .shopping && hasItems {
//            let currentFulfilledCount = cart.cartItems.filter { $0.isFulfilled }.count
//            if currentFulfilledCount > 0 {
//                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                    showingCompletedSheet = true
//                }
//            }
//        } else if newValue == .planning {
//            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                showingCompletedSheet = false
//            }
//        }
//    }
//    
//    func handleItemsChange(oldValue: Bool, newValue: Bool) {
//        print("📦 Items changed: \(oldValue) -> \(newValue)")
//        
//        if oldValue != newValue {
//            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                if cart.isShopping && newValue {
//                    showFinishTripButton = true
//                } else if !newValue {
//                    showFinishTripButton = false
//                }
//            }
//        }
//    }
//    
//    // MARK: - New Helper Methods for Popovers
//    
//    func handleEditItemPopover(_ cartItem: CartItem, item: Item?) {
//        selectedCartItemForPopover = cartItem
//        selectedItemForPopover = item
//        showingShoppingPopover = true
//    }
//    
//    func handleFulfillItemPopover(_ cartItem: CartItem, item: Item?) {
//        selectedCartItemForPopover = cartItem
//        selectedItemForPopover = item
//        showingFulfillPopover = true
//    }
//    
//    func clearSelectedItem() {
//        selectedCartItemForPopover = nil
//        selectedItemForPopover = nil
//        showingShoppingPopover = false
//        showingFulfillPopover = false
//    }
//    
//    // MARK: - Navigation Helpers
//    
//    func navigateToEditItemSheet(_ item: Item) {
//        itemToEdit = item
//    }
//    
//    func clearItemToEdit() {
//        itemToEdit = nil
//    }
//}


