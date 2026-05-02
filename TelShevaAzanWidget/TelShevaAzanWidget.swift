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
            times: schedule.displayTimes
        )
    }
}

struct TelShevaAzanWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TelShevaWidgetEntry

    private let accent = Color(red: 0.96, green: 0.78, blue: 0.38)
    private let mint = Color(red: 0.76, green: 0.93, blue: 0.87)

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

    private var nextTitle: String {
        entry.nextPrayer?.title ?? "الصلاة"
    }

    private var nextTime: String {
        entry.nextPrayer?.time ?? "--:--"
    }

    private var liveRemainingText: Text {
        guard let nextDate = entry.nextPrayer?.date else {
            return Text("باقي --")
        }

        return Text("باقي ") + Text(nextDate, style: .timer)
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

    private var homeScreenLayout: some View {
        ZStack {
            switch family {
            case .systemMedium:
                mediumHomeLayout
            default:
                smallHomeLayout
            }
        }
        .widgetContainerBackground {
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.36, blue: 0.34),
                    Color(red: 0.05, green: 0.09, blue: 0.10)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }

    private var smallHomeLayout: some View {
        VStack(alignment: .trailing, spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                Text("الصلاة القادمة")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundColor(mint)
            .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer(minLength: 1)

            Text(nextTitle)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.64)

            Text(nextTime)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundColor(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.68)

            liveRemainingText
                .font(.system(size: 10, weight: .black, design: .rounded).monospacedDigit())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.13))
                .clipShape(RoundedRectangle(cornerRadius: 7))

            HStack(spacing: 4) {
                Text(AppInfo.displayVersion)
                    .font(.system(size: 8, weight: .bold, design: .rounded).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                Spacer(minLength: 4)

                Text("تل السبع")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundColor(mint.opacity(0.9))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .padding(9)
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
                    .foregroundColor(mint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(nextTitle)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)

                Text(nextTime)
                    .font(.system(size: 35, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)

                liveRemainingText
                    .font(.system(size: 11, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.13))
                    .clipShape(RoundedRectangle(cornerRadius: 7))

                Text("تل السبع \(AppInfo.displayVersion)")
                    .font(.system(size: 9, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(mint.opacity(0.88))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 124, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(10)
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
        .foregroundColor(isActive ? accent : .white.opacity(0.86))
        .padding(.horizontal, 7)
        .frame(height: 18)
        .background(isActive ? Color.white.opacity(0.12) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    @ViewBuilder
    private var lockScreenLayout: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            switch family {
            case .accessoryInline:
                Label("\(nextTitle) \(nextTime) - \(compactRemainingText)", systemImage: "moon.stars.fill")
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 2) {
                        Text(nextTitle)
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)

                        Text(nextTime)
                            .font(.caption.monospacedDigit().weight(.black))
                            .lineLimit(1)

                        Text(compactRemainingText)
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                }
            case .accessoryRectangular:
                VStack(alignment: .trailing, spacing: 2) {
                    Text("تل السبع")
                        .font(.caption2.weight(.bold))
                    HStack(spacing: 5) {
                        Text(nextTime)
                            .font(.headline.monospacedDigit().weight(.black))
                        Text(nextTitle)
                            .font(.headline.weight(.black))
                    }
                    Text(compactRemainingText)
                        .font(.caption2.monospacedDigit().weight(.bold))
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
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
    let kind = "com.omaralasam.telshevaazan.nextPrayer"

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
