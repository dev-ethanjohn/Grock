import SwiftUI

struct VaultToolbarView: View {
    
    @Binding var toolbarAppeared: Bool
    var onAddTapped: () -> Void
    var onDismissTapped: (() -> Void)?
    var onClearTapped: (() -> Void)?
    var showClearButton: Bool = false
    
    @State private var addButtonScale: CGFloat = 1.0
    @Namespace private var buttonNamespace
    
    var body: some View {
        ZStack(alignment: .top) {
            Text("vault")
                .lexendFont(16, weight: .bold)
                .opacity(toolbarAppeared ? 1 : 0)
                .offset(y: toolbarAppeared ? 0 : -10)
                .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0).delay(0.1), value: toolbarAppeared)
            
            HStack {
                
                if showClearButton, let onDismissTapped = onDismissTapped {
                    Button(action: onDismissTapped) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 24, height: 24)
                    }
                    .transition(.scale)
                    .animation(.spring(response: 0.1, dampingFraction: 0.6, blendDuration: 0).delay(0.1), value: toolbarAppeared)
                }
                
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
                                .font(.system(size: 15, weight: .bold))
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
            }
        }
        .padding()
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
                            .font(.system(size: 15, weight: .regular))
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
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 8)
                    
                    
                    Button(action: dismissSheet) {
                        Text("Cancel")
                            .font(.system(size: 18, weight: .semibold))
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
