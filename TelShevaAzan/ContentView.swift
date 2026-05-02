import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var now = Date()
    @State private var selectedDateKey = PrayerEngine.defaultDateKey()
    @State private var followsToday = true

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let schedule = PrayerEngine.schedule(for: selectedDateKey)
        let next = PrayerEngine.nextPrayer(for: selectedDateKey, now: now)

        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720
            let sectionSpacing: CGFloat = compactHeight ? 6 : 8
            let rowSpacing: CGFloat = compactHeight ? 6 : 8
            let rowHeight = min(CGFloat(52), max(CGFloat(40), (proxy.size.height - 390) / 6))

            ZStack {
                background

                VStack(alignment: .trailing, spacing: sectionSpacing) {
                    header

                    nextPrayerPanel(next: next, compact: compactHeight)

                    dateControls

                    VStack(spacing: rowSpacing) {
                        ForEach(schedule.displayTimes) { item in
                            prayerRow(item, activeKey: next?.key, rowHeight: rowHeight)
                        }
                    }

                    Spacer(minLength: 8)

                    footerNote
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 18)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topTrailing)
                .environment(\.layoutDirection, .leftToRight)
                .multilineTextAlignment(.trailing)
                .clipped()
            }
        }
        .onReceive(timer) { value in
            now = value
            if followsToday {
                selectedDateKey = PrayerEngine.defaultDateKey(for: value)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack {
                Label(isNight ? "ليل" : "نهار", systemImage: isNight ? "moon.stars.fill" : "sun.max.fill")
                    .font(.caption2.weight(.black))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(isNight ? Color.white.opacity(0.16) : Color.white.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isNight ? Color.white.opacity(0.14) : Color.black.opacity(0.1))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()

                Text("مواقيت محلية \(AppInfo.displayVersion)")
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
            }

            Text("أذان تل السبع")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(PrayerEngine.longDateLabel(for: selectedDateKey))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func nextPrayerPanel(next: PrayerTime?, compact: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(countdownText(for: next))
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(countdownBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("تتحدث تلقائيًا")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text("الصلاة القادمة")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)

                Text(next?.title ?? "--")
                    .font(.system(size: compact ? 29 : 32, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(next?.time ?? "--:--")
                    .font(.system(size: compact ? 35 : 40, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(compact ? 12 : 14)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(isNight ? 0.22 : 0.06), radius: 12, y: 6)
    }

    private var dateControls: some View {
        HStack(spacing: 8) {
            Button("اليوم التالي") {
                moveDay(1)
            }
            .buttonStyle(CompactButtonStyle(isNight: isNight))
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: 1))

            Button("اليوم") {
                selectedDateKey = PrayerEngine.defaultDateKey(for: now)
                followsToday = true
            }
            .buttonStyle(CompactButtonStyle(isNight: isNight))

            Button("اليوم السابق") {
                moveDay(-1)
            }
            .buttonStyle(CompactButtonStyle(isNight: isNight))
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: -1))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var footerNote: some View {
        Text("مواقيت تل السبع المحلية · تتحدث تلقائيًا")
            .font(.caption2.weight(.bold))
            .foregroundStyle(accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func prayerRow(_ item: PrayerTime, activeKey: PrayerKey?, rowHeight: CGFloat) -> some View {
        HStack {
            Text(item.time)
                .font(.headline.monospacedDigit().weight(.bold))
                .foregroundStyle(item.key == activeKey ? accentColor : Color.primary)

            Spacer()

            Text(item.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(item.key == activeKey ? accentColor : Color.secondary)
        }
        .lineLimit(1)
        .padding(.horizontal, 12)
        .frame(height: rowHeight)
        .background(rowBackground(isActive: item.key == activeKey))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(rowBorder(isActive: item.key == activeKey))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var isNight: Bool {
        colorScheme == .dark
    }

    private var accentColor: Color {
        isNight ? Color(red: 0.96, green: 0.78, blue: 0.38) : Color.teal
    }

    private var panelBackground: Color {
        isNight ? Color(red: 0.07, green: 0.11, blue: 0.12).opacity(0.96) : Color.white.opacity(0.9)
    }

    private var countdownBackground: Color {
        isNight ? Color(red: 0.45, green: 0.30, blue: 0.09) : Color(red: 0.04, green: 0.31, blue: 0.29)
    }

    private func rowBackground(isActive: Bool) -> Color {
        if isNight {
            return isActive ? Color(red: 0.18, green: 0.15, blue: 0.08).opacity(0.92) : Color(red: 0.08, green: 0.13, blue: 0.14).opacity(0.92)
        }

        return isActive ? Color.teal.opacity(0.12) : Color.white.opacity(0.82)
    }

    private func rowBorder(isActive: Bool) -> Color {
        if isNight {
            return isActive ? Color(red: 0.96, green: 0.78, blue: 0.38).opacity(0.55) : Color.white.opacity(0.09)
        }

        return isActive ? Color.teal.opacity(0.55) : Color.black.opacity(0.08)
    }

    private var background: some View {
        LinearGradient(
            colors: isNight ? [
                Color(red: 0.02, green: 0.08, blue: 0.10),
                Color(red: 0.08, green: 0.16, blue: 0.14)
            ] : [
                Color(red: 0.95, green: 0.93, blue: 0.88),
                Color(red: 0.90, green: 0.96, blue: 0.94)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .ignoresSafeArea()
    }

    private func countdownText(for next: PrayerTime?) -> String {
        guard let next else { return "--:--:--" }
        let seconds = Int(next.date.timeIntervalSince(now))
        guard seconds > 0 else { return "--:--:--" }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    private func moveDay(_ offset: Int) {
        guard let nextKey = PrayerEngine.dateKey(from: selectedDateKey, offset: offset) else { return }
        selectedDateKey = nextKey
        followsToday = false
    }
}

private struct CompactButtonStyle: ButtonStyle {
    let isNight: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isNight ? Color.white.opacity(configuration.isPressed ? 0.10 : 0.16) : Color.white.opacity(configuration.isPressed ? 0.65 : 0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isNight ? Color.white.opacity(0.12) : Color.black.opacity(0.1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
        .environment(\.layoutDirection, .rightToLeft)
}
