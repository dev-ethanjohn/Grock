import SwiftUI
import AVFoundation
import UIKit

struct LoopingVideoView: View {
    let resourceName: String
    var fileExtension: String = "mov"
    var isActive: Bool = true

    @StateObject private var playerModel: LoopingVideoPlayerModel

    init(resourceName: String, fileExtension: String = "mov", isActive: Bool = true) {
        self.resourceName = resourceName
        self.fileExtension = fileExtension
        self.isActive = isActive
        _playerModel = StateObject(
            wrappedValue: LoopingVideoPlayerModel(
                resourceName: resourceName,
                fileExtension: fileExtension
            )
        )
    }

    var body: some View {
        Group {
            if playerModel.isReady {
                LoopingPlayerLayerView(player: playerModel.player)
                    .aspectRatio(playerModel.aspectRatio, contentMode: .fit)
                    .background(Color.black.opacity(0.05))
            } else {
                Color.black.opacity(0.05)
            }
        }
        .mask(bottomFadeMask)
        .onAppear {
            syncPlaybackState()
        }
        .onChange(of: isActive) { _, _ in
            syncPlaybackState()
        }
        .onDisappear {
            playerModel.pause()
        }
    }

    private func syncPlaybackState() {
        if isActive {
            playerModel.play()
        } else {
            playerModel.pause()
        }
    }

    private var bottomFadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.70),
                .init(color: .white.opacity(0.42), location: 0.86),
                .init(color: .clear, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private final class LoopingVideoPlayerModel: ObservableObject {
    let player: AVQueuePlayer
    private var looper: AVPlayerLooper?
    let isReady: Bool
    @Published var aspectRatio: CGFloat = 16.0 / 9.0

    init(resourceName: String, fileExtension: String) {
        player = AVQueuePlayer()

        guard let url = Self.resolveResourceURL(
            resourceName: resourceName,
            preferredExtension: fileExtension
        ) else {
            isReady = false
            return
        }

        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player, templateItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none
        isReady = true

        updateAspectRatio(from: url)
    }

    deinit {
        looper?.disableLooping()
        looper = nil
        player.pause()
        player.removeAllItems()
    }

    private static func resolveResourceURL(resourceName: String, preferredExtension: String) -> URL? {
        let fallbackExtensions = ["mp4", "mov", "m4v"]
        let normalizedPreferredExtension = preferredExtension.lowercased()
        let candidateExtensions = [preferredExtension] + fallbackExtensions.filter {
            $0.lowercased() != normalizedPreferredExtension
        }

        for candidateExtension in candidateExtensions {
            if let url = Bundle.main.url(forResource: resourceName, withExtension: candidateExtension) {
                return url
            }
        }

        return nil
    }

    func play() {
        guard isReady else { return }
        player.play()
    }

    func pause() {
        player.pause()
    }

    private func updateAspectRatio(from url: URL) {
        Task {
            do {
                let asset = AVURLAsset(url: url)
                let tracks = try await asset.loadTracks(withMediaType: .video)
                guard let track = tracks.first else { return }

                async let naturalSize = track.load(.naturalSize)
                async let preferredTransform = track.load(.preferredTransform)
                let transformedSize = try await naturalSize.applying(preferredTransform)
                let width = abs(transformedSize.width)
                let height = abs(transformedSize.height)
                guard width > 0, height > 0 else { return }

                await MainActor.run {
                    self.aspectRatio = width / height
                }
            } catch {
                // Keep default aspect ratio when metadata loading fails.
            }
        }
    }
}

private struct LoopingPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        let view = LoopingPlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class LoopingPlayerUIView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }
}
