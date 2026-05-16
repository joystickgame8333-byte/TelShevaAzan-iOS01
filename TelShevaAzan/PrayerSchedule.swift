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

    private static let telShevaOffsetMinutes = 2
    private static let daylightSavingOffsetMinutes = 60

    private static let jerusalemMayWinter: [String: [PrayerKey: String]] = [
        "2026-05-01": [.fajr: "03:22", .sunrise: "04:50", .dhuhr: "11:36", .asr: "15:15", .maghrib: "18:26", .isha: "19:49"],
        "2026-05-02": [.fajr: "03:21", .sunrise: "04:49", .dhuhr: "11:36", .asr: "15:15", .maghrib: "18:27", .isha: "19:50"],
        "2026-05-03": [.fajr: "03:20", .sunrise: "04:48", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:27", .isha: "19:51"],
        "2026-05-04": [.fajr: "03:19", .sunrise: "04:47", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:28", .isha: "19:52"],
        "2026-05-05": [.fajr: "03:18", .sunrise: "04:46", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:29", .isha: "19:53"],
        "2026-05-06": [.fajr: "03:16", .sunrise: "04:45", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:29", .isha: "19:54"],
        "2026-05-07": [.fajr: "03:15", .sunrise: "04:44", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:30", .isha: "19:55"],
        "2026-05-08": [.fajr: "03:14", .sunrise: "04:43", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:31", .isha: "19:56"],
        "2026-05-09": [.fajr: "03:13", .sunrise: "04:43", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:31", .isha: "19:57"],
        "2026-05-10": [.fajr: "03:12", .sunrise: "04:42", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:32", .isha: "19:58"],
        "2026-05-11": [.fajr: "03:11", .sunrise: "04:41", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:33", .isha: "19:59"],
        "2026-05-12": [.fajr: "03:10", .sunrise: "04:40", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:34", .isha: "20:00"],
        "2026-05-13": [.fajr: "03:09", .sunrise: "04:40", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:34", .isha: "20:01"],
        "2026-05-14": [.fajr: "03:08", .sunrise: "04:39", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:35", .isha: "20:02"],
        "2026-05-15": [.fajr: "03:07", .sunrise: "04:38", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:36", .isha: "20:03"],
        "2026-05-16": [.fajr: "03:06", .sunrise: "04:38", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:36", .isha: "20:04"],
        "2026-05-17": [.fajr: "03:06", .sunrise: "04:37", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:37", .isha: "20:04"],
        "2026-05-18": [.fajr: "03:05", .sunrise: "04:37", .dhuhr: "11:35", .asr: "15:15", .maghrib: "18:37", .isha: "20:05"],
        "2026-05-19": [.fajr: "03:04", .sunrise: "04:36", .dhuhr: "11:35", .asr: "15:16", .maghrib: "18:38", .isha: "20:06"],
        "2026-05-20": [.fajr: "03:03", .sunrise: "04:35", .dhuhr: "11:35", .asr: "15:16", .maghrib: "18:39", .isha: "20:07"],
        "2026-05-21": [.fajr: "03:02", .sunrise: "04:35", .dhuhr: "11:35", .asr: "15:16", .maghrib: "18:39", .isha: "20:08"],
        "2026-05-22": [.fajr: "03:02", .sunrise: "04:34", .dhuhr: "11:35", .asr: "15:16", .maghrib: "18:40", .isha: "20:09"],
        "2026-05-23": [.fajr: "03:01", .sunrise: "04:34", .dhuhr: "11:35", .asr: "15:16", .maghrib: "18:41", .isha: "20:10"],
        "2026-05-24": [.fajr: "03:00", .sunrise: "04:34", .dhuhr: "11:35", .asr: "15:16", .maghrib: "18:41", .isha: "20:11"],
        "2026-05-25": [.fajr: "02:59", .sunrise: "04:33", .dhuhr: "11:36", .asr: "15:16", .maghrib: "18:42", .isha: "20:11"],
        "2026-05-26": [.fajr: "02:59", .sunrise: "04:33", .dhuhr: "11:36", .asr: "15:16", .maghrib: "18:42", .isha: "20:12"],
        "2026-05-27": [.fajr: "02:58", .sunrise: "04:32", .dhuhr: "11:36", .asr: "15:16", .maghrib: "18:43", .isha: "20:13"],
        "2026-05-28": [.fajr: "02:58", .sunrise: "04:32", .dhuhr: "11:36", .asr: "15:16", .maghrib: "18:44", .isha: "20:14"],
        "2026-05-29": [.fajr: "02:57", .sunrise: "04:32", .dhuhr: "11:36", .asr: "15:16", .maghrib: "18:44", .isha: "20:15"],
        "2026-05-30": [.fajr: "02:57", .sunrise: "04:31", .dhuhr: "11:36", .asr: "15:16", .maghrib: "18:45", .isha: "20:15"],
        "2026-05-31": [.fajr: "02:56", .sunrise: "04:31", .dhuhr: "11:36", .asr: "15:17", .maghrib: "18:45", .isha: "20:16"]
    ]

    static let telShevaSchedule: [String: [PrayerKey: String]] = {
        let totalOffset = Self.telShevaOffsetMinutes + Self.daylightSavingOffsetMinutes
        return Self.jerusalemMayWinter.mapValues { times in
            times.mapValues { Self.addMinutes(totalOffset, to: $0) }
        }
    }()

    static var availableDateKeys: [String] {
        Self.telShevaSchedule.keys.sorted()
    }

    static func defaultDateKey(for date: Date = Date()) -> String {
        let key = Self.dateKey(for: date)
        return Self.telShevaSchedule[key] == nil ? (Self.availableDateKeys.first ?? key) : key
    }

    static func schedule(for dateKey: String) -> DaySchedule {
        let resolvedKey = Self.telShevaSchedule[dateKey] == nil ? Self.defaultDateKey() : dateKey
        return DaySchedule(dateKey: resolvedKey, times: Self.telShevaSchedule[resolvedKey] ?? [:])
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

    static func previousPrayer(for dateKey: String, now: Date = Date()) -> PrayerTime? {
        let daySchedule = Self.schedule(for: dateKey)
        let events = Self.prayerEvents(for: daySchedule.dateKey)

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
        guard let index = Self.availableDateKeys.firstIndex(of: dateKey) else { return nil }
        let nextIndex = index + offset
        guard Self.availableDateKeys.indices.contains(nextIndex) else { return nil }
        return Self.availableDateKeys[nextIndex]
    }

    static func longDateLabel(for dateKey: String) -> String {
        guard let date = Self.date(from: dateKey, time: "12:00") else { return dateKey }
        return Self.longArabicDateFormatter.string(from: date)
    }

    static func hijriDateLabel(for dateKey: String) -> String {
        guard let date = Self.date(from: dateKey, time: "12:00") else { return "" }
        return Self.hijriArabicDateFormatter.string(from: date)
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

    private static func addMinutes(_ minutes: Int, to time: String) -> String {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return time }

        let total = (parts[0] * 60 + parts[1] + minutes + 1440) % 1440
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}
