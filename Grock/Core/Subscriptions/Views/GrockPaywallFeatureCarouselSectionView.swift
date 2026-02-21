import SwiftUI
import AVFoundation

struct GrockPaywallFeatureCarouselSectionView: View {
    let features: [GrockPaywallFeature]
    @Binding var selectedIndex: Int
    let onManualInteraction: () -> Void
    private let carouselHeight: CGFloat = 370
    private let videoHeight: CGFloat = 320
    private let carouselAnimation = Animation.spring(response: 0.35, dampingFraction: 0.86)
    private let fallbackAutoAdvanceInterval: TimeInterval = 5
    private let minimumAutoAdvanceInterval: TimeInterval = 2

    @State private var tabSelection = 0
    @State private var loopResetTask: Task<Void, Never>?
    @State private var isProgrammaticTabChange = false
    @State private var videoDurationsByResource: [String: TimeInterval] = [:]

    private var resolvedIndex: Int {
        guard !features.isEmpty else { return 0 }
        return min(max(selectedIndex, 0), features.count - 1)
    }

    private var selectedFeature: GrockPaywallFeature? {
        guard !features.isEmpty else { return nil }
        return features[resolvedIndex]
    }

    private var pageCount: Int {
        guard features.count > 1 else { return features.count }
        return features.count + 1
    }

    private var maxPageIndex: Int {
        max(0, pageCount - 1)
    }

    private var trailingLoopPageIndex: Int? {
        guard features.count > 1 else { return nil }
        return features.count
    }

    private var videoResourceNamesSignature: String {
        features
            .compactMap(\.videoResourceName)
            .sorted()
            .joined(separator: "|")
    }

    private var selectedVideoDuration: TimeInterval? {
        guard let videoResourceName = selectedFeature?.videoResourceName else { return nil }
        return videoDurationsByResource[videoResourceName]
    }

    private var currentAutoAdvanceInterval: TimeInterval {
        guard let selectedVideoDuration,
              selectedVideoDuration.isFinite,
              selectedVideoDuration > 0 else {
            return fallbackAutoAdvanceInterval
        }

        return max(minimumAutoAdvanceInterval, selectedVideoDuration)
    }

    private var autoAdvanceTaskID: String {
        "\(features.count)-\(selectedIndex)-\(selectedVideoDuration ?? -1)"
    }

    private func featureForPage(_ pageIndex: Int) -> GrockPaywallFeature {
        features[pageIndex % features.count]
    }

    private func syncTabSelectionToResolvedIndex() {
        guard !features.isEmpty else { return }
        if let trailingLoopPageIndex, tabSelection == trailingLoopPageIndex { return }

        let safeIndex = min(resolvedIndex, max(0, features.count - 1))
        if tabSelection != safeIndex {
            isProgrammaticTabChange = true
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                tabSelection = safeIndex
            }
        }
    }

    private func scheduleLoopResetIfNeeded(for pageIndex: Int) {
        loopResetTask?.cancel()

        guard let trailingLoopPageIndex, pageIndex == trailingLoopPageIndex else { return }

        loopResetTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(360))
            guard !Task.isCancelled else { return }
            guard tabSelection == trailingLoopPageIndex else { return }

            isProgrammaticTabChange = true
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                tabSelection = 0
            }
        }
    }

    private func handleTabSelectionChange(_ newValue: Int) {
        guard !features.isEmpty else { return }
        let shouldNotifyManualInteraction = !isProgrammaticTabChange
        isProgrammaticTabChange = false

        if let trailingLoopPageIndex, newValue == trailingLoopPageIndex {
            if shouldNotifyManualInteraction {
                onManualInteraction()
            }
            selectedIndex = 0
            scheduleLoopResetIfNeeded(for: newValue)
            return
        }

        loopResetTask?.cancel()
        let clampedValue = min(max(newValue, 0), max(0, features.count - 1))
        if clampedValue != selectedIndex {
            if shouldNotifyManualInteraction {
                onManualInteraction()
            }
            selectedIndex = clampedValue
        }
    }

    private func advanceLeft() {
        guard features.count > 1 else { return }
        let nextPage = min(tabSelection + 1, maxPageIndex)
        isProgrammaticTabChange = true
        withAnimation(carouselAnimation) {
            tabSelection = nextPage
        }
    }

    private func resolveVideoURL(resourceName: String) -> URL? {
        for fileExtension in ["mov", "mp4", "m4v"] {
            if let url = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) {
                return url
            }
        }
        return nil
    }

    private func loadVideoDurationsIfNeeded() async {
        let resourceNames = Set(features.compactMap(\.videoResourceName))
        for resourceName in resourceNames where videoDurationsByResource[resourceName] == nil {
            guard let url = resolveVideoURL(resourceName: resourceName) else { continue }

            let asset = AVURLAsset(url: url)
            do {
                let duration = try await asset.load(.duration)
                let seconds = CMTimeGetSeconds(duration)
                guard seconds.isFinite, seconds > 0 else { continue }

                await MainActor.run {
                    videoDurationsByResource[resourceName] = seconds
                }
            } catch {
                // Keep fallback interval when duration metadata cannot be loaded.
            }
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            if let selectedFeature {
                ZStack(alignment: .topLeading) {
                    featureTextBlock(selectedFeature)
                        .id(selectedFeature.id)
                        .transition(.paywallCarouselTextSwap)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.spring(response: 0.36, dampingFraction: 0.84), value: selectedFeature.id)
            }

            ZStack(alignment: .bottom) {
                if !features.isEmpty {
                    TabView(selection: $tabSelection) {
                        ForEach(0..<pageCount, id: \.self) { pageIndex in
                            VStack(spacing: 0) {
                                if let videoResourceName = featureForPage(pageIndex).videoResourceName {
                                    LoopingVideoView(resourceName: videoResourceName)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: videoHeight)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .id("\(videoResourceName)-\(pageIndex)")
                                } else {
                                    Color.clear
                                        .frame(maxWidth: .infinity)
                                        .frame(height: videoHeight)
                                }

                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .tag(pageIndex)
                        }
                    }
                    .frame(height: carouselHeight)
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }

                HStack(spacing: 8) {
                    ForEach(Array(features.indices), id: \.self) { index in
                        Button {
                            onManualInteraction()
                            loopResetTask?.cancel()
                            withAnimation(carouselAnimation) {
                                selectedIndex = index
                                isProgrammaticTabChange = true
                                tabSelection = index
                            }
                        } label: {
                            Circle()
                                .fill(
                                    resolvedIndex == index
                                        ? Color.Grock.subscriptionAccent
                                        : Color.black.opacity(0.22)
                                )
                                .frame(
                                    width: resolvedIndex == index ? 8 : 6,
                                    height: resolvedIndex == index ? 8 : 6
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(minHeight: carouselHeight)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear {
            syncTabSelectionToResolvedIndex()
        }
        .onChange(of: tabSelection) { _, newValue in
            handleTabSelectionChange(newValue)
        }
        .onChange(of: selectedIndex) { _, _ in
            syncTabSelectionToResolvedIndex()
        }
        .onDisappear {
            loopResetTask?.cancel()
            loopResetTask = nil
        }
        .task(id: videoResourceNamesSignature) {
            await loadVideoDurationsIfNeeded()
        }
        .task(id: autoAdvanceTaskID) {
            guard features.count > 1 else { return }
            try? await Task.sleep(for: .seconds(currentAutoAdvanceInterval))
            guard !Task.isCancelled else { return }

            await MainActor.run {
                advanceLeft()
            }
        }
    }

    private func featureTextBlock(_ feature: GrockPaywallFeature) -> some View {
        VStack(alignment: .center, spacing: 10) {
            Text(feature.subtitle)
                .lexend(.footnote, weight: .regular)
                .foregroundColor(.black.opacity(0.5))
                .multilineTextAlignment(.center)

            Text(highlightedTitleAndBodyText(for: feature))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private func highlightedTitleAndBodyText(for feature: GrockPaywallFeature) -> AttributedString {
        var title = AttributedString(feature.title)
        title.font = .custom("Lexend-SemiBold", size: 16)
        title.foregroundColor = .black
        title.backgroundColor = Color(hex: "FFE08A")

        var body = AttributedString(feature.body)
        body.font = .custom("Lexend-Regular", size: 12)
        body.foregroundColor = .black
        body.backgroundColor = Color(hex: "FFE08A")

        var combined = AttributedString()
        combined.append(title)
        combined.append(AttributedString("\n"))
        combined.append(body)
        return combined
    }
}

private struct PaywallCarouselTextTransitionModifier: ViewModifier {
    let opacity: Double
    let scale: CGFloat
    let blur: CGFloat

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .scaleEffect(scale)
            .blur(radius: blur)
    }
}

private extension AnyTransition {
    static var paywallCarouselTextSwap: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: PaywallCarouselTextTransitionModifier(opacity: 0, scale: 0.96, blur: 10),
                identity: PaywallCarouselTextTransitionModifier(opacity: 1, scale: 1, blur: 0)
            ),
            removal: .modifier(
                active: PaywallCarouselTextTransitionModifier(opacity: 0, scale: 1.03, blur: 11),
                identity: PaywallCarouselTextTransitionModifier(opacity: 1, scale: 1, blur: 0)
            )
        )
    }
}

private struct GrockPaywallFeatureCarouselSectionPreview: View {
    @State private var selected = 0

    var body: some View {
        GrockPaywallFeatureCarouselSectionView(
            features: GrockPaywallPreviewFixtures.features,
            selectedIndex: $selected,
            onManualInteraction: {}
        )
        .padding()
        .background(Color.Grock.surfaceMuted)
    }
}

#Preview {
    GrockPaywallFeatureCarouselSectionPreview()
}
