import SwiftUI
import WidgetKit

struct SalatiNextTwoPrayersView: View {
    let entry: SalatiWidgetEntry

    private var nextPrayer: PrayerTime? {
        entry.upcomingPrayers.first ?? entry.nextPrayer
    }

    private var followingPrayer: PrayerTime? {
        entry.upcomingPrayers.dropFirst().first
    }

    var body: some View {
        SalatiWidgetSurface { theme in
            VStack(alignment: .trailing, spacing: 9) {
                professionalHeader(
                    title: SalatiText.nextAndFollowing,
                    symbol: SalatiPrayerSymbol.value(for: nextPrayer?.key),
                    theme: theme
                )

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(SalatiText.nextPrayerShort)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.secondaryText)

                        Text(nextPrayer?.title ?? SalatiText.prayer)
                            .font(.system(size: 27, weight: .black, design: .rounded))
                            .foregroundStyle(theme.primaryText)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    VStack(alignment: .leading, spacing: 5) {
                        SalatiTimeText(
                            value: nextPrayer?.time ?? SalatiText.noTime,
                            size: 30,
                            weight: .black,
                            color: theme.accent
                        )

                        SalatiCountdownText(
                            from: entry.date,
                            target: nextPrayer?.date,
                            size: 13,
                            color: theme.mutedText
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                followingPrayerRow(prayer: followingPrayer, theme: theme)
            }
            .salatiHomeWidgetPadding()
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private func followingPrayerRow(
        prayer: PrayerTime?,
        theme: SalatiWidgetTheme
    ) -> some View {
        HStack(spacing: 8) {
            Label(SalatiText.followingPrayer, systemImage: "arrow.left")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.mutedText)

            Text(prayer?.title ?? SalatiText.prayer)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(theme.primaryText)

            Spacer(minLength: 8)

            SalatiTimeText(
                value: prayer?.time ?? SalatiText.noTime,
                size: 16,
                weight: .black,
                color: theme.secondaryText
            )
        }
        .padding(.horizontal, 11)
        .frame(height: 34)
        .background(theme.panel, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(theme.border, lineWidth: 0.8)
        }
    }

    private var accessibilityText: String {
        let nextName = nextPrayer?.title ?? SalatiText.prayer
        let nextTime = nextPrayer?.time ?? SalatiText.noTime
        let followingName = followingPrayer?.title ?? SalatiText.prayer
        let followingTime = followingPrayer?.time ?? SalatiText.noTime
        return "\(SalatiText.nextPrayer): \(nextName)، \(nextTime). \(SalatiText.followingPrayer): \(followingName)، \(followingTime)"
    }
}

struct SalatiDawnView: View {
    let entry: SalatiWidgetEntry

    private var fajr: PrayerTime? {
        entry.dawnTimes.first { $0.key == .fajr }
    }

    private var sunrise: PrayerTime? {
        entry.dawnTimes.first { $0.key == .sunrise }
    }

    var body: some View {
        SalatiWidgetSurface { theme in
            VStack(alignment: .trailing, spacing: 8) {
                professionalHeader(
                    title: SalatiText.dawnAndSunrise,
                    symbol: "sunrise.fill",
                    theme: theme,
                    showsLocation: false
                )

                dawnRow(prayer: fajr, symbol: "moon.stars.fill", theme: theme, isPrimary: true)
                dawnRow(prayer: sunrise, symbol: "sun.max.fill", theme: theme, isPrimary: false)

                HStack(spacing: 5) {
                    Image(systemName: "hourglass")
                    Text("\(SalatiText.betweenThem) \(dawnIntervalText)")
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.mutedText)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .salatiHomeWidgetPadding(12)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(PrayerKey.fajr.title) \(fajr?.time ?? SalatiText.noTime)، \(PrayerKey.sunrise.title) \(sunrise?.time ?? SalatiText.noTime)"
        )
    }

    private func dawnRow(
        prayer: PrayerTime?,
        symbol: String,
        theme: SalatiWidgetTheme,
        isPrimary: Bool
    ) -> some View {
        HStack(spacing: 7) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isPrimary ? theme.accent : theme.secondaryText)
                .frame(width: 18)

            Text(prayer?.title ?? SalatiText.prayer)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(theme.primaryText)

            Spacer(minLength: 5)

            SalatiTimeText(
                value: prayer?.time ?? SalatiText.noTime,
                size: 18,
                weight: .black,
                color: isPrimary ? theme.accent : theme.primaryText
            )
        }
        .padding(.horizontal, 9)
        .frame(height: 36)
        .background(
            isPrimary ? theme.activePanel : theme.panel,
            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(isPrimary ? theme.activeBorder : theme.border, lineWidth: isPrimary ? 1 : 0.7)
        }
    }

    private var dawnIntervalText: String {
        guard let fajr, let sunrise else { return SalatiText.noTime }
        let minutes = max(0, Int(sunrise.date.timeIntervalSince(fajr.date) / 60))
        let hours = minutes / 60
        let remainder = minutes % 60

        if hours > 0 {
            return "\(hours)س \(remainder)د"
        }
        return "\(remainder)د"
    }
}

struct SalatiPrayerPathView: View {
    let entry: SalatiWidgetEntry

    private var title: String {
        entry.isTomorrowSchedule ? SalatiText.prayerPathTomorrow : SalatiText.prayerPath
    }

    var body: some View {
        SalatiWidgetSurface { theme in
            VStack(alignment: .trailing, spacing: 11) {
                professionalHeader(
                    title: title,
                    symbol: "point.topleft.down.to.point.bottomright.curvepath",
                    theme: theme
                )

                HStack(spacing: 0) {
                    ForEach(entry.obligatoryTimes) { prayer in
                        prayerMilestone(
                            prayer: prayer,
                            theme: theme,
                            isActive: entry.highlightedPrayer == prayer.key
                        )
                    }
                }
                .frame(maxHeight: .infinity)
                .background(alignment: .center) {
                    Capsule()
                        .fill(theme.border)
                        .frame(height: 2)
                        .padding(.horizontal, 24)
                        .offset(y: -12)
                }
            }
            .salatiHomeWidgetPadding()
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }

    private func prayerMilestone(
        prayer: PrayerTime,
        theme: SalatiWidgetTheme,
        isActive: Bool
    ) -> some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(isActive ? theme.accent : theme.panel)
                    .frame(width: isActive ? 25 : 20, height: isActive ? 25 : 20)

                Image(systemName: SalatiPrayerSymbol.value(for: prayer.key))
                    .font(.system(size: isActive ? 11 : 9, weight: .black))
                    .foregroundStyle(isActive ? theme.activePanel : theme.secondaryText)
            }

            Text(prayer.title)
                .font(.system(size: 11, weight: isActive ? .black : .bold, design: .rounded))
                .foregroundStyle(isActive ? theme.accent : theme.primaryText)
                .lineLimit(1)

            SalatiTimeText(
                value: prayer.time,
                size: 12,
                weight: isActive ? .black : .bold,
                color: isActive ? theme.accent : theme.mutedText
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.activePanel)
            }
        }
    }
}

struct SalatiTomorrowScheduleView: View {
    let entry: SalatiWidgetEntry

    var body: some View {
        SalatiWidgetSurface { theme in
            VStack(alignment: .trailing, spacing: 7) {
                professionalHeader(
                    title: SalatiText.tomorrowPlan,
                    symbol: "calendar.badge.clock",
                    theme: theme
                )

                Text(SalatiWidgetDateText.compact(for: entry.tomorrowScheduleDate))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.mutedText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                SalatiPrayerColumns(
                    times: entry.tomorrowTimes,
                    highlightedPrayer: nil,
                    theme: theme
                )
            }
            .salatiHomeWidgetPadding()
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(SalatiText.tomorrowTimes)
    }
}

private func professionalHeader(
    title: String,
    symbol: String,
    theme: SalatiWidgetTheme,
    showsLocation: Bool = true
) -> some View {
    HStack(spacing: 6) {
        Image(systemName: symbol)
            .font(.system(size: 12, weight: .black))
            .foregroundStyle(theme.accent)
            .widgetAccentable()

        Text(title)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(theme.secondaryText)
            .lineLimit(1)

        Spacer(minLength: 6)

        if showsLocation {
            HStack(spacing: 3) {
                Image(systemName: "location.fill")
                    .font(.system(size: 9, weight: .bold))
                Text(IqamaSchedule.telSheva.locationName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(theme.mutedText)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(theme.chip, in: Capsule())
        }
    }
    .frame(maxWidth: .infinity)
}
