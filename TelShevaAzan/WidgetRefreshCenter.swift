import Foundation
import WidgetKit

enum WidgetRefreshCenter {
    private static let refreshStampKey = "widgetRefreshStamp"
    private static let widgetKinds = [
        "com.omaralasam.telshevaazan.nextPrayer.v2",
        "com.omaralasam.telshevaazan.nextPrayer.v3",
        "com.omaralasam.telshevaazan.dailySchedule.v1",
        "com.omaralasam.telshevaazan.countdown.v1"
    ]

    static func refreshAll() {
        AppThemeStorage.defaults.set(Date().timeIntervalSince1970, forKey: refreshStampKey)
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
