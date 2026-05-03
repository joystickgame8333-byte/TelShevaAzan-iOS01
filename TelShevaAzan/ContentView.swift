import SwiftUI
import WidgetKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppThemeStorage.nightThemeKey, store: AppThemeStorage.defaults) private var selectedNightThemeID = PrayerVisualTheme.defaultNight.rawValue
    @AppStorage(AppThemeStorage.dayThemeKey, store: AppThemeStorage.defaults) private var selectedDayThemeID = PrayerVisualTheme.defaultDay.rawValue
    @State private var now = Date()
    @State private var selectedDateKey = PrayerEngine.defaultDateKey()
    @State private var followsToday = true

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let schedule = PrayerEngine.schedule(for: selectedDateKey)
        let next = PrayerEngine.nextPrayer(for: selectedDateKey, now: now)
        let previous = PrayerEngine.previousPrayer(for: selectedDateKey, now: now)

        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720
            let sectionSpacing: CGFloat = compactHeight ? 6 : 8
            let rowSpacing: CGFloat = compactHeight ? 6 : 8
            let rowHeight = min(CGFloat(62), max(CGFloat(40), (proxy.size.height - 455) / 6))

            ZStack {
                background

                VStack(alignment: .trailing, spacing: sectionSpacing) {
                    quranVerse

                    header

                    nextPrayerPanel(next: next, previous: previous, compact: compactHeight)

                    dateControls

                    VStack(spacing: rowSpacing) {
                        ForEach(schedule.displayTimes) { item in
                            prayerRow(item, activeKey: next?.key, rowHeight: rowHeight)
                        }
                    }

                    footerNote
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 18)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topTrailing)
                .foregroundStyle(activeTheme.primaryText)
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
        .onChange(of: selectedNightThemeID) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: selectedDayThemeID) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private var quranVerse: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("إِنَّ ٱلصَّلَوٰةَ كَانَتْ عَلَى ٱلْمُؤْمِنِينَ كِتَـٰبًا مَّوْقُوتًا")
                .font(.custom("AmiriQuran-Regular", size: 16))
                .foregroundStyle(activeTheme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.54)

            Text("النساء ١٠٣")
                .font(.caption2.weight(.bold))
                .foregroundStyle(activeTheme.secondaryText.opacity(0.74))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var header: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack {
                themeMenu

                Spacer()

                Text("مواقيت محلية \(AppInfo.displayVersion)")
                    .font(.caption2.monospacedDigit().weight(.bold))
                    .foregroundStyle(activeTheme.accent)
                    .lineLimit(1)
            }

            Text("أذان تل السبع")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(PrayerEngine.longDateLabel(for: selectedDateKey))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(activeTheme.secondaryText.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var themeMenu: some View {
        Menu {
            Section {
                ForEach(PrayerVisualTheme.nightChoices) { theme in
                    Button {
                        selectedNightThemeID = theme.rawValue
                        WidgetCenter.shared.reloadAllTimelines()
                    } label: {
                        Label {
                            Text(ArabicDisplay.rtl(theme.title))
                        } icon: {
                            Image(systemName: selectedNightThemeID == theme.rawValue ? "checkmark.circle.fill" : theme.symbol)
                        }
                    }
                }
            } header: {
                Text(ArabicDisplay.rtl("أنماط الليل"))
            }

            Section {
                ForEach(PrayerVisualTheme.dayChoices) { theme in
                    Button {
                        selectedDayThemeID = theme.rawValue
                        WidgetCenter.shared.reloadAllTimelines()
                    } label: {
                        Label {
                            Text(ArabicDisplay.rtl(theme.title))
                        } icon: {
                            Image(systemName: selectedDayThemeID == theme.rawValue ? "checkmark.circle.fill" : theme.symbol)
                        }
                    }
                }
            } header: {
                Text(ArabicDisplay.rtl("أنماط النهار"))
            }
        } label: {
            Label {
                Text(ArabicDisplay.rtl("\(activeTheme.modeTitle) · \(activeTheme.title)"))
            } icon: {
                Image(systemName: activeTheme.symbol)
            }
                .font(.caption2.weight(.black))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(activeTheme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(activeTheme.controlBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(activeTheme.controlBorder)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func nextPrayerPanel(next: PrayerTime?, previous: PrayerTime?, compact: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(countdownText(for: next))
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(activeTheme.countdownBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(elapsedText(for: previous))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(activeTheme.secondaryText.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text("الصلاة القادمة")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(activeTheme.accent)
                    .lineLimit(1)

                Text(next?.title ?? "--")
                    .font(.system(size: compact ? 29 : 32, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(next?.time ?? "--:--")
                    .font(.system(size: compact ? 35 : 40, weight: .black, design: .rounded))
                    .foregroundStyle(activeTheme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(compact ? 12 : 14)
        .background(activeTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(isNight ? 0.22 : 0.06), radius: 12, y: 6)
    }

    private var dateControls: some View {
        HStack(spacing: 8) {
            Button("اليوم التالي") {
                moveDay(1)
            }
            .buttonStyle(CompactButtonStyle(theme: activeTheme))
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: 1))

            Button("اليوم") {
                selectedDateKey = PrayerEngine.defaultDateKey(for: now)
                followsToday = true
            }
            .buttonStyle(CompactButtonStyle(theme: activeTheme))

            Button("اليوم السابق") {
                moveDay(-1)
            }
            .buttonStyle(CompactButtonStyle(theme: activeTheme))
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: -1))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var footerNote: some View {
        Text("مواقيت تل السبع المحلية · تتحدث تلقائيًا")
            .font(.caption2.weight(.bold))
            .foregroundStyle(activeTheme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func prayerRow(_ item: PrayerTime, activeKey: PrayerKey?, rowHeight: CGFloat) -> some View {
        HStack {
            Text(item.time)
                .font(.headline.monospacedDigit().weight(.bold))
                .foregroundStyle(item.key == activeKey ? activeTheme.accent : activeTheme.primaryText)

            Spacer()

            Text(item.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(item.key == activeKey ? activeTheme.accent : activeTheme.secondaryText.opacity(0.78))
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

    private var activeTheme: PrayerVisualTheme {
        PrayerVisualTheme.selected(isNight: isNight, nightID: selectedNightThemeID, dayID: selectedDayThemeID)
    }

    private func rowBackground(isActive: Bool) -> Color {
        isActive ? activeTheme.activeRowBackground : activeTheme.rowBackground
    }

    private func rowBorder(isActive: Bool) -> Color {
        isActive ? activeTheme.activeRowBorder : activeTheme.rowBorder
    }

    private var background: some View {
        LinearGradient(
            colors: activeTheme.appBackground,
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

    private func elapsedText(for previous: PrayerTime?) -> String {
        guard let previous else { return "مضى --" }
        let seconds = max(Int(now.timeIntervalSince(previous.date)), 0)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "مضى على \(previous.title) \(hours)س \(minutes)د"
        }

        return "مضى على \(previous.title) \(minutes)د"
    }

    private func moveDay(_ offset: Int) {
        guard let nextKey = PrayerEngine.dateKey(from: selectedDateKey, offset: offset) else { return }
        selectedDateKey = nextKey
        followsToday = false
    }
}

private struct CompactButtonStyle: ButtonStyle {
    let theme: PrayerVisualTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .foregroundStyle(theme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(configuration.isPressed ? theme.controlPressedBackground : theme.controlBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.controlBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
        .environment(\.layoutDirection, .rightToLeft)
}
