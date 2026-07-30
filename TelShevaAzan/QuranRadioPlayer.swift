import AVFoundation
import Combine
import Foundation
import MediaPlayer
import UIKit

final class QuranRadioPlayer: ObservableObject {
    static let shared = QuranRadioPlayer()

    @Published private(set) var isPlaying = false
    @Published private(set) var isLoading = false
    @Published private(set) var statusText = "جاهز للتشغيل"

    let sourceName = "إذاعة القرآن الكريم من نابلس"

    private let streamURL = URL(string: "https://quran-radio.org:8899/;?type=http&nocache=29")!
    private var player: AVPlayer?
    private var item: AVPlayerItem?
    private var itemStatusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private lazy var nowPlayingArtwork: MPMediaItemArtwork? = {
        guard let image = UIImage(named: "Icon-60@3x")
            ?? UIImage(named: "Icon-60@2x")
            ?? UIImage(named: "AppIcon")
        else {
            return nil
        }

        return MPMediaItemArtwork(boundsSize: image.size) { _ in image }
    }()

    private init() {
        configureRemoteCommands()
    }

    func toggle() {
        isPlaying ? pause() : play()
    }

    func play() {
        do {
            try configureAudioSession()
        } catch {
            statusText = "تعذر تفعيل صوت الخلفية"
            isLoading = false
            isPlaying = false
            return
        }

        preparePlayerIfNeeded()
        statusText = "جار الاتصال بالبث"
        isLoading = true
        player?.play()
        updateNowPlaying()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        isLoading = false
        statusText = "متوقف"
        clearNowPlaying()
        deactivateAudioSession()
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    private func preparePlayerIfNeeded() {
        guard player == nil else { return }

        let item = AVPlayerItem(url: streamURL)
        let player = AVPlayer(playerItem: item)
        self.item = item
        self.player = player

        itemStatusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }

                switch item.status {
                case .readyToPlay:
                    self.statusText = "متصل بالبث المباشر"
                case .failed:
                    self.statusText = "تعذر تشغيل البث"
                    self.isLoading = false
                    self.isPlaying = false
                    self.clearNowPlaying()
                    self.deactivateAudioSession()
                default:
                    self.statusText = "جار الاتصال بالبث"
                }
            }
        }

        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                guard let self else { return }

                switch player.timeControlStatus {
                case .playing:
                    self.isPlaying = true
                    self.isLoading = false
                    self.statusText = "يعمل الآن"
                    self.updateNowPlaying()
                case .waitingToPlayAtSpecifiedRate:
                    self.isLoading = true
                    self.statusText = "جار الاتصال بالبث"
                case .paused:
                    self.isPlaying = false
                    self.isLoading = false
                    if self.statusText != "تعذر تشغيل البث" {
                        self.statusText = "متوقف"
                    }
                    self.clearNowPlaying()
                @unknown default:
                    self.statusText = "جار تحديث حالة البث"
                }
            }
        }
    }

    private func configureRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.play()
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.pause()
            }
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            DispatchQueue.main.async {
                self?.toggle()
            }
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        commandCenter.changePlaybackPositionCommand.isEnabled = false
        commandCenter.changePlaybackRateCommand.isEnabled = false
    }

    private func updateNowPlaying() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "راديو القرآن",
            MPMediaItemPropertyArtist: sourceName,
            MPMediaItemPropertyAlbumTitle: "تطبيق صلاتي",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackRate: 1,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
            MPNowPlayingInfoPropertyExternalContentIdentifier: "salati-quran-radio-live",
            MPNowPlayingInfoPropertyServiceIdentifier: "salati"
        ]

        if let nowPlayingArtwork {
            info[MPMediaItemPropertyArtwork] = nowPlayingArtwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlaying() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        UIApplication.shared.endReceivingRemoteControlEvents()
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: .notifyOthersOnDeactivation
        )
    }
}
