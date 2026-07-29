import SwiftUI
import WidgetKit

enum SalatiText {
    static let nextPrayer = "الصلاة القادمة"
    static let nextPrayerShort = "القادمة"
    static let nextPrayerDescription = "موعد الصلاة القادمة والوقت المتبقي لها"
    static let todayTimes = "مواقيت اليوم"
    static let todayTimesDescription = "مواقيت الصلاة اليومية في تل السبع"
    static let tomorrowTimes = "مواقيت الغد"
    static let remainingUntilAdhan = "متبقي حتى الأذان"
    static let remaining = "متبقي"
    static let prayer = "الصلاة"
    static let noTime = "--:--"
    static let prayerPath = "مسار الصلوات"
    static let prayerPathTomorrow = "مسار صلوات الغد"
    static let prayerPathDescription = "تابع ترتيب الصلوات المفروضة وموضع الصلاة القادمة"
    static let obligatoryPrayers = "الصلوات المفروضة"
    static let allPrayerTimes = "جميع المواقيت"

    static func isolatedTime(_ value: String) -> String {
        "\u{2066}\(value)\u{2069}"
    }

    static func prayerAndTime(prayer: String, time: String) -> String {
        "\(prayer)  \(isolatedTime(time))"
    }

}

struct SalatiWidgetHeader: View {
    let title: String
    let symbol: String
    let theme: SalatiWidgetTheme
    var showsLocation = true

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.caption.weight(.black))
                .foregroundStyle(theme.accent)
                .widgetAccentable()

            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .layoutPriority(1)

            if showsLocation {
                Spacer(minLength: 4)
                SalatiLocationLabel(theme: theme)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct SalatiLocationLabel: View {
    let theme: SalatiWidgetTheme

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "location.fill")
                .font(.system(size: 8, weight: .bold))
            Text(IqamaSchedule.telSheva.locationName)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(theme.mutedText)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(theme.chip, in: Capsule())
    }
}

struct SalatiTimeText: View {
    let value: String
    var size: CGFloat = 18
    var weight: Font.Weight = .bold
    var color: Color? = nil

    var body: some View {
        Text(value)
            .font(.system(size: size, weight: weight, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(color ?? .primary)
            .lineLimit(1)
            .minimumScaleFactor(0.68)
            .fixedSize(horizontal: true, vertical: false)
            .environment(\.layoutDirection, .leftToRight)
            .environment(\.locale, Locale(identifier: "en_US_POSIX"))
    }
}

struct SalatiCountdownText: View {
    let from: Date
    let target: Date?
    var size: CGFloat
    var color: Color

    var body: some View {
        Group {
            if let target, target > from {
                Text(timerInterval: from...target, countsDown: true)
            } else {
                Text("00:00")
            }
        }
        .font(.system(size: size, weight: .black, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.54)
        .environment(\.layoutDirection, .leftToRight)
        .environment(\.locale, Locale(identifier: "en_US_POSIX"))
    }
}

struct SalatiCountdownRow: View {
    let label: String
    let from: Date
    let target: Date?
    let theme: SalatiWidgetTheme
    var compact = false

    var body: some View {
        HStack(spacing: 6) {
            SalatiCountdownText(
                from: from,
                target: target,
                size: compact ? 13 : 16,
                color: theme.primaryText
            )

            Spacer(minLength: 4)

            Text(label)
                .font(.system(size: compact ? 9 : 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.mutedText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.trailing)
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 5 : 7)
        .background(theme.panel, in: RoundedRectangle(cornerRadius: SalatiWidgetMetrics.compactCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SalatiWidgetMetrics.compactCornerRadius, style: .continuous)
                .stroke(theme.border, lineWidth: 0.75)
        }
    }
}

struct SalatiPrayerColumns: View {
    let times: [PrayerTime]
    let highlightedPrayer: PrayerKey?
    let theme: SalatiWidgetTheme
    var expanded = false

    private var rightColumn: [PrayerTime] { Array(times.prefix(3)) }
    private var leftColumn: [PrayerTime] { Array(times.dropFirst(3).prefix(3)) }

    var body: some View {
        HStack(alignment: .top, spacing: expanded ? 10 : 7) {
            column(leftColumn)
            column(rightColumn)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func column(_ prayers: [PrayerTime]) -> some View {
        VStack(spacing: expanded ? 7 : 4) {
            ForEach(prayers) { prayer in
                SalatiPrayerCell(
                    prayer: prayer,
                    isActive: prayer.key == highlightedPrayer,
                    theme: theme,
                    expanded: expanded
                )
            }
        }
        .frame(maxWidth: .infinity)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

struct SalatiPrayerList: View {
    let times: [PrayerTime]
    let highlightedPrayer: PrayerKey?
    let theme: SalatiWidgetTheme
    var expanded = false
    var compact = false

    var body: some View {
        VStack(spacing: compact ? 3 : (expanded ? 6 : 4)) {
            ForEach(times) { prayer in
                SalatiPrayerCell(
                    prayer: prayer,
                    isActive: prayer.key == highlightedPrayer,
                    theme: theme,
                    expanded: expanded,
                    compact: compact
                )
            }
        }
    }
}

private struct SalatiPrayerCell: View {
    let prayer: PrayerTime
    let isActive: Bool
    let theme: SalatiWidgetTheme
    let expanded: Bool
    var compact = false

    var body: some View {
        HStack(spacing: 5) {
            SalatiTimeText(
                value: prayer.time,
                size: compact ? (expanded ? 12 : 11) : (expanded ? 15 : 13),
                weight: isActive ? .black : .bold,
                color: isActive ? theme.accent : theme.primaryText
            )

            Spacer(minLength: 3)

            Text(prayer.title)
                .font(.system(
                    size: compact ? (expanded ? 10.5 : 10) : (expanded ? 13 : 11),
                    weight: isActive ? .black : .bold,
                    design: .rounded
                ))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.trailing)
        }
        .environment(\.layoutDirection, .leftToRight)
        .foregroundStyle(isActive ? theme.accent : theme.primaryText)
        .padding(.horizontal, compact ? 6 : (expanded ? 9 : 7))
        .frame(height: compact ? (expanded ? 29 : 18) : (expanded ? 34 : 26))
        .background(isActive ? theme.activePanel : theme.panel, in: RoundedRectangle(cornerRadius: SalatiWidgetMetrics.compactCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: SalatiWidgetMetrics.compactCornerRadius, style: .continuous)
                .stroke(isActive ? theme.activeBorder : theme.border, lineWidth: isActive ? 1.1 : 0.7)
        }
        .overlay(alignment: .trailing) {
            if isActive {
                Capsule()
                    .fill(theme.accent)
                    .frame(width: 3)
                    .padding(.vertical, 6)
                    .padding(.trailing, 1)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(SalatiText.prayerAndTime(prayer: prayer.title, time: prayer.time))
    }
}

enum SalatiPrayerSymbol {
    static func value(for key: PrayerKey?) -> String {
        switch key {
        case .fajr:
            return "sunrise.fill"
        case .sunrise:
            return "sun.max.fill"
        case .dhuhr:
            return "sun.max.fill"
        case .asr:
            return "cloud.sun.fill"
        case .maghrib:
            return "sunset.fill"
        case .isha:
            return "moon.stars.fill"
        case nil:
            return "clock.fill"
        }
    }
}
