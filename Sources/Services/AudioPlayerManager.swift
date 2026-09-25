import Foundation
import AVFoundation

/// The 9 language codes narration audio is available in, in the order
/// they should be offered as a fallback chain from the device's locale.
enum NarrationLanguage: String, CaseIterable {
    case ko, en, zh, th, es, de, fr, it, ru

    /// Resolves the device's preferred language to one of our supported
    /// narration languages, falling back to English if unsupported.
    static var deviceDefault: NarrationLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code = String(preferred.prefix(2)).lowercased()
        return NarrationLanguage(rawValue: code) ?? .en
    }
}

/// Plays a single site's narration audio, streamed from its CDN URL.
/// Configured for background/lock-screen playback once started, per the
/// tap-to-play flow — playback never starts on its own.
final class AudioPlayerManager: NSObject, ObservableObject {
    static let shared = AudioPlayerManager()

    @Published private(set) var isPlaying = false
    @Published private(set) var playingSiteID: String?

    private var player: AVPlayer?
    private var endObserver: NSObjectProtocol?

    private override init() {
        super.init()
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
        } catch {
            assertionFailure("Failed to configure audio session: \(error)")
        }
    }

    /// Starts playing `site`'s narration in `language`, falling back to
    /// English and then any available language if that one is missing.
    func play(site: HistoricalSite, language: NarrationLanguage = .deviceDefault) {
        let url = resolvedURL(for: site, preferred: language)
        guard let url else { return }

        stop()

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        playingSiteID = site.id

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.stop()
        }

        newPlayer.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func resume() {
        player?.play()
        isPlaying = true
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        playingSiteID = nil
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    private func resolvedURL(for site: HistoricalSite, preferred: NarrationLanguage) -> URL? {
        if let urlString = site.audioURLs[preferred.rawValue], let url = URL(string: urlString) {
            return url
        }
        if let urlString = site.audioURLs["en"], let url = URL(string: urlString) {
            return url
        }
        guard let firstAvailable = site.audioURLs.values.first else { return nil }
        return URL(string: firstAvailable)
    }
}
