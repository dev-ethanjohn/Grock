import SwiftUI
import Lottie
import SwiftData
import UIKit

struct HeaderView: View {
    let cart: Cart
    let dismiss: DismissAction
    var onBudgetTap: (() -> Void)?
    var onDeleteCart: (() -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartStateManager.self) private var stateManager
    @Environment(\.modelContext) private var modelContext
    
    private var progress: Double {
        guard stateManager.localBudget > 0 else { return 0 }
        return min(cart.totalSpent / stateManager.localBudget, 1.0)
    }
    
    @State private var headerHeight: CGFloat = 0
    
    private var budgetProgressColor: Color {
        let progress = self.progress
        if progress < 0.7 {
            return Color(hex: "98F476")
        } else if progress < 0.9 {
            return Color(hex: "FFB166")
        } else {
            return Color(hex: "F47676")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button(action: { dismiss() }) {
                    Image("back_arrow")
                        .padding(.vertical, 4)
                }
                .offset(x: -2)
                
                Spacer()
                
                ZStack {
                    HStack {
                        tripDateLabel(cart: cart)
                            .foregroundColor(Color.black.opacity(0.7))
                    }
                    .id(cart.status)
                    .transition(.scale.combined(with: .opacity))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: cart.status)
                
                Spacer()
                
                HeaderOptionsMenuButtonUIKit(
                    showCategoryIcons: stateManager.showCategoryIcons,
                    showItemPriceRow: stateManager.showItemPriceRow,
                    isPlanning: cart.isPlanning,
                    isCompleted: cart.isCompleted,
                    onEditCartName: {
                        stateManager.showingEditCartName = true
                    },
                    onToggleCategoryIcons: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            stateManager.showCategoryIcons.toggle()
                        }
                    },
                    onToggleItemPriceRow: {
                        stateManager.setItemPriceRowVisibility(!stateManager.showItemPriceRow, animated: true)
                    },
                    onStartShopping: {
                        stateManager.showingStartShoppingAlert = true
                    },
                    onReactivateCart: {
                        vaultService.reopenCart(cart: cart)
                    },
                    onDeleteCart: {
                        onDeleteCart?()
                    }
                )
                .frame(width: 28, height: 28)
            }
            .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 0) {
                    Text(cart.name)
                        .fuzzyBubblesFont(22, weight: .bold)
                        .foregroundColor(.black)
                        .padding(.trailing, 32)

                
                HStack {
                    HStack(spacing: 0) {
                        Text("Cart Value")
                            .lexendFont(11, weight: .medium)
                        
                        LottieView(animation: .named("Arrow"))
                            .playing(.fromProgress(0, toProgress: 0.5, loopMode: .playOnce))
                            .frame(width: 32, height: 26)
                            .rotationEffect(.degrees(120))
                            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                            .scaleEffect(0.8)
                            .offset(y: 4)
                            .allowsHitTesting(false)
                    }
                    
                    Spacer()
                    Text("Budget")
                        .lexendFont(11, weight: .medium)
                }
                .offset(y: 2)
                
                
                VStack(spacing: 8) {
                    FluidBudgetPillView(
                        cart: cart,
                        animatedBudget: stateManager.animatedBudget,
                        onBudgetTap: onBudgetTap,
                        hasBackgroundImage: stateManager.hasBackgroundImage,
                        isHeader: true // 👈 Mark as header
                    )
                    .frame(height: 22)
                    
                    if cart.isShopping {
                        EmptyView()
                    } else if cart.isCompleted {
                        HStack(spacing: 0) {
                            Text("Final spent \((fulfilledSpentTotal() ?? cart.totalSpent).formattedCurrency)")
                                .lexendFont(11, weight: .medium)
                                .foregroundStyle(.black.opacity(0.55))
                            Spacer()
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .background(
                  GeometryReader { geometry in
                      Color.white
                          .ignoresSafeArea(edges: .top)
                          .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 1)
                          .onAppear {
                              stateManager.headerHeight = geometry.size.height
                          }
                          .onChange(of: geometry.size.height) { _, newValue in
                              stateManager.headerHeight = newValue
                          }
                  }
              )
    }
    
    private struct HeaderOptionsMenuButtonUIKit: UIViewRepresentable {
        let showCategoryIcons: Bool
        let showItemPriceRow: Bool
        let isPlanning: Bool
        let isCompleted: Bool
        let onEditCartName: () -> Void
        let onToggleCategoryIcons: () -> Void
        let onToggleItemPriceRow: () -> Void
        let onStartShopping: () -> Void
        let onReactivateCart: () -> Void
        let onDeleteCart: () -> Void
        
        func makeUIView(context: Context) -> UIButton {
            let button = UIButton(type: .system)
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
            button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
            button.tintColor = .black
            button.showsMenuAsPrimaryAction = true
            button.changesSelectionAsPrimaryAction = false
            button.accessibilityLabel = "Cart options"
            return button
        }
        
        func updateUIView(_ uiView: UIButton, context: Context) {
            uiView.menu = buildMenu()
        }
        
        private func buildMenu() -> UIMenu {
            var children: [UIMenuElement] = []
            
            children.append(
                UIAction(title: "Edit Cart Name", image: UIImage(systemName: "pencil")) { _ in
                    onEditCartName()
                }
            )
            
            children.append(
                UIAction(
                    title: showCategoryIcons ? "Hide Category Icons" : "Show Category Icons",
                    image: UIImage(systemName: showCategoryIcons ? "eye.slash" : "eye")
                ) { _ in
                    onToggleCategoryIcons()
                }
            )
            
            children.append(
                UIAction(
                    title: showItemPriceRow ? "Simplify List" : "Show Item Price/Unit",
                    image: UIImage(systemName: showItemPriceRow ? "text.line.first.and.arrowtriangle.forward" : "text.justify")
                ) { _ in
                    onToggleItemPriceRow()
                }
            )
            
            if isPlanning {
                children.append(
                    UIAction(title: "Start Shopping", image: UIImage(systemName: "cart")) { _ in
                        onStartShopping()
                    }
                )
            } else if isCompleted {
                children.append(
                    UIAction(title: "Reactivate Cart", image: UIImage(systemName: "arrow.clockwise")) { _ in
                        onReactivateCart()
                    }
                )
            }
            
            let deleteAction = UIAction(
                title: "Delete Cart",
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                onDeleteCart()
            }
            children.append(UIMenu(options: .displayInline, children: [deleteAction]))
            
            return UIMenu(children: children)
        }
    }
    
    private func fulfilledSpentTotal() -> Double? {
        guard let vault = vaultService.vault else { return nil }
        
        return cart.cartItems
            .filter { cartItem in
                cartItem.quantity > 0 && cartItem.isFulfilled && !cartItem.isSkippedDuringShopping
            }
            .reduce(0.0) { total, cartItem in
                total + cartItem.getTotalPrice(from: vault, cart: cart)
            }
    }
    
    // Total items includes ONLY ACTIVE items (non-skipped, non-deleted)
    private var totalItems: Int {
        cart.cartItems.filter { cartItem in
            if cartItem.isShoppingOnlyItem {
                return cartItem.quantity > 0
            } else {
                return cartItem.quantity > 0 && !cartItem.isSkippedDuringShopping
            }
        }.count
    }
    
    private var fulfilledItems: Int {
        cart.cartItems.filter { cartItem in
            cartItem.isFulfilled && cartItem.quantity > 0
        }.count
    }
    
    func tripDateLabel(cart: Cart) -> Text {
        let calendar = Calendar.current
        let today = Date()
        
        func styled(_ str: String) -> Text {
            Text(str).lexendFont(12)
        }
        
        switch cart.status {
        case .planning:
            if calendar.isDate(cart.createdAt, equalTo: cart.updatedAt, toGranularity: .day) {
                if calendar.isDate(cart.updatedAt, inSameDayAs: today) {
                    return styled("Planning • Today")
                }
                return styled("Planning • " + cart.createdAt.formatted(.dateTime.month(.abbreviated).day()))
            } else {
                let dateRange = formatDateRange(start: cart.createdAt, end: cart.updatedAt)
                return styled("Planning • \(dateRange)")
            }
            
        case .shopping:
            let todayDateStr = today.formatted(.dateTime.month(.abbreviated).day())
            
            guard let startedAt = cart.startedAt else {
                return styled("Shopping • \(todayDateStr) Today")
            }
            
            if calendar.isDate(startedAt, inSameDayAs: today) {
                return styled("Shopping • \(todayDateStr) Today")
            }
            
            let startStr = startedAt.formatted(.dateTime.month(.abbreviated).day())
            
            if calendar.isDate(startedAt, equalTo: today, toGranularity: .month) {
                // Same month: Jan 30-31
                let endDayStr = today.formatted(.dateTime.day())
                return styled("Shopping • \(startStr)-\(endDayStr) Today")
            } else {
                 return styled("Shopping • \(startStr) – \(todayDateStr) Today")
            }
            
        case .completed:
            guard let startedAt = cart.startedAt, let completedAt = cart.completedAt else {
                let endDate = cart.completedAt ?? cart.createdAt
                return styled("Completed • " + endDate.formatted(.dateTime.month(.abbreviated).day()))
            }
            
            if calendar.isDate(startedAt, equalTo: completedAt, toGranularity: .day) {
                return styled("Completed • " + startedAt.formatted(.dateTime.month(.abbreviated).day()))
            }
            let dateRange = formatDateRange(start: startedAt, end: completedAt)
            return styled("Completed • \(dateRange)")
        }
    }
    
    func formatDateRange(start: Date, end: Date) -> String {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)
        
        if startDay == endDay {
            return calendar.isDateInToday(startDay)
            ? "Today"
            : start.formatted(.dateTime.month(.abbreviated).day())
        }
        
        if calendar.isDate(start, equalTo: end, toGranularity: .month) {
            return "\(start.formatted(.dateTime.month(.abbreviated).day()))–\(end.formatted(.dateTime.day()))"
        }
        
        if calendar.isDate(start, equalTo: end, toGranularity: .year) {
            return "\(start.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day()))"
        }
        
        return "\(start.formatted(.dateTime.month(.abbreviated).day().year())) – \(end.formatted(.dateTime.month(.abbreviated).day().year()))"
    }
}
