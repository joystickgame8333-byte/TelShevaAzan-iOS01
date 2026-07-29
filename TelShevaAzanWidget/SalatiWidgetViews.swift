import SwiftUI
import WidgetKit

struct SalatiNextPrayerView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    private var prayerName: String { entry.focusedPrayer?.title ?? SalatiText.prayer }
    private var prayerTime: String { entry.focusedTime }
    private var prayerDate: Date? { entry.focusedTarget }

    var body: some View {
        SalatiWidgetSurface(prayerKey: entry.focusedPrayer?.key) { theme in
            if family == .systemSmall {
                smallBody(theme: theme)
            } else {
                mediumBody(theme: theme)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.focusedTitle)، \(prayerName)، \(prayerTime)")
    }

    private func smallBody(theme: SalatiWidgetTheme) -> some View {
        VStack(spacing: 9) {
            HStack(spacing: 8) {
                prayerSymbol(theme: theme, size: 39)

                Spacer(minLength: 2)

                VStack(alignment: .trailing, spacing: 1) {
                    Text(prayerName)
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(1)

                    SalatiTimeText(
                        value: prayerTime,
                        size: 29,
                        weight: .black,
                        color: theme.accent
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .leftToRight)

            SalatiCountdownRow(
                label: entry.focusedCountdownLabel,
                from: entry.date,
                target: prayerDate,
                theme: theme,
                compact: true
            )

            SalatiPrayerProgress(
                start: entry.focusedStart,
                target: prayerDate,
                fallbackProgress: entry.focusedProgress,
                theme: theme
            )
        }
        .salatiHomeWidgetPadding()
    }

    private func mediumBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .trailing, spacing: 9) {
            SalatiWidgetHeader(
                title: entry.focusedTitle,
                symbol: momentSymbol,
                theme: theme
            )

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    SalatiTimeText(
                        value: prayerTime,
                        size: 36,
                        weight: .black,
                        color: theme.accent
                    )

                    SalatiCountdownRow(
                        label: entry.focusedCountdownLabel,
                        from: entry.date,
                        target: prayerDate,
                        theme: theme,
                        compact: true
                    )
                    .frame(maxWidth: 128)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 5) {
                    Text(prayerName)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(theme.primaryText)
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
            .frame(maxHeight: .infinity)

            SalatiPrayerProgress(
                start: entry.focusedStart,
                target: prayerDate,
                fallbackProgress: entry.focusedProgress,
                theme: theme
            )
        }
        .salatiHomeWidgetPadding()
    }

    private func prayerSymbol(theme: SalatiWidgetTheme, size: CGFloat) -> some View {
        SalatiPrayerRing(
            progress: entry.focusedProgress,
            theme: theme,
            lineWidth: 2.5
        ) {
            Circle()
                .fill(theme.activePanel)
                .padding(4)

            Image(systemName: momentSymbol)
                .font(.system(size: size * 0.42, weight: .black))
                .foregroundStyle(theme.accent)
                .widgetAccentable()
        }
        .frame(width: size, height: size)
    }

    private var momentSymbol: String {
        entry.moment == .adhan
            ? "speaker.wave.2.fill"
            : SalatiPrayerSymbol.value(for: entry.focusedPrayer?.key)
    }
}

struct SalatiPrayerScheduleView: View {
    @Environment(\.widgetFamily) private var family
    let entry: SalatiWidgetEntry

    private var title: String {
        entry.isTomorrowSchedule ? SalatiText.tomorrowTimes : SalatiText.todayTimes
    }

    var body: some View {
        SalatiWidgetSurface(prayerKey: entry.highlightedPrayerKey) { theme in
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
        VStack(alignment: .trailing, spacing: 3) {
            SalatiPrayerList(
                times: entry.obligatoryTimes,
                highlightedPrayer: entry.highlightedPrayerKey,
                theme: theme,
                compact: true
            )
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .salatiHomeWidgetPadding(12)
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
                highlightedPrayer: entry.highlightedPrayerKey,
                theme: theme
            )
        }
        .salatiHomeWidgetPadding()
    }

    private func largeBody(theme: SalatiWidgetTheme) -> some View {
        VStack(alignment: .trailing, spacing: 9) {
            SalatiWidgetHeader(title: title, symbol: "calendar", theme: theme)

            nextPrayerSummaryCard(theme: theme)

            Text(SalatiWidgetDateText.compact(for: entry.scheduleDate))
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.mutedText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.layoutDirection, .leftToRight)

            SalatiPrayerList(
                times: entry.times,
                highlightedPrayer: entry.highlightedPrayerKey,
                theme: theme,
                expanded: true,
                compact: true
            )
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .salatiHomeWidgetPadding()
    }

    private func nextPrayerSummaryCard(theme: SalatiWidgetTheme) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                SalatiTimeText(
                    value: entry.focusedTime,
                    size: 30,
                    weight: .black,
                    color: theme.accent
                )

                SalatiCountdownRow(
                    label: entry.focusedCountdownLabel,
                    from: entry.date,
                    target: entry.focusedTarget,
                    theme: theme,
                    compact: true
                )
                .frame(maxWidth: 124)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 3) {
                Text(entry.focusedShortTitle)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.mutedText)

                Text(entry.focusedPrayer?.title ?? SalatiText.prayer)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(theme.activePanel, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(theme.activeBorder.opacity(0.72), lineWidth: 0.9)
        }
        .overlay(alignment: .bottom) {
            SalatiPrayerProgress(
                start: entry.focusedStart,
                target: entry.focusedTarget,
                fallbackProgress: entry.focusedProgress,
                theme: theme
            )
            .padding(.horizontal, 13)
            .offset(y: 5)
        }
    }
}
