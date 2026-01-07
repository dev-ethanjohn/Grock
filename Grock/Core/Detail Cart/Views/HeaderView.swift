import SwiftUI
import Lottie

struct HeaderView: View {
    let cart: Cart
    let dismiss: DismissAction
    var onBudgetTap: (() -> Void)?
    
    @Environment(VaultService.self) private var vaultService
    @Environment(CartStateManager.self) private var stateManager
    
    private var progress: Double {
        guard stateManager.localBudget > 0 else { return 0 }
        let spent = cart.totalSpent
        return min(spent / stateManager.localBudget, 1.0)
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
                
                Text(tripDateLabel(cart: cart))
                    .lexendFont(12)
                    .foregroundColor(Color.black.opacity(0.7))
                
                Spacer()
                
                Menu {
                    // Edit Cart Name button
                    Button("Edit Cart Name", systemImage: "pencil") {
                        stateManager.showingEditCartName = true
                    }
                    
                    Divider()
                    
                    if cart.isPlanning {
                        Button("Start Shopping", systemImage: "cart") {
                            stateManager.showingStartShoppingAlert = true
                        }
                    } else if cart.isShopping {
                        Button("Complete Shopping", systemImage: "checkmark.circle") {
                            // This will be handled via the Floating Action Bar
                        }
                    } else if cart.isCompleted {
                        Button("Reactivate Cart", systemImage: "arrow.clockwise") {
                            vaultService.reopenCart(cart: cart)
                        }
                    }
                    Divider()
                    
                    Button("Delete Cart", systemImage: "trash", role: .destructive) {
                        // This binding will come from CartDetailContent
                    }
                } label: {
                    Image(systemName: "ellipsis")
                                         .font(.system(size: 20, weight: .medium)) // Slightly larger
                                         .foregroundColor(.black)
                                         .frame(width: 28, height: 28) // 👈 Minimum 44x44 tap target
                                         .contentShape(Rectangle())
                }
            }
            .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(cart.name)
                    .shantellSansFont(22)
                    .foregroundColor(.black)
                    .padding(.bottom, 6)
                
                HStack {
                    HStack(spacing: 0) {
                        Text("Cart Value")
                            .lexendFont(13, weight: .light)
                        
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
                        .lexendFont(13, weight: .light)
                }
                .padding(.bottom, 4)
                
                
                VStack(spacing: 8) {
                    FluidBudgetPillView(
                        cart: cart,
                        animatedBudget: stateManager.animatedBudget,
                        onBudgetTap: onBudgetTap,
                        hasBackgroundImage: stateManager.hasBackgroundImage,
                        isHeader: true // 👈 Mark as header
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
                              stateManager.headerHeight = geometry.size.height
                          }
                          .onChange(of: geometry.size.height) { _, newValue in
                              stateManager.headerHeight = newValue
                          }
                  }
              )
    }
    
    func tripDateLabel(cart: Cart) -> String {
        let calendar = Calendar.current
        let today = Date()
        
        switch cart.status {
        case .planning:
            if calendar.isDate(cart.createdAt, equalTo: cart.updatedAt, toGranularity: .day) {
                if calendar.isDate(cart.updatedAt, inSameDayAs: today) {
                    return "Planning • Today"
                }
                return "Planning • " + cart.createdAt.formatted(.dateTime.month(.abbreviated).day())
            } else {
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
