import Foundation
import WidgetKit

enum WidgetRefreshCenter {
    private static let refreshStampKey = "widgetRefreshStamp"
    private static let minimumRefreshInterval: TimeInterval = 15 * 60
    private static var lastRefreshTime: TimeInterval = 0
    private static let widgetKinds = SalatiWidgetKind.all
    private static let installedBuildKey = "widgets.installedBuild"
    private static let pendingBackgroundRefreshKey = "widgets.pendingBackgroundRefresh"

    /// A replaced extension needs a fresh timeline even if the app was recently opened.
    /// Repeat once on returning home, when WidgetKit can render the visible widgets.
    static func refreshAfterInstallationIfNeeded() {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        guard !build.isEmpty,
              UserDefaults.standard.string(forKey: installedBuildKey) != build else { return }
        UserDefaults.standard.set(build, forKey: installedBuildKey)
        UserDefaults.standard.set(true, forKey: pendingBackgroundRefreshKey)
        refreshAll(force: true)
    }

    static func appDidEnterBackground() {
        guard UserDefaults.standard.bool(forKey: pendingBackgroundRefreshKey) else { return }
        UserDefaults.standard.set(false, forKey: pendingBackgroundRefreshKey)
        refreshAll(force: true)
    }

    static func requestRepair() {
        UserDefaults.standard.set(true, forKey: pendingBackgroundRefreshKey)
        refreshAll(force: true)
    }

    static func refreshAll(force: Bool = false) {
        WatchPrayerSyncService.shared.pushLatestContext()
        let timestamp = Date().timeIntervalSince1970
        guard force || timestamp - lastRefreshTime >= minimumRefreshInterval else { return }
        lastRefreshTime = timestamp

        AppThemeStorage.defaults.set(timestamp, forKey: refreshStampKey)
        AppThemeStorage.defaults.synchronize()

        if force {
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            for kind in widgetKinds {
                WidgetCenter.shared.reloadTimelines(ofKind: kind)
            }
        }
    }
}
