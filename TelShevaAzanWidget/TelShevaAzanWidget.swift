import SwiftUI
import WidgetKit

struct TelShevaWidgetEntry: TimelineEntry {
    let date: Date
    let dateKey: String
    let nextPrayer: PrayerTime?
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
        let refreshDate = entry.nextPrayer?.date.addingTimeInterval(5) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func makeEntry(for date: Date) -> TelShevaWidgetEntry {
        let dateKey = PrayerEngine.defaultDateKey(for: date)
        let schedule = PrayerEngine.schedule(for: dateKey)
        let nextPrayer = PrayerEngine.nextPrayer(for: dateKey, now: date)

        return TelShevaWidgetEntry(
            date: date,
            dateKey: dateKey,
            nextPrayer: nextPrayer,
            times: schedule.displayTimes
        )
    }
}

struct TelShevaAzanWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TelShevaWidgetEntry

    private let accent = Color(red: 0.96, green: 0.78, blue: 0.38)
    private let mint = Color(red: 0.75, green: 0.91, blue: 0.86)

    var body: some View {
        if isLockScreenFamily {
            lockScreenLayout
        } else {
            homeScreenLayout
        }
    }

    private var isLockScreenFamily: Bool {
        if #available(iOSApplicationExtension 16.0, *) {
            return family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
        }

        return false
    }

    private var homeScreenLayout: some View {
        ZStack {
            if family == .systemMedium {
                mediumHomeLayout
            } else {
                smallHomeLayout
            }
        }
        .widgetContainerBackground {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.46, blue: 0.43),
                    Color(red: 0.09, green: 0.13, blue: 0.11)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }

    private var smallHomeLayout: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("تل السبع \(AppInfo.displayVersion)")
                .font(.caption.weight(.bold))
                .foregroundColor(mint)

            Spacer(minLength: 0)

            Text(entry.nextPrayer?.title ?? "--")
                .font(.title2.weight(.black))
                .foregroundColor(.white)
                .minimumScaleFactor(0.75)

            Text(entry.nextPrayer?.time ?? "--:--")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(accent)
                .minimumScaleFactor(0.7)

            if let nextDate = entry.nextPrayer?.date {
                Text(nextDate, style: .timer)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundColor(mint)
            }
        }
        .padding(14)
    }

    private var mediumHomeLayout: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .trailing, spacing: 8) {
                Text("تل السبع \(AppInfo.displayVersion)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(mint)

                Text(entry.nextPrayer?.title ?? "--")
                    .font(.title.weight(.black))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(entry.nextPrayer?.time ?? "--:--")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(accent)

                if let nextDate = entry.nextPrayer?.date {
                    Text(nextDate, style: .timer)
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundColor(mint)
                }
            }

            VStack(spacing: 5) {
                ForEach(entry.times.prefix(5)) { item in
                    HStack {
                        Text(item.time)
                            .font(.caption2.monospacedDigit().weight(.bold))
                            .foregroundColor(item.key == entry.nextPrayer?.key ? accent : .white.opacity(0.78))
                        Spacer(minLength: 4)
                        Text(item.title)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white.opacity(0.86))
                    }
                }
            }
        }
        .padding(14)
    }

    @ViewBuilder
    private var lockScreenLayout: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            switch family {
            case .accessoryInline:
                Label("\(entry.nextPrayer?.title ?? "الصلاة") \(entry.nextPrayer?.time ?? "--:--")", systemImage: "moon.stars.fill")
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 2) {
                        Image(systemName: "moon.stars.fill")
                            .font(.caption2.weight(.bold))
                        Text(entry.nextPrayer?.time ?? "--:--")
                            .font(.caption.monospacedDigit().weight(.black))
                            .minimumScaleFactor(0.7)
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .trailing, spacing: 2) {
                    Text("أذان تل السبع")
                        .font(.caption2.weight(.bold))
                    HStack(spacing: 5) {
                        Text(entry.nextPrayer?.time ?? "--:--")
                            .font(.headline.monospacedDigit().weight(.black))
                        Text(entry.nextPrayer?.title ?? "--")
                            .font(.headline.weight(.bold))
                    }
                    Text(lockScreenRemainingText)
                        .font(.caption2.monospacedDigit())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            default:
                smallHomeLayout
            }
        } else {
            smallHomeLayout
        }
    }

    private var lockScreenRemainingText: String {
        guard let nextDate = entry.nextPrayer?.date else { return "موعد الصلاة" }
        let minutes = max(Int(nextDate.timeIntervalSince(entry.date) / 60), 0)

        if minutes >= 60 {
            return "بعد \(minutes / 60)س \(minutes % 60)د"
        }

        return "بعد \(minutes)د"
    }
}

struct TelShevaAzanWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.nextPrayer"

    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
                TelShevaAzanWidgetView(entry: entry)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .configurationDisplayName("أذان تل السبع")
            .description("الصلاة القادمة ومواقيت اليوم لتل السبع.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
        } else {
            StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
                TelShevaAzanWidgetView(entry: entry)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .configurationDisplayName("أذان تل السبع")
            .description("الصلاة القادمة ومواقيت اليوم لتل السبع.")
            .supportedFamilies([.systemSmall, .systemMedium])
        }
    }
}

@main
struct TelShevaAzanWidgetBundle: WidgetBundle {
    var body: some Widget {
        TelShevaAzanWidget()
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
