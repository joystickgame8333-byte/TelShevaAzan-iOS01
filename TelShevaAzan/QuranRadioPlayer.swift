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
        updateNowPlaying(rate: 1)
    }

    func pause() {
        player?.pause()
        isPlaying = false
        isLoading = false
        statusText = "متوقف مؤقتًا"
        updateNowPlaying(rate: 0)
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
                    self.updateNowPlaying(rate: 0)
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
                    self.updateNowPlaying(rate: 1)
                case .waitingToPlayAtSpecifiedRate:
                    self.isLoading = true
                    self.statusText = "جار الاتصال بالبث"
                case .paused:
                    self.isPlaying = false
                    self.isLoading = false
                    if self.statusText != "تعذر تشغيل البث" {
                        self.statusText = "متوقف مؤقتًا"
                    }
                    self.updateNowPlaying(rate: 0)
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
    }

    private func updateNowPlaying(rate: Double) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "راديو القرآن",
            MPMediaItemPropertyArtist: sourceName,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: rate
        ]
    }
}
