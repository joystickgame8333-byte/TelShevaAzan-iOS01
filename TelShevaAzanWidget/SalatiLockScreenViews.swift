import SwiftUI
import WidgetKit

enum SalatiLockScreenStyle {
    case inline
    case prayerTime
    case countdown
    case nextPrayer
    case followingPrayers
    case dailySchedule
}

struct SalatiLockScreenView: View {
    let entry: SalatiWidgetEntry
    let style: SalatiLockScreenStyle

    var body: some View {
        Group {
            switch style {
            case .inline:
                SalatiLockInlineView(entry: entry)
            case .prayerTime:
                SalatiLockPrayerTimeView(entry: entry)
            case .countdown:
                SalatiLockCountdownView(entry: entry)
            case .nextPrayer:
                SalatiLockNextPrayerView(entry: entry)
            case .followingPrayers:
                SalatiLockFollowingPrayersView(entry: entry)
            case .dailySchedule:
                SalatiLockScheduleView(entry: entry)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .widgetURL(URL(string: "telshevaazan://schedule"))
    }
}

struct SalatiLockInlineView: View {
    let entry: SalatiWidgetEntry

    private var prayerName: String {
        entry.focusedPrayer?.title ?? SalatiText.prayer
    }

    private var shortName: String {
        switch entry.moment {
        case .upcoming:
            return prayerName
        case .approaching:
            return "اقترب \(prayerName)"
        case .adhan:
            return "الآن \(prayerName)"
        case .iqama:
            return "إقامة \(prayerName)"
        case .tomorrow:
            return "فجر الغد"
        }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .widgetAccentable()

                Text(shortName)
                    .fontWeight(.bold)

                Text(SalatiText.isolatedTime(entry.focusedTime))
                    .monospacedDigit()
                    .fontWeight(.black)

                Text("•")

                SalatiCountdownText(
                    from: entry.date,
                    target: entry.focusedTarget,
                    size: 10,
                    color: .primary
                )
            }

            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .widgetAccentable()

                Text("\(shortName) \(SalatiText.isolatedTime(entry.focusedTime))")
                    .fontWeight(.bold)
            }
        }
        .font(.caption)
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private var symbol: String {
        SalatiLockSymbol.value(for: entry)
    }

    private var accessibilityText: String {
        "\(entry.focusedTitle)، \(prayerName)، \(entry.focusedTime)"
    }
}

struct SalatiLockPrayerTimeView: View {
    let entry: SalatiWidgetEntry

    private var prayerName: String {
        entry.focusedPrayer?.title ?? SalatiText.prayer
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            Circle()
                .stroke(.primary.opacity(0.24), lineWidth: 2)

            Circle()
                .trim(from: 0, to: max(0.035, min(1, entry.focusedProgress)))
                .stroke(
                    .primary,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .widgetAccentable()

            VStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(.system(size: 9, weight: .black))
                    .widgetAccentable()

                SalatiTimeText(
                    value: entry.focusedTime,
                    size: 13,
                    weight: .black
                )

                Text(prayerName)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .padding(5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.focusedTitle)، \(prayerName)، \(entry.focusedTime)")
    }

    private var symbol: String {
        SalatiLockSymbol.value(for: entry)
    }
}

struct SalatiLockCountdownView: View {
    let entry: SalatiWidgetEntry

    private var prayerName: String {
        entry.focusedPrayer?.title ?? SalatiText.prayer
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            Circle()
                .stroke(.primary.opacity(0.26), lineWidth: 2.5)

            Circle()
                .trim(from: 0, to: max(0.035, min(1, entry.focusedProgress)))
                .stroke(
                    .primary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                SalatiCountdownText(
                    from: entry.date,
                    target: entry.focusedTarget,
                    size: 12,
                    color: .primary
                )
                .minimumScaleFactor(0.62)

                Text(entry.activeIqama == nil ? prayerName : "للإقامة")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .environment(\.layoutDirection, .leftToRight)
            .padding(4)
        }
        .widgetAccentable()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.focusedCountdownLabel) \(prayerName)")
    }
}

struct SalatiLockNextPrayerView: View {
    let entry: SalatiWidgetEntry

    private var prayerName: String {
        entry.focusedPrayer?.title ?? SalatiText.prayer
    }

    var body: some View {
        HStack(alignment: .center, spacing: 7) {
            VStack(alignment: .leading, spacing: 2) {
                SalatiTimeText(
                    value: entry.focusedTime,
                    size: 19,
                    weight: .black
                )

                HStack(spacing: 3) {
                    SalatiCountdownText(
                        from: entry.date,
                        target: entry.focusedTarget,
                        size: 10,
                        color: .primary
                    )

                    Text(entry.activeIqama == nil ? SalatiText.remaining : "للإقامة")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 3)

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.focusedTitle)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)

                    Image(systemName: symbol)
                        .font(.system(size: 9, weight: .black))
                        .widgetAccentable()
                }

                Text(prayerName)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.focusedTitle)، \(prayerName)، \(entry.focusedTime)")
    }

    private var symbol: String {
        SalatiLockSymbol.value(for: entry)
    }
}

struct SalatiLockFollowingPrayersView: View {
    let entry: SalatiWidgetEntry

    private var headerTitle: String {
        switch entry.moment {
        case .adhan, .iqama:
            return entry.focusedTitle
        case .upcoming, .approaching, .tomorrow:
            return SalatiText.nextAndFollowing
        }
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 4) {
                Text(headerTitle)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .lineLimit(1)

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 8, weight: .black))
                    .widgetAccentable()
            }

            HStack(spacing: 7) {
                prayerBlock(
                    title: entry.followingPrayer?.title ?? SalatiText.prayer,
                    time: entry.followingPrayer?.time ?? SalatiText.noTime,
                    caption: "بعدها",
                    emphasized: false
                )

                Rectangle()
                    .fill(.primary.opacity(0.22))
                    .frame(width: 1)

                prayerBlock(
                    title: entry.focusedPrayer?.title ?? SalatiText.prayer,
                    time: entry.focusedTime,
                    caption: entry.focusedShortTitle,
                    emphasized: true
                )
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    private func prayerBlock(
        title: String,
        time: String,
        caption: String,
        emphasized: Bool
    ) -> some View {
        VStack(spacing: 0) {
            Text(caption)
                .font(.system(size: 7, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.system(size: 11, weight: emphasized ? .black : .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            SalatiTimeText(
                value: time,
                size: 13,
                weight: emphasized ? .black : .bold
            )
        }
        .frame(maxWidth: .infinity)
        .widgetAccentable(emphasized)
    }

    private var accessibilityText: String {
        let first = entry.focusedPrayer?.title ?? SalatiText.prayer
        let second = entry.followingPrayer?.title ?? SalatiText.prayer
        return "\(first) \(entry.focusedTime)، ثم \(second) \(entry.followingPrayer?.time ?? SalatiText.noTime)"
    }
}

struct SalatiLockScheduleView: View {
    let entry: SalatiWidgetEntry

    private var firstRow: [PrayerTime] {
        Array(entry.times.prefix(3))
    }

    private var secondRow: [PrayerTime] {
        Array(entry.times.dropFirst(3).prefix(3))
    }

    var body: some View {
        VStack(spacing: 4) {
            scheduleRow(firstRow)
            scheduleRow(secondRow)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(scheduleAccessibilityText)
    }

    private func scheduleRow(_ prayers: [PrayerTime]) -> some View {
        HStack(spacing: 3) {
            ForEach(Array(prayers.reversed())) { prayer in
                VStack(spacing: 0) {
                    Text(prayer.title)
                        .font(.system(
                            size: 9.5,
                            weight: prayer.key == entry.highlightedPrayerKey ? .black : .bold,
                            design: .rounded
                        ))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    SalatiTimeText(
                        value: prayer.time,
                        size: 13,
                        weight: prayer.key == entry.highlightedPrayerKey ? .black : .bold
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)
                .background {
                    if prayer.key == entry.highlightedPrayerKey {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(.primary.opacity(0.12))
                    }
                }
                .widgetAccentable(prayer.key == entry.highlightedPrayerKey)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var scheduleAccessibilityText: String {
        entry.times
            .map { SalatiText.prayerAndTime(prayer: $0.title, time: $0.time) }
            .joined(separator: "، ")
    }
}

private enum SalatiLockSymbol {
    static func value(for entry: SalatiWidgetEntry) -> String {
        switch entry.moment {
        case .adhan:
            return "speaker.wave.2.fill"
        case .iqama:
            return "person.2.fill"
        case .upcoming, .approaching, .tomorrow:
            return SalatiPrayerSymbol.value(for: entry.focusedPrayer?.key)
        }
    }
}
