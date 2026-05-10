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
            PrayerLiveActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    PrayerIslandExpandedTimerView(context: context)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    PrayerIslandRingIcon(context: context, size: 62)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    PrayerIslandBottomView(context: context)
                }
            } compactLeading: {
                PrayerIslandCompactTimer(context: context)
            } compactTrailing: {
                PrayerIslandRingIcon(context: context, size: 32)
            } minimal: {
                PrayerIslandRingIcon(context: context, size: 28)
            }
            .keylineTint(PrayerLiveActivityPalette.islandAccent)
            .contentMargins(.all, 8, for: .expanded)
            .contentMargins(.all, 3, for: .compactLeading)
            .contentMargins(.all, 3, for: .compactTrailing)
        }
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct PrayerLiveActivityLockScreenView: View {
    @Environment(\.colorScheme) private var colorScheme
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    private var palette: PrayerLiveActivityPalette {
        PrayerLiveActivityPalette(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(spacing: 8) {
                PrayerLiveActivityCountdown(context: context, style: .lockScreen)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.phase.title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(palette.accent)

                    Text(context.attributes.cityName)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(palette.secondary)
                }

                PrayerIslandRingIcon(context: context, size: 42)
            }

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(context.attributes.prayerTime)
                    .font(.system(size: 30, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(palette.accent)

                Spacer(minLength: 10)

                Text(context.attributes.prayerName)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }

            PrayerIslandBottomView(context: context)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(
            LinearGradient(
                colors: palette.background,
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        )
        .activityBackgroundTint(palette.background.first ?? Color.black)
        .activitySystemActionForegroundColor(palette.accent)
        .environment(\.layoutDirection, .leftToRight)
        .multilineTextAlignment(.trailing)
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct PrayerIslandExpandedTimerView: View {
    @Environment(\.colorScheme) private var colorScheme
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    private var palette: PrayerLiveActivityPalette {
        PrayerLiveActivityPalette(colorScheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PrayerLiveActivityCountdown(context: context, style: .expanded)

            Text(expandedSubtitle)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(palette.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var expandedSubtitle: String {
        switch context.state.phase {
        case .almostTime:
            if context.attributes.isPreview {
                return "اختبار الجزيرة السريع"
            }
            return "حتى أذان \(context.attributes.prayerName)"
        case .now:
            return "أذان \(context.attributes.prayerName)"
        case .adhkar:
            return "أذكار بعد الصلاة"
        }
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct PrayerIslandRingIcon: View {
    @Environment(\.colorScheme) private var colorScheme
    let context: ActivityViewContext<PrayerLiveActivityAttributes>
    let size: CGFloat

    private var palette: PrayerLiveActivityPalette {
        PrayerLiveActivityPalette(colorScheme: colorScheme)
    }

    private var ringProgress: CGFloat {
        guard context.state.phase == .almostTime else { return 1 }
        let total = max(context.state.prayerDate.timeIntervalSince(context.state.updatedAt), 1)
        let remaining = max(context.state.prayerDate.timeIntervalSince(Date()), 0)
        return CGFloat(min(max(1 - (remaining / total), 0.06), 1))
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(palette.chip)

            Circle()
                .stroke(palette.accent.opacity(0.24), lineWidth: max(size * 0.10, 3))

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(
                    palette.accent,
                    style: StrokeStyle(lineWidth: max(size * 0.10, 3), lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: context.state.phase.systemImage)
                .font(.system(size: size * 0.36, weight: .black))
                .foregroundStyle(palette.accent)
        }
        .frame(width: size, height: size)
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct PrayerIslandBottomView: View {
    @Environment(\.colorScheme) private var colorScheme
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    private var palette: PrayerLiveActivityPalette {
        PrayerLiveActivityPalette(colorScheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: context.attributes.isPreview ? "sparkles" : "clock.badge.checkmark.fill")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(palette.accent)

            Text(message)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var message: String {
        switch context.state.phase {
        case .almostTime:
            return context.attributes.isPreview ? "اختبار حي للعدّاد النظامي داخل الجزيرة" : "تنبيه هادئ قبل الأذان بثلاث دقائق"
        case .now:
            return "حان الآن أذان \(context.attributes.prayerName)"
        case .adhkar:
            return "ابدأ أذكار ما بعد الصلاة بهدوء"
        }
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct PrayerIslandCompactTimer: View {
    @Environment(\.colorScheme) private var colorScheme
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    var body: some View {
        PrayerLiveActivityCountdown(context: context, style: .compact)
            .foregroundStyle(PrayerLiveActivityPalette(colorScheme: colorScheme).accent)
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct PrayerLiveActivityCountdown: View {
    @Environment(\.colorScheme) private var colorScheme

    enum Style {
        case compact
        case expanded
        case lockScreen
    }

    let context: ActivityViewContext<PrayerLiveActivityAttributes>
    let style: Style

    var body: some View {
        Group {
            if context.state.phase == .almostTime && Date() < context.state.prayerDate {
                Text(timerInterval: Date()...context.state.prayerDate, countsDown: true)
                    .monospacedDigit()
            } else {
                Text(context.state.phase.shortTitle)
            }
        }
        .font(font)
        .foregroundStyle(foreground)
        .lineLimit(1)
        .minimumScaleFactor(0.62)
    }

    private var font: Font {
        switch style {
        case .compact:
            return .system(size: 17, weight: .black, design: .rounded)
        case .expanded:
            return .system(size: 43, weight: .black, design: .rounded)
        case .lockScreen:
            return .system(size: 29, weight: .black, design: .rounded)
        }
    }

    private var foreground: Color {
        let palette = PrayerLiveActivityPalette(colorScheme: colorScheme)
        switch style {
        case .compact:
            return palette.accent
        default:
            return palette.accent
        }
    }
}

private struct PrayerLiveActivityPalette {
    let background: [Color]
    let primary: Color
    let secondary: Color
    let accent: Color
    let chip: Color

    init(colorScheme: ColorScheme) {
        let isNight = colorScheme == .dark
        let nightID = AppThemeStorage.defaults.string(forKey: AppThemeStorage.nightThemeKey) ?? PrayerVisualTheme.defaultNight.rawValue
        let dayID = AppThemeStorage.defaults.string(forKey: AppThemeStorage.dayThemeKey) ?? PrayerVisualTheme.defaultDay.rawValue
        let theme = PrayerVisualTheme.selected(isNight: isNight, nightID: nightID, dayID: dayID)

        background = theme.widgetBackground
        primary = theme.primaryText
        secondary = theme.secondaryText.opacity(0.86)
        accent = theme.accent
        chip = theme.chipBackground.opacity(isNight ? 0.84 : 0.72)
    }

    static var islandAccent: Color {
        let nightID = AppThemeStorage.defaults.string(forKey: AppThemeStorage.nightThemeKey) ?? PrayerVisualTheme.defaultNight.rawValue
        let dayID = AppThemeStorage.defaults.string(forKey: AppThemeStorage.dayThemeKey) ?? PrayerVisualTheme.defaultDay.rawValue
        return PrayerVisualTheme.selected(isNight: true, nightID: nightID, dayID: dayID).accent
    }
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
