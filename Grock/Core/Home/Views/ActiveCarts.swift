//
//  ActiveCarts.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 11/14/25.
//

import SwiftUI

struct ActiveCarts: View {
    @Environment(VaultService.self) private var vaultService
    @Bindable var viewModel: HomeViewModel
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.hasCarts {
                cartListView
            } else {
                emptyStateView
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal)
    }
    
    private var cartListView: some View {
        ScrollView {
            Color.clear
                .frame(height: viewModel.headerHeight)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.displayedCarts) { cart in
                    cartRowButton(cart: cart)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
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
    
    private func cartRowButton(cart: Cart) -> some View {
        Button(action: {
            viewModel.selectCart(cart)
        }) {
            HomeCartRowView(cart: cart, vaultService: viewModel.getVaultService(for: cart))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    
}

