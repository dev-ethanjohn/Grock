import SwiftUI

struct VaultCategorySectionView: View {
    let selectedCategoryTitle: String?
    let categoryScrollView: AnyView

    init(selectedCategoryTitle: String?, @ViewBuilder categoryScrollView: () -> some View) {
        self.selectedCategoryTitle = selectedCategoryTitle
        self.categoryScrollView = AnyView(categoryScrollView())
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                if let title = selectedCategoryTitle {
                    Text(title)
                        .lexendFont(15, weight: .medium)
                        .contentTransition(.identity)
                        .animation(.spring(duration: 0.3), value: selectedCategoryTitle)
                        .transition(.push(from: .leading))
                } else {
                    Text("Select Category")
                    .lexendFont(15, weight: .medium)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 0)

            categoryScrollView
                .padding(.bottom, 10)
                .background(
                    Rectangle()
                        .fill(.white)
                        .shadow(color: Color.black.opacity(0.16), radius: 6, x: 0, y: 1)
                        .mask(
                            Rectangle()
                                .padding(.bottom, -20)
                )
            )
        }
    }
}

struct GroceryCategoryScrollRightOverlay: View {
    var backgroundColor: Color = .white
    private var namespace: Namespace.ID?
    private var isExpanded: Bool
    private var action: (() -> Void)?
    private var showsIcon: Bool
    var accessibilityLabel: String = "Show categories"

    init(backgroundColor: Color = .white) {
        self.backgroundColor = backgroundColor
        self.namespace = nil
        self.isExpanded = false
        self.action = nil
        self.showsIcon = false
    }

    init(
        backgroundColor: Color = .white,
        namespace: Namespace.ID,
        isExpanded: Bool,
        action: @escaping () -> Void,
        accessibilityLabel: String = "Show categories"
    ) {
        self.backgroundColor = backgroundColor
        self.namespace = namespace
        self.isExpanded = isExpanded
        self.action = action
        self.showsIcon = true
        self.accessibilityLabel = accessibilityLabel
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: backgroundColor.opacity(0.0), location: 0.0),
                            .init(color: backgroundColor.opacity(0.26), location: 0.1),
                            .init(color: backgroundColor.opacity(0.63), location: 0.25),
                            .init(color: backgroundColor.opacity(0.91), location: 0.7),
                            .init(color: backgroundColor.opacity(1), location: 1.0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .allowsHitTesting(false)

            if showsIcon, let action {
                Button {
                    action()
                } label: {
                    Image("customize")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 19, height: 19)
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
                .padding(11)
                .background(
                    Group {
                        if let namespace {
                            RoundedRectangle(cornerRadius: 999)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color.gray.opacity(0.75), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.16), radius: 4, x: 0, y: 3)
                                .matchedGeometryEffect(id: "categoryManagerMorph", in: namespace, isSource: true)
                        } else {
                            RoundedRectangle(cornerRadius: 999)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 999)
                                        .stroke(Color.gray.opacity(0.75), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.16), radius: 4, x: 0, y: 3)
                        }
                    }
                )
                .opacity(shouldHideIcon ? 0 : 1)
                .padding(.trailing)
                .applyZoomSource(id: "customizeIcon", namespace: namespace)
            }
        }
        .frame(width: showsIcon ? 86 : 70)
    }

    private var shouldHideIcon: Bool {
        if #available(iOS 18.0, *) {
            return false
        }
        return isExpanded
    }
}

extension View {
    @ViewBuilder
    func applyZoomSource(id: String, namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}
