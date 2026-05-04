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

    var body: some View {
        Group {
            if isLockScreenFamily {
                lockScreenLayout
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

    private var accent: Color {
        isNight ? Color(red: 0.96, green: 0.78, blue: 0.38) : Color(red: 0.02, green: 0.43, blue: 0.39)
    }

    private var primaryText: Color {
        isNight ? .white : Color(red: 0.03, green: 0.17, blue: 0.16)
    }

    private var secondaryText: Color {
        isNight ? Color(red: 0.76, green: 0.93, blue: 0.87) : Color(red: 0.16, green: 0.46, blue: 0.42)
    }

    private var mutedText: Color {
        isNight ? .white.opacity(0.86) : Color(red: 0.12, green: 0.32, blue: 0.30).opacity(0.88)
    }

    private var chipBackground: Color {
        isNight ? Color.white.opacity(0.13) : Color.white.opacity(0.64)
    }

    private var activeRowBackground: Color {
        isNight ? Color.white.opacity(0.12) : Color(red: 0.02, green: 0.43, blue: 0.39).opacity(0.13)
    }

    private var widgetGradientColors: [Color] {
        isNight ? [
            Color(red: 0.04, green: 0.49, blue: 0.45),
            Color(red: 0.03, green: 0.30, blue: 0.28)
        ] : [
            Color(red: 0.86, green: 0.97, blue: 0.93),
            Color(red: 0.94, green: 0.91, blue: 0.74)
        ]
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
        guard let nextDate = entry.nextPrayer?.date else { return "باقي --" }
        let seconds = max(Int(nextDate.timeIntervalSince(entry.date)), 0)
        let minutes = (seconds + 59) / 60

        if minutes >= 60 {
            return "باقي \(minutes / 60)س \(minutes % 60)د"
        }

        return "باقي \(minutes)د"
    }

    private var compactElapsedText: String {
        guard let previous = entry.previousPrayer else { return "مضى --" }
        let seconds = max(Int(entry.date.timeIntervalSince(previous.date)), 0)
        let minutes = seconds / 60

        if minutes >= 60 {
            return "مضى على \(previous.title) \(minutes / 60)س \(minutes % 60)د"
        }

        return "مضى على \(previous.title) \(minutes)د"
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

    private var smallHomeLayout: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 5) {
                Spacer(minLength: 0)

                Image(systemName: isNight ? "moon.stars.fill" : "sun.max.fill")
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

    private func remainingChip(fontSize: CGFloat) -> some View {
        HStack(spacing: 4) {
            Text("باقي")

            Text(compactRemainingValue)
                .monospacedDigit()
        }
        .font(.system(size: fontSize, weight: .black, design: .rounded))
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
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours):" + String(format: "%02d", minutes)
        }

        return "\(max(minutes, 1))د"
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

@main
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
