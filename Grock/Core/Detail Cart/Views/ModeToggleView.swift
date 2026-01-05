import SwiftUI
import PhotosUI

struct ColorOption: Identifiable, Equatable {
    let id = UUID()
    let hex: String
    let name: String
    
    static let defaultColor = ColorOption(hex: "F7F2ED", name: "Beige")
    
    static let options: [ColorOption] = [
        ColorOption(hex: "F7F2ED", name: "Beige"),
        ColorOption(hex: "E8F4FD", name: "Light Blue"),
        ColorOption(hex: "F0F7E6", name: "Light Green"),
        ColorOption(hex: "FFF2F2", name: "Light Pink"),
        ColorOption(hex: "F5F0FF", name: "Light Purple"),
        ColorOption(hex: "FFF8E1", name: "Light Yellow"),
        ColorOption(hex: "FFFFFF", name: "White"),
    ]
    
    var color: Color {
        Color(hex: hex)
    }
}

// MARK: - Main View
struct ModeToggleView: View {
    let cart: Cart
    @Binding var anticipationOffset: CGFloat
    @Binding var showingStartShoppingAlert: Bool
    @Binding var showingSwitchToPlanningAlert: Bool
    @Binding var headerHeight: CGFloat
    @Binding var refreshTrigger: UUID
    @Binding var selectedColor: ColorOption
    
    @State private var showingColorPicker = false
    @Environment(VaultService.self) private var vaultService
    
    private var backgroundColor: Color {
        selectedColor.hex == "FFFFFF" ? Color.clear : selectedColor.color.darker(by: 0.02)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ToggleSwitchView(
                cart: cart,
                anticipationOffset: $anticipationOffset,
                showingStartShoppingAlert: $showingStartShoppingAlert,
                showingSwitchToPlanningAlert: $showingSwitchToPlanningAlert
            )
            
            Spacer()
            
            ColorPickerButton(
                selectedColor: $selectedColor,
                showingColorPicker: $showingColorPicker,
                cart: cart
            )
        }
        .padding(.top, headerHeight)
        .background(Color.white)
        .zIndex(100)
        .allowsHitTesting(true)
        .onChange(of: cart.status) { oldValue, newValue in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                anticipationOffset = 0
            }
        }
        .onChange(of: showingStartShoppingAlert) { oldValue, newValue in
            if !newValue && cart.status == .planning {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    anticipationOffset = 0
                }
            }
        }
        .onChange(of: showingSwitchToPlanningAlert) { oldValue, newValue in
            if !newValue && cart.status == .shopping {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    anticipationOffset = 0
                }
            }
        }
        .onAppear {
            if let savedHex = UserDefaults.standard.string(forKey: "cartBackgroundColor_\(cart.id)"),
               let savedColor = ColorOption.options.first(where: { $0.hex == savedHex }) {
                selectedColor = savedColor
            }
        }
        .onChange(of: selectedColor) { oldValue, newValue in
            UserDefaults.standard.set(newValue.hex, forKey: "cartBackgroundColor_\(cart.id)")
        }
    }
}

// MARK: - Toggle Switch Subview
struct ToggleSwitchView: View {
    let cart: Cart
    @Binding var anticipationOffset: CGFloat
    @Binding var showingStartShoppingAlert: Bool
    @Binding var showingSwitchToPlanningAlert: Bool
    
    var body: some View {
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
            
            ToggleButtons(
                cart: cart,
                anticipationOffset: $anticipationOffset,
                showingStartShoppingAlert: $showingStartShoppingAlert,
                showingSwitchToPlanningAlert: $showingSwitchToPlanningAlert
            )
        }
        .frame(width: 176, height: 30)
    }
}

// MARK: - Toggle Buttons Subview
struct ToggleButtons: View {
    let cart: Cart
    @Binding var anticipationOffset: CGFloat
    @Binding var showingStartShoppingAlert: Bool
    @Binding var showingSwitchToPlanningAlert: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            PlanningButton(
                cart: cart,
                anticipationOffset: $anticipationOffset,
                showingSwitchToPlanningAlert: $showingSwitchToPlanningAlert
            )
            
            ShoppingButton(
                cart: cart,
                anticipationOffset: $anticipationOffset,
                showingStartShoppingAlert: $showingStartShoppingAlert
            )
        }
    }
}

// MARK: - Individual Button Views
struct PlanningButton: View {
    let cart: Cart
    @Binding var anticipationOffset: CGFloat
    @Binding var showingSwitchToPlanningAlert: Bool
    
    var body: some View {
        Button(action: handlePlanningTap) {
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
    }
    
    private func handlePlanningTap() {
        if cart.status == .shopping {
            withAnimation(.easeInOut(duration: 0.1)) {
                anticipationOffset = -14
            }
            showingSwitchToPlanningAlert = true
        }
    }
}

struct ShoppingButton: View {
    let cart: Cart
    @Binding var anticipationOffset: CGFloat
    @Binding var showingStartShoppingAlert: Bool
    
    var body: some View {
        Button(action: handleShoppingTap) {
            Text("Shopping")
                .shantellSansFont(13)
                .foregroundColor(cart.isShopping ? .black : Color(hex: "999999"))
                .frame(width: 88, height: 26)
                .offset(x: cart.isShopping ? anticipationOffset : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: anticipationOffset)
                .animation(.easeInOut(duration: 0.2), value: cart.isShopping)
        }
        .disabled(cart.isCompleted)
        .buttonStyle(.plain)
    }
    
    private func handleShoppingTap() {
        if cart.status == .planning {
            withAnimation(.easeInOut(duration: 0.1)) {
                anticipationOffset = 14
            }
            showingStartShoppingAlert = true
        }
    }
}

// MARK: - Color Picker Button Subview
struct ColorPickerButton: View {
    @Binding var selectedColor: ColorOption
    @Binding var showingColorPicker: Bool
    let cart: Cart
    
    var body: some View {
        Button(action: { showingColorPicker.toggle() }) {
            ZStack {
                Circle()
                    .fill(selectedColor.hex == "FFFFFF" ? Color.white : selectedColor.color)
                    .frame(width: 20, height: 20)
                
                if selectedColor.hex == "FFFFFF" {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .frame(width: 18, height: 18)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(1.5)
        .background(.white)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.7), radius: 1, x: 0, y: 0.5)
        .popover(
            isPresented: $showingColorPicker,
            attachmentAnchor: .point(.bottom),
            arrowEdge: .bottom
        ) {
            ColorPickerPopup(
                selectedColor: $selectedColor,
                isPresented: $showingColorPicker,
                cart: cart
            )
            .presentationCompactAdaptation(.popover)
            .presentationCornerRadius(16)
        }
    }
}

// MARK: - ColorPickerPopup
struct ColorPickerPopup: View {
    @Binding var selectedColor: ColorOption
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    let cart: Cart
    
    @State private var selectedImage: UIImage? = nil
    @State private var photosPickerItem: PhotosPickerItem? = nil
    @State private var isLoadingImage = false
    
    var body: some View {
        HStack(spacing: 16) {
            ImagePickerCircle(
                selectedImage: $selectedImage,
                photosPickerItem: $photosPickerItem,
                isLoadingImage: $isLoadingImage,
                cart: cart
            )
            
            ColorScrollView(
                selectedColor: $selectedColor,
                selectedImage: $selectedImage,
                photosPickerItem: $photosPickerItem,
                isPresented: $isPresented,
                cart: cart
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 64)
        .onAppear {
            if let image = CartBackgroundImageManager.shared.loadImage(forCartId: cart.id) {
                selectedImage = image
            }
        }
    }
}

// MARK: - ImagePickerCircle Subview
struct ImagePickerCircle: View {
    @Binding var selectedImage: UIImage?
    @Binding var photosPickerItem: PhotosPickerItem?
    @Binding var isLoadingImage: Bool
    let cart: Cart
    
    var body: some View {
        PhotosPicker(
            selection: $photosPickerItem,
            matching: .images,
            photoLibrary: .shared()
        ) {
            ZStack {
                if isLoadingImage {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    ProgressView()
                        .scaleEffect(0.7)
                } else if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: "photo")
                        .font(.system(size: 16))
                        .foregroundColor(.black.opacity(0.6))
                }
                
                if !isLoadingImage {
                    Image(systemName: selectedImage == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color.white).frame(width: 12, height: 12))
                        .offset(x: 12, y: 12)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 40, height: 40)
        .onChange(of: photosPickerItem) { oldItem, newItem in
            Task {
                isLoadingImage = true
                
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    
                    let maxSize: CGFloat = 1000
                    let resizedImage = image.resized(to: maxSize)
                    
                    await MainActor.run {
                        selectedImage = resizedImage
                        isLoadingImage = false
                    }
                    
                    CartBackgroundImageManager.shared.saveImage(resizedImage, forCartId: cart.id)
                    
                    NotificationCenter.default.post(
                        name: Notification.Name("CartBackgroundImageChanged"),
                        object: nil,
                        userInfo: ["cartId": cart.id]
                    )
                } else {
                    await MainActor.run {
                        isLoadingImage = false
                    }
                }
            }
        }
    }
}

// MARK: - ColorScrollView Subview
struct ColorScrollView: View {
    @Binding var selectedColor: ColorOption
    @Binding var selectedImage: UIImage?
    @Binding var photosPickerItem: PhotosPickerItem?
    @Binding var isPresented: Bool
    let cart: Cart
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ColorOption.options) { colorOption in
                    ColorCircleView(
                        colorOption: colorOption,
                        isSelected: selectedColor == colorOption,
                        onSelect: {
                            handleColorSelection(colorOption)
                        }
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 40)
    }
    
    private func handleColorSelection(_ colorOption: ColorOption) {
        selectedColor = colorOption
        
        if colorOption.hex != "FFFFFF" {
            CartBackgroundImageManager.shared.deleteImage(forCartId: cart.id)
            selectedImage = nil
            photosPickerItem = nil
            
            NotificationCenter.default.post(
                name: Notification.Name("CartBackgroundImageChanged"),
                object: nil,
                userInfo: ["cartId": cart.id]
            )
        }
        
        isPresented = false
    }
}

// MARK: - ColorCircleView
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
                            .stroke(
                                isSelected ? Color.black : Color.black.opacity(0.1),
                                lineWidth: isSelected ? 1.5 : 0.5
                            )
                    )
                
                if colorOption.hex == "FFFFFF" {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        .frame(width: 28, height: 28)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black.opacity(0.8))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Image Resize Extension
extension UIImage {
    func resized(to maxSize: CGFloat) -> UIImage {
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Background Image Manager
class CartBackgroundImageManager {
    static let shared = CartBackgroundImageManager()
    private let fileManager = FileManager.default
    
    private init() {}
    
    func saveImage(_ image: UIImage, forCartId cartId: String) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        
        let filename = getDocumentsDirectory().appendingPathComponent("cart_background_\(cartId).jpg")
        
        do {
            try data.write(to: filename)
            UserDefaults.standard.set(true, forKey: "hasBackgroundImage_\(cartId)")
            print("✅ Saved background image for cart: \(cartId)")
        } catch {
            print("❌ Failed to save image: \(error)")
        }
    }
    
    func loadImage(forCartId cartId: String) -> UIImage? {
        let filename = getDocumentsDirectory().appendingPathComponent("cart_background_\(cartId).jpg")
        
        if fileManager.fileExists(atPath: filename.path),
           let data = try? Data(contentsOf: filename),
           let image = UIImage(data: data) {
            return image
        }
        return nil
    }
    
    func hasBackgroundImage(forCartId cartId: String) -> Bool {
        return UserDefaults.standard.bool(forKey: "hasBackgroundImage_\(cartId)")
    }
    
    func deleteImage(forCartId cartId: String) {
        let filename = getDocumentsDirectory().appendingPathComponent("cart_background_\(cartId).jpg")
        
        do {
            if fileManager.fileExists(atPath: filename.path) {
                try fileManager.removeItem(at: filename)
            }
            UserDefaults.standard.removeObject(forKey: "hasBackgroundImage_\(cartId)")
            print("🗑️ Deleted background image for cart: \(cartId)")
        } catch {
            print("❌ Failed to delete image: \(error)")
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
