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
                    switch family {
                    case .systemSmall:
                        smallBody(theme: theme)
                    case .systemLarge:
                        largeBody(theme: theme)
                    default:
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
            Label {
                Text(SalatiText.prayerAndTime(prayer: prayerName, time: prayerTime))
            } icon: {
                Image(systemName: SalatiPrayerSymbol.value(for: entry.nextPrayer?.key))
            }
        case .accessoryCircular:
            VStack(spacing: 1) {
                Image(systemName: SalatiPrayerSymbol.value(for: entry.nextPrayer?.key))
                    .font(.caption.weight(.bold))
                    .widgetAccentable()
                SalatiTimeText(value: prayerTime, size: 15, weight: .black)
                Text(prayerName)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .background(AccessoryWidgetBackground())
        default:
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: SalatiPrayerSymbol.value(for: entry.nextPrayer?.key))
                        .widgetAccentable()
                    Text(SalatiText.nextPrayer)
                        .font(.caption2.weight(.bold))
                    Spacer(minLength: 2)
                    SalatiTimeText(value: prayerTime, size: 15, weight: .black)
                }
                HStack(spacing: 5) {
                    Text(prayerName)
                        .font(.headline.weight(.bold))
                    Spacer(minLength: 2)
                    SalatiCountdownText(from: entry.date, target: prayerDate, size: 12, color: .primary)
                }
            }
        }
    }

    private func smallBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .trailing, spacing: 7) {
            SalatiWidgetHeader(
                title: SalatiText.nextPrayer,
                symbol: SalatiPrayerSymbol.value(for: entry.nextPrayer?.key),
                theme: theme
            )

            Spacer(minLength: 0)

            Text(prayerName)
                .font(.system(size: 27, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                SalatiTimeText(value: prayerTime, size: 28, weight: .black, color: theme.accent)
                Spacer(minLength: 4)
                Text(SalatiText.remaining)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.mutedText)
                SalatiCountdownText(from: entry.date, target: prayerDate, size: 15, color: theme.primaryText)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(theme.panel, in: RoundedRectangle(cornerRadius: SalatiWidgetMetrics.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SalatiWidgetMetrics.cornerRadius, style: .continuous)
                    .stroke(theme.border, lineWidth: 0.8)
            }
        }
        .salatiHomeWidgetPadding()
    }

    private func mediumBody(theme: SalatiWidgetTheme) -> some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                Text("\(SalatiText.remaining) \(SalatiText.until)\(prayerName)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)

                Spacer(minLength: 5)

                SalatiLocationLabel(theme: theme)
            }

            SalatiCountdownText(from: entry.date, target: prayerDate, size: 27, color: theme.primaryText)
                .frame(maxWidth: .infinity)

            Text(SalatiWidgetDateText.compact(for: entry.scheduleDate))
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(theme.mutedText)
                .lineLimit(1)

            SalatiPrayerColumns(
                times: entry.times,
                highlightedPrayer: entry.highlightedPrayer,
                theme: theme
            )
        }
        .salatiHomeWidgetPadding(12)
    }

    private func largeBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .trailing, spacing: 11) {
            SalatiWidgetHeader(
                title: SalatiText.nextPrayer,
                symbol: SalatiPrayerSymbol.value(for: entry.nextPrayer?.key),
                theme: theme
            )

            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(prayerName)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .lineLimit(1)
                    Text(SalatiWidgetDateText.compact(for: entry.scheduleDate))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.mutedText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(spacing: 3) {
                    SalatiTimeText(value: prayerTime, size: 31, weight: .black, color: theme.accent)
                    SalatiCountdownText(from: entry.date, target: prayerDate, size: 17, color: theme.primaryText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(theme.panel, in: RoundedRectangle(cornerRadius: SalatiWidgetMetrics.cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: SalatiWidgetMetrics.cornerRadius, style: .continuous)
                        .stroke(theme.border, lineWidth: 0.8)
                }
            }

            SalatiPrayerColumns(
                times: entry.times,
                highlightedPrayer: entry.highlightedPrayer,
                theme: theme,
                expanded: true
            )
        }
        .salatiHomeWidgetPadding()
    }
}

struct SalatiPrayerScheduleView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    var body: some View {
        SalatiWidgetSurface { theme in
            VStack(alignment: .trailing, spacing: family == .systemLarge ? 12 : 8) {
                SalatiWidgetHeader(
                    title: entry.isTomorrowSchedule ? SalatiText.tomorrowTimes : SalatiText.todayTimes,
                    symbol: "calendar",
                    theme: theme
                )

                Text(SalatiWidgetDateText.compact(for: entry.scheduleDate))
                    .font(.system(size: family == .systemLarge ? 13 : 11, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.mutedText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if family == .systemLarge, let nextPrayer = entry.nextPrayer {
                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(SalatiText.nextPrayer)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.secondaryText)
                            Text(nextPrayer.title)
                                .font(.title2.weight(.black))
                        }
                        Spacer(minLength: 4)
                        SalatiTimeText(value: nextPrayer.time, size: 27, weight: .black, color: theme.accent)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(theme.activePanel, in: RoundedRectangle(cornerRadius: SalatiWidgetMetrics.cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: SalatiWidgetMetrics.cornerRadius, style: .continuous)
                            .stroke(theme.activeBorder, lineWidth: 1)
                    }
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
        .accessibilityLabel(entry.isTomorrowSchedule ? SalatiText.tomorrowTimes : SalatiText.todayTimes)
    }
}

struct SalatiIqamaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    private var prayerName: String { entry.nextIqama?.prayer.title ?? SalatiText.prayer }
    private var iqamaTime: String { entry.nextIqama.map { Self.timeFormatter.string(from: $0.date) } ?? SalatiText.noTime }
    private var iqamaDate: Date? { entry.nextIqama?.date }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = PrayerEngine.calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

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
        .accessibilityLabel("\(SalatiText.iqama) \(prayerName)، \(iqamaTime)")
    }

    private var isAccessoryFamily: Bool {
        family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular
    }

    @ViewBuilder
    private var accessoryBody: some View {
        switch family {
        case .accessoryInline:
            Label {
                Text("\(SalatiText.iqama) \(SalatiText.prayerAndTime(prayer: prayerName, time: iqamaTime))")
            } icon: {
                Image(systemName: "person.2.fill")
            }
        case .accessoryCircular:
            VStack(spacing: 1) {
                Image(systemName: "person.2.fill")
                    .font(.caption.weight(.bold))
                    .widgetAccentable()
                SalatiTimeText(value: iqamaTime, size: 14, weight: .black)
                Text(prayerName)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .background(AccessoryWidgetBackground())
        default:
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .widgetAccentable()
                    Text(SalatiText.nextIqama)
                        .font(.caption2.weight(.bold))
                    Spacer(minLength: 2)
                    SalatiTimeText(value: iqamaTime, size: 15, weight: .black)
                }
                HStack(spacing: 5) {
                    Text(prayerName)
                        .font(.headline.weight(.bold))
                    Spacer(minLength: 2)
                    SalatiCountdownText(from: entry.date, target: iqamaDate, size: 12, color: .primary)
                }
            }
        }
    }

    private func smallBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .trailing, spacing: 7) {
            SalatiWidgetHeader(title: SalatiText.nextIqama, symbol: "person.2.fill", theme: theme)
            Spacer(minLength: 0)
            Text(prayerName)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            SalatiTimeText(value: iqamaTime, size: 30, weight: .black, color: theme.accent)
                .frame(maxWidth: .infinity, alignment: .trailing)
            HStack(spacing: 5) {
                Text(SalatiText.remaining)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.mutedText)
                Spacer(minLength: 3)
                SalatiCountdownText(from: entry.date, target: iqamaDate, size: 15, color: theme.primaryText)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(theme.panel, in: Capsule())
        }
        .salatiHomeWidgetPadding()
    }

    private func mediumBody(theme: SalatiWidgetTheme) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .trailing, spacing: 6) {
                SalatiWidgetHeader(title: SalatiText.nextIqama, symbol: "person.2.fill", theme: theme)
                Spacer(minLength: 0)
                Text(prayerName)
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .lineLimit(1)
                Text(IqamaSchedule.telSheva.locationName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            VStack(spacing: 7) {
                SalatiTimeText(value: iqamaTime, size: 31, weight: .black, color: theme.accent)
                SalatiCountdownText(from: entry.date, target: iqamaDate, size: 17, color: theme.primaryText)
            }
            .frame(width: 120)
            .padding(.vertical, 12)
            .background(theme.panel, in: RoundedRectangle(cornerRadius: SalatiWidgetMetrics.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SalatiWidgetMetrics.cornerRadius, style: .continuous)
                    .stroke(theme.border, lineWidth: 0.8)
            }
        }
        .salatiHomeWidgetPadding()
    }
}
