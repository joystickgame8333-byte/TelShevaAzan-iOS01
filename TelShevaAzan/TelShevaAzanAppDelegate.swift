import UIKit

final class TelShevaAzanAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        Task { @MainActor in
            await PrayerLiveActivityCenter.shared.syncImmediately(now: Date())
        }
        return true
    }

    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            await PrayerLiveActivityCenter.shared.syncImmediately(now: Date())
            PrayerLiveActivityBackgroundScheduler.shared.scheduleNext()
            completionHandler(.newData)
        }
    }
}
