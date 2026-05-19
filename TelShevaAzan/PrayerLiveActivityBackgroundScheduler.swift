import Foundation

#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

@MainActor
final class PrayerLiveActivityBackgroundScheduler {
    static let shared = PrayerLiveActivityBackgroundScheduler()

    static let taskIdentifier = "com.omaralasam.telshevaazan.prayer-live-activity"

    private let leadTime: TimeInterval = 5 * 60
    private var didRegister = false

    private init() {}

    func register() {
#if canImport(BackgroundTasks)
        guard !didRegister else { return }
        didRegister = true

        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            PrayerLiveActivityBackgroundScheduler.handle(task)
        }
#endif
    }

    func scheduleNext(now: Date = Date()) {
#if canImport(BackgroundTasks)
        guard #available(iOS 16.1, *) else { return }
        let dateKey = PrayerEngine.defaultDateKey(for: now)
        guard let nextPrayer = PrayerEngine.nextPrayer(for: dateKey, now: now) else { return }

        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        let wakeDate = nextPrayer.date.addingTimeInterval(-leadTime)
        request.earliestBeginDate = max(wakeDate, now.addingTimeInterval(60))

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // iOS can reject refresh requests when Background App Refresh is disabled.
        }
#endif
    }

#if canImport(BackgroundTasks)
    private nonisolated static func handle(_ task: BGTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        Task { @MainActor in
            await PrayerLiveActivityCenter.shared.syncImmediately(now: Date())
            PrayerLiveActivityBackgroundScheduler.shared.scheduleNext()
            task.setTaskCompleted(success: true)
        }
    }
#endif
}
