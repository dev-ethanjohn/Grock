import SwiftUI

struct VaultMainContent: View {
    @Environment(VaultService.self) private var vaultService
    @Environment(CartViewModel.self) private var cartViewModel
    
    @Binding var selectedCategory: GroceryCategory?
    @Binding var categorySectionHeight: CGFloat
    @Binding var toolbarAppeared: Bool
    @Binding var showAddItemPopover: Bool
    @Binding var createCartButtonVisible: Bool
    @Binding var hasActiveItems: Bool
    
    let onAddTapped: () -> Void
    let onDismissTapped: () -> Void
    let onClearTapped: () -> Void
    let categoryScrollView: AnyView
    let categoryContentScrollView: AnyView
    let dismissKeyboard: () -> Void
    
    var body: some View {
        if vaultService.vault != nil {
            VStack(spacing: 0) {
                VaultToolbarView(
                    toolbarAppeared: $toolbarAppeared,
                    onAddTapped: onAddTapped,
                    onDismissTapped: onDismissTapped,
                    onClearTapped: onClearTapped,
                    showClearButton: hasActiveItems
                )
                
                if let vault = vaultService.vault, !vault.categories.isEmpty {
                    ZStack(alignment: .top) {
                        categoryContentScrollView
                            .frame(maxHeight: .infinity)
                            .padding(.top, categorySectionHeight)
                            .zIndex(0)
                        
                        VaultCategorySectionView(selectedCategory: selectedCategory) {
                            categoryScrollView
                        }
                        .onTapGesture {
                            dismissKeyboard()
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        categorySectionHeight = geo.size.height
                                    }
                                    .onChange(of: geo.size.height) { _, newValue in
                                        categorySectionHeight = newValue
                                    }
                            }
                        )
                        .zIndex(1)
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
    }
}
