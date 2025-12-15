import SwiftUI

struct CategoryCircularButton: View {
    @Binding var selectedCategory: GroceryCategory?
    let selectedCategoryEmoji: String
    let hasError: Bool
    var isEditable: Bool = true
    var onTap: (() -> Void)? = nil
    
    @State private var showLockTooltip = false
    
    var body: some View {
        HStack {
            Spacer()
            
            if isEditable {
                // Editable category button (Menu)
                Menu {
                    Section {
                        Text("Grocery Categories")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(GroceryCategory.allCases) { category in
                            Text("\(category.title) \(category.emoji)")
                                .tag(category as GroceryCategory?)
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    categoryButtonContent
                }
                .offset(x: -4)
            } else {
                // Non-editable category button (Button with lock action)
                Button(action: {
                    onTap?()
                    showLockTooltip = true
                    
                    // Auto-hide tooltip
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showLockTooltip = false
                        }
                    }
                }) {
                    categoryButtonContent
                        .overlay(
                            // Lock overlay
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.3))
                                    .frame(width: 34, height: 34)
                                
                                // Lock icon
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                        )
                }
                .buttonStyle(.plain)
                .offset(x: -4)
                .overlay(
                    // Lock tooltip
                    Group {
                        if showLockTooltip {
                            CategoryLockTooltipView()
                                .offset(y: -45)
                        }
                    },
                    alignment: .top
                )
            }
        }
    }
    
    private var categoryButtonContent: some View {
        ZStack {
            // Main circle that morphs
            Circle()
                .fill(selectedCategory == nil
                      ? .gray.opacity(0.2)
                      : selectedCategory!.pastelColor)
                .frame(width: 34, height: 34)
                .opacity(isEditable ? 1.0 : 0.8) // Dim when not editable
            
            // Outer stroke (non-animating)
            Circle()
                .stroke(
                    selectedCategory == nil
                    ? Color.gray
                    : selectedCategory!.pastelColor.darker(by: 0.2),
                    lineWidth: 1.5
                )
                .frame(width: 34, height: 34)
                .opacity(isEditable ? 1.0 : 0.6) // Dim stroke when not editable
            
            // Error stroke
            if hasError {
                Circle()
                    .stroke(Color(hex: "#FA003F"), lineWidth: 2)
                    .frame(width: 34 + 8, height: 34 + 8)
            }
            
            // Content
            if selectedCategory == nil {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.gray)
                    .opacity(isEditable ? 1.0 : 0.6)
            } else {
                Text(selectedCategoryEmoji)
                    .font(.system(size: 18))
                    .opacity(isEditable ? 1.0 : 0.8)
            }
        }
        .frame(width: 40, height: 40)
        .contentShape(Circle())
    }
}

// Lock tooltip view
struct CategoryLockTooltipView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Category Locked")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("Can only change in planning mode")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
            
            // Tooltip arrow
            Triangle()
                .fill(Color.white)
                .frame(width: 12, height: 8)
                .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                .offset(y: -1)
        }
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.9).combined(with: .opacity),
                removal: .opacity
            )
        )
        .zIndex(1000)
    }
}

struct SimpleLockBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
            Text("Locked")
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
