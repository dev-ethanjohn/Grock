import SwiftUI

struct VaultItemRow: View {
    let item: Item
    let category: GroceryCategory?
    @Binding var isSwiped: Bool
    var onDelete: (() -> Void)?
    
    @State private var offsetX: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .trailing) {

            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        onDelete?()
                        resetSwipe()
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .padding(.trailing, 12)
            }
            
            // Content
            HStack(alignment: .top, spacing: 4) {
                Circle()
                    .fill(category?.pastelColor ?? Color.primary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.name)
                        .foregroundColor(Color(hex: "888"))
                    + Text(" >")
                        .font(.fuzzyBold_20)
                        .foregroundStyle(Color(hex: "bbb"))
                    
                    if let priceOption = item.priceOptions.first {
                        HStack(spacing: 4) {
                            Text("₱\(priceOption.pricePerUnit.priceValue, specifier: "%.2f")")
                            Text("/ \(priceOption.pricePerUnit.unit)")
                                .font(.caption)
                            Spacer()
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "888"))
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "plus")
                        .foregroundColor(.gray)
                        .font(.footnote)
                        .bold()
                        .padding(6)
                        .background(Color(hex: "fff"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.white)
            .offset(x: offsetX)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !isSwiped && value.translation.width < 0 {
                            // Normal swipe to open
                            offsetX = value.translation.width
                        } else if isSwiped && value.translation.width > 0 {
                            // Allow dragging right to close
                            offsetX = value.translation.width - 80
                        } else if isSwiped && value.translation.width < 0 {
                            // Rubber band effect when swiping left while already swiped
                            let resistance: CGFloat = 0.3
                            offsetX = -80 + (value.translation.width * resistance)
                        }
                    }
                    .onEnded { value in
                        // Use simpler animation without complex spring parameters
                        withAnimation(.interactiveSpring(response: 0.3)) {
                            if !isSwiped && value.translation.width < -80 {
                                // Swipe open
                                offsetX = -80
                                isSwiped = true
                            } else if isSwiped && value.translation.width > 40 {
                                // Swipe closed
                                resetSwipe()
                            } else {
                                // Return to current state (with rubber band snap back)
                                offsetX = isSwiped ? -80 : 0
                            }
                        }
                    }
            )
            .onTapGesture {
                if isSwiped {
                    resetSwipe()
                }
            }
            // Add context menu for long press
            .contextMenu {
                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                
                // You can add more context menu options here
                Button {
                    // Edit action
                    print("Edit item: \(item.name)")
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .onChange(of: isSwiped) {_, newValue in
            // Use simpler animation
            withAnimation(.interactiveSpring(response: 0.3)) {
                offsetX = newValue ? -80 : 0
            }
        }
        .onAppear {
            // Set initial offset without animation
            offsetX = isSwiped ? -80 : 0
        }
    }
    
    private func resetSwipe() {
        // Use simpler animation
        withAnimation(.interactiveSpring(response: 0.3)) {
            offsetX = 0
            isSwiped = false
        }
    }
}
