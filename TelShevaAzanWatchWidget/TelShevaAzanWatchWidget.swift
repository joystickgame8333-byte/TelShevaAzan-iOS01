import SwiftUI
import WidgetKit

struct WatchPrayerEntry: TimelineEntry {
    let date: Date
    let nextPrayer: PrayerTime?
}

struct WatchPrayerProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchPrayerEntry {
        makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchPrayerEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchPrayerEntry>) -> Void) {
        let entry = makeEntry(for: Date())
        let refreshDate = entry.nextPrayer?.date.addingTimeInterval(30) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func makeEntry(for date: Date) -> WatchPrayerEntry {
        let dateKey = PrayerEngine.defaultDateKey(for: date)
        return WatchPrayerEntry(
            date: date,
            nextPrayer: PrayerEngine.nextPrayer(for: dateKey, now: date)
        )
    }
}

struct TelShevaWatchWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WatchPrayerEntry

    private let accent = Color(red: 0.96, green: 0.75, blue: 0.32)

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                Label {
                    Text("\(nextTitle) \(nextTime) · \(remainingText)")
                } icon: {
                    Image(systemName: "moon.stars.fill")
                }
            case .accessoryCircular:
                circular
            case .accessoryRectangular:
                rectangular
            case .accessoryCorner:
                Text(nextTime)
                    .font(.system(size: 14, weight: .black, design: .rounded).monospacedDigit())
                    .widgetLabel {
                        Text(nextTitle)
                    }
            default:
                rectangular
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(accent)

                Text(nextTitle)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                Text(nextTime)
                    .font(.system(size: 13, weight: .black, design: .rounded).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(7)
        }
    }

    private var rectangular: some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text("تل السبع")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(nextTime)
                    .font(.system(size: 17, weight: .black, design: .rounded).monospacedDigit())
                Text(nextTitle)
                    .font(.system(size: 18, weight: .black, design: .rounded))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.72)

            Text(remainingText)
                .font(.system(size: 12, weight: .bold, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .multilineTextAlignment(.trailing)
    }

    private var nextTitle: String {
        entry.nextPrayer?.title ?? "الصلاة"
    }

    private var nextTime: String {
        entry.nextPrayer?.time ?? "--:--"
    }

    private var remainingText: String {
        guard let nextDate = entry.nextPrayer?.date else { return "باقي --:--" }
        let seconds = max(Int(nextDate.timeIntervalSince(entry.date)), 0)
        let minutes = max((seconds + 59) / 60, 1)
        return String(format: "باقي %02d:%02d", minutes / 60, minutes % 60)
    }
}

@main
struct TelShevaAzanWatchWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.watch.nextPrayer"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WatchPrayerProvider()) { entry in
            TelShevaWatchWidgetView(entry: entry)
        }
        .configurationDisplayName("أذان تل السبع")
        .description("يعرض الصلاة القادمة في تل السبع على ساعة Apple.")
        .supportedFamilies([.accessoryInline, .accessoryCircular, .accessoryRectangular, .accessoryCorner])
    }
}
