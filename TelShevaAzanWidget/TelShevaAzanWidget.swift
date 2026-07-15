import Foundation
import SwiftUI
import WidgetKit

struct SalatiWidgetEntry: TimelineEntry {
    let date: Date
    let dateKey: String
    let nextPrayer: PrayerTime?
    let times: [PrayerTime]
}

struct SalatiWidgetProvider: TimelineProvider {
    private static let timelineDays = 14

    func placeholder(in context: Context) -> SalatiWidgetEntry {
        Self.entry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SalatiWidgetEntry) -> Void) {
        completion(Self.entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalatiWidgetEntry>) -> Void) {
        let now = Date()
        let transitionDates = Self.transitionDates(after: now)
        completion(Timeline(entries: transitionDates.map { Self.entry(for: $0) }, policy: .after(transitionDates.last?.addingTimeInterval(300) ?? now.addingTimeInterval(3600))))
    }

    private static func entry(for date: Date) -> SalatiWidgetEntry {
        let dateKey = PrayerEngine.defaultDateKey(for: date)
        return SalatiWidgetEntry(
            date: date,
            dateKey: dateKey,
            nextPrayer: PrayerEngine.nextPrayer(for: dateKey, now: date),
            times: PrayerEngine.schedule(for: dateKey).displayTimes
        )
    }

    private static func transitionDates(after now: Date) -> [Date] {
        let start = PrayerEngine.calendar.startOfDay(for: now)
        var dates = [now]

        for offset in 0...timelineDays {
            guard let day = PrayerEngine.calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let dateKey = PrayerEngine.defaultDateKey(for: day)

            for prayer in PrayerEngine.schedule(for: dateKey).displayTimes where prayer.date > now {
                dates.append(prayer.date.addingTimeInterval(1))
            }

            if let nextDay = PrayerEngine.calendar.date(byAdding: .day, value: 1, to: day), nextDay > now {
                dates.append(nextDay.addingTimeInterval(1))
            }
        }

        return Array(Set(dates.map { Date(timeIntervalSince1970: $0.timeIntervalSince1970.rounded()) })).sorted()
    }
}

private enum SalatiText {
    static let nextPrayer = "\u{0627}\u{0644}\u{0635}\u{0644}\u{0627}\u{0629} \u{0627}\u{0644}\u{0642}\u{0627}\u{062f}\u{0645}\u{0629}"
    static let next = "\u{0627}\u{0644}\u{0642}\u{0627}\u{062f}\u{0645}"
    static let adhan = "\u{0623}\u{0630}\u{0627}\u{0646}"
    static let todayTimes = "\u{0645}\u{0648}\u{0627}\u{0642}\u{064a}\u{062a} \u{0627}\u{0644}\u{064a}\u{0648}\u{0645}"
    static let todayDate = "\u{062a}\u{0627}\u{0631}\u{064a}\u{062e} \u{0627}\u{0644}\u{064a}\u{0648}\u{0645}"
    static let iqama = "\u{0627}\u{0644}\u{0625}\u{0642}\u{0627}\u{0645}\u{0629}"
    static let nextIqama = "\u{0627}\u{0644}\u{0625}\u{0642}\u{0627}\u{0645}\u{0629} \u{0627}\u{0644}\u{0642}\u{0627}\u{062f}\u{0645}\u{0629}"
    static let prayer = "\u{0627}\u{0644}\u{0635}\u{0644}\u{0627}\u{0629}"
}

private enum SalatiWidgetPalette {
    static let blue = Color(red: 0.05, green: 0.49, blue: 0.98)
    static let nightTop = Color(red: 0.015, green: 0.10, blue: 0.18)
    static let nightBottom = Color(red: 0.005, green: 0.03, blue: 0.06)
    static let dayTop = Color(red: 0.88, green: 0.95, blue: 1.0)
    static let dayBottom = Color(red: 0.69, green: 0.84, blue: 0.95)
}

private struct SalatiWidgetSurface<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content.widgetContainerBackground { background }
    }

    private var background: some View {
        let night = colorScheme == .dark
        return ZStack {
            LinearGradient(
                colors: night ? [SalatiWidgetPalette.nightTop, SalatiWidgetPalette.nightBottom] : [SalatiWidgetPalette.dayTop, SalatiWidgetPalette.dayBottom],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            RadialGradient(
                colors: [SalatiWidgetPalette.blue.opacity(night ? 0.24 : 0.14), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 180
            )
        }
    }
}

private struct SalatiHeader: View {
    let title: String

    var body: some View {
        HStack {
            Circle().fill(SalatiWidgetPalette.blue).frame(width: 10, height: 10)
            Spacer(minLength: 8)
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

private struct SalatiNextPrayerView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    private var prayerName: String { entry.nextPrayer?.title ?? SalatiText.prayer }
    private var prayerTime: String { entry.nextPrayer?.time ?? "--:--" }

    var body: some View {
        Group {
            if isLockScreenFamily {
                lockScreenBody
            } else {
                SalatiWidgetSurface {
                    switch family {
                    case .systemSmall: smallBody
                    case .systemLarge: largeBody
                    default: mediumBody
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
    }

    private var isLockScreenFamily: Bool {
        family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular
    }

    @ViewBuilder
    private var lockScreenBody: some View {
        switch family {
        case .accessoryInline:
            Text("\(prayerName) \(prayerTime)")
        case .accessoryCircular:
            VStack(spacing: 1) {
                Text(prayerTime).font(.system(size: 16, weight: .bold, design: .rounded)).monospacedDigit()
                Text(prayerName).font(.system(size: 10, weight: .semibold)).lineLimit(1)
            }
            .background(AccessoryWidgetBackground())
        default:
            HStack(spacing: 7) {
                Image(systemName: "clock.fill")
                VStack(alignment: .trailing, spacing: 2) {
                    Text(SalatiText.nextPrayer).font(.caption2)
                    Text("\(prayerName)  \(prayerTime)").font(.headline).monospacedDigit()
                }
            }
            .environment(\.layoutDirection, .leftToRight)
        }
    }

    private var smallBody: some View {
        VStack(alignment: .trailing, spacing: 7) {
            SalatiHeader(title: SalatiText.next)
            Spacer(minLength: 0)
            Text(prayerName)
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .trailing)
            SalatiTimeCapsule(value: prayerTime, fontSize: 34)
        }
        .padding(14)
    }

    private var mediumBody: some View {
        HStack(spacing: 14) {
            SalatiTimeCapsule(value: prayerTime, fontSize: 34).frame(width: 118)
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 6) {
                Text(SalatiText.nextPrayer)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text("\(SalatiText.adhan) \(prayerName)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text(PrayerEngine.hijriDateLabel(for: entry.dateKey))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(15)
    }

    private var largeBody: some View {
        VStack(spacing: 12) {
            mediumBody.frame(height: 105)
            Divider().opacity(0.45)
            SalatiPrayerGrid(times: entry.times, highlightedPrayer: entry.nextPrayer?.key)
        }
        .padding(15)
    }
}

private struct SalatiPrayerScheduleView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    var body: some View {
        SalatiWidgetSurface {
            VStack(alignment: .trailing, spacing: family == .systemLarge ? 13 : 9) {
                SalatiHeader(title: SalatiText.todayTimes)
                if family == .systemLarge {
                    Text(PrayerEngine.longDateLabel(for: entry.dateKey))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                SalatiPrayerGrid(times: entry.times, highlightedPrayer: entry.nextPrayer?.key, expanded: family == .systemLarge)
                if family == .systemLarge { Spacer(minLength: 0) }
            }
            .padding(family == .systemLarge ? 16 : 14)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
    }
}

private struct SalatiPrayerGrid: View {
    let times: [PrayerTime]
    let highlightedPrayer: PrayerKey?
    var expanded = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: expanded ? 12 : 8) {
            ForEach(times) { prayer in
                VStack(spacing: 3) {
                    Text(prayer.title)
                        .font(.system(size: expanded ? 14 : 11, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(prayer.time)
                        .font(.system(size: expanded ? 20 : 16, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                }
                .foregroundStyle(prayer.key == highlightedPrayer ? SalatiWidgetPalette.blue : Color.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, expanded ? 10 : 7)
                .background(prayer.key == highlightedPrayer ? SalatiWidgetPalette.blue.opacity(0.13) : .white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }
}

private enum SalatiIqamaTime {
    private static let offsets: [PrayerKey: Int] = [.fajr: 25, .dhuhr: 15, .asr: 17, .maghrib: 8, .isha: 15]
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = PrayerEngine.calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func value(for prayer: PrayerTime?) -> String? {
        guard let prayer, let minutes = offsets[prayer.key] else { return nil }
        return formatter.string(from: prayer.date.addingTimeInterval(TimeInterval(minutes * 60)))
    }
}

private struct SalatiIqamaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    private var prayerName: String { entry.nextPrayer?.title ?? SalatiText.prayer }
    private var iqamaTime: String { SalatiIqamaTime.value(for: entry.nextPrayer) ?? "--:--" }

    var body: some View {
        Group {
            if isLockScreenFamily {
                lockScreenBody
            } else {
                SalatiWidgetSurface {
                    family == .systemSmall ? AnyView(smallBody) : AnyView(mediumBody)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
    }

    private var isLockScreenFamily: Bool {
        family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular
    }

    @ViewBuilder
    private var lockScreenBody: some View {
        switch family {
        case .accessoryInline:
            Text("\(SalatiText.iqama) \(prayerName) \(iqamaTime)")
        case .accessoryCircular:
            VStack(spacing: 1) {
                Text(iqamaTime).font(.system(size: 14, weight: .bold, design: .rounded)).monospacedDigit()
                Text(SalatiText.iqama).font(.system(size: 10, weight: .semibold))
            }
            .background(AccessoryWidgetBackground())
        default:
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                VStack(alignment: .trailing, spacing: 2) {
                    Text(SalatiText.iqama).font(.caption2)
                    Text("\(prayerName)  \(iqamaTime)").font(.headline).monospacedDigit()
                }
            }
            .environment(\.layoutDirection, .leftToRight)
        }
    }

    private var smallBody: some View {
        VStack(alignment: .trailing, spacing: 8) {
            SalatiHeader(title: SalatiText.nextIqama)
            Spacer(minLength: 0)
            Text(prayerName)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            SalatiTimeCapsule(value: iqamaTime, fontSize: 31)
        }
        .padding(14)
    }

    private var mediumBody: some View {
        HStack(spacing: 16) {
            SalatiTimeCapsule(value: iqamaTime, fontSize: 31).frame(width: 120)
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 7) {
                Text(SalatiText.nextIqama)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(prayerName)
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                Text("\(SalatiText.iqama) \(SalatiText.prayer)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(15)
    }
}

private struct SalatiDateWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    private var day: String {
        let formatter = DateFormatter()
        formatter.calendar = PrayerEngine.calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "d"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        Group {
            if isLockScreenFamily {
                lockScreenBody
            } else {
                SalatiWidgetSurface {
                    family == .systemSmall ? AnyView(smallBody) : AnyView(mediumBody)
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
    }

    private var isLockScreenFamily: Bool {
        family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular
    }

    @ViewBuilder
    private var lockScreenBody: some View {
        switch family {
        case .accessoryInline:
            Text(PrayerEngine.hijriDateLabel(for: entry.dateKey))
        case .accessoryCircular:
            Text(day).font(.system(size: 28, weight: .bold, design: .rounded)).background(AccessoryWidgetBackground())
        default:
            VStack(alignment: .trailing, spacing: 2) {
                Text(PrayerEngine.longDateLabel(for: entry.dateKey)).font(.caption2).lineLimit(1)
                Text(PrayerEngine.hijriDateLabel(for: entry.dateKey)).font(.headline).lineLimit(1)
            }
        }
    }

    private var smallBody: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text(SalatiText.todayDate).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(day)
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(SalatiWidgetPalette.blue)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(PrayerEngine.hijriDateLabel(for: entry.dateKey)).font(.system(size: 12, weight: .semibold, design: .rounded)).lineLimit(1)
        }
        .padding(14)
    }

    private var mediumBody: some View {
        HStack(spacing: 14) {
            Text(day)
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(SalatiWidgetPalette.blue)
                .frame(width: 82)
                .background(.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            VStack(alignment: .trailing, spacing: 8) {
                Text(SalatiText.todayDate).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(.secondary)
                Text(PrayerEngine.longDateLabel(for: entry.dateKey)).font(.system(size: 17, weight: .bold, design: .rounded)).lineLimit(1).minimumScaleFactor(0.7)
                Text(PrayerEngine.hijriDateLabel(for: entry.dateKey)).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundStyle(.secondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(14)
    }
}

private struct SalatiTimeCapsule: View {
    let value: String
    let fontSize: CGFloat

    var body: some View {
        Text(value)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(SalatiWidgetPalette.blue)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(.white.opacity(0.36), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.78), lineWidth: 1.3))
    }
}

struct SalatiNextPrayerWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.nextPrayer.v7"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { SalatiNextPrayerView(entry: $0) }
            .configurationDisplayName("\u{0627}\u{0644}\u{0635}\u{0644}\u{0627}\u{0629} \u{0627}\u{0644}\u{0642}\u{0627}\u{062f}\u{0645}\u{0629}")
            .description("\u{0623}\u{0630}\u{0627}\u{0646} \u{0627}\u{0644}\u{0635}\u{0644}\u{0627}\u{0629} \u{0627}\u{0644}\u{0642}\u{0627}\u{062f}\u{0645}\u{0629}")
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct SalatiPrayerScheduleWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.dailySchedule.v7"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { SalatiPrayerScheduleView(entry: $0) }
            .configurationDisplayName("\u{0645}\u{0648}\u{0627}\u{0642}\u{064a}\u{062a} \u{0627}\u{0644}\u{064a}\u{0648}\u{0645}")
            .description("\u{0645}\u{0648}\u{0627}\u{0642}\u{064a}\u{062a} \u{0627}\u{0644}\u{064a}\u{0648}\u{0645}")
            .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct SalatiDateWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.date.today.v7"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { SalatiDateWidgetView(entry: $0) }
            .configurationDisplayName("\u{062a}\u{0627}\u{0631}\u{064a}\u{062e} \u{0627}\u{0644}\u{064a}\u{0648}\u{0645}")
            .description("\u{0627}\u{0644}\u{062a}\u{0627}\u{0631}\u{064a}\u{062e} \u{0627}\u{0644}\u{0645}\u{064a}\u{0644}\u{0627}\u{062f}\u{064a} \u{0648}\u{0627}\u{0644}\u{0647}\u{062c}\u{0631}\u{064a}")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct SalatiIqamaWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.iqama.v1"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { SalatiIqamaWidgetView(entry: $0) }
            .configurationDisplayName("\u{0627}\u{0644}\u{0625}\u{0642}\u{0627}\u{0645}\u{0629} \u{0627}\u{0644}\u{0642}\u{0627}\u{062f}\u{0645}\u{0629}")
            .description("\u{0648}\u{0642}\u{062a} \u{0625}\u{0642}\u{0627}\u{0645}\u{0629} \u{0627}\u{0644}\u{0635}\u{0644}\u{0627}\u{0629} \u{0627}\u{0644}\u{0642}\u{0627}\u{062f}\u{0645}\u{0629}")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct TelShevaAzanWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalatiNextPrayerWidget()
        SalatiPrayerScheduleWidget()
        SalatiDateWidget()
        SalatiIqamaWidget()
    }
}

private extension View {
    @ViewBuilder
    func widgetContainerBackground(_ content: () -> some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { content() }
        } else {
            background(content())
        }
    }
}
