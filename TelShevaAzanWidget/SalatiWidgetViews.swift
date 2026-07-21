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
            SalatiAccessoryInlineView(prayerName: prayerName, prayerTime: prayerTime)

        case .accessoryCircular:
            SalatiAccessoryCircularView(
                prayerName: prayerName,
                from: entry.date,
                target: prayerDate
            )

        default:
            SalatiAccessoryRectangularView(
                prayerName: prayerName,
                prayerTime: prayerTime,
                prayerSymbol: SalatiPrayerSymbol.value(for: entry.nextPrayer?.key),
                from: entry.date,
                target: prayerDate
            )
        }
    }

    private func smallBody(theme: SalatiWidgetTheme) -> some View {
        VStack(spacing: 5) {
            SalatiWidgetHeader(
                title: SalatiText.nextPrayerShort,
                symbol: SalatiPrayerSymbol.value(for: entry.nextPrayer?.key),
                theme: theme,
                showsLocation: false
            )

            Spacer(minLength: 0)

            Text(prayerName)
                .font(.system(size: 23, weight: .black, design: .rounded))
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .center)

            SalatiTimeText(value: prayerTime, size: 31, weight: .black, color: theme.accent)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer(minLength: 0)

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
                        .fixedSize(horizontal: true, vertical: false)
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

    private var compactTimes: [PrayerTime] {
        guard let highlightedPrayer = entry.highlightedPrayer,
              let index = entry.times.firstIndex(where: { $0.key == highlightedPrayer }) else {
            return Array(entry.times.prefix(3))
        }
        return Array(entry.times[index...].prefix(3))
    }

    var body: some View {
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
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }

    private func smallBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SalatiWidgetHeader(title: title, symbol: "calendar", theme: theme, showsLocation: false)

            Text(SalatiWidgetDateText.compact(for: entry.scheduleDate))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(theme.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
                .frame(maxWidth: .infinity, alignment: .leading)

            SalatiPrayerList(
                times: compactTimes,
                highlightedPrayer: entry.highlightedPrayer,
                theme: theme
            )
        }
        .salatiHomeWidgetPadding()
    }

    private func mediumBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SalatiWidgetHeader(title: title, symbol: "calendar", theme: theme)

            Text(SalatiWidgetDateText.compact(for: entry.scheduleDate))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.mutedText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            SalatiPrayerColumns(
                times: entry.times,
                highlightedPrayer: entry.highlightedPrayer,
                theme: theme
            )
        }
        .salatiHomeWidgetPadding()
    }

    private func largeBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SalatiWidgetHeader(title: title, symbol: "calendar", theme: theme)

            HStack(spacing: 8) {
                Text(SalatiWidgetDateText.compact(for: entry.scheduleDate))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.mutedText)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let nextPrayer = entry.nextPrayer {
                    Text(SalatiText.nextPrayerSummary(nextPrayer.title))
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .environment(\.layoutDirection, .leftToRight)

            SalatiPrayerList(
                times: entry.times,
                highlightedPrayer: entry.highlightedPrayer,
                theme: theme,
                expanded: true
            )
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .salatiHomeWidgetPadding()
    }
}
