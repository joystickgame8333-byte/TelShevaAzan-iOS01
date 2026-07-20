import SwiftUI
import WidgetKit

enum SalatiText {
    static let nextPrayer = "الصلاة القادمة"
    static let nextPrayerDescription = "موعد الصلاة القادمة والوقت المتبقي لها"
    static let todayTimes = "مواقيت اليوم"
    static let todayTimesDescription = "مواقيت الصلاة اليومية في تل السبع"
    static let tomorrowTimes = "مواقيت الغد"
    static let nextIqama = "الإقامة القادمة"
    static let nextIqamaDescription = "موعد الإقامة القادمة في تل السبع"
    static let remaining = "متبقي"
    static let until = "لـ"
    static let adhan = "الأذان"
    static let iqama = "الإقامة"
    static let prayer = "الصلاة"
    static let noTime = "--:--"

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

            Spacer(minLength: 4)

            SalatiLocationLabel(theme: theme)
        }
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
                .lineLimit(1)
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
            .minimumScaleFactor(0.72)
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
        .minimumScaleFactor(0.58)
        .environment(\.layoutDirection, .leftToRight)
        .environment(\.locale, Locale(identifier: "en_US_POSIX"))
    }
}

struct SalatiPrayerColumns: View {
    let times: [PrayerTime]
    let highlightedPrayer: PrayerKey?
    let theme: SalatiWidgetTheme
    var expanded = false

    private var firstColumn: [PrayerTime] { Array(times.prefix(3)) }
    private var secondColumn: [PrayerTime] { Array(times.dropFirst(3).prefix(3)) }

    var body: some View {
        HStack(alignment: .top, spacing: expanded ? 10 : 7) {
            column(firstColumn)
            column(secondColumn)
        }
        .environment(\.layoutDirection, .rightToLeft)
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
    }
}

private struct SalatiPrayerCell: View {
    let prayer: PrayerTime
    let isActive: Bool
    let theme: SalatiWidgetTheme
    let expanded: Bool

    var body: some View {
        HStack(spacing: 5) {
            Text(prayer.title)
                .font(.system(size: expanded ? 13 : 11, weight: isActive ? .black : .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 3)

            SalatiTimeText(
                value: prayer.time,
                size: expanded ? 15 : 13,
                weight: isActive ? .black : .bold,
                color: isActive ? theme.accent : theme.primaryText
            )
        }
        .foregroundStyle(isActive ? theme.accent : theme.primaryText)
        .padding(.horizontal, expanded ? 9 : 7)
        .frame(height: expanded ? 34 : 26)
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
