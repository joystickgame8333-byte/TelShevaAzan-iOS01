import SwiftUI
import WidgetKit

struct SalatiPrayerPathView: View {
    let entry: SalatiWidgetEntry

    private var title: String {
        entry.isTomorrowSchedule ? SalatiText.prayerPathTomorrow : SalatiText.prayerPath
    }

    var body: some View {
        SalatiWidgetSurface { theme in
            VStack(alignment: .trailing, spacing: 12) {
                SalatiWidgetHeader(
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
                        .fill(theme.secondaryText.opacity(0.20))
                        .frame(height: 1.5)
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
                    .frame(width: isActive ? 27 : 21, height: isActive ? 27 : 21)

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
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(theme.activeBorder, lineWidth: 1)
                    }
            }
        }
    }
}
