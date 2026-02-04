import SwiftUI

private struct AccordionHeaderButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        // Avoid the default "flash" on tap while still giving a tiny tactile response.
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AccordionSectionView<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
//    let accent: Color
    let accentDeep: Color
    @Binding var isExpanded: Bool
    let hasContent: Bool
    let background: Color
    let borderColor: Color
    let cornerRadius: CGFloat
    let content: () -> Content

    init(
        icon: String,
        title: String,
        subtitle: String,
        accentDeep: Color,
        isExpanded: Binding<Bool>,
        hasContent: Bool,
        background: Color = .clear,
        borderColor: Color = Color.gray.opacity(0.35),
        cornerRadius: CGFloat = 12,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.accentDeep = accentDeep
        self._isExpanded = isExpanded
        self.hasContent = hasContent
        self.background = background
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        Group {
            if hasContent {
                VStack(spacing: 0) {
                    Button(action: {
                        let expanding = !isExpanded
                        withAnimation(
                            // Keep both expand + collapse fluid. Expand can be a bit bouncier,
                            // collapse stays springy but slightly more damped.
                            .spring(
                                response: expanding ? 0.34 : 0.28,
                                dampingFraction: expanding ? 0.78 : 0.86,
                                blendDuration: 0.12
                            )
                        ) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack(alignment: .top, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: icon)
                                    .font(.system(size: 16, weight: .bold))
//                                    .foregroundColor(.black)
                                    .foregroundStyle(accentDeep)
                                    .offset(y: 4)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(title)
                                        .lexendFont(14, weight: .semibold)
                                        .foregroundColor(accentDeep)
//                                        .foregroundColor(.black)
                                    Text(subtitle)
                                        .lexendFont(12)
//                                        .foregroundColor(accent.opacity(0.7))
                                        .foregroundColor(accentDeep.opacity(0.7))
                                }
                                .foregroundColor(.black.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            VStack {
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                    .foregroundColor(.black)
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(AccordionHeaderButtonStyle())
                    .zIndex(1)
                    
                    // Clip the dropdown region so a `.move(edge: .top)` transition can't visually slide "over" the header.
                    ZStack(alignment: .top) {
                        if isExpanded {
                            content()
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .clipped()
                }
                .background(background)
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(borderColor, lineWidth: 1)
                )
                .padding(1)
                .clipped()
            } else {
                EmptyView()
            }
        }
    }
}

private struct AccordionPreviewWrapper: View {
    @State private var expanded = true
    var body: some View {
        AccordionSectionView(
            icon: "shippingbox.fill",
            title: "Preview Section",
            subtitle: "This is a preview subtitle",
//            accent: Color(hex: "6D6D6D"),
            accentDeep: Color(hex: "3A3A3A"),
            isExpanded: $expanded,
            hasContent: true,
            background: Color(hex: "F9F9F9")
        ) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Item 1")
                Text("Item 2")
                Text("Item 3")
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
    }
}

#Preview("AccordionSectionView") {
        AccordionPreviewWrapper()
            .padding()
            .background(Color.orange)
            .fixedSize(horizontal: false, vertical: true)
}
