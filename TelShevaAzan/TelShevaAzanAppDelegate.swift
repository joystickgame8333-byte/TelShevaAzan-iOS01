import UIKit

final class TelShevaAzanAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task { @MainActor in
            PrayerLocationManager.shared.resumeBackgroundMonitoring()
        }
        return true
    }
}
