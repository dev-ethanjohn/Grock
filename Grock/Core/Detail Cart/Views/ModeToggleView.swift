import SwiftUI
import PhotosUI

struct ColorOption: Identifiable, Equatable {
    let id = UUID()
    let hex: String
    let name: String
    
    static let defaultColor =  ColorOption(hex: "FFFFFF", name: "White")
    
    static let options: [ColorOption] = [
        // Warm tones
        ColorOption(hex: "F5E9D9", name: "Warm Beige"),
        ColorOption(hex: "FFE6E6", name: "Blush Pink"),
        ColorOption(hex: "FFE8CC", name: "Peach"),
        ColorOption(hex: "FFF5CC", name: "Butter Yellow"),
        ColorOption(hex: "FFEB99", name: "Lemon"),
        ColorOption(hex: "FFD8B8", name: "Apricot"),
        
        // Cool tones
        ColorOption(hex: "D6EDFF", name: "Sky Blue"),
        ColorOption(hex: "EDE6FF", name: "Lavender"),
        ColorOption(hex: "E3F7CD", name: "Mint Green"),
        ColorOption(hex: "E0F7FA", name: "Ice Blue"),
        ColorOption(hex: "F0E6FF", name: "Lilac"),
        ColorOption(hex: "D4F0C1", name: "Pear Green"),
        
        // Neutral/Soft tones
        ColorOption(hex: "F5F0E6", name: "Oatmeal"),
        ColorOption(hex: "E8F4F8", name: "Morning Mist"),
        ColorOption(hex: "F0F0F0", name: "Cloud Gray"),
        ColorOption(hex: "FFFFFF", name: "White"),
    ]
    
    var color: Color {
        Color(hex: hex)
    }
}

struct ModeToggleView: View {
    let cart: Cart
    
    @Environment(CartStateManager.self) private var stateManager
    @Environment(VaultService.self) private var vaultService
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ToggleSwitchView(cart: cart)
            
            Spacer()
            
            // Use Bindable(stateManager) to create bindings
            ColorPickerButton(
                selectedColor: Binding(
                    get: { stateManager.selectedColor },
                    set: { stateManager.selectedColor = $0 }
                ),
                showingColorPicker: Binding(
                    get: { stateManager.showingColorPicker },
                    set: { stateManager.showingColorPicker = $0 }
                ),
                cart: cart
            )
        }
        .padding(.top, stateManager.headerHeight)
//        .background(Color(hex: "#f7f7f7"))
        .zIndex(100)
        .allowsHitTesting(true)
        .onChange(of: cart.status) { oldValue, newValue in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                stateManager.anticipationOffset = 0
            }
        }
        .onChange(of: stateManager.showingStartShoppingAlert) { oldValue, newValue in
            if !newValue && cart.status == .planning {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    stateManager.anticipationOffset = 0
                }
            }
        }
        .onChange(of: stateManager.showingSwitchToPlanningAlert) { oldValue, newValue in
            if !newValue && cart.status == .shopping {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    stateManager.anticipationOffset = 0
                }
            }
        }
        .onAppear {
            if let savedHex = UserDefaults.standard.string(forKey: "cartBackgroundColor_\(cart.id)"),
               let savedColor = ColorOption.options.first(where: { $0.hex == savedHex }) {
                stateManager.selectedColor = savedColor
            }
        }
        .onChange(of: stateManager.selectedColor) { oldValue, newValue in
            UserDefaults.standard.set(newValue.hex, forKey: "cartBackgroundColor_\(cart.id)")
        }
    }
}

// MARK: - Toggle Switch Subview
struct ToggleSwitchView: View {
    let cart: Cart
    
    @Environment(CartStateManager.self) private var stateManager
    
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
                    .offset(x: stateManager.anticipationOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: stateManager.anticipationOffset)
                
                if cart.isPlanning {
                    Spacer()
                }
            }
            .frame(width: 176)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cart.status)
            
            ToggleButtons(cart: cart)
        }
        .frame(width: 176, height: 30)
    }
}

// MARK: - Toggle Buttons Subview
struct ToggleButtons: View {
    let cart: Cart
    
    @Environment(CartStateManager.self) private var stateManager
    
    var body: some View {
        HStack(spacing: 0) {
            PlanningButton(cart: cart)
            
            ShoppingButton(cart: cart)
        }
    }
}

// MARK: - Individual Button Views
struct PlanningButton: View {
    let cart: Cart
    
    @Environment(CartStateManager.self) private var stateManager
    
    var body: some View {
        Button(action: handlePlanningTap) {
            Text("Planning")
                .lexendFont(13, weight: .medium)
                .foregroundColor(cart.isPlanning ? .black : Color(hex: "999999"))
                .frame(width: 88, height: 26)
                .offset(x: cart.isPlanning ? stateManager.anticipationOffset : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: stateManager.anticipationOffset)
                .animation(.easeInOut(duration: 0.2), value: cart.isPlanning)
        }
        .disabled(cart.isCompleted)
        .buttonStyle(.plain)
    }
    
    private func handlePlanningTap() {
        if cart.status == .shopping {
            withAnimation(.easeInOut(duration: 0.1)) {
                stateManager.anticipationOffset = -14
            }
            stateManager.showingSwitchToPlanningAlert = true
        }
    }
}

struct ShoppingButton: View {
    let cart: Cart
    
    @Environment(CartStateManager.self) private var stateManager
    
    var body: some View {
        Button(action: handleShoppingTap) {
            Text("Shopping")
                .lexendFont(13, weight: .medium)
                .foregroundColor(cart.isShopping ? .black : Color(hex: "999999"))
                .frame(width: 88, height: 26)
                .offset(x: cart.isShopping ? stateManager.anticipationOffset : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: stateManager.anticipationOffset)
                .animation(.easeInOut(duration: 0.2), value: cart.isShopping)
        }
        .disabled(cart.isCompleted)
        .buttonStyle(.plain)
    }
    
    private func handleShoppingTap() {
        if cart.status == .planning {
            withAnimation(.easeInOut(duration: 0.1)) {
                stateManager.anticipationOffset = 14
            }
            stateManager.showingStartShoppingAlert = true
        }
    }
}
// MARK: - Color Picker Button Subview
// MARK: - Color Picker Button Subview
struct ColorPickerButton: View {
    @Binding var selectedColor: ColorOption
    @Binding var showingColorPicker: Bool
    let cart: Cart
    
    @State private var hasBackgroundImage: Bool = false
    
    var body: some View {
        Button(action: { showingColorPicker.toggle() }) {
            ZStack {
                if hasBackgroundImage, let image = CartBackgroundImageManager.shared.loadImage(forCartId: cart.id) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 20, height: 20)
                        .brightness(-0.02)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.7), lineWidth: 1)
                        )
                } else {
                    // Show color circle
                    Circle()
                        .fill(selectedColor.hex == "FFFFFF" ? Color.white : selectedColor.color.darker(by: 0.02))
                        .frame(width: 20, height: 20)
                    
                    if selectedColor.hex == "FFFFFF" {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .frame(width: 18, height: 18)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(1.5)
        .background(.white)
        .clipShape(Circle())
        .shadow(color: Color.black.opacity(0.7), radius: 1, x: 0, y: 0.5)
        .onAppear {
            checkForBackgroundImage()
        }
        .onChange(of: showingColorPicker) { oldValue, newValue in
            if !newValue {
                // Refresh when popup is dismissed
                checkForBackgroundImage()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CartBackgroundImageChanged"))) { notification in
            if let cartId = notification.userInfo?["cartId"] as? String, cartId == cart.id {
                checkForBackgroundImage()
            }
        }
        .popover(
            isPresented: $showingColorPicker,
            attachmentAnchor: .point(.top),
            arrowEdge: .bottom
        ) {
            ColorPickerPopup(
                selectedColor: $selectedColor,
                isPresented: $showingColorPicker,
                cart: cart
            )
            .presentationCompactAdaptation(.popover)
            .presentationCornerRadius(16)
            .presentationBackground(.white)
        }
    }
    
    private func checkForBackgroundImage() {
        hasBackgroundImage = CartBackgroundImageManager.shared.hasBackgroundImage(forCartId: cart.id)
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
    
    // Computed property to check if image is selected
    private var isImageSelected: Bool {
        selectedImage != nil
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ImagePickerCircle(
                selectedImage: $selectedImage,
                photosPickerItem: $photosPickerItem,
                isLoadingImage: $isLoadingImage,
                cart: cart
            )
            
            //
            Text("|")
                .foregroundStyle(Color(.systemGray))
                .padding(.leading, 8)
            
            ColorScrollView(
                selectedColor: $selectedColor,
                selectedImage: $selectedImage,
                photosPickerItem: $photosPickerItem,
                isPresented: $isPresented,
                cart: cart,
                isImageSelected: isImageSelected
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


// MARK: - Fast and Simple ImagePickerCircle
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
                                .stroke(Color.black, lineWidth: 2)
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
                        .lexendFont(16)
                        .foregroundColor(.black.opacity(0.6))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 40, height: 40)
        .onChange(of: photosPickerItem) { oldItem, newItem in
            guard let newItem = newItem else { return }
            
            Task {
                isLoadingImage = true
                
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    // Fast image processing on background thread
                    let processedImage = await Task.detached(priority: .userInitiated) { () -> UIImage? in
                        guard let image = UIImage(data: data) else { return nil }
                        
                        // Quick resize for performance
                        let maxDimension: CGFloat = 1200
                        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
                        
                        if scale < 1.0 {
                            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                            
                            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                            image.draw(in: CGRect(origin: .zero, size: newSize))
                            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
                            UIGraphicsEndImageContext()
                            
                            return resizedImage
                        }
                        
                        return image
                    }.value
                    
                    await MainActor.run {
                        if let processedImage = processedImage {
                            selectedImage = processedImage
                            CartBackgroundImageManager.shared.saveImage(processedImage, forCartId: cart.id)
                            
                            NotificationCenter.default.post(
                                name: Notification.Name("CartBackgroundImageChanged"),
                                object: nil,
                                userInfo: ["cartId": cart.id]
                            )
                        }
                        
                        isLoadingImage = false
                        photosPickerItem = nil
                    }
                } else {
                    await MainActor.run {
                        isLoadingImage = false
                        photosPickerItem = nil
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
    let isImageSelected: Bool // Add this parameter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ColorOption.options) { colorOption in
                    ColorCircleView(
                        colorOption: colorOption,
                        isSelected: !isImageSelected && selectedColor == colorOption, // Only show checkmark if no image is selected
                        onSelect: {
                            handleColorSelection(colorOption)
                        }
                    )
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
        }
        .frame(height: 40)
    }
    
    private func handleColorSelection(_ colorOption: ColorOption) {
        selectedColor = colorOption
        
        // Clear any selected image when a color is chosen
        CartBackgroundImageManager.shared.deleteImage(forCartId: cart.id)
        selectedImage = nil
        photosPickerItem = nil
        
        NotificationCenter.default.post(
            name: Notification.Name("CartBackgroundImageChanged"),
            object: nil,
            userInfo: ["cartId": cart.id]
        )
        
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
                    .fill(colorOption.color.darker(by: 0.02))
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
                        .lexendFont(12, weight: .bold)
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

class CartBackgroundImageManager: @unchecked Sendable {
    static let shared = CartBackgroundImageManager()
    private let fileManager = FileManager.default
    
    private init() {}
    
    func saveImage(_ image: UIImage, forCartId cartId: String) {
        // Save to cache FIRST (for immediate access)
        ImageCacheManager.shared.saveImage(image, forCartId: cartId)
        
        // Then save to disk
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
        // Try cache first
        if let cached = ImageCacheManager.shared.getImage(forCartId: cartId) {
            return cached
        }
        
        // Fall back to disk
        let filename = getDocumentsDirectory().appendingPathComponent("cart_background_\(cartId).jpg")
        
        if fileManager.fileExists(atPath: filename.path),
           let data = try? Data(contentsOf: filename),
           let image = UIImage(data: data) {
            // Cache it for next time
            ImageCacheManager.shared.saveImage(image, forCartId: cartId)
            return image
        }
        return nil
    }
    
    func hasBackgroundImage(forCartId cartId: String) -> Bool {
        return UserDefaults.standard.bool(forKey: "hasBackgroundImage_\(cartId)")
    }
    
    func deleteImage(forCartId cartId: String) {
        // Remove from cache
        ImageCacheManager.shared.deleteImage(forCartId: cartId)
        
        // Remove from disk
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
