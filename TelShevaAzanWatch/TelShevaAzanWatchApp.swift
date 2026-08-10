import SwiftUI
import WidgetKit

@main
struct TelShevaAzanWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchPrayerView()
        }
    }
}

struct WatchPrayerView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var connectivity = WatchConnectivityService.shared
    @State private var now = Date()

    private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    private var todayKey: String {
        PrayerEngine.defaultDateKey(for: now)
    }

    private var scheduleKey: String {
        PrayerEngine.automaticScheduleDateKey(for: now)
    }

    private var isTomorrowSchedule: Bool {
        scheduleKey != todayKey
    }

    private var nextPrayer: PrayerTime? {
        PrayerEngine.nextPrayer(for: scheduleKey, now: now)
    }

    private var activeIqama: IqamaEvent? {
        IqamaSchedule.telSheva.activeEvent(at: now)
    }

    private var schedule: [PrayerTime] {
        PrayerEngine.schedule(for: scheduleKey).displayTimes
    }

    var body: some View {
        ZStack {
            WatchPalette.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 9) {
                    header
                    primaryCard
                    prayerList
                }
                .padding(.horizontal, 7)
                .padding(.top, 5)
                .padding(.bottom, 10)
            }
        }
        .foregroundStyle(.white)
        .onReceive(timer) { now = $0 }
        .onChange(of: connectivity.lastUpdate) { _ in
            now = Date()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .active else { return }
            refreshPrayerData()
        }
        .onAppear {
            refreshPrayerData()
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Text(isTomorrowSchedule ? "غدًا" : "اليوم")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(WatchPalette.secondaryText)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(WatchPalette.softSurface)
                .clipShape(Capsule())

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 1) {
                Text("صلاتي")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                Text(WatchPrayerSharedState.locationName)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(WatchPalette.accent)
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var primaryCard: some View {
        HStack(spacing: 7) {
            VStack(alignment: .leading, spacing: 4) {
                Text(primaryTime)
                    .font(.system(size: 27, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(WatchPalette.accent)
                    .lineLimit(1)

                Text(primaryCountdown)
                    .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(WatchPalette.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 2)

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Text(primaryLabel)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(WatchPalette.accent)
                    Image(systemName: primarySymbol)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(WatchPalette.accent)
                }

                Text(primaryTitle)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, 10)
        .padding(.vertical, 11)
        .background(
            LinearGradient(
                colors: [WatchPalette.heroTop, WatchPalette.heroBottom],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(WatchPalette.accent.opacity(0.42), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var prayerList: some View {
        VStack(spacing: 4) {
            HStack {
                Text(isTomorrowSchedule ? "مواقيت الغد" : "مواقيت اليوم")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(WatchPalette.secondaryText)
                Spacer()
            }
            .environment(\.layoutDirection, .rightToLeft)

            ForEach(schedule) { prayer in
                WatchPrayerRow(
                    prayer: prayer,
                    isHighlighted: prayer.key == highlightedPrayerKey
                )
            }
        }
    }

    private var primaryLabel: String {
        activeIqama == nil ? "الصلاة القادمة" : "الإقامة القادمة"
    }

    private var highlightedPrayerKey: PrayerKey? {
        if let iqama = activeIqama, !isTomorrowSchedule {
            return iqama.prayer.key
        }
        return nextPrayer?.key
    }

    private var primaryTitle: String {
        activeIqama?.prayer.title ?? nextPrayer?.title ?? "الصلاة"
    }

    private var primaryTime: String {
        if let iqama = activeIqama {
            return Self.timeFormatter.string(from: iqama.date)
        }
        return nextPrayer?.time ?? "--:--"
    }

    private var primarySymbol: String {
        activeIqama == nil ? symbol(for: nextPrayer?.key) : "person.2.fill"
    }

    private var primaryCountdown: String {
        let target = activeIqama?.date ?? nextPrayer?.date
        guard let target else { return "متبقي --:--" }
        let seconds = max(Int(target.timeIntervalSince(now).rounded(.up)), 0)
        return "متبقي \(formatDuration(seconds))"
    }

    private func refreshPrayerData() {
        now = Date()
        PalestinePrayerCalendar.refreshRemoteIfNeeded { didUpdate in
            guard didUpdate else { return }
            now = Date()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = max((seconds + 59) / 60, 0)
        return String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    private func symbol(for key: PrayerKey?) -> String {
        switch key {
        case .fajr: return "sunrise.fill"
        case .sunrise: return "sun.max.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "cloud.sun.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        case nil: return "clock.fill"
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

private struct WatchPrayerRow: View {
    let prayer: PrayerTime
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text(prayer.time)
                .font(.system(size: 13, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(isHighlighted ? WatchPalette.accent : .white)

            Spacer(minLength: 5)

            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isHighlighted ? WatchPalette.accent : WatchPalette.mutedText)
                .frame(width: 15)

            Text(prayer.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isHighlighted ? .white : WatchPalette.secondaryText)
                .frame(minWidth: 44, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, 8)
        .frame(height: 29)
        .background(isHighlighted ? WatchPalette.activeSurface : WatchPalette.rowSurface)
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isHighlighted ? WatchPalette.accent.opacity(0.55) : Color.white.opacity(0.08), lineWidth: 0.8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var symbol: String {
        switch prayer.key {
        case .fajr: return "sunrise.fill"
        case .sunrise, .dhuhr: return "sun.max.fill"
        case .asr: return "cloud.sun.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        }
    }
}

enum WatchPalette {
    static let accent = Color(red: 0.05, green: 0.52, blue: 1.00)
    static let secondaryText = Color(red: 0.72, green: 0.79, blue: 0.86)
    static let mutedText = Color(red: 0.45, green: 0.55, blue: 0.64)
    static let softSurface = Color.white.opacity(0.08)
    static let rowSurface = Color(red: 0.07, green: 0.12, blue: 0.16).opacity(0.96)
    static let activeSurface = Color(red: 0.02, green: 0.24, blue: 0.42).opacity(0.98)
    static let heroTop = Color(red: 0.03, green: 0.21, blue: 0.35)
    static let heroBottom = Color(red: 0.02, green: 0.08, blue: 0.13)
    static let background = LinearGradient(
        colors: [Color(red: 0.00, green: 0.035, blue: 0.06), Color.black],
        startPoint: .topTrailing,
        endPoint: .bottomLeading
    )
}
