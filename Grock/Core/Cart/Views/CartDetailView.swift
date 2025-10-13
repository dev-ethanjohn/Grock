//
//  CartDetailView.swift
//  Grock
//
//  Created by Ethan John Paguntalan on 10/13/25.
//

import SwiftUI

struct CartDetailView: View {
    let cart: Cart
    @Environment(VaultService.self) private var vaultService
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var editingItem: CartItem?
    @State private var showingEditSheet = false
    @State private var showingCompleteAlert = false
    
    // MARK: - Computed Properties
    private var cartItemsWithDetails: [(cartItem: CartItem, item: Item?)] {
        cart.cartItems.map { cartItem in
            (cartItem, vaultService.findItemById(cartItem.itemId))
        }
    }
    
    private var totalCost: Double {
        cart.totalSpent
    }
    
    private var isOverBudget: Bool {
        totalCost > cart.budget
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with status badge
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(cart.name)
                        .font(.fuzzyBold_20)
                        .foregroundColor(.black)
                    
                    // Status badge
                    Text(cart.status.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(cart.status.color)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Menu {
                    if cart.isActive {
                        Button("Complete Cart", systemImage: "checkmark.circle") {
                            showingCompleteAlert = true
                        }
                    } else {
                        Button("Reactivate Cart", systemImage: "arrow.clockwise") {
                            vaultService.reactivateCart(cart)
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
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Cart Content
            if cartItemsWithDetails.isEmpty {
                emptyCartView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(cartItemsWithDetails, id: \.cartItem.itemId) { cartItem, item in
                            CartItemRowView(
                                cartItem: cartItem,
                                item: item,
                                cart: cart,
                                onEdit: {
                                    // Only allow editing for active carts
                                    if cart.isActive {
                                        editingItem = cartItem
                                        showingEditSheet = true
                                    }
                                }
                            )
                            .opacity(cart.isActive ? 1.0 : 0.7) // Visual distinction
                        }
                    }
                    .padding()
                }
            }
            
            budgetSummaryView
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        // In CartDetailView - editing from cart
        .sheet(isPresented: $showingEditSheet) {
            if let editingItem = editingItem,
               let item = vaultService.findItemById(editingItem.itemId),
               cart.isActive {
                EditItemSheet(
                    item: item,
                    isPresented: $showingEditSheet,
                    onSave: { updatedItem in
                        print("Item updated from cart - active carts will reflect new prices")
                    }, context: .cart
                )
                .environment(vaultService)
            }
        }
        .alert("Complete Cart", isPresented: $showingCompleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete", role: .destructive) {
                vaultService.completeCart(cart)
            }
        } message: {
            Text("This will preserve current prices and mark this cart as completed. You won't be able to edit items anymore.")
        }
        .alert("Delete Cart", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                vaultService.deleteCart(cart)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this cart? This action cannot be undone.")
        }
    }
    
    // MARK: - Subviews
    
    private var emptyCartView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Cart is empty")
                .font(.title2)
                .foregroundColor(.gray)
            
            Text("Add items from your vault to get started")
                .font(.body)
                .foregroundColor(.gray.opacity(0.8))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var budgetSummaryView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Total:")
                    .font(.fuzzyBold_18)
                Spacer()
                Text(formatCurrency(totalCost))
                    .font(.fuzzyBold_18)
            }
            
            HStack {
                Text("Budget:")
                    .font(.fuzzyBold_16)
                    .foregroundColor(.gray)
                Spacer()
                Text(formatCurrency(cart.budget))
                    .font(.fuzzyBold_16)
                    .foregroundColor(.gray)
            }
            
            // Budget progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    
                    Rectangle()
                        .fill(budgetProgressColor)
                        .frame(width: min(progressWidth(for: geometry.size.width), geometry.size.width), height: 8)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
            
            if isOverBudget {
                Text("Over budget by \(formatCurrency(totalCost - cart.budget))")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private var budgetProgressColor: Color {
        let progress = totalCost / cart.budget
        if progress < 0.7 {
            return .green
        } else if progress < 0.9 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let progress = totalCost / cart.budget
        return CGFloat(progress) * totalWidth
    }
    
    private func formatCurrency(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return "₱\(Int(value))"
        } else if value * 10 == Double(Int(value * 10)) {
            return String(format: "₱%.1f", value)
        } else {
            return String(format: "₱%.2f", value)
        }
    }
}

// MARK: - CartItemRowView
struct CartItemRowView: View {
    let cartItem: CartItem
    let item: Item?
    let cart: Cart
    let onEdit: () -> Void
    
    @Environment(VaultService.self) private var vaultService
    
    private var itemName: String {
        item?.name ?? "Unknown Item"
    }
    
    private var price: Double {
        guard let vault = vaultService.vault else { return 0.0 }
        return cartItem.getPrice(from: vault, cart: cart)
    }
    
    private var unit: String {
        guard let vault = vaultService.vault else { return "" }
        return cartItem.getUnit(from: vault, cart: cart)
    }
    
    private var totalPrice: Double {
        guard let vault = vaultService.vault else { return 0.0 }
        return cartItem.getTotalPrice(from: vault, cart: cart)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Item icon/placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(itemName.prefix(1))
                        .font(.fuzzyBold_16)
                        .foregroundColor(.black)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(itemName)
                    .font(.fuzzyBold_16)
                    .foregroundColor(.black)
                    .lineLimit(1)
                
                Text("₱\(price, specifier: "%.2f") • \(unit) • \(cartItem.selectedStore)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text("×\(Int(cartItem.quantity))")
                .font(.fuzzyBold_16)
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
            
            Text("₱\(totalPrice, specifier: "%.2f")")
                .font(.fuzzyBold_16)
                .foregroundColor(.black)
                .frame(width: 80, alignment: .trailing)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .onTapGesture {
            onEdit()
        }
    }
}


// MARK: - CartStatus Extension
extension CartStatus {
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        }
    }
    
    var color: Color {
        switch self {
        case .active: return .blue
        case .completed: return .green
        }
    }
}

// MARK: - GroceryCategory Helper Extension
extension GroceryCategory {
    static func fromTitle(_ title: String) -> GroceryCategory {
        return GroceryCategory.allCases.first { $0.title == title } ?? .freshProduce
    }
}
