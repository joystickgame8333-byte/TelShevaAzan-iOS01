import Foundation
import WidgetKit

enum WidgetRefreshCenter {
    private static let refreshStampKey = "widgetRefreshStamp"
    private static let minimumRefreshInterval: TimeInterval = 0.20
    private static var lastRefreshTime: TimeInterval = 0
    private static let widgetKinds = [
        "com.omaralasam.telshevaazan.nextPrayer.v5",
        "com.omaralasam.telshevaazan.nextPrayer.clean.v5",
        "com.omaralasam.telshevaazan.dailySchedule.v5",
        "com.omaralasam.telshevaazan.countdown.v5",
        "com.omaralasam.telshevaazan.date.today.v5",
        "com.omaralasam.telshevaazan.lockCircle.prayerTime.v5",
        "com.omaralasam.telshevaazan.lockCircle.iqamaMinutes.v5",
        "com.omaralasam.telshevaazan.lockCircle.iqamaTime.v5",
        "com.omaralasam.telshevaazan.lockCircle.nextCountdown.v5",
        "com.omaralasam.telshevaazan.lockCircle.sunriseTime.v5",
        "com.omaralasam.telshevaazan.nextPrayer.v2",
        "com.omaralasam.telshevaazan.nextPrayer.v3",
        "com.omaralasam.telshevaazan.nextPrayer.clean.v4",
        "com.omaralasam.telshevaazan.dailySchedule.v1",
        "com.omaralasam.telshevaazan.countdown.v1",
        "com.omaralasam.telshevaazan.date.today.v1",
        "com.omaralasam.telshevaazan.lockCircle.prayerTime.v2",
        "com.omaralasam.telshevaazan.lockCircle.iqamaMinutes.v2",
        "com.omaralasam.telshevaazan.lockCircle.iqamaTime.v2",
        "com.omaralasam.telshevaazan.lockCircle.nextCountdown.v2",
        "com.omaralasam.telshevaazan.lockCircle.sunriseTime.v2"
    ]

    static func refreshAll() {
        let timestamp = Date().timeIntervalSince1970
        guard timestamp - lastRefreshTime >= minimumRefreshInterval else { return }
        lastRefreshTime = timestamp

        AppThemeStorage.defaults.set(timestamp, forKey: refreshStampKey)
        AppThemeStorage.defaults.synchronize()

        for kind in widgetKinds {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    static func refreshAgainSoon() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            refreshAll()
        }
    }
}
