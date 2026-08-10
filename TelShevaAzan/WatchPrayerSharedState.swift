import Foundation

enum WatchPrayerSharedState {
    static let appGroupIdentifier = "group.com.omaralasam.telshevaazan"
    static let schemaVersion = 1

    private enum Key {
        static let schemaVersion = "watchPrayer.schemaVersion"
        static let sentAt = "watchPrayer.sentAt"
        static let locationID = "watchPrayer.locationID"
        static let locationName = "watchPrayer.locationName"
        static let dayThemeID = "watchPrayer.dayThemeID"
        static let nightThemeID = "watchPrayer.nightThemeID"
        static let calendarRevision = "watchPrayer.calendarRevision"
    }

    static let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard

    static var locationName: String {
        defaults.string(forKey: Key.locationName) ?? "تل السبع"
    }

    static var dayThemeID: String {
        defaults.string(forKey: Key.dayThemeID) ?? "daySalatiGlass"
    }

    static var nightThemeID: String {
        defaults.string(forKey: Key.nightThemeID) ?? "nightSalatiGlass"
    }

    static func applicationContext(
        dayThemeID: String,
        nightThemeID: String,
        calendarRevision: Int,
        sentAt: Date = Date()
    ) -> [String: Any] {
        [
            Key.schemaVersion: schemaVersion,
            Key.sentAt: sentAt.timeIntervalSince1970,
            Key.locationID: "telSheva",
            Key.locationName: "تل السبع",
            Key.dayThemeID: dayThemeID,
            Key.nightThemeID: nightThemeID,
            Key.calendarRevision: calendarRevision
        ]
    }

    @discardableResult
    static func apply(applicationContext: [String: Any]) -> Bool {
        let incomingSchema = (applicationContext[Key.schemaVersion] as? NSNumber)?.intValue
            ?? applicationContext[Key.schemaVersion] as? Int
        guard incomingSchema == schemaVersion else {
            return false
        }

        let incomingTimestamp = applicationContext[Key.sentAt] as? TimeInterval ?? 0
        let storedTimestamp = defaults.double(forKey: Key.sentAt)
        guard incomingTimestamp >= storedTimestamp else { return false }

        for key in [Key.schemaVersion, Key.sentAt, Key.locationID, Key.locationName,
                    Key.dayThemeID, Key.nightThemeID, Key.calendarRevision] {
            if let value = applicationContext[key] {
                defaults.set(value, forKey: key)
            }
        }
        defaults.synchronize()
        return true
    }
}
