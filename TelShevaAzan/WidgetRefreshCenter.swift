import Foundation
import WidgetKit

enum WidgetRefreshCenter {
    private static let refreshStampKey = "widgetRefreshStamp"
    private static let minimumRefreshInterval: TimeInterval = 15 * 60
    private static var lastRefreshTime: TimeInterval = 0
    private static let widgetKinds = [
        "com.omaralasam.telshevaazan.nextPrayer.v7",
        "com.omaralasam.telshevaazan.dailySchedule.v7",
        "com.omaralasam.telshevaazan.date.today.v7"
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
    }

    static func refreshAgainSoon() {
        // Timeline entries keep the prayer transition current; requesting a
        // second reload immediately only burns WidgetKit's refresh budget.
    }
}
