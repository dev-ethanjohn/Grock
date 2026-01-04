import SwiftUI

struct ColorOption: Identifiable, Equatable {
    let id = UUID()
    let hex: String
    let name: String
    
    static let defaultColor = ColorOption(hex: "F7F2ED", name: "Beige")
    
    static let options: [ColorOption] = [
        ColorOption(hex: "F7F2ED", name: "Beige"),      // Original
        ColorOption(hex: "E8F4FD", name: "Light Blue"),
        ColorOption(hex: "F0F7E6", name: "Light Green"),
        ColorOption(hex: "FFF2F2", name: "Light Pink"),
        ColorOption(hex: "F5F0FF", name: "Light Purple"),
        ColorOption(hex: "FFF8E1", name: "Light Yellow"),
        ColorOption(hex: "FFFFFF", name: "White"),       // White will make rows transparent
    ]
    
    var color: Color {
        Color(hex: hex)
    }
}

struct ModeToggleView: View {
    
    let cart: Cart
    @Binding var anticipationOffset: CGFloat
    @Binding var showingStartShoppingAlert: Bool
    @Binding var showingSwitchToPlanningAlert: Bool
    @Binding var headerHeight: CGFloat
    @Binding var refreshTrigger: UUID
    @Binding var selectedColor: ColorOption
    
    // Add these new state properties
    @State private var showingColorPicker = false
    
    @Environment(VaultService.self) private var vaultService
    
    // Add this computed property
    private var backgroundColor: Color {
        selectedColor.hex == "FFFFFF" ? Color.clear : selectedColor.color.darker(by: 0.02)
    }
    
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
            
            // Updated circle button with color picker
            Button(action: {
                showingColorPicker.toggle()
            }) {
                ZStack {
                    // Outer ring
                    Circle()
                        .fill(selectedColor.hex == "FFFFFF" ? Color.white : selectedColor.color)
                        .frame(width: 20, height: 20)
                    
                    // Inner circle for white color option
                    if selectedColor.hex == "FFFFFF" {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 18, height: 18)
                    }
                  
                }
            }
            .padding(1.5)
            .background(.white)
            .clipShape(Circle())
            .shadow(color: Color.black.opacity(0.7), radius: 1, x: 0, y: 0.5)
            .popover(isPresented: $showingColorPicker,
                               attachmentAnchor: .rect(.bounds),
                               arrowEdge: .bottom) { // Specify arrow direction
                          ColorPickerPopup(selectedColor: $selectedColor)
                    .presentationCompactAdaptation(.popover)
//                              .frame(width: 300, height: 200)
                              .presentationCornerRadius(16)
                      }
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
        .onAppear {
            // Load saved color preference or use default
            if let savedHex = UserDefaults.standard.string(forKey: "cartBackgroundColor_\(cart.id)"),
               let savedColor = ColorOption.options.first(where: { $0.hex == savedHex }) {
                selectedColor = savedColor
            }
        }
        .onChange(of: selectedColor) { oldValue, newValue in
            // Save color preference
            UserDefaults.standard.set(newValue.hex, forKey: "cartBackgroundColor_\(cart.id)")
        }
    }
}

struct ColorPickerPopup: View {
    @Binding var selectedColor: ColorOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ColorOption.options) { colorOption in
                        ColorCircleView(
                            colorOption: colorOption,
                            isSelected: selectedColor == colorOption,
                            onSelect: {
                                selectedColor = colorOption
                                dismiss()
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
//        .frame(width: 300, height: 200)
    }
}

struct ColorCircleView: View {
    let colorOption: ColorOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
                ZStack {
                    Circle()
                        .fill(colorOption.color)
                          .frame(width: 30, height: 30)
                          .overlay(
                              Circle()
                                  //todo: slide overlay based on selected color.
                                  .stroke(
                                      isSelected ? Color.black : Color.black.opacity(0.1),
                                      lineWidth: 0.5
                                  )
                          )
                    
                    if colorOption.hex == "FFFFFF" {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 28, height: 28)
                    }
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.8))
                    }
                }
                
        }
        .buttonStyle(.plain)
    }
}
