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
        return Self.entry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SalatiWidgetEntry) -> Void) {
        completion(Self.entry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalatiWidgetEntry>) -> Void) {
        let now = Date()
        let dates = Self.transitionDates(after: now)
        let entries = dates.map { Self.entry(for: $0) }
        let reloadDate = dates.last?.addingTimeInterval(5 * 60) ?? now.addingTimeInterval(60 * 60)
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }

    private static func entry(for date: Date) -> SalatiWidgetEntry {
        let dateKey = PrayerEngine.defaultDateKey(for: date)
        let schedule = PrayerEngine.schedule(for: dateKey)

        return SalatiWidgetEntry(
            date: date,
            dateKey: dateKey,
            nextPrayer: PrayerEngine.nextPrayer(for: dateKey, now: date),
            times: schedule.displayTimes
        )
    }

    private static func transitionDates(after now: Date) -> [Date] {
        var dates = [now]
        let start = PrayerEngine.calendar.startOfDay(for: now)

        for offset in 0...timelineDays {
            guard let day = PrayerEngine.calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let dateKey = PrayerEngine.defaultDateKey(for: day)

            for prayer in PrayerEngine.schedule(for: dateKey).displayTimes where prayer.date > now {
                dates.append(prayer.date.addingTimeInterval(1))
            }

            if let midnight = PrayerEngine.calendar.date(byAdding: .day, value: 1, to: day), midnight > now {
                dates.append(midnight.addingTimeInterval(1))
            }
        }

        return Array(Set(dates.map { Date(timeIntervalSince1970: $0.timeIntervalSince1970.rounded()) })).sorted()
    }
}

private enum SalatiWidgetPalette {
    static let blue = Color(red: 0.05, green: 0.49, blue: 0.98)
    static let nightTop = Color(red: 0.02, green: 0.12, blue: 0.21)
    static let nightBottom = Color(red: 0.005, green: 0.035, blue: 0.065)
    static let dayTop = Color(red: 0.87, green: 0.95, blue: 1.0)
    static let dayBottom = Color(red: 0.69, green: 0.84, blue: 0.95)
}

private struct SalatiWidgetSurface<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(surfaceBackground)
            .widgetContainerBackground { surfaceBackground }
    }

    @ViewBuilder
    private var surfaceBackground: some View {
        let isNight = colorScheme == .dark
        ZStack {
            LinearGradient(
                colors: isNight
                    ? [SalatiWidgetPalette.nightTop, SalatiWidgetPalette.nightBottom]
                    : [SalatiWidgetPalette.dayTop, SalatiWidgetPalette.dayBottom],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            RadialGradient(
                colors: [SalatiWidgetPalette.blue.opacity(isNight ? 0.28 : 0.15), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 180
            )
        }
    }
}

private struct SalatiNextPrayerView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    private var prayerName: String { entry.nextPrayer?.title ?? "الصلاة" }
    private var prayerTime: String { entry.nextPrayer?.time ?? "--:--" }

    var body: some View {
        Group {
            if isLockScreenFamily {
                lockScreenBody
            } else {
                SalatiWidgetSurface {
                    if family == .systemSmall {
                        smallBody
                    } else if family == .systemLarge {
                        largeBody
                    } else {
                        mediumBody
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
    }

    private var isLockScreenFamily: Bool {
        if #available(iOSApplicationExtension 16.0, *) {
            return family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular
        }
        return false
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
                    Text("الصلاة القادمة").font(.caption2)
                    Text("\(prayerName)  \(prayerTime)").font(.headline).monospacedDigit()
                }
            }
        }
    }

    private var smallBody: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack {
                Circle().fill(SalatiWidgetPalette.blue).frame(width: 10, height: 10)
                Spacer()
                Text("القادمة")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text(prayerName)
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .frame(maxWidth: .infinity, alignment: .trailing)

            timeCapsule(prayerTime, compact: false)
        }
        .padding(14)
    }

    private var mediumBody: some View {
        HStack(spacing: 14) {
            timeCapsule(prayerTime, compact: false)
                .frame(width: 118)

            VStack(alignment: .trailing, spacing: 6) {
                HStack {
                    Circle().fill(SalatiWidgetPalette.blue).frame(width: 10, height: 10)
                    Spacer()
                    Text("الصلاة القادمة")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Text("أذان \(prayerName)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
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
        .padding(15)
    }

    private var largeBody: some View {
        VStack(spacing: 12) {
            mediumBody
                .frame(height: 105)

            Divider().opacity(0.45)

            SalatiPrayerGrid(times: entry.times, highlightedPrayer: entry.nextPrayer?.key)
        }
        .padding(15)
    }

    private func timeCapsule(_ value: String, compact: Bool) -> some View {
        Text(value)
            .font(.system(size: compact ? 18 : 34, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(SalatiWidgetPalette.blue)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 7 : 11)
            .background(.white.opacity(0.36), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.78), lineWidth: 1.3))
    }
}

private struct SalatiPrayerScheduleView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    var body: some View {
        SalatiWidgetSurface {
            if family == .systemLarge {
                largeBody
            } else {
                mediumBody
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
    }

    private var mediumBody: some View {
        VStack(alignment: .trailing, spacing: 9) {
            header
            SalatiPrayerGrid(times: entry.times, highlightedPrayer: entry.nextPrayer?.key)
        }
        .padding(14)
    }

    private var largeBody: some View {
        VStack(alignment: .trailing, spacing: 13) {
            header
            Text(PrayerEngine.longDateLabel(for: entry.dateKey))
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
            SalatiPrayerGrid(times: entry.times, highlightedPrayer: entry.nextPrayer?.key, expanded: true)
            Spacer(minLength: 0)
        }
        .padding(16)
    }

    private var header: some View {
        HStack {
            Circle().fill(SalatiWidgetPalette.blue).frame(width: 10, height: 10)
            Spacer()
            Text("مواقيت اليوم")
                .font(.system(size: 17, weight: .bold, design: .rounded))
        }
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
                .background(
                    prayer.key == highlightedPrayer ? SalatiWidgetPalette.blue.opacity(0.13) : .white.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }
        }
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
                    if family == .systemSmall { smallBody } else { mediumBody }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
    }

    private var isLockScreenFamily: Bool {
        if #available(iOSApplicationExtension 16.0, *) {
            return family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular
        }
        return false
    }

    @ViewBuilder
    private var lockScreenBody: some View {
        switch family {
        case .accessoryInline:
            Text(PrayerEngine.hijriDateLabel(for: entry.dateKey))
        case .accessoryCircular:
            Text(day).font(.system(size: 28, weight: .bold, design: .rounded))
                .background(AccessoryWidgetBackground())
        default:
            VStack(alignment: .trailing, spacing: 2) {
                Text(PrayerEngine.longDateLabel(for: entry.dateKey)).font(.caption2).lineLimit(1)
                Text(PrayerEngine.hijriDateLabel(for: entry.dateKey)).font(.headline).lineLimit(1)
            }
        }
    }

    private var smallBody: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text("تاريخ اليوم")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(day)
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(SalatiWidgetPalette.blue)
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text(PrayerEngine.hijriDateLabel(for: entry.dateKey))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
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
                Text("تاريخ اليوم")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(PrayerEngine.longDateLabel(for: entry.dateKey))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(PrayerEngine.hijriDateLabel(for: entry.dateKey))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(14)
    }
}

struct SalatiNextPrayerWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.nextPrayer.v7"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiNextPrayerView(entry: entry)
        }
        .configurationDisplayName("الصلاة القادمة")
        .description("أذان الصلاة القادمة ووقته.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct SalatiPrayerScheduleWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.dailySchedule.v7"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiPrayerScheduleView(entry: entry)
        }
        .configurationDisplayName("مواقيت اليوم")
        .description("جدول مواقيت الصلاة في تل السبع.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct SalatiDateWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.date.today.v7"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiDateWidgetView(entry: entry)
        }
        .configurationDisplayName("تاريخ اليوم")
        .description("التاريخ الميلادي والهجري.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct TelShevaAzanWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalatiNextPrayerWidget()
        SalatiPrayerScheduleWidget()
        SalatiDateWidget()
    }
}

private extension View {
    @ViewBuilder
    func widgetContainerBackground<Background: View>(@ViewBuilder _ background: () -> Background) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { background() }
        } else {
            self.background(background())
        }
    }
}
