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

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.46, blue: 0.43),
                    Color(red: 0.09, green: 0.13, blue: 0.11)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            if family == .systemMedium {
                mediumLayout
            } else {
                smallLayout
            }
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("تل السبع \(AppInfo.displayVersion)")
                .font(.caption.weight(.bold))
                .foregroundColor(Color(red: 0.75, green: 0.91, blue: 0.86))

            Spacer(minLength: 0)

            Text(entry.nextPrayer?.title ?? "--")
                .font(.title2.weight(.black))
                .foregroundColor(.white)
                .minimumScaleFactor(0.75)

            Text(entry.nextPrayer?.time ?? "--:--")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.96, green: 0.78, blue: 0.38))
                .minimumScaleFactor(0.7)

            if let nextDate = entry.nextPrayer?.date {
                Text(nextDate, style: .timer)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundColor(Color(red: 0.86, green: 0.94, blue: 0.91))
            }
        }
        .padding(14)
    }

    private var mediumLayout: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .trailing, spacing: 8) {
                Text("تل السبع \(AppInfo.displayVersion)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color(red: 0.75, green: 0.91, blue: 0.86))

                Text(entry.nextPrayer?.title ?? "--")
                    .font(.title.weight(.black))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(entry.nextPrayer?.time ?? "--:--")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.96, green: 0.78, blue: 0.38))

                if let nextDate = entry.nextPrayer?.date {
                    Text(nextDate, style: .timer)
                        .font(.caption.monospacedDigit().weight(.bold))
                        .foregroundColor(Color(red: 0.86, green: 0.94, blue: 0.91))
                }
            }

            VStack(spacing: 5) {
                ForEach(entry.times.prefix(5)) { item in
                    HStack {
                        Text(item.time)
                            .font(.caption2.monospacedDigit().weight(.bold))
                            .foregroundColor(item.key == entry.nextPrayer?.key ? Color(red: 0.96, green: 0.78, blue: 0.38) : .white.opacity(0.78))
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
}

struct TelShevaAzanWidget: Widget {
    let kind = "TelShevaAzanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
            TelShevaAzanWidgetView(entry: entry)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .configurationDisplayName("أذان تل السبع")
        .description("الصلاة القادمة ومواقيت اليوم لتل السبع.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct TelShevaAzanWidgetBundle: WidgetBundle {
    var body: some Widget {
        TelShevaAzanWidget()
    }
}
