import SwiftUI

struct HeaderView: View {
    let cart: Cart
       let animatedBudget: Double
       let localBudget: Double
       @Binding var showingDeleteAlert: Bool
       @Binding var showingCompleteAlert: Bool
       @Binding var showingStartShoppingAlert: Bool
       @Binding var headerHeight: CGFloat
       let dismiss: DismissAction
       @Binding var showingEditCartName: Bool  // These two parameters
       @Binding var refreshTrigger: UUID      // are in this order
       var onBudgetTap: (() -> Void)?
    
    private var progress: Double {
        guard localBudget > 0 else { return 0 }
        let spent = cart.totalSpent
        return min(spent / localBudget, 1.0)
    }
    
    @Environment(VaultService.self) private var vaultService
    
    private var budgetProgressColor: Color {
        let progress = self.progress
        if progress < 0.7 {
            return Color(hex: "98F476")
        } else if progress < 0.9 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        return CGFloat(progress) * totalWidth
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: { dismiss() }) {
                    Image("back_arrow")
                }
                .offset(x: -2)
                
                Spacer()
                
                Text(tripDateLabel(cart: cart))
                    .lexendFont(12)
                    .foregroundColor(Color.black.opacity(0.7))
                
                Spacer()
                
                Menu {
                    // ADD THIS: Edit Cart Name button as the first option
                    Button("Edit Cart Name", systemImage: "pencil") {
                        showingEditCartName = true
                    }
                    
                    Divider()
                    
                    if cart.isPlanning {
                        Button("Start Shopping", systemImage: "cart") {
                            showingStartShoppingAlert = true
                        }
                    } else if cart.isShopping {
                        Button("Complete Shopping", systemImage: "checkmark.circle") {
                            showingCompleteAlert = true
                        }
                    } else if cart.isCompleted {
                        Button("Reactivate Cart", systemImage: "arrow.clockwise") {
                            vaultService.reopenCart(cart: cart)
                        }
                    }
                    Divider()
                    
                    Button("Delete Cart", systemImage: "trash", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
            }
            .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(cart.name)
                    .shantellSansFont(24)
                    .foregroundColor(.black)
                
                VStack(spacing: 8) {
                        FluidBudgetPillView(
                            cart: cart,
                            animatedBudget: animatedBudget,
                            onBudgetTap: onBudgetTap
                        )
                    .frame(height: 22)
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
                        headerHeight = geometry.size.height
                    }
                    .onChange(of: geometry.size.height) {_, newValue in
                        headerHeight = newValue
                    }
            }
        )
    }
    
    func tripDateLabel(cart: Cart) -> String {
        let calendar = Calendar.current
        let today = Date()
        
        switch cart.status {
        case .planning:
            // Planning carts show creation → last edit timeline
            if calendar.isDate(cart.createdAt, equalTo: cart.updatedAt, toGranularity: .day) {
                if calendar.isDate(cart.updatedAt, inSameDayAs: today) {
                    return "Planning • Today"
                }
                return "Planning • " + cart.createdAt.formatted(.dateTime.month(.abbreviated).day())
            } else {
                // Show the planning period
                let dateRange = formatDateRange(start: cart.createdAt, end: cart.updatedAt)
                return "Planning • \(dateRange)"
            }
            
        case .shopping:
            guard let startedAt = cart.startedAt else {
                return "Shopping • Today"
            }
            
            if calendar.isDate(startedAt, inSameDayAs: today) {
                return "Shopping • Today"
            }
            // Show shopping period
            let dateRange = formatDateRange(start: startedAt, end: today)
            return "Shopping • \(dateRange)"
            
        case .completed:
            guard let startedAt = cart.startedAt, let completedAt = cart.completedAt else {
                let endDate = cart.completedAt ?? cart.createdAt
                return "Completed • " + endDate.formatted(.dateTime.month(.abbreviated).day())
            }
            
            if calendar.isDate(startedAt, equalTo: completedAt, toGranularity: .day) {
                return "Completed • " + startedAt.formatted(.dateTime.month(.abbreviated).day())
            }
            // Show completed shopping period
            let dateRange = formatDateRange(start: startedAt, end: completedAt)
            return "Completed • \(dateRange)"
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

