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
    @Published private(set) var debugText = ""

    private let previewDuration: TimeInterval = 30
    private let autoLeadTime: TimeInterval = 5 * 60
    private let postPrayerDisplayDuration: TimeInterval = 45
    private let nowDisplayDuration: TimeInterval = 0
    private let expiredCleanupGrace: TimeInterval = 0
    private var lastSyncDate = Date.distantPast
    private var lastCleanupDate = Date.distantPast

    private init() {}

    func syncImmediately(now: Date = Date(), themeID: String? = nil) async {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        await syncActivity(now: now, themeID: themeID ?? Self.fallbackThemeID(now: now))
#endif
    }

    func startPreview(themeID: String? = nil) {
        let now = Date()
        let dateKey = PrayerEngine.defaultDateKey(for: now)
        startPreview(
            next: PrayerEngine.nextPrayer(for: dateKey, now: now),
            previous: PrayerEngine.previousPrayer(for: dateKey, now: now),
            themeID: themeID
        )
    }

    func startPreview(prayerKey: PrayerKey, themeID: String? = nil) {
        let now = Date()
        let prayerDate = now.addingTimeInterval(previewDuration)
        let previousDate = now.addingTimeInterval(-3600)
        let previousKey = Self.previousPreviewPrayerKey(for: prayerKey)
        let next = PrayerTime(
            key: prayerKey,
            title: prayerKey.title,
            time: Self.previewTimeText(for: prayerDate),
            date: prayerDate
        )
        let previous = PrayerTime(
            key: previousKey,
            title: previousKey.title,
            time: Self.previewTimeText(for: previousDate),
            date: previousDate
        )

        startPreview(next: next, previous: previous, themeID: themeID)
    }

    func startPreview(next: PrayerTime?, previous: PrayerTime?, themeID: String? = nil) {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else {
            statusText = "غير مدعوم على هذا الإصدار"
            detailText = "Live Activities تحتاج iOS 16.1 أو أحدث."
            debugText = ""
            return
        }
        Task {
            await startPreviewActivity(next: next, previous: previous, themeID: themeID ?? Self.fallbackThemeID())
        }
#else
        statusText = "غير مدعوم في هذا البناء"
        detailText = "ActivityKit غير متاح في هذه البيئة."
        debugText = ""
#endif
    }

    func syncWithPrayerWindow(now: Date = Date(), themeID: String? = nil) {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *) else { return }
        cleanupExpiredLiveActivities(now: now)
        guard now.timeIntervalSince(lastSyncDate) >= 2 else { return }
        lastSyncDate = now

        Task {
            await syncActivity(now: now, themeID: themeID ?? Self.fallbackThemeID(now: now))
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

    private static func previousPreviewPrayerKey(for key: PrayerKey) -> PrayerKey {
        switch key {
        case .fajr:
            return .isha
        case .dhuhr:
            return .fajr
        case .asr:
            return .dhuhr
        case .maghrib:
            return .asr
        case .isha:
            return .maghrib
        case .sunrise:
            return .fajr
        }
    }

    private static func previewTimeText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

#if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private func startPreviewActivity(next: PrayerTime?, previous: PrayerTime?, themeID: String) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            isPreviewActive = false
            statusText = "Live Activities مقفلة"
            detailText = "افتح إعدادات الآيفون > أذان تل السبع > فعّل Live Activities، ثم ارجع واضغط اختبار الجزيرة."
            debugText = ""
            return
        }
        guard isWidgetExtensionBundled else {
            isPreviewActive = false
            statusText = "الجزيرة غير مدمجة في هذا البناء"
            detailText = "هذا يحدث إذا تم فتح مشروع قديم أو تثبيت IPA لا يحتوي على TelShevaAzanWidgetExtensionV3. ابنِ النسخة من GitHub Actions بعد توليد المشروع من project.yml."
            debugText = "Missing PlugIns/TelShevaAzanWidgetExtensionV3.appex"
            return
        }

        let now = Date()
        await cleanupExpiredLiveActivities(now: now, includeStalePreviews: true)
        await endActivities(where: { _ in true })

        let prayerDate = now.addingTimeInterval(previewDuration)
        let activityEndDate = prayerDate
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
            themeID: themeID,
            isPreview: true
        )
        let state = PrayerLiveActivityAttributes.ContentState(
            phase: .almostTime,
            prayerDate: prayerDate,
            updatedAt: now
        )

        do {
            let activity = try requestActivity(attributes: attributes, state: state, staleDate: activityEndDate)
            keepAlive(activity, until: activityEndDate)
            isPreviewActive = true
            statusText = "تم تشغيل الجزيرة"
            detailText = "اخرج من التطبيق أو اقفل الشاشة. العدّاد الظاهر في الجزيرة يعمل من نظام iOS، وليس من مؤقت خلفي داخل التطبيق."
            debugText = ""
        } catch {
            isPreviewActive = false
            statusText = "لم يبدأ اختبار الجزيرة"
            detailText = "النظام رفض تشغيل Live Activity الآن. تأكد من تفعيل Live Activities للتطبيق ومن أن الجهاز iOS 16.1 أو أحدث."
            debugText = String(describing: error)
        }
    }

    @available(iOS 16.1, *)
    private func syncActivity(now: Date, themeID: String) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            statusText = "Live Activities مقفلة"
            detailText = "فعّل Live Activities من إعدادات الآيفون حتى تظهر الجزيرة وشاشة القفل للصلاة."
            debugText = ""
            return
        }
        guard isWidgetExtensionBundled else {
            statusText = "الجزيرة غير مدمجة في هذا البناء"
            detailText = "ثبت نسخة تحتوي على TelShevaAzanWidgetExtensionV3 حتى تعمل الجزيرة وشاشة القفل."
            debugText = "Missing PlugIns/TelShevaAzanWidgetExtensionV3.appex"
            return
        }
        await cleanupExpiredLiveActivities(now: now, includeStalePreviews: true)

        let hasActivePreview = Activity<PrayerLiveActivityAttributes>.activities.contains { $0.attributes.isPreview }
        if isPreviewActive && !hasActivePreview {
            isPreviewActive = false
        }

        guard !isPreviewActive else { return }
        await endActivities(where: { $0.attributes.isPreview })

        let dateKey = PrayerEngine.defaultDateKey(for: now)
        let previousAtNow = PrayerEngine.previousPrayer(for: dateKey, now: now)

        let targetPrayer: PrayerTime
        let previous: PrayerTime?
        if let justStartedPrayer = previousAtNow,
           now.timeIntervalSince(justStartedPrayer.date) <= postPrayerDisplayDuration {
            targetPrayer = justStartedPrayer
            previous = PrayerEngine.previousPrayer(for: dateKey, now: justStartedPrayer.date.addingTimeInterval(-1))
        } else {
            guard let nextPrayer = PrayerEngine.nextPrayer(for: dateKey, now: now) else { return }
            targetPrayer = nextPrayer
            previous = previousAtNow
        }

        let secondsUntilPrayer = targetPrayer.date.timeIntervalSince(now)
        let prayerID = realPrayerID(for: targetPrayer)

        for activity in Activity<PrayerLiveActivityAttributes>.activities where !activity.attributes.isPreview && activity.attributes.prayerID != prayerID {
            if now >= activityEndDate(for: activity) {
                await endActivity(activity, phase: .adhkar)
            }
        }

        if secondsUntilPrayer > autoLeadTime {
            return
        }

        if secondsUntilPrayer <= -postPrayerDisplayDuration {
            return
        }

        let activityEndDate = liveActivityEndDate(for: targetPrayer.date, isPreview: false)
        let phase = phase(for: secondsUntilPrayer)
        let state = PrayerLiveActivityAttributes.ContentState(
            phase: phase,
            prayerDate: targetPrayer.date,
            updatedAt: now
        )

        if let activity = Activity<PrayerLiveActivityAttributes>.activities.first(where: { !$0.attributes.isPreview && $0.attributes.prayerID == prayerID }) {
            await updateActivity(activity, state: state, staleDate: activityEndDate)
            keepAlive(activity, until: activityEndDate)
            return
        }

        let attributes = PrayerLiveActivityAttributes(
            prayerID: prayerID,
            prayerName: targetPrayer.title,
            prayerTime: targetPrayer.time,
            prayerDate: targetPrayer.date,
            previousPrayerName: previous?.title ?? "الصلاة السابقة",
            previousPrayerDate: previous?.date,
            cityName: "تل السبع",
            themeID: themeID,
            isPreview: false
        )

        do {
            let activity = try requestActivity(attributes: attributes, state: state, staleDate: activityEndDate)
            keepAlive(activity, until: activityEndDate)
            statusText = "الجزيرة تعمل الآن"
            detailText = "ظهرت Live Activity للصلاة القادمة. إذا قفلت الشاشة الآن ستظهر بطاقة شاشة القفل حتى وقت الأذان."
            debugText = ""
        } catch {
            statusText = "لم تبدأ الجزيرة تلقائيًا"
            detailText = "النظام رفض تشغيل Live Activity في نافذة الصلاة الحالية. جرّب فتح التطبيق قبل الأذان بخمس دقائق وتأكد أن Live Activities مفعلة."
            debugText = String(describing: error)
            return
        }
    }

    @available(iOS 16.1, *)
    private func cleanupExpiredLiveActivities(now: Date, includeStalePreviews: Bool) async {
        let cleanupDate = now.addingTimeInterval(-expiredCleanupGrace)

        for activity in Activity<PrayerLiveActivityAttributes>.activities {
            let endDate = activityEndDate(for: activity)
            let expiredLongEnough = endDate <= cleanupDate
            let oldPreview = includeStalePreviews && activity.attributes.isPreview && endDate <= cleanupDate

            if expiredLongEnough || oldPreview {
                await endActivity(activity, phase: .adhkar)
            }
        }
    }

    @available(iOS 16.1, *)
    private func activityEndDate(for activity: Activity<PrayerLiveActivityAttributes>) -> Date {
        liveActivityEndDate(for: activity.attributes.prayerDate, isPreview: activity.attributes.isPreview)
    }

    private func liveActivityEndDate(for prayerDate: Date, isPreview: Bool) -> Date {
        isPreview ? prayerDate : prayerDate.addingTimeInterval(postPrayerDisplayDuration)
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
    private func keepAlive(_ activity: Activity<PrayerLiveActivityAttributes>, until endDate: Date) {
        let onNowHandler: (() -> Void)?
        if nowDisplayDuration > 0 {
            onNowHandler = { [weak self] in
                Task { @MainActor in
                    guard let self else { return }
                    let now = Date()
                    let state = PrayerLiveActivityAttributes.ContentState(
                        phase: .now,
                        prayerDate: activity.attributes.prayerDate,
                        updatedAt: now
                    )
                    await self.updateActivity(activity, state: state, staleDate: endDate)
                }
            }
        } else {
            onNowHandler = nil
        }

        PrayerLiveActivityKeepAlive.shared.start(
            until: endDate,
            nowDate: activity.attributes.prayerDate,
            nowDisplayDuration: nowDisplayDuration,
            onWarning: { [weak self] in
                Task { @MainActor in
                    let state = PrayerLiveActivityAttributes.ContentState(
                        phase: .almostTime,
                        prayerDate: activity.attributes.prayerDate,
                        updatedAt: Date()
                    )
                    await self?.updateActivity(activity, state: state, staleDate: endDate)
                }
            },
            onNow: onNowHandler,
            onEnd: { [weak self] in
                Task { @MainActor in
                    await self?.endActivity(activity, phase: .now)
                }
            }
        )
    }

    @available(iOS 16.1, *)
    private func endActivities(where shouldEnd: (Activity<PrayerLiveActivityAttributes>) -> Bool) async {
        var endedAnyActivity = false

        for activity in Activity<PrayerLiveActivityAttributes>.activities where shouldEnd(activity) {
            endedAnyActivity = true
            await endActivity(activity, phase: .adhkar)
        }

        if endedAnyActivity {
            PrayerLiveActivityKeepAlive.shared.stop()
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

    private static func prayerKey(for attributes: PrayerLiveActivityAttributes) -> PrayerKey {
        if let rawValue = attributes.prayerID.split(separator: "-").first,
           let key = PrayerKey(rawValue: String(rawValue)) {
            return key
        }

        return PrayerKey.allCases.first { $0.title == attributes.prayerName } ?? .fajr
    }

    private static func iqamaDelayMinutes(for prayerKey: PrayerKey) -> Int {
        switch prayerKey {
        case .fajr:
            return 25
        case .dhuhr, .sunrise:
            return 15
        case .asr:
            return 12
        case .maghrib:
            return 7
        case .isha:
            return 10
        }
    }

    private static func iqamaDate(for prayerDate: Date, prayerKey: PrayerKey) -> Date {
        prayerDate.addingTimeInterval(TimeInterval(iqamaDelayMinutes(for: prayerKey) * 60))
    }

    private static func fallbackThemeID(now: Date = Date()) -> String {
        let hour = PrayerEngine.calendar.component(.hour, from: now)
        let isNight = hour < 6 || hour >= 18

        if isNight {
            return AppThemeStorage.defaults.string(forKey: AppThemeStorage.nightThemeKey) ?? PrayerVisualTheme.nightAppleGlass.rawValue
        }

        return AppThemeStorage.defaults.string(forKey: AppThemeStorage.dayThemeKey) ?? PrayerVisualTheme.dayAppleGlass.rawValue
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
