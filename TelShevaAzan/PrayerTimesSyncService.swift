import Combine
import Foundation

@MainActor
final class PrayerTimesSyncService: ObservableObject {
    static let shared = PrayerTimesSyncService()

    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isRefreshing = false

    private let defaults = AppThemeStorage.defaults
    private let lastSyncKey = "authoritativePrayerSchedule.lastSync.v1"
    private let refreshInterval: TimeInterval = 6 * 60 * 60
    private let latitude = 31.245
    private let longitude = 34.842

    private init() {
        lastUpdated = defaults.object(forKey: lastSyncKey) as? Date
    }

    func refreshIfNeeded(force: Bool = false) {
        guard !isRefreshing else { return }
        if !force,
           let lastUpdated,
           Date().timeIntervalSince(lastUpdated) < refreshInterval {
            return
        }

        isRefreshing = true
        Task {
            defer { isRefreshing = false }

            do {
                let days = try await fetchCurrentAndNextMonth()
                PrayerEngine.applyAuthoritativeSchedule(days)
                PrayerEngine.refreshAuthoritativeScheduleFromCache()

                let timestamp = Date()
                defaults.set(timestamp, forKey: lastSyncKey)
                defaults.synchronize()
                lastUpdated = timestamp

                PrayerNotificationManager.shared.refreshIfEnabled()
                WidgetRefreshCenter.refreshAll(force: true)
            } catch {
                // The bundled annual schedule remains available offline.
            }
        }
    }

    private func fetchCurrentAndNextMonth() async throws -> [String: [PrayerKey: String]] {
        let today = Date()
        let nextMonth = PrayerEngine.calendar.date(byAdding: .month, value: 1, to: today) ?? today
        let current = try await fetchMonth(containing: today)
        let next = (try? await fetchMonth(containing: nextMonth)) ?? [:]
        return current.merging(next, uniquingKeysWith: { _, latest in latest })
    }

    private func fetchMonth(containing date: Date) async throws -> [String: [PrayerKey: String]] {
        let components = PrayerEngine.calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year, let month = components.month else {
            return [:]
        }

        var url = URLComponents(string: "https://api.aladhan.com/v1/calendar/\(year)/\(month)")!
        url.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "method", value: "4"),
            URLQueryItem(name: "school", value: "0"),
            URLQueryItem(name: "timezonestring", value: "Asia/Jerusalem"),
            URLQueryItem(name: "latitudeAdjustmentMethod", value: "3")
        ]

        let (data, response) = try await URLSession.shared.data(from: url.url!)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PrayerTimesSyncError.invalidResponse
        }

        let payload = try JSONDecoder().decode(AlAdhanCalendarResponse.self, from: data)
        guard payload.code == 200 else { throw PrayerTimesSyncError.invalidPayload }

        return Dictionary(uniqueKeysWithValues: payload.data.compactMap { day in
            guard let dateKey = Self.dateKey(from: day.date.gregorian.date),
                  let fajr = Self.cleanTime(day.timings["Fajr"]),
                  let sunrise = Self.cleanTime(day.timings["Sunrise"]),
                  let dhuhr = Self.cleanTime(day.timings["Dhuhr"]),
                  let asr = Self.cleanTime(day.timings["Asr"]),
                  let maghrib = Self.cleanTime(day.timings["Maghrib"]),
                  let isha = Self.cleanTime(day.timings["Isha"]) else {
                return nil
            }

            let times: [PrayerKey: String] = [
                .fajr: fajr,
                .sunrise: sunrise,
                .dhuhr: dhuhr,
                .asr: asr,
                .maghrib: maghrib,
                .isha: isha
            ]
            return (dateKey, times)
        })
    }

    private static func dateKey(from apiDate: String) -> String? {
        let values = apiDate.split(separator: "-")
        guard values.count == 3 else { return nil }
        return "\(values[2])-\(values[1])-\(values[0])"
    }

    private static func cleanTime(_ value: String?) -> String? {
        guard let value else { return nil }
        let time = value.split(separator: " ").first.map(String.init) ?? ""
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2,
              (0...23).contains(parts[0]),
              (0...59).contains(parts[1]) else {
            return nil
        }

        return String(format: "%02d:%02d", parts[0], parts[1])
    }
}

private enum PrayerTimesSyncError: Error {
    case invalidResponse
    case invalidPayload
}

private struct AlAdhanCalendarResponse: Decodable {
    let code: Int
    let data: [AlAdhanCalendarDay]
}

private struct AlAdhanCalendarDay: Decodable {
    let timings: [String: String]
    let date: AlAdhanDate
}

private struct AlAdhanDate: Decodable {
    let gregorian: AlAdhanGregorianDate
}

private struct AlAdhanGregorianDate: Decodable {
    let date: String
}
