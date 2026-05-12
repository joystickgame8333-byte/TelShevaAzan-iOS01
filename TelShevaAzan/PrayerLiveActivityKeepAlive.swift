import AVFoundation
import Foundation

final class PrayerLiveActivityKeepAlive {
    static let shared = PrayerLiveActivityKeepAlive()

    private var player: AVAudioPlayer?
    private var warningTimer: DispatchSourceTimer?
    private var nowTimer: DispatchSourceTimer?
    private var endTimer: DispatchSourceTimer?
    private var onWarning: (() -> Void)?
    private var onNow: (() -> Void)?
    private var onEnd: (() -> Void)?

    private init() {}

    func start(
        until endDate: Date,
        nowDisplayDuration: TimeInterval = 0,
        onWarning: (() -> Void)? = nil,
        onNow: (() -> Void)? = nil,
        onEnd: @escaping () -> Void
    ) {
        stop()
        self.onWarning = onWarning
        self.onNow = onNow
        self.onEnd = onEnd

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(data: Self.silentWAV(durationSeconds: 1))
            player.numberOfLoops = -1
            player.prepareToPlay()
            player.play()
            self.player = player
        } catch {
            self.player = nil
        }

        if let onWarning {
            let warningDelay = endDate.addingTimeInterval(-10).timeIntervalSinceNow
            if warningDelay > 0 {
                let timer = DispatchSource.makeTimerSource(queue: .main)
                timer.schedule(deadline: .now() + warningDelay)
                timer.setEventHandler { [weak self] in
                    self?.onWarning?()
                    self?.warningTimer?.cancel()
                    self?.warningTimer = nil
                    self?.onWarning = nil
                }
                timer.resume()
                warningTimer = timer
            } else {
                onWarning()
                self.onWarning = nil
            }
        }

        if let onNow {
            let nowDelay = endDate.timeIntervalSinceNow
            if nowDelay > 0 {
                let timer = DispatchSource.makeTimerSource(queue: .main)
                timer.schedule(deadline: .now() + nowDelay)
                timer.setEventHandler { [weak self] in
                    self?.onNow?()
                    self?.nowTimer?.cancel()
                    self?.nowTimer = nil
                    self?.onNow = nil
                }
                timer.resume()
                nowTimer = timer
            } else {
                onNow()
                self.onNow = nil
            }
        }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + max(0, endDate.addingTimeInterval(nowDisplayDuration).timeIntervalSinceNow))
        timer.setEventHandler { [weak self] in
            self?.onEnd?()
            self?.stop()
        }
        timer.resume()
        endTimer = timer
    }

    func stop() {
        warningTimer?.cancel()
        warningTimer = nil
        nowTimer?.cancel()
        nowTimer = nil
        endTimer?.cancel()
        endTimer = nil
        onWarning = nil
        onNow = nil
        onEnd = nil

        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private static func silentWAV(durationSeconds: Double) -> Data {
        let sampleRate: UInt32 = 8_000
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let bytesPerSample = UInt32(bitsPerSample / 8)
        let sampleCount = UInt32(durationSeconds * Double(sampleRate))
        let dataSize = sampleCount * UInt32(channels) * bytesPerSample
        let byteRate = sampleRate * UInt32(channels) * bytesPerSample
        let blockAlign = channels * (bitsPerSample / 8)

        var data = Data()
        data.append("RIFF".data(using: .ascii)!)
        data.appendLittleEndian(UInt32(36 + dataSize))
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1))
        data.appendLittleEndian(channels)
        data.appendLittleEndian(sampleRate)
        data.appendLittleEndian(byteRate)
        data.appendLittleEndian(blockAlign)
        data.appendLittleEndian(bitsPerSample)
        data.append("data".data(using: .ascii)!)
        data.appendLittleEndian(dataSize)
        data.append(Data(count: Int(dataSize)))
        return data
    }
}

private extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { buffer in
            append(contentsOf: buffer)
        }
    }
}
