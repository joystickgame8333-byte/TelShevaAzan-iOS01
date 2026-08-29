import SwiftUI
import WidgetKit

struct WatchPrayerEntry: TimelineEntry {
    let date: Date
    let nextPrayer: PrayerTime?
    let scheduleIsTomorrow: Bool
}

struct WatchPrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchPrayerEntry {
        makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchPrayerEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchPrayerEntry>) -> Void) {
        let now = Date()
        var dates = [now]

        for dateKey in PrayerEngine.upcomingDateKeys(from: now, count: 3) {
            if let midnight = PrayerEngine.date(from: dateKey, time: "00:00"), midnight > now {
                dates.append(midnight)
            }
            let events = PrayerEngine.schedule(for: dateKey).displayTimes.filter {
                PrayerEngine.prayerOrder.contains($0.key) && $0.date > now
            }
            dates.append(contentsOf: events.map(\.date))
        }

        let uniqueDates = Array(Set(dates)).sorted()
        let entries = uniqueDates.map(makeEntry(for:))
        let reloadDate = (uniqueDates.last ?? now).addingTimeInterval(60)
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }

    private func makeEntry(for date: Date) -> WatchPrayerEntry {
        let todayKey = PrayerEngine.defaultDateKey(for: date)
        let scheduleKey = PrayerEngine.automaticScheduleDateKey(for: date)
        return WatchPrayerEntry(
            date: date,
            nextPrayer: PrayerEngine.nextPrayer(for: scheduleKey, now: date),
            scheduleIsTomorrow: scheduleKey != todayKey
        )
    }
}

struct TelShevaWatchWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WatchPrayerEntry

    private let accent = Color(red: 0.05, green: 0.52, blue: 1.00)

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                inline
            case .accessoryCircular:
                circular
            case .accessoryRectangular:
                rectangular
            case .accessoryCorner:
                corner
            default:
                rectangular
            }
        }
        .widgetAccentable()
    }

    private var inline: some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
            Text(nextTitle)
                .environment(\.layoutDirection, .rightToLeft)
            Text("·")
            if let target = entry.nextPrayer?.date {
                Text(target, style: .timer)
                    .monospacedDigit()
            } else {
                Text("--:--")
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()

            if let target = entry.nextPrayer?.date {
                ProgressView(timerInterval: entry.date...target, countsDown: true)
                    .progressViewStyle(.circular)
                    .tint(accent)

                VStack(spacing: 0) {
                    Image(systemName: symbol)
                        .font(.system(size: 8, weight: .black))
                    Text(nextTitle)
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .environment(\.layoutDirection, .rightToLeft)
                    Text(target, style: .timer)
                        .font(.system(size: 8, weight: .bold, design: .rounded).monospacedDigit())
                        .minimumScaleFactor(0.6)
                }
            } else {
                Image(systemName: "clock")
            }
        }
    }

    private var rectangular: some View {
        HStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 1) {
                Text(nextTime)
                    .font(.system(size: 18, weight: .black, design: .rounded).monospacedDigit())
                if let target = entry.nextPrayer?.date {
                    Text(target, style: .timer)
                        .font(.system(size: 11, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 3)

            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 3) {
                    Text(entry.scheduleIsTomorrow ? "غدًا" : "القادمة")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                    Image(systemName: symbol)
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(accent)
                }
                Text(nextTitle)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
        .environment(\.layoutDirection, .leftToRight)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var corner: some View {
        Text(nextTime)
            .font(.system(size: 14, weight: .black, design: .rounded).monospacedDigit())
            .widgetLabel {
                Label(nextTitle, systemImage: symbol)
                    .environment(\.layoutDirection, .rightToLeft)
            }
    }

    private var nextTitle: String {
        entry.nextPrayer?.title ?? "الصلاة"
    }

    private var nextTime: String {
        entry.nextPrayer?.time ?? "--:--"
    }

    private var symbol: String {
        switch entry.nextPrayer?.key {
        case .fajr: return "sunrise.fill"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "cloud.sun.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.stars.fill"
        case .sunrise: return "sun.max.fill"
        case nil: return "clock.fill"
        }
    }
}

@main
struct TelShevaAzanWatchWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.watch.nextPrayer"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchPrayerProvider()) { entry in
            TelShevaWatchWidgetView(entry: entry)
        }
        .configurationDisplayName("صلاتي")
        .description("يعرض الصلاة القادمة حسب المنطقة المعتمدة على ساعة Apple.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular, .accessoryCorner])
    }
}
