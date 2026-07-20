import Foundation

private struct PalestinePrayerCalendarPayload: Codable {
    let schemaVersion: Int
    let revision: Int
    let sourceName: String
    let sourceURL: String
    let baseLocation: String
    let baseTimeStandard: String
    let cityOffsetsMinutes: [String: Int]
    let days: [String: PalestinePrayerCalendarDay]
}

private struct PalestinePrayerCalendarDay: Codable {
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String

    func time(for key: PrayerKey) -> String {
        switch key {
        case .fajr: return fajr
        case .sunrise: return sunrise
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }
}

private final class PalestinePrayerCalendarBundleToken {}

enum PalestinePrayerCalendar {
    private static let resourceName = "prayer-calendar-v1"
    private static let cityKey = "telSheva"
    private static let cacheKey = "prayerCalendar.remotePayload.v1"
    private static let lastRefreshKey = "prayerCalendar.lastRemoteRefresh.v1"
    private static let refreshInterval: TimeInterval = 24 * 60 * 60
    private static let remoteURL = URL(
        string: "https://raw.githubusercontent.com/joystickgame8333-byte/TelShevaAzan-iOS01/main/TelShevaAzan/Resources/PrayerCalendar/prayer-calendar-v1.json"
    )!

    private static let stateLock = NSLock()
    private static var activePayload: PalestinePrayerCalendarPayload = loadInitialPayload()

    private static let sharedDefaults: UserDefaults = {
        #if os(watchOS)
        return .standard
        #else
        return UserDefaults(suiteName: "group.com.omaralasam.telshevaazan") ?? .standard
        #endif
    }()

    static var dataRevision: Int {
        stateLock.lock()
        defer { stateLock.unlock() }
        return activePayload.revision
    }

    static func schedule(for date: Date, calendar: Calendar) -> [PrayerKey: String]? {
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else { return nil }
        let dateKey = String(format: "%02d-%02d", locale: Locale(identifier: "en_US_POSIX"), month, day)

        stateLock.lock()
        let payload = activePayload
        stateLock.unlock()

        guard let sourceDay = payload.days[dateKey],
              let cityOffset = payload.cityOffsetsMinutes[cityKey] else {
            return nil
        }

        let midday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
        let daylightSavingOffset = calendar.timeZone.daylightSavingTimeOffset(for: midday) == 0 ? 0 : 60
        let totalOffset = cityOffset + daylightSavingOffset

        return Dictionary(uniqueKeysWithValues: PrayerEngine.displayOrder.map { key in
            (key, offset(sourceDay.time(for: key), by: totalOffset))
        })
    }

    static func refreshRemoteIfNeeded(
        force: Bool = false,
        now: Date = Date(),
        completion: @escaping (Bool) -> Void = { _ in }
    ) {
        let lastRefresh = sharedDefaults.object(forKey: lastRefreshKey) as? Date ?? .distantPast
        guard force || now.timeIntervalSince(lastRefresh) >= refreshInterval else {
            completion(false)
            return
        }

        sharedDefaults.set(now, forKey: lastRefreshKey)
        var request = URLRequest(url: remoteURL)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadIgnoringLocalCacheData

        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let data,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let remotePayload = decodedPayload(from: data) else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            stateLock.lock()
            let shouldUpdate = remotePayload.revision > activePayload.revision
            if shouldUpdate {
                activePayload = remotePayload
            }
            stateLock.unlock()

            if shouldUpdate {
                sharedDefaults.set(data, forKey: cacheKey)
            }
            DispatchQueue.main.async { completion(shouldUpdate) }
        }.resume()
    }

    private static func loadInitialPayload() -> PalestinePrayerCalendarPayload {
        guard let bundledPayload = bundledPayload() else {
            fatalError("The official Palestine prayer calendar resource is missing or invalid.")
        }

        guard let cachedData = sharedDefaults.data(forKey: cacheKey),
              let cachedPayload = decodedPayload(from: cachedData),
              cachedPayload.revision >= bundledPayload.revision else {
            return bundledPayload
        }
        return cachedPayload
    }

    private static func bundledPayload() -> PalestinePrayerCalendarPayload? {
        let bundles = [Bundle(for: PalestinePrayerCalendarBundleToken.self), .main]
        for bundle in bundles {
            let candidateURLs = [
                bundle.url(forResource: resourceName, withExtension: "json", subdirectory: "PrayerCalendar"),
                bundle.url(forResource: resourceName, withExtension: "json")
            ]
            for case let url? in candidateURLs {
                if let data = try? Data(contentsOf: url), let payload = decodedPayload(from: data) {
                    return payload
                }
            }
        }
        return nil
    }

    private static func decodedPayload(from data: Data) -> PalestinePrayerCalendarPayload? {
        guard let payload = try? JSONDecoder().decode(PalestinePrayerCalendarPayload.self, from: data),
              isValid(payload) else {
            return nil
        }
        return payload
    }

    private static func isValid(_ payload: PalestinePrayerCalendarPayload) -> Bool {
        guard payload.schemaVersion == 1,
              payload.revision > 0,
              payload.baseLocation == "jerusalem",
              payload.baseTimeStandard == "winter",
              payload.cityOffsetsMinutes[cityKey] == 2,
              Set(payload.days.keys) == expectedDateKeys else {
            return false
        }

        return payload.days.values.allSatisfy { day in
            PrayerEngine.displayOrder.allSatisfy { isValidTime(day.time(for: $0)) }
        }
    }

    private static let expectedDateKeys: Set<String> = {
        let monthLengths = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        return Set(monthLengths.enumerated().flatMap { monthIndex, dayCount in
            (1...dayCount).map { day in
                String(
                    format: "%02d-%02d",
                    locale: Locale(identifier: "en_US_POSIX"),
                    monthIndex + 1,
                    day
                )
            }
        })
    }()

    private static func isValidTime(_ time: String) -> Bool {
        let values = time.split(separator: ":").compactMap { Int($0) }
        return values.count == 2 && (0..<24).contains(values[0]) && (0..<60).contains(values[1])
    }

    private static func offset(_ time: String, by minutes: Int) -> String {
        let values = time.split(separator: ":").compactMap { Int($0) }
        guard values.count == 2 else { return time }
        let total = (values[0] * 60 + values[1] + minutes).quotientAndRemainder(dividingBy: 24 * 60)
        let normalized = total.remainder >= 0 ? total.remainder : total.remainder + 24 * 60
        return String(format: "%02d:%02d", normalized / 60, normalized % 60)
    }
}
