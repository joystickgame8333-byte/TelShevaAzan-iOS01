import Foundation
import WatchConnectivity

final class WatchPrayerSyncService: NSObject, WCSessionDelegate {
    static let shared = WatchPrayerSyncService()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func pushLatestContext() {
        guard WCSession.isSupported() else { return }
        let context = WatchPrayerSharedState.applicationContext(
            dayThemeID: AppThemeStorage.defaults.string(forKey: AppThemeStorage.dayThemeKey)
                ?? PrayerVisualTheme.defaultDay.rawValue,
            nightThemeID: AppThemeStorage.defaults.string(forKey: AppThemeStorage.nightThemeKey)
                ?? PrayerVisualTheme.defaultNight.rawValue,
            calendarRevision: PalestinePrayerCalendar.dataRevision
        )

        do {
            try WCSession.default.updateApplicationContext(context)
        } catch {
            // The next activation/foreground refresh retries with the newest complete context.
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated, error == nil else { return }
        pushLatestContext()
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
