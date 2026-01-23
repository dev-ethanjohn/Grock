import SwiftUI

struct AccordionSectionView<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let background: Color
    let accent: Color
    @Binding var isExpanded: Bool
    let hasContent: Bool
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accent)
                            .padding(12)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .lexendFont(14, weight: .semibold)
                                .foregroundColor(accent)
                            Text(subtitle)
                                .lexendFont(12)
                                .foregroundColor(accent.opacity(0.7))
                        }
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
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(background.opacity(1))
                )
            }
            .buttonStyle(.plain)
            
            Group {
                if isExpanded && hasContent {
                    content()
                        .padding(.top, 8)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            )
                        )
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
            .clipped()
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
            background: Color(hex: "EFEFEF"),
            accent: Color(hex: "6D6D6D"),
            isExpanded: $expanded,
            hasContent: true
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
        .background(Color.white)
}
