import Foundation
import SwiftUI
import WidgetKit

struct TelShevaWidgetEntry: TimelineEntry {
    let date: Date
    let dateKey: String
    let nextPrayer: PrayerTime?
    let previousPrayer: PrayerTime?
    let times: [PrayerTime]
}

struct TelShevaWidgetProvider: TimelineProvider {
    private static let timelineHorizon: TimeInterval = 30 * 60 * 60

    func placeholder(in context: Context) -> TelShevaWidgetEntry {
        Self.makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (TelShevaWidgetEntry) -> Void) {
        completion(Self.makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TelShevaWidgetEntry>) -> Void) {
        let now = Date()
        let dates = Self.timelineDates(startingAt: now)
        let entries = dates.map { Self.makeEntry(for: $0) }
        let refreshDate = dates.last?.addingTimeInterval(5 * 60) ?? now.addingTimeInterval(30 * 60)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    static func displayEntry(from entry: TelShevaWidgetEntry) -> TelShevaWidgetEntry {
        entry
    }

    static func makeEntry(for date: Date) -> TelShevaWidgetEntry {
        let dateKey = PrayerEngine.defaultDateKey(for: date)
        let schedule = PrayerEngine.schedule(for: dateKey)

        return TelShevaWidgetEntry(
            date: date,
            dateKey: dateKey,
            nextPrayer: PrayerEngine.nextPrayer(for: dateKey, now: date),
            previousPrayer: PrayerEngine.previousPrayer(for: dateKey, now: date),
            times: schedule.displayTimes
        )
    }

    private static func timelineDates(startingAt now: Date) -> [Date] {
        let start = PrayerEngine.calendar.dateInterval(of: .minute, for: now)?.start ?? now
        let end = now.addingTimeInterval(timelineHorizon)
        var dates: [Date] = [now]

        var cursor = PrayerEngine.calendar.date(byAdding: .minute, value: 1, to: start) ?? now.addingTimeInterval(60)
        var minuteIndex = 1
        while cursor <= end {
            if minuteIndex <= 180 || minuteIndex % 5 == 0 {
                dates.append(cursor)
            }

            cursor = PrayerEngine.calendar.date(byAdding: .minute, value: 1, to: cursor) ?? cursor.addingTimeInterval(60)
            minuteIndex += 1
        }

        for offset in 0...2 {
            guard let day = PrayerEngine.calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let dateKey = PrayerEngine.defaultDateKey(for: day)
            for prayer in PrayerEngine.schedule(for: dateKey).displayTimes {
                appendTransitionDates(around: prayer.date, start: now, end: end, to: &dates)
                if let iqama = iqamaDate(for: prayer) {
                    appendTransitionDates(around: iqama, start: now, end: end, to: &dates)
                }
            }
        }

        if let midnight = PrayerEngine.calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0, second: 1),
            matchingPolicy: .nextTime
        ) {
            appendIfInRange(midnight, start: now, end: end, to: &dates)
        }

        return Array(Set(dates.map { roundedToSecond($0) })).sorted()
    }

    private static func appendTransitionDates(around date: Date, start: Date, end: Date, to dates: inout [Date]) {
        appendIfInRange(date.addingTimeInterval(-1), start: start, end: end, to: &dates)
        appendIfInRange(date, start: start, end: end, to: &dates)
        appendIfInRange(date.addingTimeInterval(1), start: start, end: end, to: &dates)
        appendIfInRange(date.addingTimeInterval(60), start: start, end: end, to: &dates)
    }

    private static func appendIfInRange(_ date: Date, start: Date, end: Date, to dates: inout [Date]) {
        guard date >= start && date <= end else { return }
        dates.append(date)
    }

    private static func roundedToSecond(_ date: Date) -> Date {
        Date(timeIntervalSince1970: date.timeIntervalSince1970.rounded())
    }

    private static func iqamaDate(for prayer: PrayerTime) -> Date? {
        guard let minutes = iqamaOffsetMinutes(for: prayer.key) else { return nil }
        return prayer.date.addingTimeInterval(TimeInterval(minutes * 60))
    }

    private static func iqamaOffsetMinutes(for key: PrayerKey) -> Int? {
        switch key {
        case .fajr:
            return 25
        case .dhuhr:
            return 15
        case .asr:
            return 17
        case .maghrib:
            return 8
        case .isha:
            return 15
        case .sunrise:
            return nil
        }
    }
}

struct TelShevaAzanWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: TelShevaWidgetEntry
    var presentation: TelShevaWidgetPresentation = .nextPrayer

    private var displayEntry: TelShevaWidgetEntry {
        TelShevaWidgetProvider.displayEntry(from: entry)
    }

    private var renderDate: Date {
        displayEntry.date
    }

    var body: some View {
        Group {
            if isLockScreenFamily {
                lockScreenLayout
            } else if presentation == .countdown {
                countdownHomeLayout
            } else if presentation == .schedule {
                scheduleHomeLayout
            } else {
                homeScreenLayout
            }
        }
        .dynamicTypeSize(.xSmall ... .large)
        .unredacted()
    }

    private var isLockScreenFamily: Bool {
        if #available(iOSApplicationExtension 16.0, *) {
            return family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular
        }

        return false
    }

    private var isNight: Bool {
        colorScheme == .dark
    }

    private var selectedNightThemeID: String {
        AppThemeStorage.defaults.string(forKey: AppThemeStorage.nightThemeKey) ?? PrayerVisualTheme.defaultNight.rawValue
    }

    private var selectedDayThemeID: String {
        AppThemeStorage.defaults.string(forKey: AppThemeStorage.dayThemeKey) ?? PrayerVisualTheme.defaultDay.rawValue
    }

    private var theme: PrayerVisualTheme {
        let selectedTheme = PrayerVisualTheme.selected(isNight: isNight, nightID: selectedNightThemeID, dayID: selectedDayThemeID)

        switch selectedTheme {
        case .nightDawnGlass:
            return .nightGlass
        case .dayDawnGlass:
            return .dayGlass
        default:
            return selectedTheme
        }
    }

    private var accent: Color {
        theme.accent
    }

    private var primaryText: Color {
        theme.primaryText
    }

    private var secondaryText: Color {
        theme.secondaryText
    }

    private var mutedText: Color {
        theme.mutedText
    }

    private var chipBackground: Color {
        theme.chipBackground
    }

    private var activeRowBackground: Color {
        theme.activeRowBackground
    }

    private var widgetGradientColors: [Color] {
        theme.widgetBackground
    }

    private var widgetBackground: some View {
        LinearGradient(
            colors: widgetGradientColors,
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    private var nabawiImageName: String {
        isNight ? "nabawi-night" : "nabawi-day"
    }

    private var widgetSurfaceBackground: some View {
        ZStack {
            LinearGradient(
                colors: isNight
                    ? [
                        Color(red: 0.01, green: 0.04, blue: 0.07),
                        Color(red: 0.02, green: 0.12, blue: 0.21),
                        Color.black
                    ]
                    : [
                        Color(red: 0.92, green: 0.97, blue: 1.00),
                        Color(red: 0.78, green: 0.88, blue: 0.94),
                        Color(red: 0.96, green: 0.98, blue: 1.00)
                    ],
                startPoint: .leading,
                endPoint: .trailing
            )

            RadialGradient(
                colors: [accent.opacity(isNight ? 0.22 : 0.16), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 190
            )
        }
        .clipped()
    }

    private var capsuleFill: Color {
        isNight ? Color.white.opacity(0.105) : Color.white.opacity(0.58)
    }

    private var capsuleStroke: Color {
        isNight ? Color.white.opacity(0.13) : Color.white.opacity(0.84)
    }

    private var faintCapsuleFill: Color {
        isNight ? Color.white.opacity(0.075) : Color.white.opacity(0.48)
    }

    private var nextAzanTitle: String {
        displayEntry.nextPrayer?.key == .sunrise ? nextTitle : "أذان \(nextTitle)"
    }

    private var remainingMinutes: Int {
        guard let nextDate = displayEntry.nextPrayer?.date else { return 0 }
        let seconds = max(Int(nextDate.timeIntervalSince(renderDate)), 0)
        return max((seconds + 59) / 60, 1)
    }

    private var remainingMinuteLabel: String {
        let minutes = remainingMinutes
        return minutes < 100 ? "\(minutes) دقيقة" : hourMinuteText(fromMinutes: minutes)
    }

    private var remainingTimerText: Text {
        Text(remainingMinuteLabel)
            .fontWeight(.black)
    }

    private var nextIqamaTime: String? {
        guard let prayer = displayEntry.nextPrayer,
              let minutes = iqamaOffsetMinutes(for: prayer.key) else {
            return nil
        }

        return clockText(for: prayer.date.addingTimeInterval(TimeInterval(minutes * 60)))
    }

    private var nextIqamaMinutesLabel: String? {
        guard let prayer = displayEntry.nextPrayer,
              let minutes = iqamaOffsetMinutes(for: prayer.key) else {
            return nil
        }

        return "\(minutes) دقيقة"
    }

    private var nextMetaText: Text {
        if let iqama = nextIqamaTime {
            return Text("الإقامة ") + Text(iqama).fontWeight(.black) + Text(" · متبقي ") + remainingTimerText
        }

        return Text("متبقي ") + remainingTimerText
    }

    private var nextTitle: String {
        displayEntry.nextPrayer?.title ?? "الصلاة"
    }

    private var nextTime: String {
        displayEntry.nextPrayer?.time ?? "--:--"
    }

    private var compactRemainingText: String {
        guard let nextDate = displayEntry.nextPrayer?.date else { return "باقي على الصلاة --:--" }
        let seconds = max(Int(nextDate.timeIntervalSince(renderDate)), 0)
        let minutes = (seconds + 59) / 60
        return "باقي على الصلاة \(hourMinuteText(fromMinutes: minutes))"
    }

    private var compactElapsedText: String {
        guard let previous = displayEntry.previousPrayer else { return "مضى --:--" }
        let seconds = max(Int(renderDate.timeIntervalSince(previous.date)), 0)
        let minutes = seconds / 60
        return "مضى على \(previous.title) \(hourMinuteText(fromMinutes: minutes))"
    }

    private var inlineLiveText: Text {
        Text("\(nextTitle) \(nextTime) · \(compactRemainingText)")
    }

    private var liveRemainingText: Text {
        Text(compactRemainingText)
    }

    private var liveElapsedText: Text {
        Text(compactElapsedText)
    }

    private var homeScreenLayout: some View {
        ZStack {
            widgetSurfaceBackground
                .ignoresSafeArea()

            switch family {
            case .systemMedium:
                mediumHomeLayout
            default:
                smallHomeLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(widgetSurfaceBackground)
        .widgetContainerBackground {
            widgetSurfaceBackground
        }
    }

    private var scheduleHomeLayout: some View {
        ZStack {
            widgetSurfaceBackground
                .ignoresSafeArea()

            switch family {
            case .systemLarge:
                largeScheduleLayout
            default:
                mediumScheduleLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(widgetSurfaceBackground)
        .widgetContainerBackground {
            widgetSurfaceBackground
        }
    }

    private var countdownHomeLayout: some View {
        ZStack {
            widgetSurfaceBackground
                .ignoresSafeArea()

            switch family {
            case .systemMedium:
                mediumCountdownLayout
            default:
                smallCountdownLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(widgetSurfaceBackground)
        .widgetContainerBackground {
            widgetSurfaceBackground
        }
    }

    private var smallHomeLayout: some View {
        VStack(alignment: .trailing, spacing: 6) {
            salatiTopline("القادم")

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 5) {
                Text(nextTitle)
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                salatiTimeCapsule(nextTime, fontSize: 27)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer(minLength: 0)

            salatiMetaCapsule(Text("متبقي ") + remainingTimerText, compact: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(12)
    }

    private var mediumHomeLayout: some View {
        VStack(alignment: .trailing, spacing: 10) {
            salatiTopline("الصلاة القادمة")

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: 14) {
                salatiTimeCapsule(nextTime, fontSize: 39)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(nextAzanTitle)
                        .font(.system(size: 25, weight: .black, design: .rounded))
                        .foregroundColor(primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)

                    Text(compactElapsedText)
                        .font(.system(size: 11, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundColor(secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)

            salatiMetaCapsule(nextMetaText)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(16)
    }

    private var mediumScheduleLayout: some View {
        VStack(alignment: .trailing, spacing: 9) {
            salatiTopline("باقي اليوم")

            VStack(spacing: 7) {
                ForEach(Array(upcomingPrayerRows.prefix(3))) { item in
                    schedulePrayerRow(item, height: 28)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(16)
    }

    private var largeScheduleLayout: some View {
        VStack(alignment: .trailing, spacing: 11) {
            salatiTopline("الأحد")

            HStack(alignment: .center, spacing: 12) {
                salatiTimeCapsule(nextTime, fontSize: 44)

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(nextTitle)
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundColor(primaryText)
                        .lineLimit(1)

                    Text("الصلاة القادمة")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(secondaryText)
                        .lineLimit(1)
                }
            }

            VStack(spacing: 6) {
                ForEach(Array(displayEntry.times.prefix(6))) { item in
                    schedulePrayerRow(item, height: 26)
                }
            }

            Spacer(minLength: 0)

            salatiMetaCapsule(nextMetaText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(16)
    }

    private var smallCountdownLayout: some View {
        VStack(alignment: .trailing, spacing: 8) {
            salatiTopline("متبقي")

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 8) {
                Text(nextAzanTitle)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                salatiTimeCapsule(compactRemainingValue, fontSize: 34)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer(minLength: 0)

            salatiMetaCapsule(Text("الأذان ") + Text(nextTime).fontWeight(.black))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(14)
    }

    private var mediumCountdownLayout: some View {
        VStack(alignment: .trailing, spacing: 10) {
            salatiTopline("الأذان والإقامة")

            HStack(spacing: 10) {
                salatiInfoPanel(title: "الإقامة", value: nextIqamaTime ?? "--:--", footer: nextIqamaMinutesLabel ?? "بعد الأذان", highlighted: false)
                salatiInfoPanel(title: "الأذان", value: nextTime, footer: remainingMinuteLabel, highlighted: true)
            }

            salatiMetaCapsule(Text(nextAzanTitle) + Text(" · متبقي ") + Text(remainingMinuteLabel).fontWeight(.black))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .multilineTextAlignment(.trailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(14)
    }

    private func salatiTopline(_ title: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accent)
                .frame(width: 9, height: 9)
                .shadow(color: accent.opacity(0.55), radius: 7)

            Spacer(minLength: 8)

            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    private func salatiTimeCapsule(_ value: String, fontSize: CGFloat) -> some View {
        Text(value)
            .font(.system(size: fontSize, weight: .black, design: .rounded).monospacedDigit())
            .foregroundColor(accent)
            .lineLimit(1)
            .minimumScaleFactor(0.58)
            .padding(.horizontal, fontSize > 38 ? 18 : 14)
            .padding(.vertical, fontSize > 38 ? 10 : 8)
            .background(
                Capsule(style: .continuous)
                    .fill(capsuleFill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(capsuleStroke, lineWidth: 1)
            )
    }

    private func salatiMetaCapsule(_ content: Text, compact: Bool = false) -> some View {
        content
            .font(.system(size: compact ? 10 : 11, weight: .bold, design: .rounded).monospacedDigit())
            .foregroundColor(secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.54)
            .padding(.horizontal, compact ? 10 : 14)
            .padding(.vertical, compact ? 5 : 8)
            .background(
                Capsule(style: .continuous)
                    .fill(faintCapsuleFill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(capsuleStroke.opacity(0.78), lineWidth: 1)
            )
    }

    private func salatiInfoPanel(title: String, value: String, footer: String, highlighted: Bool) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(secondaryText)
                .lineLimit(1)

            salatiTimeCapsule(value, fontSize: 28)

            Text(footer)
                .font(.system(size: 10, weight: .black, design: .rounded).monospacedDigit())
                .foregroundColor(secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.66)
        }
        .frame(maxWidth: .infinity, minHeight: 86)
        .padding(.horizontal, 9)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(highlighted ? capsuleFill : capsuleFill.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(capsuleStroke, lineWidth: 1)
        )
    }

    private var upcomingPrayerRows: [PrayerTime] {
        let upcoming = displayEntry.times.filter { $0.date >= renderDate }
        return upcoming.isEmpty ? Array(displayEntry.times.prefix(3)) : Array(upcoming.prefix(3))
    }

    private func clockText(for date: Date) -> String {
        let components = PrayerEngine.calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private func iqamaOffsetMinutes(for key: PrayerKey) -> Int? {
        switch key {
        case .fajr:
            return 25
        case .dhuhr:
            return 15
        case .asr:
            return 17
        case .maghrib:
            return 8
        case .isha:
            return 15
        case .sunrise:
            return nil
        }
    }

    private var compactRemainingValue: String {
        guard let nextDate = displayEntry.nextPrayer?.date else { return "--" }
        let seconds = max(Int(nextDate.timeIntervalSince(renderDate)), 0)
        let minutes = max((seconds + 59) / 60, 1)

        return hourMinuteText(fromMinutes: minutes)
    }

    private var prayerProgress: CGFloat {
        guard let previous = displayEntry.previousPrayer, let next = displayEntry.nextPrayer else { return 0 }
        let total = max(next.date.timeIntervalSince(previous.date), 1)
        let elapsed = min(max(renderDate.timeIntervalSince(previous.date), 0), total)

        return CGFloat(elapsed / total)
    }

    private func countdownProgressBar(height: CGFloat) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                Capsule()
                    .fill(chipBackground.opacity(0.64))

                Capsule()
                    .fill(accent)
                    .frame(width: max(height, proxy.size.width * prayerProgress))
                    .shadow(color: accent.opacity(0.24), radius: 5)
            }
        }
        .frame(height: height)
    }

    private func hourMinuteText(fromMinutes minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    private func mediumPrayerRow(_ item: PrayerTime) -> some View {
        let isActive = item.key == displayEntry.nextPrayer?.key

        return HStack(spacing: 6) {
            Text(item.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer(minLength: 2)

            Text(item.time)
                .font(.system(size: 13, weight: .black, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundColor(isActive ? accent : mutedText)
        .padding(.horizontal, 7)
        .frame(height: 18)
        .background(isActive ? activeRowBackground : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }

    private func schedulePrayerRow(_ item: PrayerTime, height: CGFloat) -> some View {
        let isActive = item.key == displayEntry.nextPrayer?.key

        return HStack(spacing: 8) {
            Text(item.time)
                .font(.system(size: height > 24 ? 13 : 12, weight: .black, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(
                    Capsule(style: .continuous)
                        .fill(isActive ? Color.white.opacity(0.22) : capsuleFill.opacity(0.72))
                )

            Spacer(minLength: 4)

            Text(item.title)
                .font(.system(size: height > 24 ? 14 : 13, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .foregroundColor(isActive ? .white : primaryText)
        .padding(.horizontal, 10)
        .frame(height: height)
        .background(isActive ? accent : faintCapsuleFill)
        .overlay(
            Capsule(style: .continuous)
                .stroke(isActive ? accent.opacity(0.62) : capsuleStroke.opacity(0.76), lineWidth: 1)
        )
        .clipShape(Capsule(style: .continuous))
    }

    @ViewBuilder
    private var lockScreenLayout: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            switch family {
            case .accessoryInline:
                Label {
                    Text("\(nextAzanTitle) \(nextTime) · متبقي \(remainingMinuteLabel)")
                } icon: {
                    Image(systemName: "clock.fill")
                }
            case .accessoryCircular:
                SalatiLockCircleWidgetView(entry: entry, kind: .prayerTime)
            case .accessoryRectangular:
                VStack(alignment: .trailing, spacing: 3) {
                    Text("الآن")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .opacity(0.82)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(nextTime)
                            .font(.system(size: 20, weight: .black, design: .rounded).monospacedDigit())
                            .lineLimit(1)

                        Text(nextAzanTitle)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }

                    Text("الإقامة \(nextIqamaTime ?? "--:--") · متبقي \(remainingMinuteLabel)")
                        .font(.system(size: 11, weight: .black, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                        .opacity(0.86)

                    Text(compactElapsedText)
                        .font(.system(size: 9, weight: .semibold, design: .rounded).monospacedDigit())
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                        .opacity(0.74)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
                .environment(\.layoutDirection, .leftToRight)
            default:
                smallHomeLayout
            }
        } else {
            smallHomeLayout
        }
    }
}

enum TelShevaWidgetPresentation {
    case nextPrayer
    case schedule
    case countdown
}

@available(iOSApplicationExtension 16.0, *)
private enum SalatiLockCircleKind: String {
    case prayerTime
    case iqamaMinutes
    case iqamaTime
    case nextCountdown
    case sunriseTime

    var widgetKind: String {
        "com.omaralasam.telshevaazan.lockCircle.\(rawValue).v5"
    }

    var displayName: String {
        switch self {
        case .prayerTime:
            return "وقت الصلاة"
        case .iqamaMinutes:
            return "مدة الإقامة"
        case .iqamaTime:
            return "وقت الإقامة"
        case .nextCountdown:
            return "المتبقي للصلاة"
        case .sunriseTime:
            return "الشروق"
        }
    }

    var description: String {
        switch self {
        case .prayerTime:
            return "دائرة شاشة القفل تعرض الصلاة القادمة ووقتها."
        case .iqamaMinutes:
            return "دائرة شاشة القفل تعرض مدة الإقامة للصلاة القادمة."
        case .iqamaTime:
            return "دائرة شاشة القفل تعرض وقت إقامة الصلاة القادمة."
        case .nextCountdown:
            return "دائرة شاشة القفل تعرض المتبقي للصلاة القادمة."
        case .sunriseTime:
            return "دائرة شاشة القفل تعرض وقت الشروق."
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
private struct SalatiLockCircleWidgetView: View {
    let entry: TelShevaWidgetEntry
    let kind: SalatiLockCircleKind

    private var displayEntry: TelShevaWidgetEntry {
        TelShevaWidgetProvider.displayEntry(from: entry)
    }

    private var renderDate: Date {
        displayEntry.date
    }

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            ringLayer

            switch kind {
            case .prayerTime:
                circleStack(
                    title: displayEntry.nextPrayer?.title ?? "الصلاة",
                    value: displayEntry.nextPrayer?.time ?? "--:--",
                    valueSize: 14,
                    titleSize: 9,
                    footer: "أذان"
                )
            case .iqamaMinutes:
                circleStack(
                    title: nil,
                    value: iqamaMinuteValue(for: displayEntry.nextPrayer),
                    valueSize: 24,
                    titleSize: 10,
                    footer: "إقامة"
                )
            case .iqamaTime:
                circleStack(
                    title: "الإقامة",
                    value: iqamaTimeValue(for: displayEntry.nextPrayer),
                    valueSize: 13,
                    titleSize: 8,
                    footer: nil
                )
            case .nextCountdown:
                circleStack(
                    title: nil,
                    value: remainingValue(until: displayEntry.nextPrayer?.date),
                    valueSize: 22,
                    titleSize: 10,
                    footer: remainingUnit(until: displayEntry.nextPrayer?.date)
                )
            case .sunriseTime:
                circleStack(
                    title: "الشروق",
                    value: prayer(.sunrise)?.time ?? "--:--",
                    valueSize: 13,
                    titleSize: 8,
                    footer: nil
                )
            }
        }
        .dynamicTypeSize(.xSmall ... .small)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var ringLayer: some View {
        ZStack {
            if usesOpenGauge {
                Circle()
                    .trim(from: 0.14, to: 0.86)
                    .stroke(.white.opacity(0.36), style: StrokeStyle(lineWidth: 5.2, lineCap: .round))
                    .rotationEffect(.degrees(115))

                Circle()
                    .trim(from: 0.14, to: 0.14 + (0.72 * progress))
                    .stroke(.white, style: StrokeStyle(lineWidth: 5.2, lineCap: .round))
                    .rotationEffect(.degrees(115))
            } else {
                Circle()
                    .stroke(.white.opacity(0.36), style: StrokeStyle(lineWidth: 5.2, lineCap: .round))

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 5.2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(5.5)
    }

    private func circleStack(title: String?, value: String, valueSize: CGFloat, titleSize: CGFloat, footer: String?) -> some View {
        VStack(spacing: 1) {
            if let title {
                Text(title)
                    .font(.system(size: titleSize, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            Text(value)
                .font(.system(size: valueSize, weight: .black, design: .rounded).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.48)

            if let footer {
                Text(footer)
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .opacity(0.86)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .padding(10)
    }

    private var usesOpenGauge: Bool {
        kind == .iqamaMinutes || kind == .nextCountdown || kind == .sunriseTime
    }

    private var progress: CGFloat {
        switch kind {
        case .prayerTime:
            return intervalProgress
        case .iqamaMinutes:
            return iqamaProgress
        case .iqamaTime:
            return iqamaProgress
        case .nextCountdown:
            return intervalProgress
        case .sunriseTime:
            return 0.38
        }
    }

    private var intervalProgress: CGFloat {
        guard let previous = displayEntry.previousPrayer,
              let next = displayEntry.nextPrayer else {
            return 0.58
        }

        let total = next.date.timeIntervalSince(previous.date)
        guard total > 0 else { return 0.58 }

        return clampedProgress(renderDate.timeIntervalSince(previous.date) / total)
    }

    private var iqamaProgress: CGFloat {
        if let previous = displayEntry.previousPrayer,
           let minutes = iqamaOffsetMinutes(for: previous.key) {
            let iqamaDate = previous.date.addingTimeInterval(TimeInterval(minutes * 60))

            if renderDate >= previous.date && renderDate <= iqamaDate {
                return clampedProgress(renderDate.timeIntervalSince(previous.date) / max(iqamaDate.timeIntervalSince(previous.date), 1))
            }
        }

        return 0.68
    }

    private func clampedProgress(_ value: TimeInterval) -> CGFloat {
        CGFloat(min(max(value, 0.06), 0.98))
    }

    private func prayer(_ key: PrayerKey) -> PrayerTime? {
        displayEntry.times.first { $0.key == key }
    }

    private func remainingValue(until targetDate: Date?) -> String {
        guard let targetDate else { return "--:--" }
        let seconds = max(Int(targetDate.timeIntervalSince(renderDate)), 0)
        let minutes = (seconds + 59) / 60

        if minutes < 100 {
            return "\(minutes)"
        }

        return String(format: "%d:%02d", minutes / 60, minutes % 60)
    }

    private func remainingUnit(until targetDate: Date?) -> String {
        guard let targetDate else { return "متبقي" }
        let seconds = max(Int(targetDate.timeIntervalSince(renderDate)), 0)
        let minutes = (seconds + 59) / 60
        return minutes < 100 ? "دقيقة" : "متبقي"
    }

    private func iqamaMinuteValue(for prayer: PrayerTime?) -> String {
        guard let prayer, let minutes = iqamaOffsetMinutes(for: prayer.key) else {
            return "--"
        }

        return "\(minutes)"
    }

    private func iqamaTimeValue(for prayer: PrayerTime?) -> String {
        guard let prayer, let minutes = iqamaOffsetMinutes(for: prayer.key) else {
            return "--:--"
        }

        return clockText(for: prayer.date.addingTimeInterval(TimeInterval(minutes * 60)))
    }

    private func clockText(for date: Date) -> String {
        let components = PrayerEngine.calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private func iqamaOffsetMinutes(for key: PrayerKey) -> Int? {
        switch key {
        case .fajr:
            return 25
        case .dhuhr:
            return 15
        case .asr:
            return 17
        case .maghrib:
            return 8
        case .isha:
            return 15
        case .sunrise:
            return nil
        }
    }

}

@available(iOSApplicationExtension 16.0, *)
private struct SalatiPrayerTimeLockCircleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SalatiLockCircleKind.prayerTime.widgetKind, provider: TelShevaWidgetProvider()) { entry in
            SalatiLockCircleWidgetView(entry: entry, kind: .prayerTime)
        }
        .configurationDisplayName(SalatiLockCircleKind.prayerTime.displayName)
        .description(SalatiLockCircleKind.prayerTime.description)
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOSApplicationExtension 16.0, *)
private struct SalatiIqamaMinutesLockCircleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SalatiLockCircleKind.iqamaMinutes.widgetKind, provider: TelShevaWidgetProvider()) { entry in
            SalatiLockCircleWidgetView(entry: entry, kind: .iqamaMinutes)
        }
        .configurationDisplayName(SalatiLockCircleKind.iqamaMinutes.displayName)
        .description(SalatiLockCircleKind.iqamaMinutes.description)
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOSApplicationExtension 16.0, *)
private struct SalatiIqamaTimeLockCircleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SalatiLockCircleKind.iqamaTime.widgetKind, provider: TelShevaWidgetProvider()) { entry in
            SalatiLockCircleWidgetView(entry: entry, kind: .iqamaTime)
        }
        .configurationDisplayName(SalatiLockCircleKind.iqamaTime.displayName)
        .description(SalatiLockCircleKind.iqamaTime.description)
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOSApplicationExtension 16.0, *)
private struct SalatiNextCountdownLockCircleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SalatiLockCircleKind.nextCountdown.widgetKind, provider: TelShevaWidgetProvider()) { entry in
            SalatiLockCircleWidgetView(entry: entry, kind: .nextCountdown)
        }
        .configurationDisplayName(SalatiLockCircleKind.nextCountdown.displayName)
        .description(SalatiLockCircleKind.nextCountdown.description)
        .supportedFamilies([.accessoryCircular])
    }
}

@available(iOSApplicationExtension 16.0, *)
private struct SalatiSunriseLockCircleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SalatiLockCircleKind.sunriseTime.widgetKind, provider: TelShevaWidgetProvider()) { entry in
            SalatiLockCircleWidgetView(entry: entry, kind: .sunriseTime)
        }
        .configurationDisplayName(SalatiLockCircleKind.sunriseTime.displayName)
        .description(SalatiLockCircleKind.sunriseTime.description)
        .supportedFamilies([.accessoryCircular])
    }
}

private enum SalatiWidgetDateText {
    private static let gregorianLongFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "EEEE، d MMMM yyyy"
        return formatter
    }()

    private static let gregorianShortFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "d MMMM"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "EEEE"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let hijriFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "d MMMM yyyy هـ"
        return formatter
    }()

    static func gregorianLong(for date: Date) -> String {
        latinDigits(gregorianLongFormatter.string(from: date))
    }

    static func gregorianShort(for date: Date) -> String {
        latinDigits(gregorianShortFormatter.string(from: date))
    }

    static func weekday(for date: Date) -> String {
        weekdayFormatter.string(from: date)
    }

    static func dayNumber(for date: Date) -> String {
        latinDigits(dayFormatter.string(from: date))
    }

    static func hijri(for date: Date) -> String {
        latinDigits(hijriFormatter.string(from: date))
    }

    private static func latinDigits(_ text: String) -> String {
        let replacements: [Character: Character] = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9",
            "۰": "0", "۱": "1", "۲": "2", "۳": "3", "۴": "4",
            "۵": "5", "۶": "6", "۷": "7", "۸": "8", "۹": "9"
        ]

        return String(text.map { replacements[$0] ?? $0 })
    }
}

private struct SalatiDateWidgetView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: TelShevaWidgetEntry

    private var displayEntry: TelShevaWidgetEntry {
        TelShevaWidgetProvider.displayEntry(from: entry)
    }

    var body: some View {
        Group {
            if isLockScreenFamily {
                lockScreenBody
            } else {
                homeBody
            }
        }
        .dynamicTypeSize(.xSmall ... .large)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var isNight: Bool {
        colorScheme == .dark
    }

    private var accent: Color {
        Color(red: 0.16, green: 0.53, blue: 1.0)
    }

    private var primaryText: Color {
        isNight ? .white : Color(red: 0.02, green: 0.06, blue: 0.11)
    }

    private var secondaryText: Color {
        isNight ? Color.white.opacity(0.72) : Color(red: 0.25, green: 0.33, blue: 0.42)
    }

    private var isLockScreenFamily: Bool {
        if #available(iOSApplicationExtension 16.0, *) {
            return family == .accessoryInline || family == .accessoryCircular || family == .accessoryRectangular
        }

        return false
    }

    @ViewBuilder
    private var lockScreenBody: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            switch family {
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 1) {
                        Text(SalatiWidgetDateText.dayNumber(for: displayEntry.date))
                            .font(.system(size: 25, weight: .black, design: .rounded).monospacedDigit())
                            .lineLimit(1)

                        Text(SalatiWidgetDateText.weekday(for: displayEntry.date))
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                    }
                    .padding(8)
                }
            case .accessoryRectangular:
                VStack(alignment: .trailing, spacing: 2) {
                    Text(SalatiWidgetDateText.gregorianShort(for: displayEntry.date))
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .lineLimit(1)
                    Text(SalatiWidgetDateText.hijri(for: displayEntry.date))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)
                        .opacity(0.74)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            case .accessoryInline:
                Text("\(SalatiWidgetDateText.weekday(for: displayEntry.date)) · \(SalatiWidgetDateText.hijri(for: displayEntry.date))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
            default:
                homeBody
            }
        } else {
            homeBody
        }
    }

    private var homeBody: some View {
        ZStack {
            background
                .ignoresSafeArea()

            if family == .systemMedium {
                mediumHomeBody
            } else {
                smallHomeBody
            }
        }
        .widgetContainerBackground {
            background
        }
    }

    private var smallHomeBody: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Circle()
                    .fill(accent)
                    .frame(width: 12, height: 12)
                Spacer()
                Text("تاريخ اليوم")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(secondaryText)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 3) {
                Text(SalatiWidgetDateText.weekday(for: displayEntry.date))
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)

                Text(SalatiWidgetDateText.dayNumber(for: displayEntry.date))
                    .font(.system(size: 58, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            dateCapsule(text: SalatiWidgetDateText.hijri(for: displayEntry.date))
        }
        .padding(18)
    }

    private var mediumHomeBody: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                Text(SalatiWidgetDateText.dayNumber(for: displayEntry.date))
                    .font(.system(size: 64, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(accent)
                    .lineLimit(1)

                Text(SalatiWidgetDateText.weekday(for: displayEntry.date))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
            }
            .frame(width: 104)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(isNight ? Color.white.opacity(0.06) : Color.white.opacity(0.48))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(isNight ? 0.10 : 0.75), lineWidth: 1.2)
                    )
            )

            VStack(alignment: .trailing, spacing: 11) {
                HStack {
                    Circle()
                        .fill(accent)
                        .frame(width: 10, height: 10)
                    Spacer()
                    Text("تاريخ اليوم")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(secondaryText)
                }

                Spacer(minLength: 0)

                Text(SalatiWidgetDateText.gregorianLong(for: displayEntry.date))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                dateCapsule(text: SalatiWidgetDateText.hijri(for: displayEntry.date))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(18)
    }

    private func dateCapsule(text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(secondaryText)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(
                Capsule()
                    .fill(isNight ? Color.white.opacity(0.075) : Color.white.opacity(0.54))
                    .overlay(Capsule().stroke(Color.white.opacity(isNight ? 0.10 : 0.82), lineWidth: 1))
            )
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: isNight
                    ? [
                        Color(red: 0.01, green: 0.04, blue: 0.07),
                        Color(red: 0.02, green: 0.12, blue: 0.21),
                        Color.black
                    ]
                    : [
                        Color(red: 0.91, green: 0.97, blue: 1.0),
                        Color(red: 0.76, green: 0.88, blue: 0.95),
                        Color(red: 0.98, green: 0.99, blue: 1.0)
                    ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )

            RadialGradient(
                colors: [accent.opacity(isNight ? 0.22 : 0.18), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 190
            )
        }
    }
}

private struct SalatiDateWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.date.today.v5"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
            SalatiDateWidgetView(entry: entry)
        }
        .configurationDisplayName("تاريخ اليوم")
        .description("يعرض التاريخ الميلادي والهجري بتصميم صلاتي.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct TelShevaAzanWidgetBundle: WidgetBundle {
    var body: some Widget {
#if WIDGET_V3
        TelShevaAzanLegacyWidget()
#else
        TelShevaAzanWidget()
        TelShevaAzanScheduleWidget()
        TelShevaAzanCountdownWidget()
        SalatiDateWidget()
        if #available(iOSApplicationExtension 16.0, *) {
            SalatiPrayerTimeLockCircleWidget()
            SalatiIqamaMinutesLockCircleWidget()
            SalatiIqamaTimeLockCircleWidget()
            SalatiNextCountdownLockCircleWidget()
            SalatiSunriseLockCircleWidget()
        }
#endif
    }
}

struct TelShevaAzanWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.nextPrayer.v5"

    var body: some WidgetConfiguration {
        if #available(iOSApplicationExtension 16.0, *) {
            StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
                TelShevaAzanWidgetView(entry: entry)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .configurationDisplayName("الصلاة القادمة")
            .description("يعرض الصلاة القادمة ووقت الأذان والمتبقي عليها.")
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular])
        } else {
            StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
                TelShevaAzanWidgetView(entry: entry)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .configurationDisplayName("الصلاة القادمة")
            .description("يعرض الصلاة القادمة ووقت الأذان والمتبقي عليها.")
            .supportedFamilies([.systemSmall, .systemMedium])
        }
    }
}

struct TelShevaAzanLegacyWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.nextPrayer.clean.v5"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
            TelShevaAzanWidgetView(entry: entry)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .configurationDisplayName("الصلاة القادمة")
        .description("يعرض الصلاة القادمة ووقت الأذان والمتبقي عليها.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct TelShevaAzanScheduleWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.dailySchedule.v5"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
            TelShevaAzanWidgetView(entry: entry, presentation: .schedule)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .configurationDisplayName("جدول الصلاة")
        .description("ودجت جديد يعرض مواقيت اليوم والصلاة القادمة.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct TelShevaAzanCountdownWidget: Widget {
    let kind = "com.omaralasam.telshevaazan.countdown.v5"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TelShevaWidgetProvider()) { entry in
            TelShevaAzanWidgetView(entry: entry, presentation: .countdown)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .configurationDisplayName("عداد الصلاة")
        .description("ودجت زجاجي يركز على الوقت المتبقي للصلاة القادمة.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private extension View {
    @ViewBuilder
    func widgetContainerBackground<Background: View>(@ViewBuilder _ background: () -> Background) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                background()
            }
        } else {
            self.background(background())
        }
    }
}
