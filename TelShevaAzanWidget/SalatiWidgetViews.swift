import SwiftUI
import WidgetKit

struct SalatiNextPrayerView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    private var prayerName: String { entry.nextPrayer?.title ?? SalatiText.prayer }
    private var prayerTime: String { entry.nextPrayer?.time ?? SalatiText.noTime }
    private var prayerDate: Date? { entry.nextPrayer?.date }

    var body: some View {
        Group {
            if isAccessoryFamily {
                accessoryBody
            } else {
                SalatiWidgetSurface { theme in
                    if family == .systemSmall {
                        smallBody(theme: theme)
                    } else {
                        mediumBody(theme: theme)
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(SalatiText.nextPrayer)، \(prayerName)، \(prayerTime)")
    }

    private var isAccessoryFamily: Bool {
        family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular
    }

    @ViewBuilder
    private var accessoryBody: some View {
        switch family {
        case .accessoryInline:
            Text(SalatiText.prayerAndTime(prayer: prayerName, time: prayerTime))
                .fixedSize(horizontal: true, vertical: false)

        case .accessoryCircular:
            VStack(spacing: 1) {
                SalatiTimeText(value: prayerTime, size: 17, weight: .black)
                Text(prayerName)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AccessoryWidgetBackground())

        default:
            VStack(spacing: 4) {
                HStack(spacing: 5) {
                    SalatiTimeText(value: prayerTime, size: 15, weight: .black)
                    Spacer(minLength: 4)
                    Text(SalatiText.nextPrayerShort)
                        .font(.caption2.weight(.bold))
                        .fixedSize(horizontal: true, vertical: false)
                    Image(systemName: SalatiPrayerSymbol.value(for: entry.nextPrayer?.key))
                        .widgetAccentable()
                }
                .environment(\.layoutDirection, .leftToRight)

                HStack(spacing: 5) {
                    SalatiCountdownText(from: entry.date, target: prayerDate, size: 12, color: .primary)
                        .frame(maxWidth: 72, alignment: .leading)
                    Spacer(minLength: 4)
                    Text(prayerName)
                        .font(.headline.weight(.bold))
                        .fixedSize(horizontal: true, vertical: false)
                }
                .environment(\.layoutDirection, .leftToRight)
            }
        }
    }

    private func smallBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            SalatiWidgetHeader(
                title: SalatiText.nextPrayerShort,
                symbol: SalatiPrayerSymbol.value(for: entry.nextPrayer?.key),
                theme: theme,
                showsLocation: false
            )

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 7) {
                SalatiTimeText(value: prayerTime, size: 25, weight: .black, color: theme.accent)

                Spacer(minLength: 3)

                Text(prayerName)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
                    .multilineTextAlignment(.trailing)
            }
            .environment(\.layoutDirection, .leftToRight)

            SalatiCountdownRow(
                label: SalatiText.remaining,
                from: entry.date,
                target: prayerDate,
                theme: theme,
                compact: true
            )

        }
        .salatiHomeWidgetPadding()
    }

    private func mediumBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SalatiWidgetHeader(
                title: SalatiText.nextPrayer,
                symbol: SalatiPrayerSymbol.value(for: entry.nextPrayer?.key),
                theme: theme
            )

            HStack(alignment: .center, spacing: 10) {
                SalatiTimeText(value: prayerTime, size: 32, weight: .black, color: theme.accent)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(prayerName)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .lineLimit(1)
                    Text(SalatiWidgetDateText.compact(for: entry.scheduleDate))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .environment(\.layoutDirection, .leftToRight)

            SalatiCountdownRow(
                label: SalatiText.remainingUntilAdhan,
                from: entry.date,
                target: prayerDate,
                theme: theme
            )
        }
        .salatiHomeWidgetPadding()
    }
}

struct SalatiPrayerScheduleView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    private var title: String {
        entry.isTomorrowSchedule ? SalatiText.tomorrowTimes : SalatiText.todayTimes
    }

    var body: some View {
        SalatiWidgetSurface { theme in
            VStack(alignment: .leading, spacing: family == .systemLarge ? 12 : 8) {
                SalatiWidgetHeader(title: title, symbol: "calendar", theme: theme)

                if family == .systemLarge, let nextPrayer = entry.nextPrayer {
                    HStack(spacing: 8) {
                    Text(SalatiWidgetDateText.compact(for: entry.scheduleDate))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.mutedText)
                        .lineLimit(1)

                        Spacer(minLength: 4)
                        Text(SalatiText.nextPrayerSummary(nextPrayer.title))
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(theme.secondaryText)
                            .lineLimit(1)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                } else {
                    Text(SalatiWidgetDateText.compact(for: entry.scheduleDate))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.mutedText)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                SalatiPrayerColumns(
                    times: entry.times,
                    highlightedPrayer: entry.highlightedPrayer,
                    theme: theme,
                    expanded: family == .systemLarge
                )
            }
            .salatiHomeWidgetPadding()
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

struct SalatiIqamaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    private var prayerName: String { entry.nextIqama?.prayer.title ?? SalatiText.prayer }
    private var iqamaTime: String { entry.nextIqama.map { Self.timeFormatter.string(from: $0.date) } ?? SalatiText.noTime }
    private var iqamaDate: Date? { entry.nextIqama?.date }
    private var iqamaDelayMinutes: Int {
        guard let event = entry.nextIqama else { return 0 }
        return max(0, Int(event.date.timeIntervalSince(event.prayer.date).rounded() / 60))
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = PrayerEngine.calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        SalatiWidgetSurface { theme in
            if family == .systemSmall {
                smallBody(theme: theme)
            } else {
                mediumBody(theme: theme)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("الإقامة \(prayerName)، \(iqamaTime)")
    }

    private func smallBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            SalatiWidgetHeader(
                title: SalatiText.iqamaShort,
                symbol: "person.2.fill",
                theme: theme,
                showsLocation: false
            )

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 7) {
                SalatiTimeText(value: iqamaTime, size: 24, weight: .black, color: theme.accent)

                Spacer(minLength: 3)

                Text(prayerName)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.trailing)
            }
            .environment(\.layoutDirection, .leftToRight)

            Text(SalatiText.iqamaDelay(minutes: iqamaDelayMinutes))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(theme.mutedText)
                .fixedSize(horizontal: true, vertical: false)

            SalatiCountdownRow(
                label: SalatiText.remaining,
                from: entry.date,
                target: iqamaDate,
                theme: theme,
                compact: true
            )
        }
        .salatiHomeWidgetPadding()
    }

    private func mediumBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SalatiWidgetHeader(title: SalatiText.nextIqama, symbol: "person.2.fill", theme: theme)

            HStack(alignment: .center, spacing: 10) {
                SalatiTimeText(value: iqamaTime, size: 32, weight: .black, color: theme.accent)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(prayerName)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .lineLimit(1)
                    Text(SalatiText.iqamaAfterAdhan(prayer: prayerName, minutes: iqamaDelayMinutes))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.mutedText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .environment(\.layoutDirection, .leftToRight)

            SalatiCountdownRow(
                label: SalatiText.remainingUntilIqama,
                from: entry.date,
                target: iqamaDate,
                theme: theme
            )
        }
        .salatiHomeWidgetPadding()
    }
}
