import SwiftUI

struct ModeToggleView: View {
    
    let cart: Cart
    @Binding var anticipationOffset: CGFloat
    @Binding var showingStartShoppingAlert: Bool
    @Binding var showingSwitchToPlanningAlert: Bool
    @Binding var headerHeight: CGFloat
    @Binding var refreshTrigger: UUID
    
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ZStack {
                Color(hex: "EEEEEE")
                    .frame(width: 176, height: 26)
                    .cornerRadius(16)
                
                HStack {
                    if cart.isShopping {
                        Spacer()
                    }
                    Color.white
                        .frame(width: 88, height: 30)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0.5, y: 1)
                        .offset(x: anticipationOffset)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: anticipationOffset)
                    if cart.isPlanning {
                        Spacer()
                    }
                }
                .frame(width: 176)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cart.status)
                
                HStack(spacing: 0) {
                    Button(action: {
                        if cart.status == .shopping {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                anticipationOffset = -14
                            }
                            
                            showingSwitchToPlanningAlert = true
                        }
                    }) {
                        Text("Planning")
                            .shantellSansFont(13)
                            .foregroundColor(cart.isPlanning ? .black : Color(hex: "999999"))
                            .frame(width: 88, height: 26)
                            .offset(x: cart.isPlanning ? anticipationOffset : 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: anticipationOffset)
                            .animation(.easeInOut(duration: 0.2), value: cart.isPlanning)
                    }
                    .disabled(cart.isCompleted)
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        if cart.status == .planning {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                anticipationOffset = 14
                            }
                            
                            showingStartShoppingAlert = true
                        }
                    }) {
                        Text("Shopping")
                            .shantellSansFont(13)
                            .foregroundColor(cart.isShopping ? .black : Color(hex: "999999"))
                            .frame(width: 88, height: 26)
                            .offset(x: cart.isShopping ? anticipationOffset : 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: anticipationOffset)
                            .animation(.easeInOut(duration: 0.2), value: cart.isShopping)
                    }
                    .disabled(cart.isCompleted)
                }
            }
            .frame(width: 176, height: 30)
            
            Spacer()
            
            Button(action: {
            }) {
                Image(systemName: "circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .fontWeight(.light)
                    .foregroundColor(.black)
                
            }
            .padding(1.5)
            .background(.white)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0, y: 0.5)
        }
        .padding(.top, headerHeight)
        .background(Color.white)
        .onChange(of: cart.status) { oldValue, newValue in
            // Reset anticipation offset when status actually changes
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                anticipationOffset = 0
            }
        }
        .onChange(of: showingStartShoppingAlert) { oldValue, newValue in
            if !newValue && cart.status == .planning {
                // User cancelled the shopping alert, reset anticipation
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    anticipationOffset = 0
                }
            }
        }
        .onChange(of: showingSwitchToPlanningAlert) { oldValue, newValue in
            if !newValue && cart.status == .shopping {
                // User cancelled the planning alert, reset anticipation
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    anticipationOffset = 0
                }
            }
        }
    }
}

