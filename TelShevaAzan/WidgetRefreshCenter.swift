import Foundation
import WidgetKit

enum WidgetRefreshCenter {
    private static let refreshStampKey = "widgetRefreshStamp"
    private static let minimumRefreshInterval: TimeInterval = 15 * 60
    private static var lastRefreshTime: TimeInterval = 0
    private static let widgetKinds = SalatiWidgetKind.all

    static func refreshAll(force: Bool = false) {
        let timestamp = Date().timeIntervalSince1970
        guard force || timestamp - lastRefreshTime >= minimumRefreshInterval else { return }
        lastRefreshTime = timestamp

        AppThemeStorage.defaults.set(timestamp, forKey: refreshStampKey)
        AppThemeStorage.defaults.synchronize()

        for kind in widgetKinds {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
    }
}
