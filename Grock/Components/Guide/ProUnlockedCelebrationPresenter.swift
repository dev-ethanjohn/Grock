import SwiftUI
import UIKit
import Combine

struct ProUnlockedCelebrationContent: Equatable {
    enum Placement: Equatable {
        case top
        case bottom
    }

    let contextualMessage: String?
    let placement: Placement

    static let generic = ProUnlockedCelebrationContent(
        contextualMessage: "Everything just unlocked with Grock Pro.",
        placement: .bottom
    )

    static func forFeatureFocus(_ focus: GrockPaywallFeatureFocus?) -> ProUnlockedCelebrationContent {
        guard let focus else { return .generic }

        switch focus {
        case .stores:
            return ProUnlockedCelebrationContent(
                contextualMessage: "You can now add unlimited stores and compare prices across all of them.",
                placement: .top
            )
        case .categories:
            return ProUnlockedCelebrationContent(
                contextualMessage: "You can now create and edit custom categories to organize your vault your way.",
                placement: .bottom
            )
        case .activeCarts:
            return ProUnlockedCelebrationContent(
                contextualMessage: "You can now keep multiple active carts at once without replacing your current cart.",
                placement: .bottom
            )
        case .backgrounds:
            return ProUnlockedCelebrationContent(
                contextualMessage: "You can now use photo backgrounds to personalize your carts.",
                placement: .bottom
            )
        }
    }

    static func forUnlockContext(
        _ context: ProUnlockCelebrationContext?,
        featureFocus: GrockPaywallFeatureFocus?
    ) -> ProUnlockedCelebrationContent {
        if let context {
            switch context {
            case .customUnits:
                return ProUnlockedCelebrationContent(
                    contextualMessage: "You can now add your own custom units and reuse them whenever you add items.",
                    placement: .top
                )
            }
        }

        return forFeatureFocus(featureFocus)
    }
}

@MainActor
final class ProUnlockedCelebrationPresenter {
    static let shared = ProUnlockedCelebrationPresenter()

    private let state = ProUnlockedCelebrationPresenterState()
    private var overlayWindow: ProUnlockedCelebrationWindow?
    private var hideWorkItem: DispatchWorkItem?

    private init() {}

    func show(duration: TimeInterval = 3.6) {
        show(content: .generic, duration: duration)
    }

    func show(featureFocus: GrockPaywallFeatureFocus?, duration: TimeInterval = 3.6) {
        show(content: .forFeatureFocus(featureFocus), duration: duration)
    }

    func show(
        featureFocus: GrockPaywallFeatureFocus?,
        celebrationContext: ProUnlockCelebrationContext?,
        duration: TimeInterval = 3.6
    ) {
        show(
            content: .forUnlockContext(celebrationContext, featureFocus: featureFocus),
            duration: duration
        )
    }

    func show(content: ProUnlockedCelebrationContent, duration: TimeInterval = 3.6) {
        ensureWindow()
        guard overlayWindow != nil else { return }

        hideWorkItem?.cancel()
        hideWorkItem = nil
        state.content = content
        state.playbackToken = UUID()
        state.isPresented = true

        guard duration > 0 else { return }

        let workItem = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
    }

    func hide() {
        hideWorkItem?.cancel()
        hideWorkItem = nil

        guard overlayWindow != nil else { return }
        state.isPresented = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
            self?.cleanupIfHidden()
        }
    }

    func toggle(duration: TimeInterval = 3.6) {
        state.isPresented ? hide() : show(duration: duration)
    }

    private func ensureWindow() {
        if let existingWindow = overlayWindow {
            existingWindow.isHidden = false
            existingWindow.windowLevel = .alert + 1
            return
        }

        guard let scene = targetScene() else { return }

        let rootView = ProUnlockedCelebrationWindowRootView(state: state)
        let host = UIHostingController(rootView: rootView)
        host.view.backgroundColor = .clear

        let window = ProUnlockedCelebrationWindow(windowScene: scene)
        window.rootViewController = host
        window.backgroundColor = .clear
        window.windowLevel = .alert + 1
        window.isHidden = false
        overlayWindow = window
    }

    private func cleanupIfHidden() {
        guard !state.isPresented else { return }
        overlayWindow?.isHidden = true
        overlayWindow?.rootViewController = nil
        overlayWindow = nil
    }

    private func targetScene() -> UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }

        if let keyScene = scenes.first(where: { scene in
            scene.activationState == .foregroundActive && scene.windows.contains(where: \.isKeyWindow)
        }) {
            return keyScene
        }

        if let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) {
            return activeScene
        }

        return scenes.first
    }
}

private final class ProUnlockedCelebrationPresenterState: ObservableObject {
    @Published var isPresented = false
    @Published var content: ProUnlockedCelebrationContent = .generic
    @Published var playbackToken = UUID()
}

private final class ProUnlockedCelebrationWindow: UIWindow {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        false
    }
}

private struct ProUnlockedCelebrationWindowRootView: View {
    @ObservedObject var state: ProUnlockedCelebrationPresenterState

    var body: some View {
        ZStack {
            ProUnlockedCelebrationOverlay(
                isPresented: state.isPresented,
                content: state.content,
                playbackToken: state.playbackToken
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.clear)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
