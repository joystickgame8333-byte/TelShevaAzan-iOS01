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
            SalatiPrayerBadge(prayerName: context.attributes.prayerName, size: 30, mode: salatiBadgeMode(for: context))

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
                SalatiCountdownText(context: context, size: 28, mode: salatiBadgeMode(for: context))
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
                SalatiCountdownText(context: context, size: 16, mode: salatiBadgeMode(for: context))
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
        SalatiPrayerBadge(prayerName: context.attributes.prayerName, size: 22, mode: salatiBadgeMode(for: context))
            .frame(width: 24, height: 24)
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct SalatiIslandCompactTrailing: View {
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    var body: some View {
        SalatiCountdownText(context: context, size: 11, mode: salatiBadgeMode(for: context))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .allowsTightening(true)
            .frame(width: 36, height: 18, alignment: .leading)
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct SalatiIslandMinimal: View {
    let context: ActivityViewContext<PrayerLiveActivityAttributes>

    private var isPrayerDue: Bool {
        context.state.phase != .almostTime || Date() >= context.state.prayerDate
    }

    var body: some View {
        SalatiPrayerBadge(prayerName: context.attributes.prayerName, size: 18, mode: salatiBadgeMode(for: context))
            .accessibilityLabel(isPrayerDue ? "حان الأذان" : "اقترب الأذان")
    }
}

@available(iOSApplicationExtension 16.1, *)
private enum SalatiPrayerBadgeMode {
    case normal
    case warning
    case now
}

@available(iOSApplicationExtension 16.1, *)
private func salatiBadgeMode(for context: ActivityViewContext<PrayerLiveActivityAttributes>) -> SalatiPrayerBadgeMode {
    let now = Date()

    if context.state.phase != .almostTime || now >= context.state.prayerDate {
        return .now
    }

    if context.state.prayerDate.timeIntervalSince(now) <= 10 {
        return .warning
    }

    return .normal
}

@available(iOSApplicationExtension 16.1, *)
private struct SalatiPrayerBadge: View {
    let prayerName: String
    let size: CGFloat
    let mode: SalatiPrayerBadgeMode

    private var prayerKey: PrayerKey {
        PrayerKey.allCases.first { $0.title == prayerName } ?? .fajr
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.36, style: .continuous)
                .fill(backgroundGradient)

            badgeSymbol
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.36, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.36, style: .continuous)
                .stroke(borderColor, lineWidth: max(size * 0.035, 0.6))
        )
        .shadow(color: .black.opacity(0.24), radius: size * 0.16, y: size * 0.08)
        .shadow(color: SalatiLiveActivityStyle.gold.opacity(glowOpacity), radius: size * 0.26)
    }

    private var borderColor: Color {
        switch mode {
        case .normal:
            return .white.opacity(0.16)
        case .warning:
            return SalatiLiveActivityStyle.gold.opacity(0.48)
        case .now:
            return SalatiLiveActivityStyle.gold.opacity(0.68)
        }
    }

    private var glowOpacity: Double {
        switch mode {
        case .normal:
            return 0
        case .warning:
            return 0.24
        case .now:
            return 0.42
        }
    }

    private var backgroundGradient: LinearGradient {
        switch prayerKey {
        case .fajr:
            return LinearGradient(
                colors: [Color(red: 0.16, green: 0.20, blue: 0.38), Color(red: 0.04, green: 0.08, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dhuhr, .sunrise:
            return LinearGradient(
                colors: [Color(red: 0.13, green: 0.46, blue: 0.86), Color(red: 0.34, green: 0.76, blue: 1.0)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .asr:
            return LinearGradient(
                colors: [Color(red: 0.15, green: 0.23, blue: 0.34), Color(red: 0.07, green: 0.12, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .maghrib:
            return LinearGradient(
                colors: [Color(red: 0.33, green: 0.20, blue: 0.36), Color(red: 0.67, green: 0.36, blue: 0.30), Color(red: 0.13, green: 0.10, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .isha:
            return LinearGradient(
                colors: [Color(red: 0.07, green: 0.11, blue: 0.24), Color(red: 0.03, green: 0.07, blue: 0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private var badgeSymbol: some View {
        celestialLayer
        mosqueLayer
        horizonLayer
    }

    @ViewBuilder
    private var celestialLayer: some View {
        switch prayerKey {
        case .fajr:
            crescent(cutout: Color(red: 0.10, green: 0.14, blue: 0.29), scale: 0.54, x: 0.23, y: -0.23)
            dawnGlow
        case .dhuhr, .sunrise:
            sun(scale: 0.34, x: 0.26, y: -0.26)
            Circle()
                .fill(.white.opacity(0.12))
                .frame(width: size * 1.08, height: size * 0.58)
                .offset(x: -size * 0.24, y: size * 0.44)
        case .asr:
            sun(scale: 0.34, x: 0.18, y: -0.06)
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(width: size * 0.58, height: size * 0.22)
                .offset(x: -size * 0.05, y: size * 0.22)
        case .maghrib:
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.84, blue: 0.44), Color(red: 1.0, green: 0.52, blue: 0.30)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.58, height: size * 0.58)
                .shadow(color: Color(red: 1.0, green: 0.55, blue: 0.30).opacity(0.46), radius: size * 0.18)
                .offset(x: size * 0.12, y: size * 0.20)
        case .isha:
            crescent(cutout: Color(red: 0.06, green: 0.10, blue: 0.22), scale: 0.48, x: 0.23, y: -0.08)
            star(sizeMultiplier: 0.12, x: -0.30, y: -0.23)
            star(sizeMultiplier: 0.09, x: -0.07, y: 0.28)
            star(sizeMultiplier: 0.07, x: -0.33, y: 0.18)
        }
    }

    private var mosqueLayer: some View {
        ZStack {
            Circle()
                .fill(mosqueColor)
                .frame(width: size * 0.42, height: size * 0.42)
                .offset(x: size * 0.07, y: size * 0.10)

            RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                .fill(mosqueColor)
                .frame(width: size * 0.50, height: size * 0.30)
                .offset(x: size * 0.06, y: size * 0.24)

            RoundedRectangle(cornerRadius: size * 0.04, style: .continuous)
                .fill(mosqueColor)
                .frame(width: size * 0.12, height: size * 0.62)
                .offset(x: -size * 0.31, y: size * 0.09)

            Capsule()
                .fill(SalatiLiveActivityStyle.gold.opacity(mode == .normal ? 0.82 : 1.0))
                .frame(width: size * 0.14, height: size * 0.06)
                .offset(x: -size * 0.31, y: -size * 0.25)

            RoundedRectangle(cornerRadius: size * 0.03, style: .continuous)
                .fill(Color(red: 0.03, green: 0.07, blue: 0.08).opacity(0.55))
                .frame(width: size * 0.12, height: size * 0.19)
                .offset(x: size * 0.07, y: size * 0.29)
        }
        .shadow(color: .black.opacity(0.18), radius: size * 0.08, y: size * 0.04)
    }

    private var horizonLayer: some View {
        Capsule()
            .fill(horizonColor)
            .frame(width: size * 0.78, height: max(size * 0.08, 2))
            .offset(x: size * 0.02, y: size * 0.34)
    }

    private var mosqueColor: Color {
        mode == .now ? Color(red: 1.0, green: 0.97, blue: 0.82) : Color.white.opacity(0.93)
    }

    private var horizonColor: Color {
        switch prayerKey {
        case .maghrib:
            return .white.opacity(mode == .normal ? 0.82 : 0.95)
        case .asr:
            return .white.opacity(0.34)
        default:
            return SalatiLiveActivityStyle.gold.opacity(mode == .normal ? 0.72 : 0.96)
        }
    }

    private var dawnGlow: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [SalatiLiveActivityStyle.gold.opacity(0.96), .white.opacity(0.55)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size * 0.64, height: max(size * 0.08, 2))
            .offset(x: size * 0.06, y: size * 0.30)
    }

    private func sun(scale: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(Color(red: 1.0, green: 0.88, blue: 0.42))
            .frame(width: size * scale, height: size * scale)
            .shadow(color: Color(red: 1.0, green: 0.78, blue: 0.28).opacity(mode == .normal ? 0.54 : 0.78), radius: size * 0.18)
            .offset(x: size * x, y: size * y)
    }

    private func crescent(cutout: Color, scale: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.94, green: 0.97, blue: 1.0))
                .frame(width: size * scale, height: size * scale)

            Circle()
                .fill(cutout)
                .frame(width: size * scale * 0.88, height: size * scale * 0.88)
                .offset(x: -size * scale * 0.26)
        }
        .offset(x: size * x, y: size * y)
    }

    private func star(sizeMultiplier: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle()
            .fill(SalatiLiveActivityStyle.gold)
            .frame(width: max(size * sizeMultiplier, 2), height: max(size * sizeMultiplier, 2))
            .offset(x: size * x, y: size * y)
    }
}

@available(iOSApplicationExtension 16.1, *)
private struct SalatiCountdownText: View {
    let context: ActivityViewContext<PrayerLiveActivityAttributes>
    let size: CGFloat
    var mode: SalatiPrayerBadgeMode = .normal

    var body: some View {
        if Date() < context.state.prayerDate {
            Text(timerInterval: Date()...context.state.prayerDate, countsDown: true)
                .font(.system(size: size, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(countdownColor)
                .shadow(color: countdownColor.opacity(mode == .normal ? 0 : 0.62), radius: size * 0.34)
        } else {
            Text("الآن")
                .font(.system(size: size, weight: .black, design: .rounded))
                .foregroundStyle(countdownColor)
                .shadow(color: countdownColor.opacity(0.62), radius: size * 0.34)
        }
    }

    private var countdownColor: Color {
        switch mode {
        case .normal:
            return SalatiLiveActivityStyle.gold
        case .warning:
            return Color(red: 1.0, green: 0.84, blue: 0.42)
        case .now:
            return Color(red: 1.0, green: 0.94, blue: 0.70)
        }
    }
}

private enum SalatiLiveActivityStyle {
    static let gold = Color(red: 0.98, green: 0.76, blue: 0.30)
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
