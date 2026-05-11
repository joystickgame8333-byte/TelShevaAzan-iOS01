import Combine
import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class PrayerLiveActivityCenter: ObservableObject {
    static let shared = PrayerLiveActivityCenter()

    @Published private(set) var isPreviewActive = false
    @Published private(set) var statusText = "جاهز لاختبار الجزيرة"
    @Published private(set) var detailText = "اضغط الاختبار ثم اخرج من التطبيق أو اقفل الشاشة. العدّاد يعمل من النظام داخل Live Activity بدون مؤقت خلفي من التطبيق."
    @Published private(set) var debugText = "Live Activity debug: لم يبدأ الاختبار بعد"

    private let previewDuration: TimeInterval = 30
    private let autoLeadTime: TimeInterval = 180
    private let keepAfterPrayer: TimeInterval = 120
    private let expiredCleanupGrace: TimeInterval = 60
    private var lastSyncDate = Date.distantPast
    private var lastCleanupDate = Date.distantPast

    private init() {}

    func startPreview() {
        let now = Date()
        let dateKey = PrayerEngine.defaultDateKey(for: now)
        startPreview(
            next: PrayerEngine.nextPrayer(for: dateKey, now: now),
            previous: PrayerEngine.previousPrayer(for: dateKey, now: now)
        )
    }

    func startPreview(next: PrayerTime?, previous: PrayerTime?) {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else {
            statusText = "غير مدعوم على هذا الإصدار"
            detailText = "Live Activities تحتاج iOS 16.1 أو أحدث."
            debugText = "Activity.request: not attempted\nError: iOS 16.1 required"
            return
        }
        Task {
            await startPreviewActivity(next: next, previous: previous)
        }
#else
        statusText = "غير مدعوم في هذا البناء"
        detailText = "ActivityKit غير متاح في هذه البيئة."
        debugText = "Activity.request: not available\nError: ActivityKit unavailable"
#endif
    }

    func syncWithPrayerWindow(now: Date = Date()) {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        cleanupExpiredLiveActivities(now: now)
        guard now.timeIntervalSince(lastSyncDate) >= 20 else { return }
        lastSyncDate = now

        Task {
            await syncActivity(now: now)
        }
#endif
    }

    func cleanupExpiredLiveActivities(now: Date = Date()) {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        guard now.timeIntervalSince(lastCleanupDate) >= 2 else { return }
        lastCleanupDate = now

        Task {
            await cleanupExpiredLiveActivities(now: now, includeStalePreviews: true)
        }
#endif
    }

#if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private func startPreviewActivity(next: PrayerTime?, previous: PrayerTime?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            isPreviewActive = false
            statusText = "Live Activities مقفلة"
            detailText = "افتح إعدادات الآيفون > أذان تل السبع > فعّل Live Activities، ثم ارجع واضغط اختبار الجزيرة."
            debugText = """
            Activity.request: not attempted
            Widget extension bundled: \(isWidgetExtensionBundled ? "yes" : "no")
            Active activities count: \(Activity<PrayerLiveActivityAttributes>.activities.count)
            Error: Live Activities disabled
            """
            return
        }

        let now = Date()
        await cleanupExpiredLiveActivities(now: now, includeStalePreviews: true)
        await endActivities(where: { _ in true })

        let prayerDate = now.addingTimeInterval(previewDuration)
        let prayerName = next?.title ?? "المغرب"
        let previousName = previous?.title ?? "الصلاة السابقة"
        let attributes = PrayerLiveActivityAttributes(
            prayerID: "preview-\(Int(now.timeIntervalSince1970))",
            prayerName: prayerName,
            prayerTime: Self.timeText(for: prayerDate),
            prayerDate: prayerDate,
            previousPrayerName: previousName,
            previousPrayerDate: previous?.date ?? now.addingTimeInterval(-3600),
            cityName: "تل السبع",
            isPreview: true
        )
        let state = PrayerLiveActivityAttributes.ContentState(
            phase: .almostTime,
            prayerDate: prayerDate,
            updatedAt: now
        )

        do {
            let activity = try requestActivity(attributes: attributes, state: state, staleDate: prayerDate.addingTimeInterval(120))
            isPreviewActive = true
            statusText = "تم تشغيل الجزيرة"
            detailText = "اخرج من التطبيق أو اقفل الشاشة. العدّاد الظاهر في الجزيرة يعمل من نظام iOS، وليس من مؤقت خلفي داخل التطبيق."
            debugText = """
            Live Activity requested successfully
            Activity ID: \(activity.id)
            Active activities count: \(Activity<PrayerLiveActivityAttributes>.activities.count)
            Widget extension bundled: \(isWidgetExtensionBundled ? "yes" : "no")
            Error: none
            """
        } catch {
            isPreviewActive = false
            statusText = "لم يبدأ اختبار الجزيرة"
            detailText = "النظام رفض تشغيل Live Activity الآن. تأكد من تفعيل Live Activities للتطبيق ومن أن الجهاز iOS 16.1 أو أحدث."
            debugText = """
            Activity.request: failed
            Activity ID: -
            Active activities count: \(Activity<PrayerLiveActivityAttributes>.activities.count)
            Widget extension bundled: \(isWidgetExtensionBundled ? "yes" : "no")
            Error: \(String(describing: error))
            """
        }
    }

    @available(iOS 16.1, *)
    private func syncActivity(now: Date) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        await cleanupExpiredLiveActivities(now: now, includeStalePreviews: true)
        guard !isPreviewActive else { return }
        await endActivities(where: { $0.attributes.isPreview })

        let dateKey = PrayerEngine.defaultDateKey(for: now)
        guard let next = PrayerEngine.nextPrayer(for: dateKey, now: now) else { return }

        let secondsUntilPrayer = next.date.timeIntervalSince(now)
        let previous = PrayerEngine.previousPrayer(for: dateKey, now: now)
        let prayerID = realPrayerID(for: next)

        for activity in Activity<PrayerLiveActivityAttributes>.activities where !activity.attributes.isPreview && activity.attributes.prayerID != prayerID {
            await endActivity(activity, phase: .adhkar)
        }

        if secondsUntilPrayer > autoLeadTime {
            return
        }

        guard secondsUntilPrayer >= -keepAfterPrayer else {
            await endActivities(where: { !$0.attributes.isPreview })
            return
        }

        let phase = phase(for: secondsUntilPrayer)
        let state = PrayerLiveActivityAttributes.ContentState(
            phase: phase,
            prayerDate: next.date,
            updatedAt: now
        )

        if let activity = Activity<PrayerLiveActivityAttributes>.activities.first(where: { !$0.attributes.isPreview && $0.attributes.prayerID == prayerID }) {
            await updateActivity(activity, state: state, staleDate: next.date.addingTimeInterval(keepAfterPrayer))
            return
        }

        let attributes = PrayerLiveActivityAttributes(
            prayerID: prayerID,
            prayerName: next.title,
            prayerTime: next.time,
            prayerDate: next.date,
            previousPrayerName: previous?.title ?? "الصلاة السابقة",
            previousPrayerDate: previous?.date,
            cityName: "تل السبع",
            isPreview: false
        )

        do {
            _ = try requestActivity(attributes: attributes, state: state, staleDate: next.date.addingTimeInterval(keepAfterPrayer))
        } catch {
            return
        }
    }

    @available(iOS 16.1, *)
    private func cleanupExpiredLiveActivities(now: Date, includeStalePreviews: Bool) async {
        let cleanupDate = now.addingTimeInterval(-expiredCleanupGrace)

        for activity in Activity<PrayerLiveActivityAttributes>.activities {
            let prayerDate = activityPrayerDate(for: activity)
            let expiredLongEnough = prayerDate <= cleanupDate
            let oldPreview = includeStalePreviews && activity.attributes.isPreview && prayerDate <= cleanupDate

            if expiredLongEnough || oldPreview {
                await endActivity(activity, phase: .adhkar)
            }
        }
    }

    @available(iOS 16.1, *)
    private func activityPrayerDate(for activity: Activity<PrayerLiveActivityAttributes>) -> Date {
        if #available(iOS 16.2, *) {
            return activity.content.state.prayerDate
        }

        return activity.attributes.prayerDate
    }

    @available(iOS 16.1, *)
    private func requestActivity(
        attributes: PrayerLiveActivityAttributes,
        state: PrayerLiveActivityAttributes.ContentState,
        staleDate: Date
    ) throws -> Activity<PrayerLiveActivityAttributes> {
        if #available(iOS 16.2, *) {
            let content = ActivityContent(state: state, staleDate: staleDate)
            return try Activity.request(attributes: attributes, content: content, pushType: nil)
        } else {
            return try Activity.request(attributes: attributes, contentState: state, pushType: nil)
        }
    }

    @available(iOS 16.1, *)
    private func updateActivity(
        _ activity: Activity<PrayerLiveActivityAttributes>,
        state: PrayerLiveActivityAttributes.ContentState,
        staleDate: Date
    ) async {
        if #available(iOS 16.2, *) {
            await activity.update(ActivityContent(state: state, staleDate: staleDate))
        } else {
            await activity.update(using: state)
        }
    }

    @available(iOS 16.1, *)
    private func endActivity(_ activity: Activity<PrayerLiveActivityAttributes>, phase: PrayerLiveActivityPhase) async {
        let state = PrayerLiveActivityAttributes.ContentState(
            phase: phase,
            prayerDate: activity.attributes.prayerDate,
            updatedAt: Date()
        )
        if #available(iOS 16.2, *) {
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
        } else {
            await activity.end(using: state, dismissalPolicy: .immediate)
        }

        if activity.attributes.isPreview {
            isPreviewActive = false
            statusText = "انتهى اختبار الجزيرة"
            detailText = "تقدر تضغط اختبار الجزيرة مرة ثانية وتشاهدها من شاشة القفل أو Dynamic Island."
        }
    }

    @available(iOS 16.1, *)
    private func endActivities(where shouldEnd: (Activity<PrayerLiveActivityAttributes>) -> Bool) async {
        for activity in Activity<PrayerLiveActivityAttributes>.activities where shouldEnd(activity) {
            await endActivity(activity, phase: .adhkar)
        }
    }

    private func phase(for secondsUntilPrayer: TimeInterval) -> PrayerLiveActivityPhase {
        if secondsUntilPrayer > 0 {
            return .almostTime
        }

        if secondsUntilPrayer > -180 {
            return .now
        }

        return .adhkar
    }

    private func realPrayerID(for prayer: PrayerTime) -> String {
        "\(prayer.key.rawValue)-\(Int(prayer.date.timeIntervalSince1970))"
    }

    private var isWidgetExtensionBundled: Bool {
        guard let plugInsURL = Bundle.main.builtInPlugInsURL else { return false }
        let extensionURL = plugInsURL.appendingPathComponent("TelShevaAzanWidgetExtensionV3.appex")
        return FileManager.default.fileExists(atPath: extensionURL.path)
    }

    private static func timeText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
#endif
}
