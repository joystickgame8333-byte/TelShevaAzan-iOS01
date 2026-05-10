import Combine
import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class PrayerLiveActivityCenter: ObservableObject {
    static let shared = PrayerLiveActivityCenter()

    @Published private(set) var isPreviewActive = false

    private let previewDuration: TimeInterval = 180
    private let autoLeadTime: TimeInterval = 180
    private let keepAfterPrayer: TimeInterval = 600
    private var lastSyncDate = Date.distantPast
    private var previewLifecycleTask: Task<Void, Never>?

    private init() {}

    func startPreview(next: PrayerTime?, previous: PrayerTime?) {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        Task {
            await startPreviewActivity(next: next, previous: previous)
        }
#endif
    }

    func syncWithPrayerWindow(now: Date = Date()) {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        guard now.timeIntervalSince(lastSyncDate) >= 20 else { return }
        lastSyncDate = now

        Task {
            await syncActivity(now: now)
        }
#endif
    }

#if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private func startPreviewActivity(next: PrayerTime?, previous: PrayerTime?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        previewLifecycleTask?.cancel()
        await endActivities(where: { _ in true })

        let now = Date()
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
        let state = PrayerLiveActivityAttributes.ContentState(phase: .almostTime, updatedAt: now)

        do {
            let activity = try requestActivity(attributes: attributes, state: state, staleDate: prayerDate.addingTimeInterval(900))
            isPreviewActive = true
            runPreviewLifecycle(activityID: activity.id, prayerDate: prayerDate)
        } catch {
            isPreviewActive = false
        }
    }

    @available(iOS 16.1, *)
    private func syncActivity(now: Date) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        guard !isPreviewActive else { return }
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
        let state = PrayerLiveActivityAttributes.ContentState(phase: phase, updatedAt: now)

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
        let state = PrayerLiveActivityAttributes.ContentState(phase: phase, updatedAt: Date())
        if #available(iOS 16.2, *) {
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: .immediate)
        } else {
            await activity.end(using: state, dismissalPolicy: .immediate)
        }

        if activity.attributes.isPreview {
            isPreviewActive = false
        }
    }

    @available(iOS 16.1, *)
    private func endActivities(where shouldEnd: (Activity<PrayerLiveActivityAttributes>) -> Bool) async {
        for activity in Activity<PrayerLiveActivityAttributes>.activities where shouldEnd(activity) {
            await endActivity(activity, phase: .adhkar)
        }
    }

    @available(iOS 16.1, *)
    private func runPreviewLifecycle(activityID: String, prayerDate: Date) {
        previewLifecycleTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 170_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.setPreviewPhase(activityID: activityID, phase: .now, staleDate: prayerDate.addingTimeInterval(900))

            try? await Task.sleep(nanoseconds: 35_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.setPreviewPhase(activityID: activityID, phase: .adhkar, staleDate: prayerDate.addingTimeInterval(900))

            try? await Task.sleep(nanoseconds: 35_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.endPreview(activityID: activityID)
        }
    }

    @available(iOS 16.1, *)
    private func setPreviewPhase(activityID: String, phase: PrayerLiveActivityPhase, staleDate: Date) async {
        guard let activity = Activity<PrayerLiveActivityAttributes>.activities.first(where: { $0.id == activityID }) else {
            isPreviewActive = false
            return
        }

        let state = PrayerLiveActivityAttributes.ContentState(phase: phase, updatedAt: Date())
        await updateActivity(activity, state: state, staleDate: staleDate)
    }

    @available(iOS 16.1, *)
    private func endPreview(activityID: String) async {
        guard let activity = Activity<PrayerLiveActivityAttributes>.activities.first(where: { $0.id == activityID }) else {
            isPreviewActive = false
            return
        }

        await endActivity(activity, phase: .adhkar)
        isPreviewActive = false
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

    private static func timeText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
#endif
}
