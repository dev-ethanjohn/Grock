import SwiftUI
import SwiftData

struct ActiveCarts: View {
    @Environment(VaultService.self) private var vaultService
    @Bindable var viewModel: HomeViewModel
    let refreshTrigger: UUID
    
    @State private var showEditBudgetForCart: Cart? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.hasCarts {
                cartListView
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else {
                emptyStateView
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.hasCarts)
    }
    
    private var cartListView: some View {
          ScrollView {
              Color.clear
                  .frame(height: viewModel.headerHeight)
              
              LazyVStack(spacing: 12) {
                  ForEach(Array(viewModel.displayedCarts.enumerated()), id: \.element.id) { index, cart in
                      Button(action: {
                          viewModel.selectCart(cart)
                      }) {
                          HomeCartRowView(
                              cart: cart,
                              vaultService: viewModel.getVaultService(for: cart)
                          )
                      }
                      .buttonStyle(.plain)
                      .transition(.asymmetric(
                          insertion: .scale(scale: 0.8).combined(with: .opacity),
                          removal: .scale(scale: 0.9).combined(with: .opacity)
                      ))
                      .animation(
                          .spring(response: 0.5, dampingFraction: 0.7)
                              .delay(Double(index) * 0.05),
                          value: viewModel.displayedCarts.count
                      )
                  }
              }
          }
      }
      
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No carts yet!")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Create your first cart to start shopping")
                .font(.body)
                .foregroundColor(.gray.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(.vertical, 40)
    }
}
