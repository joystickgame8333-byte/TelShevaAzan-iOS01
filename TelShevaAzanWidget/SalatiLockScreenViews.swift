import SwiftUI
import WidgetKit

struct SalatiAccessoryInlineView: View {
    let prayerName: String
    let prayerTime: String

    var body: some View {
        Text("\(prayerName)  •  \(SalatiText.isolatedTime(prayerTime))")
            .font(.caption.weight(.bold))
            .fixedSize(horizontal: true, vertical: false)
    }
}

struct SalatiAccessoryCircularView: View {
    let prayerName: String
    let from: Date
    let target: Date?

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            Circle()
                .stroke(.primary.opacity(0.28), lineWidth: 2.5)

            VStack(spacing: 1) {
                SalatiCountdownText(from: from, target: target, size: 13, color: .primary)
                    .minimumScaleFactor(0.7)

                Text(prayerName)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: true, vertical: false)
            }
            .padding(5)
        }
        .widgetAccentable()
        .accessibilityLabel("\(SalatiText.remaining) \(prayerName)")
    }
}

struct SalatiAccessoryRectangularView: View {
    let prayerName: String
    let prayerTime: String
    let prayerSymbol: String
    let from: Date
    let target: Date?

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                SalatiTimeText(value: prayerTime, size: 20, weight: .black)

                HStack(spacing: 3) {
                    SalatiCountdownText(from: from, target: target, size: 10, color: .primary)
                    Text(SalatiText.remaining)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .fixedSize(horizontal: true, vertical: false)
                }
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text(SalatiText.nextPrayerShort)
                        .font(.caption2.weight(.bold))
                    Image(systemName: prayerSymbol)
                        .font(.caption2.weight(.bold))
                        .widgetAccentable()
                }

                Text(prayerName)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(SalatiText.nextPrayer)، \(prayerName)، \(prayerTime)")
    }
}
