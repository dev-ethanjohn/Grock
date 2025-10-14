//  CartConfirmationPopover.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/10/25.
//
import SwiftUI

// MARK: - Preference Keys and Extensions

extension View {
    /// This `offset` is needed to get the CGRect value from the view
    /// with this function, we can get the values we needed
    @ViewBuilder
    func offset(completion: @escaping (CGRect)->()) -> some View {
        self
            .overlay {
                GeometryReader { geo in
                    let rect = geo.frame(in: .named(Constants.offsetNameSpace))
                    Color.clear
                        .preference(key: OffsetKey.self, value: rect)
                        .onPreferenceChange(OffsetKey.self) { value in
                            completion(value)
                        }
                }
            }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    /// with this function, we can get the scroll view indicator position
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) { }
}

struct OffsetKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct Constants {
    static let offsetNameSpace: String = "offset-namespace"
}

// MARK: - Vertical Scroll View with Custom Indicator
struct VerticalScrollViewWithCustomIndicator<Content: View>: View {
    
    private let contentBody: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.contentBody = content
    }
    
    @State private var scrollPosition: CGPoint = .zero
    @State private var startOffset: CGFloat = 0
    @State private var indicatorOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    
    private let indicatorBgHeight: CGFloat = 200
    private let indicatorFrontHeight: CGFloat = 60
    private let indicatorWidth: CGFloat = 6
    private let paddingContentToScrollIndicator: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            
            GeometryReader { geometryParent in
                
                HStack(alignment: .top, spacing: 0) {
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        
                        // MARK: Scroll view content
                        contentBody()
                            .background(
                                GeometryReader { contentGeometry in
                                    Color.clear
                                        .onAppear {
                                            contentHeight = contentGeometry.size.height
                                        }
                                        .onChange(of: contentGeometry.size.height) {_, newHeight in
                                            contentHeight = newHeight
                                        }
                                }
                            )
                            .offset { rect in
                                
                                // MARK: FINDING SCROLL INDICATOR OFFSET (VERTICAL)
                                let viewHeight = geometryParent.size.height
                                
                                // Calculate how much content is visible vs hidden
                                let hiddenContentHeight = max(0, contentHeight - viewHeight)
                                
                                if hiddenContentHeight > 0 {
                                    // Current scroll position (0 = top, hiddenContentHeight = bottom)
                                    let currentScroll = -scrollPosition.y
                                    
                                    // Calculate progress (0 to 1)
                                    let scrollProgress = max(0, min(1, currentScroll / hiddenContentHeight))
                                    
                                    // Calculate indicator position within available space
                                    let availableSpace = indicatorBgHeight - indicatorFrontHeight
                                    let newOffset = scrollProgress * availableSpace
                                    
                                    // Apply bounds checking
                                    indicatorOffset = max(0, min(newOffset, availableSpace))
                                } else {
                                    indicatorOffset = 0
                                }
                                
                            }
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .preference(
                                            key: ScrollOffsetPreferenceKey.self,
                                            value: geometry.frame(in: .named(Constants.offsetNameSpace)).origin
                                        )
                                }
                            )
                            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                                self.scrollPosition = value
                            }
                        
                    }
                    .coordinateSpace(name: Constants.offsetNameSpace)
                    
                }
                .padding(0)
                
            }
            .offset { rect in
                if startOffset != rect.minY {
                    startOffset = rect.minY
                }
            }
            
            
            // MARK: Custom vertical scroll view indicator
            GeometryReader { geometry in
                
                // Apply clipping to the entire ZStack container
                ZStack(alignment: .top) {
                    // Background track - this defines the clipping bounds
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: indicatorWidth, height: indicatorBgHeight)
                        .padding(.trailing, paddingContentToScrollIndicator)
                        .zIndex(0)
                    
                    
                    RoundedRectangle(cornerRadius: 2)
                        .frame(width: indicatorWidth, height: indicatorFrontHeight)
                        .foregroundColor(.gray.opacity(0.7))
                        .padding(.trailing, paddingContentToScrollIndicator)
                        .zIndex(1)
                        .offset(y: indicatorOffset)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: indicatorOffset)
                }
                
                .frame(height: indicatorBgHeight)
                .clipped()
                .offset(x: 8)
                
            }
            .frame(width: 20)
            
            
        }
        .padding(0)
        .frame(maxHeight: 200)
    }
}


// MARK: - Cart Confirmation Popover
struct CartConfirmationPopover: View {
    @Binding var isPresented: Bool
    let activeCartItems: [String: Double]
    let vaultService: VaultService
    let onConfirm: (String, Double) -> Void
    let onCancel: () -> Void
    
    @State private var cartTitle: String = ""
    @State private var budget: String = ""
    @FocusState private var focusedField: Field?
    @State private var showing = false
    
    private enum Field {
        case title, budget
    }
    
    private var activeItemsWithDetails: [(item: Item, quantity: Double)] {
        activeCartItems.compactMap { itemId, quantity in
            guard let item = findItemById(itemId) else { return nil }
            return (item, quantity)
        }
    }
    
    private var totalCartValue: Double {
        activeItemsWithDetails.reduce(0) { total, itemData in
            let (item, quantity) = itemData
            let price = item.priceOptions.first?.pricePerUnit.priceValue ?? 0.0
            return total + (price * quantity)
        }
    }
    
    private var budgetValue: Double {
        Double(budget) ?? 0.0
    }
    
    private var isOverBudget: Bool {
        budgetValue > 0 && totalCartValue > budgetValue
    }
    
    private var canConfirm: Bool {
        !cartTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                titleSection
                itemsSection
                dividerSection
                totalsSection
                buttonsSection
            }
            .frame(width: UIScreen.main.bounds.width * 0.92)
            .presentationBackground(.clear)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 1)
        .frame(width: UIScreen.main.bounds.width * 1)
        .background(Color.white.opacity(0.01))
        .scaleEffect(showing ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                showing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = .title
            }
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            focusedField = nil
        }
    }
    
    // MARK: - Subviews
    
    private var titleSection: some View {
        VStack(spacing: 0) {
            TextField("Shopping List", text: $cartTitle)
                .lexendFont(20, weight: .semibold)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .budget
                }
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .offset(y: 8)
        }
        .padding(20)
    }
    
    private var itemsSection: some View {
        Group {
            if activeItemsWithDetails.isEmpty {
                emptyCartView
            } else {
                itemsListView
            }
        }
    }
    
    private var emptyCartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No items selected")
                .font(.fuzzyBold_16)
                .foregroundColor(.gray)
        }
        .frame(minHeight: 120)
        .padding(.horizontal, 20)
    }
    
    private var itemsListView: some View {
        Group {
            if activeItemsWithDetails.count <= 4 {
                // Just use VStack for small number of items
                VStack(spacing: 0) {
                    ForEach(Array(activeItemsWithDetails.enumerated()), id: \.element.item.id) { index, data in
                        let (item, quantity) = data
                        CartItemRow(item: item, quantity: quantity, isLastItem: index == activeItemsWithDetails.count - 1)
                    }
                }
                .padding(.horizontal, 20)
            } else {
                // Use Custom ScrollView with moving indicator
                VerticalScrollViewWithCustomIndicator {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(activeItemsWithDetails.enumerated()), id: \.element.item.id) { index, data in
                            let (item, quantity) = data
                            CartItemRow(item: item, quantity: quantity, isLastItem: index == activeItemsWithDetails.count - 1)
                        }
                    }
                    .padding(.leading, 20)
                }
            }
        }
    }
    
    private var dividerSection: some View {
        Text("• • •")
            .frame(maxWidth: .infinity)
            .padding(.bottom, 8)
            .foregroundStyle(.gray)
    }
    
    private var totalsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Estimated Total:")
                    .lexendFont(16)
                Spacer()
                Text(formatCurrency(totalCartValue))
                    .lexendFont(16, weight: .medium)
            }
            
            budgetRow
                .padding(.bottom)
        }
        .padding(.horizontal, 20)
    }
    
    private var buttonsSection: some View {
        HStack(spacing: 12) {
            cancelButton
            confirmButton
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private var cancelButton: some View {
        Button(action: {
            focusedField = nil
            
            // This stays EXACTLY the same
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)) {
                showing = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onCancel()
            }
        }) {
            Text("Cancel")
                .font(.fuzzyBold_16)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
    }
    
    private var confirmButton: some View {
        Button(action: {
            focusedField = nil
            
            withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)) {
                showing = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onCancel()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    onConfirm(cartTitle, budgetValue)
                }
            }
        })  {
            Text("Confirm")
                .font(.fuzzyBold_16)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(canConfirm ? Color.black : Color.gray)
                .cornerRadius(10)
        }
        .disabled(!canConfirm)
    }
    
    private var budgetRow: some View {
        HStack {
            Text("Budget:")
                .lexendFont(16)
            Spacer()
            
            HStack(spacing: 4) {
                Text("₱")
                    .lexendFont(18, weight: .medium)
                    .foregroundStyle(budget.isEmpty ? .gray : .black)
                
                Text(budget.isEmpty ? "0" : budget)
                    .foregroundStyle(budget.isEmpty ? .gray : .black)
                    .lexendFont(18, weight: .medium)
                    .multilineTextAlignment(.trailing)
                    .overlay(
                        TextField("0", text: $budget)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                            .fixedSize(horizontal: true, vertical: false)
                            .autocorrectionDisabled(true)
                            .offset(x: 0)
                            .textInputAutocapitalization(.never)
                            .numbersOnly($budget, includeDecimal: true, maxDigits: 10)
                            .lexendFont(18, weight: .medium)
                            .focused($focusedField, equals: .budget)
                            .opacity(focusedField == .budget ? 1 : 0)
                            .onAppear {
                                if budgetValue > 0 {
                                    let formatter = NumberFormatter()
                                    formatter.numberStyle = .decimal
                                    formatter.maximumFractionDigits = 2
                                    formatter.minimumFractionDigits = 0
                                    budget = formatter.string(from: NSNumber(value: budgetValue)) ?? ""
                                }
                            }
                    )
            }
            .background(
                Group {
                    if !budget.isEmpty {
                        GeometryReader { geometry in
                            ZStack(alignment: .bottom) {
                                // Highlight background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isOverBudget ? Color.red.opacity(0.28) : Color.green.opacity(0.28))
                                    .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                                    .offset(y: geometry.size.height * 0.15)
                                
                                // Underline at bottom
                                Rectangle()
                                    .fill(.black)
                                    .frame(width: geometry.size.width, height: 2)
                                    .offset(y: 8)
                            }
                        }
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = .budget
            }
        }
        .padding(.bottom)
    }
    
    // MARK: - Helper Methods
    
    private func formatCurrency(_ value: Double) -> String {
        if value == Double(Int(value)) {
            // Whole number - remove decimals
            return "₱\(Int(value))"
        } else if value * 10 == Double(Int(value * 10)) {
            // Single decimal place (like 12.50 becomes 12.5)
            return String(format: "₱%.1f", value)
        } else {
            // Two decimal places
            return String(format: "₱%.2f", value)
        }
    }
    
    private func findItemById(_ itemId: String) -> Item? {
        guard let vault = vaultService.vault else { return nil }
        
        for category in vault.categories {
            if let item = category.items.first(where: { $0.id == itemId }) {
                return item
            }
        }
        return nil
    }
}
