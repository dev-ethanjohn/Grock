import SwiftUI

struct VaultToolbarView: View {
    
    @Binding var toolbarAppeared: Bool
    @Binding var searchText: String
    @Binding var isSearching: Bool
    var matchedNamespace: Namespace.ID
    var onAddTapped: () -> Void
    var onDismissTapped: (() -> Void)?
    var onClearTapped: (() -> Void)?
    var showClearButton: Bool = false
    
    @State private var addButtonScale: CGFloat = 1.0
    @Namespace private var buttonNamespace
    @FocusState private var searchFieldIsFocused: Bool
    @State private var isAnimating: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Centered title
            HStack {
                Spacer()
                Text("vault")
                    .lexendFont(16, weight: .bold)
                    .opacity(toolbarAppeared ? 1 : 0)
                    .offset(y: toolbarAppeared ? 0 : -10)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0).delay(0.1), value: toolbarAppeared)
                Spacer()
            }
            .frame(height: 44)
            .padding(.top, 18)
            
            // Trailing Buttons (Clear & Add)
            HStack(spacing: 4) {
                Spacer()
                
                if showClearButton {
                    Button(action: {
                        onClearTapped?()
                    }) {
                        Text("Clear")
                            .fuzzyBubblesFont(13, weight: .bold)
                            .foregroundColor(.white)
                            .fixedSize()
                            .padding(.horizontal, 12)
                            .frame(height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(hex: "FA003F"))
                            )
                    }
                    .transition(
                        .scale(scale: 0.5, anchor: .center)
                        .combined(with: .opacity)
                    )
                    .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showClearButton)
                }
                
                Button(action: {
                    animateAddButton()
                    onAddTapped()
                }) {
                    ZStack {
                        if !showClearButton {
                            Text("Add")
                                .fuzzyBubblesFont(13, weight: .bold)
                                .foregroundColor(.white)
                                .fixedSize()
                                .matchedGeometryEffect(id: "buttonContent", in: buttonNamespace)
                                .transition(.opacity)
                        } else {
                            Image(systemName: "plus")
                                .lexendFont(15, weight: .bold)
                                .foregroundStyle(.white)
                                .matchedGeometryEffect(id: "buttonContent", in: buttonNamespace)
                                .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, showClearButton ? 0 : 12)
                    .frame(width: showClearButton ? 24 : nil, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: showClearButton ? 14 : 14)
                            .fill(Color.black)
                            .matchedGeometryEffect(id: "buttonBackground", in: buttonNamespace)
                    )
                    .scaleEffect(addButtonScale)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.65), value: showClearButton)
                .padding(.trailing, 20)
            }
            .frame(height: 44)
            .padding(.top, 18)
            
            // Leading Stack (X Icon & Search)
            // Flattened hierarchy to match ManageCartSheet for smoother animation
            
            // 1. X Icon (Leading)
            if showClearButton, let onDismissTapped = onDismissTapped {
                Button(action: onDismissTapped) {
                    Image(systemName: "xmark")
                        .lexendFont(16, weight: .bold)
                        .foregroundColor(.black)
                        .frame(width: 24, height: 24)
                }
                .padding(.leading, 16)
                .padding(.top, 14)
                .transition(.scale)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showClearButton)
            }
            
            // 2. Search Component
            if isSearching {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .lexend(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                        .matchedGeometryEffect(id: "searchIcon", in: matchedNamespace, isSource: false)
                    
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Search items in Vault")
                                .lexendFont(16)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        
                        TextField("", text: $searchText)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($searchFieldIsFocused)
                    }
                    
                    Button(action: {
                        guard !isAnimating else { return }
                        isAnimating = true
                        
                        UIApplication.shared.endEditing()
                        searchText = ""
                        searchFieldIsFocused = false
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSearching = false
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            isAnimating = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                        .matchedGeometryEffect(id: "searchCapsule", in: matchedNamespace, isSource: false)
                )
                // Dynamic padding to account for X icon
                .padding(.leading, (showClearButton && onDismissTapped != nil) ? 48 : 16)
                .padding(.trailing, 16)
                .padding(.top, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.scale.combined(with: .opacity))
            } else {
                Button(action: {
                    guard !isAnimating else { return }
                    isAnimating = true
                    
                    UIApplication.shared.endEditing()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSearching = true
                    }
                    searchFieldIsFocused = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isAnimating = false
                    }
                }) {
                    ZStack {
                        Capsule()
                            .fill(Color.white)
                            .matchedGeometryEffect(id: "searchCapsule", in: matchedNamespace, isSource: true)
                            .frame(height: 28)
                            .frame(width: 36, alignment: .leading)
                        
                        Image(systemName: "magnifyingglass")
                            .lexend(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.black)
                            .matchedGeometryEffect(id: "searchIcon", in: matchedNamespace, isSource: true)
                    }
                }
                .padding(.leading, (showClearButton && onDismissTapped != nil) ? 48 : 16)
                .padding(.top, 14)
            }
        }
        .background(Color.white)
        .padding(.bottom, 8)
    }
    
    private func animateAddButton() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            addButtonScale = 0.9
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                addButtonScale = 1.0
            }
        }
    }
}

struct CustomActionSheet: View {
    let title: String
    let message: String
    let primaryAction: () -> Void
    let secondaryAction: () -> Void
    
    @State private var offset: CGFloat = 1000
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.primary.opacity(0.2)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissSheet()
                }
            
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Text(title)
                            .fuzzyBubblesFont(20, weight: .bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text(message)
                            .lexendFont(15, weight: .regular)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 1)
                        .padding(.horizontal, 8)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            offset = 1000
                            backgroundOpacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            primaryAction()
                        }
                    }) {
                        Text("Leave")
                            .lexendFont(18, weight: .regular)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 8)
                    
                    
                    Button(action: dismissSheet) {
                        Text("Cancel")
                            .lexendFont(18, weight: .semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
                .offset(y: offset)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                offset = 0
                backgroundOpacity = 1
            }
        }
    }
    
    private func dismissSheet() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            offset = 1000
            backgroundOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            secondaryAction()
        }
    }
}


struct CustomActionSheetModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                CustomActionSheet(
                    title: title,
                    message: message,
                    primaryAction: {
                        primaryAction()
                        isPresented = false
                    },
                    secondaryAction: {
                        secondaryAction?()
                        isPresented = false
                    }
                )
                .zIndex(999)
                .transition(.identity)
            }
        }
    }
}

extension View {
    func customActionSheet(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        primaryAction: @escaping () -> Void,
        secondaryAction: (() -> Void)? = nil
    ) -> some View {
        self.modifier(
            CustomActionSheetModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                primaryAction: primaryAction,
                secondaryAction: secondaryAction
            )
        )
    }
}
