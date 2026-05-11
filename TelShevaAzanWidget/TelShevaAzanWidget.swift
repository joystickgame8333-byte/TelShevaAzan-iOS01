import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif
import SwiftUI
import WidgetKit

struct TelShevaWidgetEntry: TimelineEntry {
    let date: Date
    let dateKey: String
    let nextPrayer: PrayerTime?
    let previousPrayer: PrayerTime?
    let times: [PrayerTime]
}

struct TelShevaWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TelShevaWidgetEntry {
        makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (TelShevaWidgetEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TelShevaWidgetEntry>) -> Void) {
        let entry = makeEntry(for: Date())
        let refreshDate = entry.nextPrayer?.date.addingTimeInterval(10) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func makeEntry(for date: Date) -> TelShevaWidgetEntry {
        let dateKey = PrayerEngine.defaultDateKey(for: date)
        let schedule = PrayerEngine.schedule(for: dateKey)

        return TelShevaWidgetEntry(
            date: date,
            dateKey: dateKey,
            nextPrayer: PrayerEngine.nextPrayer(for: dateKey, now: date),
            previousPrayer: PrayerEngine.previousPrayer(for: dateKey, now: date),
            times: schedule.displayTimes
        )
    }
}

struct TelShevaAzanWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: TelShevaWidgetEntry
    var presentation: TelShevaWidgetPresentation = .nextPrayer

    var body: some View {
        Group {
            if isLockScreenFamily {
                lockScreenLayout
            } else if presentation == .countdown {
                countdownHomeLayout
            } else if presentation == .schedule {
                scheduleHomeLayout
            } else {
                homeScreenLayout
            }
        }
        .dynamicTypeSize(.xSmall ... .large)
    }

    private var isLockScreenFamily: Bool {
        if #available(iOSApplicationExtension 16.0, *) {
            return family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular
        }

        return false
    }

    private var isNight: Bool {
        colorScheme == .dark
    }

    private var selectedNightThemeID: String {
        AppThemeStorage.defaults.string(forKey: AppThemeStorage.nightThemeKey) ?? PrayerVisualTheme.defaultNight.rawValue
    }

    private var selectedDayThemeID: String {
        AppThemeStorage.defaults.string(forKey: AppThemeStorage.dayThemeKey) ?? PrayerVisualTheme.defaultDay.rawValue
    }

    private var theme: PrayerVisualTheme {
        let selectedTheme = PrayerVisualTheme.selected(isNight: isNight, nightID: selectedNightThemeID, dayID: selectedDayThemeID)

        switch selectedTheme {
        case .nightDawnGlass:
            return .nightGlass
        case .dayDawnGlass:
            return .dayGlass
        default:
            return selectedTheme
        }
    }

    private var accent: Color {
        theme.accent
    }

    private var primaryText: Color {
        theme.primaryText
    }

    private var secondaryText: Color {
        theme.secondaryText
    }

    private var mutedText: Color {
        theme.mutedText
    }

    private var chipBackground: Color {
        theme.chipBackground
    }

    private var activeRowBackground: Color {
        theme.activeRowBackground
    }

    private var widgetGradientColors: [Color] {
        theme.widgetBackground
    }

    private var widgetBackground: some View {
        LinearGradient(
            colors: widgetGradientColors,
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    private var nextTitle: String {
        entry.nextPrayer?.title ?? "الصلاة"
    }

    private var nextTime: String {
        entry.nextPrayer?.time ?? "--:--"
    }

    private var compactRemainingText: String {
        guard let nextDate = entry.nextPrayer?.date else { return "باقي على الصلاة --:--" }
        let seconds = max(Int(nextDate.timeIntervalSince(entry.date)), 0)
        let minutes = (seconds + 59) / 60
        return "باقي على الصلاة \(hourMinuteText(fromMinutes: minutes))"
    }

    private var compactElapsedText: String {
        guard let previous = entry.previousPrayer else { return "مضى --:--" }
        let seconds = max(Int(entry.date.timeIntervalSince(previous.date)), 0)
        let minutes = seconds / 60
        return "مضى على \(previous.title) \(hourMinuteText(fromMinutes: minutes))"
    }

    private var inlineLiveText: Text {
        Text("\(nextTitle) \(nextTime) · \(compactRemainingText)")
    }

    private var liveRemainingText: Text {
        Text(compactRemainingText)
    }

    private var liveElapsedText: Text {
        Text(compactElapsedText)
    }

    private var homeScreenLayout: some View {
        ZStack {
            widgetBackground
            .ignoresSafeArea()

            switch family {
            case .systemMedium:
                mediumHomeLayout
            default:
                smallHomeLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(widgetBackground)
        .widgetContainerBackground {
            widgetBackground
        }
    }

    private var scheduleHomeLayout: some View {
        ZStack {
            widgetBackground
                .ignoresSafeArea()

            switch family {
            case .systemLarge:
                largeScheduleLayout
            default:
                mediumScheduleLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(widgetBackground)
        .widgetContainerBackground {
            widgetBackground
        }
    }

    private var countdownHomeLayout: some View {
        ZStack {
            widgetBackground
                .ignoresSafeArea()

            switch family {
            case .systemMedium:
                mediumCountdownLayout
            default:
                smallCountdownLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(widgetBackground)
        .widgetContainerBackground {
            widgetBackground
        }
    }

    private var smallHomeLayout: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 5) {
                Spacer(minLength: 0)

                Image(systemName: theme.symbol)
                    .font(.system(size: 12, weight: .black, design: .rounded))

                Text("تل السبع")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundColor(secondaryText)
            .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer(minLength: 1)

            Text("الصلاة القادمة")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(nextTitle)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.64)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(nextTime)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, alignment: .trailing)

            remainingChip(fontSize: 11)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(compactElapsedText)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(secondaryText.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(spacing: 4) {
                Text("v\(AppInfo.build)")
                    .font(.system(size: 8, weight: .black, design: .rounded).monospacedDigit())
                    .lineLimit(1)
                    .foregroundColor(secondaryText.opacity(0.68))

                Spacer(minLength: 4)

                Text("مواقيت محلية")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundColor(secondaryText.opacity(0.94))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(10)
    }

    private var mediumHomeLayout: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 2) {
                ForEach(Array(entry.times.prefix(6))) { item in
                    mediumPrayerRow(item)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .trailing, spacing: 4) {
                Text("الصلاة القادمة")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(nextTitle)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(nextTime)
                    .font(.system(size: 35, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                remainingChip(fontSize: 11)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(compactElapsedText)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(secondaryText.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("تل السبع \(AppInfo.displayVersion)")
                    .font(.system(size: 9, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(secondaryText.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 124, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(10)
    }

    private var mediumScheduleLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 3) {
                ForEach(Array(entry.times.prefix(6))) { item in
                    schedulePrayerRow(item, height: 21)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .trailing, spacing: 5) {
                Text("جدول اليوم")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundColor(accent)
                    .lineLimit(1)

                Text("تل السبع")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                remainingChip(fontSize: 11)
                    .padding(.top, 2)

                Text("\(nextTitle) \(nextTime)")
                    .font(.system(size: 12, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundColor(secondaryText.opacity(0.90))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Spacer(minLength: 0)

                Text("v\(AppInfo.build)")
                    .font(.system(size: 9, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(secondaryText.opacity(0.72))
                    .lineLimit(1)
            }
            .frame(width: 108, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(10)
    }

    private var largeScheduleLayout: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                remainingChip(fontSize: 13)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("جدول صلاة اليوم")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(accent)
                        .lineLimit(1)

                    Text("أذان تل السبع")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text("\(nextTitle) \(nextTime)")
                        .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundColor(secondaryText.opacity(0.88))
                        .lineLimit(1)
                }
            }

            VStack(spacing: 6) {
                ForEach(Array(entry.times.prefix(6))) { item in
                    schedulePrayerRow(item, height: 34)
                }
            }

            Spacer(minLength: 0)

            Text("مواقيت محلية · \(AppInfo.displayVersion)")
                .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundColor(secondaryText.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(16)
    }

    private var smallCountdownLayout: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(spacing: 5) {
                Spacer(minLength: 0)

                Text("عداد الصلاة")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .lineLimit(1)

                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 12, weight: .black, design: .rounded))
            }
            .foregroundColor(secondaryText)
            .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer(minLength: 1)

            Text("باقي على \(nextTitle)")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(compactRemainingValue)
                .font(.system(size: 39, weight: .black, design: .rounded).monospacedDigit())
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .frame(maxWidth: .infinity, alignment: .trailing)

            countdownProgressBar(height: 7)

            Text("\(nextTime) · \(nextTitle)")
                .font(.system(size: 11, weight: .black, design: .rounded).monospacedDigit())
                .foregroundColor(primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(compactElapsedText)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(secondaryText.opacity(0.76))
                .lineLimit(1)
                .minimumScaleFactor(0.66)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(11)
    }

    private var mediumCountdownLayout: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .trailing, spacing: 8) {
                Text("عداد الصلاة")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(accent)
                    .lineLimit(1)

                Text("باقي على \(nextTitle)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(secondaryText)
                    .lineLimit(1)

                Text(compactRemainingValue)
                    .font(.system(size: 40, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                countdownProgressBar(height: 8)

                Text(compactElapsedText)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(secondaryText.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(alignment: .trailing, spacing: 6) {
                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(accent)

                Text(nextTitle)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(nextTime)
                    .font(.system(size: 30, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundColor(primaryText)
                    .lineLimit(1)

                Text("تل السبع")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(secondaryText.opacity(0.80))
                    .lineLimit(1)
            }
            .frame(width: 104, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(12)
    }

    private func remainingChip(fontSize: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("باقي على الصلاة")
                .font(.system(size: max(fontSize - 2, 8), weight: .black, design: .rounded))

            Text(compactRemainingValue)
                .font(.system(size: fontSize + 2, weight: .black, design: .rounded))
                .monospacedDigit()
        }
        .foregroundColor(primaryText)
        .lineLimit(1)
        .minimumScaleFactor(0.66)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(chipBackground)
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var compactRemainingValue: String {
        guard let nextDate = entry.nextPrayer?.date else { return "--" }
        let seconds = max(Int(nextDate.timeIntervalSince(entry.date)), 0)
        let minutes = max((seconds + 59) / 60, 1)

        return hourMinuteText(fromMinutes: minutes)
    }

    private var prayerProgress: CGFloat {
        guard let previous = entry.previousPrayer, let next = entry.nextPrayer else { return 0 }
        let total = max(next.date.timeIntervalSince(previous.date), 1)
        let elapsed = min(max(entry.date.timeIntervalSince(previous.date), 0), total)

        return CGFloat(elapsed / total)
    }

    private func countdownProgressBar(height: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                Capsule()
                    .fill(chipBackground.opacity(0.64))

                Capsule()
                    .fill(accent)
                    .frame(width: max(height, proxy.size.width * prayerProgress))
                    .shadow(color: accent.opacity(0.24), radius: 5)
            }
        }
        .frame(height: height)
    }

    private func hourMinuteText(fromMinutes minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    private func mediumPrayerRow(_ item: PrayerTime) -> some View {
        let isActive = item.key == entry.nextPrayer?.key

        return HStack(spacing: 6) {
            Text(item.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 2)

            Text(item.time)
                .font(.system(size: 13, weight: .black, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundColor(isActive ? accent : mutedText)
        .padding(.horizontal, 7)
        .frame(height: 18)
        .background(isActive ? activeRowBackground : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func schedulePrayerRow(_ item: PrayerTime, height: CGFloat) -> some View {
        let isActive = item.key == entry.nextPrayer?.key

        return HStack(spacing: 8) {
            Text(item.time)
                .font(.system(size: height > 24 ? 18 : 13, weight: .black, design: .rounded).monospacedDigit())
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(item.title)
                .font(.system(size: height > 24 ? 18 : 13, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundColor(isActive ? accent : mutedText)
        .padding(.horizontal, height > 24 ? 12 : 8)
        .frame(height: height)
        .background(isActive ? activeRowBackground : chipBackground.opacity(0.42))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isActive ? accent.opacity(0.58) : secondaryText.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var lockScreenLayout: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            switch family {
            case .accessoryInline:
                Label {
                    inlineLiveText
                } icon: {
                    Image(systemName: "clock.fill")
                }
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10, weight: .bold))
                            .imageScale(.small)
                            .padding(.bottom, 1)

                        Text(nextTitle)
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)

                        Text(nextTime)
                            .font(.system(size: 14, weight: .black, design: .rounded).monospacedDigit())
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(7)
                }
            case .accessoryRectangular:
                VStack(alignment: .trailing, spacing: 1) {
                    Text("تل السبع")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(nextTime)
                            .font(.system(size: 17, weight: .black, design: .rounded).monospacedDigit())
                            .lineLimit(1)

                        Text(nextTitle)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    liveRemainingText
                        .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .multilineTextAlignment(.trailing)

                    liveElapsedText
                        .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .multilineTextAlignment(.trailing)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .leftToRight)
            default:
                smallHomeLayout
            }
        } else {
            smallHomeLayout
        }
    }
}

enum TelShevaWidgetPresentation {
    case nextPrayer
    case schedule
    case countdown
}

@main
struct TelShevaAzanWidgetBundle: WidgetBundle {
    var body: some Widget {
#if WIDGET_V3
        TelShevaAzanLegacyWidget()
        if #available(iOSApplicationExtension 16.1, *) {
            PrayerLiveActivityWidget()
        }
#else
        TelShevaAzanWidget()
        TelShevaAzanScheduleWidget()
        TelShevaAzanCountdownWidget()
#endif
    }
}

struct TelShevaAzanWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.nextPrayer.v2"

    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
                TelShevaAzanWidgetView(entry: entry)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .configurationDisplayName("الصلاة القادمة")
            .description("يعرض الصلاة القادمة ووقت الأذان والباقي عليها في تل السبع.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
        } else {
            StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
                TelShevaAzanWidgetView(entry: entry)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .configurationDisplayName("الصلاة القادمة")
            .description("يعرض الصلاة القادمة ووقت الأذان والباقي عليها في تل السبع.")
            .supportedFamilies([.systemSmall, .systemMedium])
        }
    }
}

struct TelShevaAzanLegacyWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.nextPrayer.v3"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
            TelShevaAzanWidgetView(entry: entry)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .configurationDisplayName("الصلاة القادمة الاحتياطي")
        .description("توافق مع الودجت السابق حتى لا يظهر الودجت القديم باللون الأسود.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct TelShevaAzanScheduleWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.dailySchedule.v1"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
            TelShevaAzanWidgetView(entry: entry, presentation: .schedule)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .configurationDisplayName("جدول الصلاة")
        .description("ودجت جديد يعرض مواقيت اليوم والصلاة القادمة.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct TelShevaAzanCountdownWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.countdown.v1"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
            TelShevaAzanWidgetView(entry: entry, presentation: .countdown)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .configurationDisplayName("عداد الصلاة")
        .description("ودجت زجاجي يركز على الوقت المتبقي للصلاة القادمة.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#if WIDGET_V3
@available(iOSApplicationExtension 16.1, *)
struct PrayerLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PrayerLiveActivityAttributes.self) { context in
            SalatiLiveActivityCard(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    SalatiIslandExpandedCenter(context: context)
                }
            } compactLeading: {
                SalatiIslandCompactLeading(context: context)
            } compactTrailing: {
                SalatiIslandCompactTrailing(context: context)
            } minimal: {
                SalatiIslandMinimal(context: context)
            }
        }
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct SalatiLiveActivityCard: View {
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    private var isPrayerDue: Bool {
        context.state.phase != .almostTime || Date() >= context.state.prayerDate
    }

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: isPrayerDue ? "bell.badge.fill" : "bell.fill")
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(SalatiLiveActivityStyle.gold)

            Text(isPrayerDue ? "حان أذان \(context.attributes.prayerName)" : "باقي على صلاة \(context.attributes.prayerName)")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if isPrayerDue {
                Text("الآن")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(SalatiLiveActivityStyle.gold)
                    .lineLimit(1)
            } else {
                SalatiCountdownText(context: context, size: 28)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .environment(\.layoutDirection, .rightToLeft)
        .multilineTextAlignment(.center)
        .activityBackgroundTint(Color(red: 0.04, green: 0.07, blue: 0.07))
        .activitySystemActionForegroundColor(SalatiLiveActivityStyle.gold)
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct SalatiIslandExpandedCenter: View {
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    private var isPrayerDue: Bool {
        context.state.phase != .almostTime || Date() >= context.state.prayerDate
    }

    var body: some View {
        VStack(spacing: 1) {
            Text(isPrayerDue ? "حان الأذان" : "باقي على \(context.attributes.prayerName)")
                .font(.caption.weight(.black))
                .foregroundStyle(isPrayerDue ? SalatiLiveActivityStyle.gold : .white)
                .lineLimit(1)
                .minimumScaleFactor(0.64)

            if isPrayerDue {
                Text("الآن")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(SalatiLiveActivityStyle.gold)
            } else {
                SalatiCountdownText(context: context, size: 16)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .multilineTextAlignment(.center)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct SalatiIslandCompactLeading: View {
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    var body: some View {
        Text(salatiRemainingText(for: context.attributes.prayerName))
            .font(.caption2.weight(.black))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.62)
            .environment(\.layoutDirection, .rightToLeft)
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct SalatiIslandCompactTrailing: View {
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    var body: some View {
        SalatiCountdownText(context: context, size: 12)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct SalatiIslandMinimal: View {
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    private var isPrayerDue: Bool {
        context.state.phase != .almostTime || Date() >= context.state.prayerDate
    }

    var body: some View {
        Image(systemName: isPrayerDue ? "bell.badge.fill" : "bell.fill")
            .foregroundStyle(SalatiLiveActivityStyle.gold)
            .accessibilityLabel(isPrayerDue ? "حان الأذان" : "اقترب الأذان")
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct SalatiCountdownText: View {
    let context: ActivityViewContext<PrayerLiveActivityAttributes>
    let size: CGFloat

    var body: some View {
        if Date() < context.state.prayerDate {
            Text(timerInterval: Date()...context.state.prayerDate, countsDown: true)
                .font(.system(size: size, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(SalatiLiveActivityStyle.gold)
        } else {
            Text("الآن")
                .font(.system(size: size, weight: .black, design: .rounded))
                .foregroundStyle(SalatiLiveActivityStyle.gold)
        }
    }
}

private enum SalatiLiveActivityStyle {
    static let gold = Color(red: 0.98, green: 0.76, blue: 0.30)
}

private func salatiRemainingText(for prayerName: String) -> String {
    if prayerName.hasPrefix("ال") {
        return "متبقي لل\(prayerName.dropFirst(2))"
    }

    return "متبقي لـ\(prayerName)"
}

#endif

private extension View {
    @ViewBuilder
    func widgetContainerBackground<Background: View>(@ViewBuilder _ background: () -> Background) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                background()
            }
        } else {
            self.background(background())
        }
    }
}
