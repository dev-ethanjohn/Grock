import SwiftUI

struct CartItemRow: View {
    let item: Item
    let quantity: Double
    let isLastItem: Bool
    let selectedStore: String?

    init(item: Item, quantity: Double, isLastItem: Bool, selectedStore: String? = nil) {
        self.item = item
        self.quantity = quantity
        self.isLastItem = isLastItem
        self.selectedStore = selectedStore
    }
    
    private var displayQuantity: String {
        if quantity == Double(Int(quantity)) {
            return "\(Int(quantity))"
        } else {
            return "\(quantity)"
        }
    }
    
    private var displayUnit: String {
        if let selectedPriceOption {
            return selectedPriceOption.pricePerUnit.unit
        }
        return ""
    }
    
    private var itemPrice: Double {
        selectedPriceOption?.pricePerUnit.priceValue ?? 0.0
    }
    
    private var itemTotal: Double {
        itemPrice * quantity
    }
    
    private var displayTotal: String {
        let symbol = CurrencyManager.shared.selectedCurrency.symbol
        if itemTotal == Double(Int(itemTotal)) {
            // Whole number - remove decimals
            return "\(symbol)\(Int(itemTotal))"
        } else if itemTotal * 10 == Double(Int(itemTotal * 10)) {
            // Single decimal place (like 12.50 becomes 12.5)
            return String(format: "%@%.1f", symbol, itemTotal)
        } else {
            // Two decimal places
            return String(format: "%@%.2f", symbol, itemTotal)
        }
    }

    private var selectedPriceOption: PriceOption? {
        if let selectedStore {
            return item.priceOptions.first(where: { $0.store.caseInsensitiveCompare(selectedStore) == .orderedSame })
                ?? item.priceOptions.first
        }
        return item.priceOptions.first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                
                Text("\(displayQuantity)\(displayUnit) - \(item.name)")
                    .lexendFont(15, weight: .regular)
                
                Spacer()
                
                Text(displayTotal)
                    .lexendFont(16, weight: .light)
                
            }
            .padding(.vertical, 8)
            .padding(.bottom, 2)
            .padding(.trailing, 2)
            
            if !isLastItem {
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [8, 4]))
                    .frame(height: 1)
                    .foregroundColor(Color(hex: "ddd"))
            }
        }
    }
}

#Preview {
    let pricePerUnit1 = PricePerUnit(priceValue: 49.99, unit: "kg")
    let priceOption1 = PriceOption(store: "SuperMart", pricePerUnit: pricePerUnit1)
    
    let pricePerUnit2 = PricePerUnit(priceValue: 12.50, unit: "pc")
    let priceOption2 = PriceOption(store: "BudgetStore", pricePerUnit: pricePerUnit2)
    
    let pricePerUnit3 = PricePerUnit(priceValue: 30.0, unit: "kg")
    let priceOption3 = PriceOption(store: "FreshMart", pricePerUnit: pricePerUnit3)
    
    let item1 = Item(name: "Apples")
    item1.priceOptions = [priceOption1]
    
    let item2 = Item(name: "Toothbrush")
    item2.priceOptions = [priceOption2]
    
    let item3 = Item(name: "Bananas")
    item3.priceOptions = [priceOption3]
    
    return ZStack {
        Color.black.opacity(0.05)
            .ignoresSafeArea()
        
        VStack(spacing: 0) {
            CartItemRow(item: item1, quantity: 1.5, isLastItem: false)
            CartItemRow(item: item2, quantity: 3, isLastItem: false)
            CartItemRow(item: item3, quantity: 2, isLastItem: true)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding()
    }

}
