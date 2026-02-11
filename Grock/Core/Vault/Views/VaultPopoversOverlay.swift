import SwiftUI

struct VaultPopoversOverlay: View {
    @Environment(VaultService.self) private var vaultService
    
    @Binding var showAddItemPopover: Bool
    @Binding var createCartButtonVisible: Bool
    
    var body: some View {
        Group {
            if showAddItemPopover {
                AddItemPopover(
                    isPresented: $showAddItemPopover,
                    createCartButtonVisible: $createCartButtonVisible,
                    onSave: { itemName, categoryName, store, unit, price in
                        _ = vaultService.addItem(
                            name: itemName,
                            toCategoryName: categoryName,
                            store: store,
                            price: price,
                            unit: unit
                        )
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            createCartButtonVisible = true
                        }
                    }
                )
                .transition(.opacity)
                .zIndex(1)
                .onAppear {
                    createCartButtonVisible = false
                }
            }
        }
    }
}
