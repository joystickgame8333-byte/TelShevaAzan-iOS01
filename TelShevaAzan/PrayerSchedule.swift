import Foundation

enum PrayerKey: String, CaseIterable, Hashable, Identifiable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fajr:
            return "الفجر"
        case .sunrise:
            return "الشروق"
        case .dhuhr:
            return "الظهر"
        case .asr:
            return "العصر"
        case .maghrib:
            return "المغرب"
        case .isha:
            return "العشاء"
        }
    }
}

struct PrayerTime: Identifiable {
    let key: PrayerKey
    let title: String
    let time: String
    let date: Date

    var id: String { key.rawValue }
}

struct DaySchedule {
    let dateKey: String
    let times: [PrayerKey: String]

    var displayTimes: [PrayerTime] {
        PrayerEngine.displayOrder.compactMap { key in
            guard let time = times[key],
                  let date = PrayerEngine.date(from: dateKey, time: time) else {
                return nil
            }

            return PrayerTime(key: key, title: key.title, time: time, date: date)
        }
    }
}

struct IqamaSchedule {
    let locationID: String
    let locationName: String
    private let delaysMinutes: [PrayerKey: Int]

    static let telSheva = IqamaSchedule(
        locationID: "telSheva",
        locationName: "تل السبع",
        delaysMinutes: [
            .fajr: 24,
            .dhuhr: 14,
            .asr: 16,
            .maghrib: 7,
            .isha: 14
        ]
    )

    func iqamaDate(for prayer: PrayerTime) -> Date? {
        guard let delayMinutes = delaysMinutes[prayer.key] else { return nil }
        return prayer.date.addingTimeInterval(TimeInterval(delayMinutes * 60))
    }

    func activeEvent(at date: Date = Date()) -> IqamaEvent? {
        let dateKey = PrayerEngine.defaultDateKey(for: date)

        return PrayerEngine.schedule(for: dateKey).displayTimes.compactMap { prayer in
            guard prayer.key != .sunrise,
                  prayer.date <= date,
                  let iqamaDate = iqamaDate(for: prayer),
                  date < iqamaDate else {
                return nil
            }

            return IqamaEvent(prayer: prayer, date: iqamaDate)
        }
        .first
    }
}

struct IqamaEvent {
    let prayer: PrayerTime
    let date: Date
    var isPreview = false
}

enum IqamaPreviewStorage {
    static let expirationKey = "iqama_countdown_preview_expiration"
    static let prayerKey = "iqama_countdown_preview_prayer"
    static let duration: TimeInterval = 2 * 60
    static let defaults = UserDefaults(
        suiteName: "group.com.omaralasam.telshevaazan"
    ) ?? .standard

    @discardableResult
    static func start(
        prayer: PrayerKey = .dhuhr,
        at date: Date = Date()
    ) -> Date {
        let expiration = date.addingTimeInterval(duration)
        defaults.set(expiration.timeIntervalSince1970, forKey: expirationKey)
        defaults.set(prayer.rawValue, forKey: prayerKey)
        defaults.synchronize()
        return expiration
    }

    static func activeEvent(
        at date: Date = Date(),
        dateKey: String? = nil
    ) -> IqamaEvent? {
        let expiration = expirationDate
        guard expiration > date else { return nil }

        let selectedKey = defaults.string(forKey: prayerKey)
            .flatMap(PrayerKey.init(rawValue:)) ?? .dhuhr
        let scheduleKey = dateKey ?? PrayerEngine.automaticScheduleDateKey(for: date)
        let prayer = PrayerEngine.schedule(for: scheduleKey).displayTimes.first {
            $0.key == selectedKey
        }

        return prayer.map {
            IqamaEvent(prayer: $0, date: expiration, isPreview: true)
        }
    }

    static var expirationDate: Date {
        Date(timeIntervalSince1970: defaults.double(forKey: expirationKey))
    }
}

enum PrayerEngine {
    static let timeZone = TimeZone(identifier: "Asia/Jerusalem")!
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = Self.timeZone
        return calendar
    }()
    private static let posixLocale = Locale(identifier: "en_US_POSIX")
    private static let longArabicDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.timeZone = Self.timeZone
        formatter.dateStyle = .full
        return formatter
    }()
    private static let hijriArabicDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.calendar = Calendar(identifier: .islamicUmmAlQura)
        formatter.timeZone = Self.timeZone
        formatter.dateStyle = .long
        return formatter
    }()

    static let prayerOrder: [PrayerKey] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
    static let displayOrder: [PrayerKey] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]


    static func defaultDateKey(for date: Date = Date()) -> String {
        Self.dateKey(for: date)
    }

    static func schedule(for dateKey: String) -> DaySchedule {
        if let date = Self.date(from: dateKey, time: "12:00"),
           let times = PalestinePrayerCalendar.schedule(for: date, calendar: Self.calendar) {
            return DaySchedule(dateKey: dateKey, times: times)
        }

        return DaySchedule(dateKey: dateKey, times: [:])
    }

    static func supportedDateRange(around date: Date = Date()) -> ClosedRange<Date> {
        let year = Self.calendar.component(.year, from: date)
        let start = Self.calendar.date(from: DateComponents(
            calendar: Self.calendar,
            timeZone: Self.timeZone,
            year: year - 2,
            month: 1,
            day: 1,
            hour: 0,
            minute: 0
        )) ?? date
        let end = Self.calendar.date(from: DateComponents(
            calendar: Self.calendar,
            timeZone: Self.timeZone,
            year: year + 5,
            month: 12,
            day: 31,
            hour: 23,
            minute: 59
        )) ?? date
        return start...end
    }

    static func upcomingDateKeys(from date: Date = Date(), count: Int = 60) -> [String] {
        guard count > 0 else { return [] }
        let start = Self.calendar.startOfDay(for: date)
        return (0..<count).compactMap { offset in
            guard let day = Self.calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return Self.dateKey(for: day)
        }
    }

    static func remainingSeconds(until date: Date, now: Date = Date()) -> Int {
        max(0, Int(date.timeIntervalSince(now).rounded(.up)))
    }

    static func elapsedSeconds(since date: Date, now: Date = Date()) -> Int {
        max(0, Int(now.timeIntervalSince(date).rounded(.down)))
    }

    static func nextPrayer(for dateKey: String, now: Date = Date()) -> PrayerTime? {
        let daySchedule = Self.schedule(for: dateKey)
        let events = Self.prayerEvents(for: dateKey)

        if daySchedule.dateKey == Self.dateKey(for: now), let upcoming = events.first(where: { $0.date > now }) {
            return upcoming
        }

        if daySchedule.dateKey == Self.dateKey(for: now),
           let nextDateKey = Self.dateKey(from: daySchedule.dateKey, offset: 1),
           let nextDayFirstPrayer = Self.prayerEvents(for: nextDateKey).first {
            return nextDayFirstPrayer
        }

        return events.first
    }

    static func automaticScheduleDateKey(for date: Date = Date()) -> String {
        let todayKey = Self.dateKey(for: date)
        let todaySchedule = Self.schedule(for: todayKey)

        guard let ishaTime = todaySchedule.times[.isha],
              let ishaDate = Self.date(from: todayKey, time: ishaTime),
              date >= ishaDate,
              let tomorrowKey = Self.dateKey(from: todayKey, offset: 1) else {
            return todayKey
        }

        return tomorrowKey
    }

    static func previousPrayer(for dateKey: String, now: Date = Date()) -> PrayerTime? {
        let daySchedule = Self.schedule(for: dateKey)
        let events = Self.prayerEvents(for: daySchedule.dateKey)

        if daySchedule.dateKey > Self.dateKey(for: now) {
            return nil
        }

        if daySchedule.dateKey == Self.dateKey(for: now) {
            if let previous = events.last(where: { $0.date <= now }) {
                return previous
            }

            if let previousDateKey = Self.dateKey(from: daySchedule.dateKey, offset: -1),
               let previousDayLastPrayer = Self.prayerEvents(for: previousDateKey).last {
                return previousDayLastPrayer
            }
        }

        return events.last
    }

    private static func prayerEvents(for dateKey: String) -> [PrayerTime] {
        let daySchedule = Self.schedule(for: dateKey)
        return Self.prayerOrder.compactMap { key -> PrayerTime? in
            guard let time = daySchedule.times[key],
                  let date = Self.date(from: daySchedule.dateKey, time: time) else {
                return nil
            }

            return PrayerTime(key: key, title: key.title, time: time, date: date)
        }
    }

    static func canMove(from dateKey: String, by offset: Int) -> Bool {
        Self.dateKey(from: dateKey, offset: offset) != nil
    }

    static func dateKey(from dateKey: String, offset: Int) -> String? {
        guard let date = Self.date(from: dateKey, time: "12:00"),
              let nextDate = Self.calendar.date(byAdding: .day, value: offset, to: date) else {
            return nil
        }
        return Self.dateKey(for: nextDate)
    }

    static func longDateLabel(for dateKey: String) -> String {
        guard let date = Self.date(from: dateKey, time: "12:00") else { return dateKey }
        return Self.latinDigits(Self.longArabicDateFormatter.string(from: date))
    }

    static func hijriDateLabel(for dateKey: String) -> String {
        guard let date = Self.date(from: dateKey, time: "12:00") else { return "" }
        return Self.latinDigits(Self.hijriArabicDateFormatter.string(from: date))
    }

    static func date(from dateKey: String, time: String) -> Date? {
        let dateParts = dateKey.split(separator: "-").compactMap { Int($0) }
        let timeParts = time.split(separator: ":").compactMap { Int($0) }
        guard dateParts.count == 3, timeParts.count == 2 else { return nil }

        var components = DateComponents()
        components.calendar = Self.calendar
        components.timeZone = Self.timeZone
        components.year = dateParts[0]
        components.month = dateParts[1]
        components.day = dateParts[2]
        components.hour = timeParts[0]
        components.minute = timeParts[1]
        return Self.calendar.date(from: components)
    }

    private static func dateKey(for date: Date) -> String {
        let components = Self.calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            locale: Self.posixLocale,
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
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

    private static func addMinutes(_ minutes: Int, to time: String) -> String {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return time }

        let total = (parts[0] * 60 + parts[1] + minutes + 1440) % 1440
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
