import Foundation
import WidgetKit

struct SalatiWidgetEntry: TimelineEntry {
    let date: Date
    let dateKey: String
    let nextPrayer: PrayerTime?
    let times: [PrayerTime]

    var highlightedPrayer: PrayerKey? {
        guard let nextPrayer,
              PrayerEngine.defaultDateKey(for: nextPrayer.date) == dateKey else {
            return nil
        }
        return nextPrayer.key
    }

    var scheduleDate: Date {
        PrayerEngine.date(from: dateKey, time: "12:00") ?? date
    }

    var isTomorrowSchedule: Bool {
        dateKey != PrayerEngine.defaultDateKey(for: date)
    }

    var obligatoryTimes: [PrayerTime] {
        times.filter { $0.key != .sunrise }
    }

    var activeIqama: IqamaEvent? {
        IqamaSchedule.telSheva.activeEvent(at: date)
    }

    var focusedPrayer: PrayerTime? {
        activeIqama?.prayer ?? nextPrayer
    }

    var focusedTarget: Date? {
        activeIqama?.date ?? nextPrayer?.date
    }

    var focusedTime: String {
        if let activeIqama {
            return SalatiWidgetDateText.clock(for: activeIqama.date)
        }
        return nextPrayer?.time ?? SalatiText.noTime
    }

    var focusedTitle: String {
        activeIqama == nil ? SalatiText.nextPrayer : SalatiText.nextIqama
    }

    var focusedCountdownLabel: String {
        activeIqama == nil ? SalatiText.remaining : SalatiText.remainingUntilIqama
    }

    var followingPrayer: PrayerTime? {
        if activeIqama != nil {
            return nextPrayer
        }

        guard let nextPrayer else { return nil }

        if let following = obligatoryTimes.first(where: { $0.date > nextPrayer.date }) {
            return following
        }

        guard let nextDateKey = PrayerEngine.dateKey(from: dateKey, offset: 1) else {
            return nil
        }
        return PrayerEngine.schedule(for: nextDateKey).displayTimes.first { $0.key != .sunrise }
    }

    static var preview: SalatiWidgetEntry {
        let components = DateComponents(
            calendar: PrayerEngine.calendar,
            timeZone: PrayerEngine.timeZone,
            year: 2026,
            month: 7,
            day: 20,
            hour: 20,
            minute: 42
        )
        return SalatiWidgetProvider.makeEntry(for: PrayerEngine.calendar.date(from: components) ?? Date())
    }
}

struct SalatiWidgetProvider: TimelineProvider {
    private static let timelineDays = 7

    func placeholder(in context: Context) -> SalatiWidgetEntry {
        Self.makeEntry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SalatiWidgetEntry) -> Void) {
        completion(Self.makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalatiWidgetEntry>) -> Void) {
        let now = Date()
        let transitionDates = Self.transitionDates(after: now)
        let entries = transitionDates.map(Self.makeEntry(for:))
        let refreshDate = transitionDates.last?.addingTimeInterval(60) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(refreshDate)))
    }

    static func makeEntry(for date: Date) -> SalatiWidgetEntry {
        let dateKey = PrayerEngine.automaticScheduleDateKey(for: date)
        return SalatiWidgetEntry(
            date: date,
            dateKey: dateKey,
            nextPrayer: PrayerEngine.nextPrayer(for: dateKey, now: date),
            times: PrayerEngine.schedule(for: dateKey).displayTimes
        )
    }

    private static func transitionDates(after now: Date) -> [Date] {
        let start = PrayerEngine.calendar.startOfDay(for: now)
        var dates: Set<Date> = [now]

        for offset in 0...timelineDays {
            guard let day = PrayerEngine.calendar.date(byAdding: .day, value: offset, to: start) else {
                continue
            }
            let dateKey = PrayerEngine.defaultDateKey(for: day)

            for prayer in PrayerEngine.schedule(for: dateKey).displayTimes where prayer.key != .sunrise {
                Self.insertTransition(after: prayer.date, now: now, into: &dates)

                if let iqamaDate = IqamaSchedule.telSheva.iqamaDate(for: prayer) {
                    Self.insertTransition(after: iqamaDate, now: now, into: &dates)
                }
            }

            if let nextDay = PrayerEngine.calendar.date(byAdding: .day, value: 1, to: day) {
                Self.insertTransition(after: nextDay, now: now, into: &dates)
            }
        }

        return dates.sorted()
    }

    private static func insertTransition(after eventDate: Date, now: Date, into dates: inout Set<Date>) {
        let transition = eventDate.addingTimeInterval(1)
        guard transition > now else { return }
        dates.insert(Date(timeIntervalSince1970: transition.timeIntervalSince1970.rounded()))
    }
}

enum SalatiWidgetDateText {
    private static let gregorianFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = PrayerEngine.calendar
        formatter.locale = Locale(identifier: "ar")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "d MMMM"
        return formatter
    }()

    private static let hijriFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.locale = Locale(identifier: "ar")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "d MMMM"
        return formatter
    }()

    static func compact(for date: Date) -> String {
        "\(latinDigits(gregorianFormatter.string(from: date)))  •  \(latinDigits(hijriFormatter.string(from: date)))"
    }

    static func clock(for date: Date) -> String {
        let components = PrayerEngine.calendar.dateComponents([.hour, .minute], from: date)
        return String(
            format: "%02d:%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            components.hour ?? 0,
            components.minute ?? 0
        )
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
