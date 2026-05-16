import AVFoundation
import SwiftUI

final class FajrAlarmAudioPlayer: ObservableObject {
    static let shared = FajrAlarmAudioPlayer()

    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?

    private init() {}

    func start(fileNames: [String]) {
        stop()

        guard let url = firstExistingSoundURL(fileNames: fileNames) else {
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 1.0
            player.prepareToPlay()
            player.play()

            self.player = player
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false

        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func firstExistingSoundURL(fileNames: [String]) -> URL? {
        for fileName in fileNames {
            let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            if let url = Bundle.main.url(forResource: parts[0], withExtension: parts[1]) {
                return url
            }
        }

        return nil
    }
}

struct FajrAlarmRingingView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var audioPlayer = FajrAlarmAudioPlayer.shared

    let alarm: FajrAlarmPresentation
    let theme: PrayerVisualTheme

    var body: some View {
        ZStack {
            ThemeBackdrop(theme: theme)

            VStack(spacing: 22) {
                Spacer(minLength: 28)

                alarmHeader

                Spacer(minLength: 8)

                alarmBody

                Spacer(minLength: 16)

                actionButtons
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            audioPlayer.start(fileNames: alarm.soundFileNames)
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }

    private var alarmHeader: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(theme.accent.opacity(theme.isNightTheme ? 0.18 : 0.14))
                    .frame(width: 96, height: 96)

                Circle()
                    .stroke(theme.accent.opacity(theme.isNightTheme ? 0.72 : 0.50), lineWidth: 2)
                    .frame(width: 96, height: 96)

                Image(systemName: "alarm.fill")
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(theme.accent)
            }

            Text("منبه الفجر")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.center)

            Text(audioPlayer.isPlaying ? "الصوت يعمل الآن" : "افتح الصوت من إعدادات الآيفون إذا لم تسمعه")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(theme.secondaryText.opacity(0.86))
                .multilineTextAlignment(.center)
        }
    }

    private var alarmBody: some View {
        VStack(spacing: 18) {
            Text(alarm.title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(theme.accent)
                .multilineTextAlignment(.center)

            Text(alarm.body)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(5)

            Text("اضغط صحيت لإيقاف منبه اليوم، أو غفوة ليعود بعد \(alarm.snoozeMinutes) دقائق.")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.secondaryText.opacity(0.88))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.panelBackground.opacity(theme.isNightTheme ? 0.88 : 0.76))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(theme.activeRowBorder.opacity(0.82), lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(theme.isNightTheme ? 0.28 : 0.12), radius: 24, y: 12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            alarmActionButton(title: "صحيت", isPrimary: true) {
                PrayerNotificationManager.shared.stopFajrAlarm(dateKey: alarm.dateKey)
                audioPlayer.stop()
                dismiss()
            }

            alarmActionButton(title: "غفوة \(alarm.snoozeMinutes) دقائق", isPrimary: false) {
                PrayerNotificationManager.shared.snoozeFajrAlarm(dateKey: alarm.dateKey)
                audioPlayer.stop()
                dismiss()
            }
        }
    }

    private func alarmActionButton(title: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: isPrimary ? 24 : 20, weight: .black, design: .rounded))
                .foregroundStyle(isPrimary ? (theme.isNightTheme ? Color.black.opacity(0.92) : .white) : theme.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: isPrimary ? 62 : 58)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isPrimary ? theme.accent : theme.controlBackground)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isPrimary ? theme.accent.opacity(0.55) : theme.controlBorder.opacity(0.95), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
