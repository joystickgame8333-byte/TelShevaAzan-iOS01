import Combine
import Foundation
import UserNotifications

enum PrayerNotificationSound: String, CaseIterable, Identifiable {
    case bundledAdhan
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bundledAdhan:
            return "مقطع الأذان الحالي"
        case .system:
            return "صوت الآيفون"
        }
    }

    var subtitle: String {
        switch self {
        case .bundledAdhan:
            return "المقطع الذي أرسلته يعمل مع إشعارات الصلاة"
        case .system:
            return "تنبيه قصير من النظام بدون أذان"
        }
    }

    var systemImage: String {
        switch self {
        case .bundledAdhan:
            return "waveform.circle.fill"
        case .system:
            return "iphone.gen3.radiowaves.left.and.right"
        }
    }
}

enum AdhkarReminderStyle: String, CaseIterable, Identifiable {
    case tasbih
    case istighfar
    case salawat
    case shortDua

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tasbih:
            return "تسبيح بعد الصلاة"
        case .istighfar:
            return "استغفار"
        case .salawat:
            return "الصلاة على النبي"
        case .shortDua:
            return "دعاء خفيف"
        }
    }

    var subtitle: String {
        switch self {
        case .tasbih:
            return "سبحان الله، والحمد لله، والله أكبر"
        case .istighfar:
            return "أستغفر الله وأتوب إليه"
        case .salawat:
            return "اللهم صل وسلم على نبينا محمد"
        case .shortDua:
            return "رب اغفر لي وتب علي"
        }
    }

    var notificationBody: String {
        switch self {
        case .tasbih:
            return "سبحان الله 33، الحمد لله 33، الله أكبر 34"
        case .istighfar:
            return "أستغفر الله وأتوب إليه"
        case .salawat:
            return "اللهم صل وسلم على نبينا محمد"
        case .shortDua:
            return "رب اغفر لي وتب علي إنك أنت التواب الرحيم"
        }
    }

    var systemImage: String {
        switch self {
        case .tasbih:
            return "sparkles"
        case .istighfar:
            return "leaf.fill"
        case .salawat:
            return "heart.fill"
        case .shortDua:
            return "hands.sparkles.fill"
        }
    }
}

final class PrayerNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let openSettingsNotification = Notification.Name("PrayerNotificationManagerOpenSettings")

    private static let enabledKey = "prayer_notifications_enabled"
    private static let enabledPrayerIDsKey = "prayer_notifications_enabled_prayers"
    private static let selectedSoundIDKey = "prayer_notifications_selected_sound"
    private static let adhkarEnabledKey = "prayer_notifications_adhkar_enabled"
    private static let adhkarDelayMinutesKey = "prayer_notifications_adhkar_delay_minutes"
    private static let adhkarPrayerIDsKey = "prayer_notifications_adhkar_prayers"
    private static let selectedAdhkarStyleIDKey = "prayer_notifications_adhkar_style"

    static let shared = PrayerNotificationManager()

    @Published private(set) var isEnabled = UserDefaults.standard.bool(forKey: PrayerNotificationManager.enabledKey)
    @Published private(set) var statusText = "التنبيهات غير مفعلة"
    @Published private(set) var enabledPrayerIDs: Set<String>
    @Published private(set) var selectedSoundID: String
    @Published private(set) var isAdhkarReminderEnabled: Bool
    @Published private(set) var adhkarDelayMinutes: Int
    @Published private(set) var enabledAdhkarPrayerIDs: Set<String>
    @Published private(set) var selectedAdhkarStyleID: String

    private let center = UNUserNotificationCenter.current()
    private let notificationPrefix = "tel-sheva-prayer-"
    private let previewNotificationIdentifier = "tel-sheva-prayer-preview"
    private let maxPendingNotifications = 60
    private let defaults = UserDefaults.standard

    private var selectedSound: PrayerNotificationSound {
        PrayerNotificationSound(rawValue: selectedSoundID) ?? .bundledAdhan
    }

    private var selectedAdhkarStyle: AdhkarReminderStyle {
        AdhkarReminderStyle(rawValue: selectedAdhkarStyleID) ?? .tasbih
    }

    private override init() {
        let savedPrayerIDs = UserDefaults.standard.stringArray(forKey: Self.enabledPrayerIDsKey)
        if let savedPrayerIDs, !savedPrayerIDs.isEmpty {
            enabledPrayerIDs = Set(savedPrayerIDs)
        } else {
            enabledPrayerIDs = Set(PrayerEngine.prayerOrder.map(\.rawValue))
        }

        let savedSoundID = UserDefaults.standard.string(forKey: Self.selectedSoundIDKey)
        selectedSoundID = savedSoundID ?? PrayerNotificationSound.bundledAdhan.rawValue
        isAdhkarReminderEnabled = UserDefaults.standard.bool(forKey: Self.adhkarEnabledKey)
        let savedDelay = UserDefaults.standard.integer(forKey: Self.adhkarDelayMinutesKey)
        adhkarDelayMinutes = savedDelay == 0 ? 5 : savedDelay

        let savedAdhkarPrayerIDs = UserDefaults.standard.stringArray(forKey: Self.adhkarPrayerIDsKey)
        if let savedAdhkarPrayerIDs, !savedAdhkarPrayerIDs.isEmpty {
            enabledAdhkarPrayerIDs = Set(savedAdhkarPrayerIDs)
        } else {
            enabledAdhkarPrayerIDs = Set(PrayerEngine.prayerOrder.map(\.rawValue))
        }

        let savedAdhkarStyleID = UserDefaults.standard.string(forKey: Self.selectedAdhkarStyleIDKey)
        selectedAdhkarStyleID = savedAdhkarStyleID ?? AdhkarReminderStyle.tasbih.rawValue

        super.init()
        center.delegate = self
        refreshStatus()
    }

    func enable() {
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self else { return }

                self.isEnabled = granted
                self.defaults.set(granted, forKey: Self.enabledKey)

                if granted {
                    self.scheduleUpcomingPrayerNotifications()
                } else {
                    self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                }
            }
        }
    }

    func disable() {
        isEnabled = false
        defaults.set(false, forKey: Self.enabledKey)
        removeScheduledPrayerNotifications()
        statusText = "التنبيهات غير مفعلة"
    }

    func refreshIfEnabled() {
        guard isEnabled else {
            refreshStatus()
            return
        }

        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self else { return }
                if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                    self.scheduleUpcomingPrayerNotifications()
                } else {
                    self.isEnabled = false
                    self.defaults.set(false, forKey: Self.enabledKey)
                    self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                }
            }
        }
    }

    func toggle() {
        isEnabled ? disable() : enable()
    }

    func setPrayer(_ key: PrayerKey, enabled: Bool) {
        if enabled {
            enabledPrayerIDs.insert(key.rawValue)
        } else {
            enabledPrayerIDs.remove(key.rawValue)
        }

        persistPrayerSelection()
        rescheduleIfEnabled()
    }

    func isPrayerEnabled(_ key: PrayerKey) -> Bool {
        enabledPrayerIDs.contains(key.rawValue)
    }

    func selectSound(_ sound: PrayerNotificationSound) {
        selectedSoundID = sound.rawValue
        defaults.set(sound.rawValue, forKey: Self.selectedSoundIDKey)
        rescheduleIfEnabled()
    }

    func setAdhkarReminderEnabled(_ enabled: Bool) {
        isAdhkarReminderEnabled = enabled
        defaults.set(enabled, forKey: Self.adhkarEnabledKey)

        if enabled && !isEnabled {
            enable()
        } else {
            rescheduleIfEnabled()
        }
    }

    func setAdhkarDelayMinutes(_ minutes: Int) {
        adhkarDelayMinutes = minutes
        defaults.set(minutes, forKey: Self.adhkarDelayMinutesKey)
        rescheduleIfEnabled()
    }

    func selectAdhkarStyle(_ style: AdhkarReminderStyle) {
        selectedAdhkarStyleID = style.rawValue
        defaults.set(style.rawValue, forKey: Self.selectedAdhkarStyleIDKey)
        rescheduleIfEnabled()
    }

    func setAdhkarPrayer(_ key: PrayerKey, enabled: Bool) {
        if enabled {
            enabledAdhkarPrayerIDs.insert(key.rawValue)
        } else {
            enabledAdhkarPrayerIDs.remove(key.rawValue)
        }

        persistAdhkarPrayerSelection()
        rescheduleIfEnabled()
    }

    func isAdhkarPrayerEnabled(_ key: PrayerKey) -> Bool {
        enabledAdhkarPrayerIDs.contains(key.rawValue)
    }

    func sendPreviewNotification() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.schedulePreviewNotification()
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        guard granted else {
                            self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                            return
                        }

                        self.isEnabled = true
                        self.defaults.set(true, forKey: Self.enabledKey)
                        self.schedulePreviewNotification()
                        self.scheduleUpcomingPrayerNotifications()
                    }
                }
            default:
                DispatchQueue.main.async {
                    self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                }
            }
        }
    }

    func sendTestNotification() {
        sendPreviewNotification()
    }

    private func rescheduleIfEnabled() {
        guard isEnabled else {
            refreshStatus()
            return
        }

        scheduleUpcomingPrayerNotifications()
    }

    private func persistPrayerSelection() {
        defaults.set(Array(enabledPrayerIDs).sorted(), forKey: Self.enabledPrayerIDsKey)
    }

    private func persistAdhkarPrayerSelection() {
        defaults.set(Array(enabledAdhkarPrayerIDs).sorted(), forKey: Self.adhkarPrayerIDsKey)
    }

    private func scheduleUpcomingPrayerNotifications() {
        let events = upcomingNotificationEvents()
        removeScheduledPrayerNotifications {
            for event in events {
                self.center.add(self.request(for: event))
            }

            DispatchQueue.main.async {
                if self.enabledPrayerIDs.isEmpty && (!self.isAdhkarReminderEnabled || self.enabledAdhkarPrayerIDs.isEmpty) {
                    self.statusText = "اختر صلاة واحدة على الأقل للتنبيه"
                } else {
                    self.statusText = events.isEmpty ? "لا توجد صلوات قادمة في الجدول" : "التنبيهات مفعلة للصلوات المختارة"
                }
            }
        }
    }

    private func upcomingNotificationEvents() -> [ScheduledPrayerNotification] {
        let now = Date()
        let events = PrayerEngine.availableDateKeys.flatMap { dateKey in
            PrayerEngine.prayerOrder.flatMap { key -> [ScheduledPrayerNotification] in
                guard let time = PrayerEngine.schedule(for: dateKey).times[key],
                      let date = PrayerEngine.date(from: dateKey, time: time) else {
                    return []
                }

                let prayer = PrayerTime(key: key, title: key.title, time: time, date: date)
                var result: [ScheduledPrayerNotification] = []

                if enabledPrayerIDs.contains(key.rawValue), date > now {
                    result.append(ScheduledPrayerNotification(kind: .adhan, prayer: prayer, date: date))
                }

                if isAdhkarReminderEnabled, enabledAdhkarPrayerIDs.contains(key.rawValue) {
                    let reminderDate = date.addingTimeInterval(TimeInterval(adhkarDelayMinutes * 60))
                    if reminderDate > now {
                        result.append(ScheduledPrayerNotification(kind: .adhkar, prayer: prayer, date: reminderDate))
                    }
                }

                return result
            }
        }

        return events
            .sorted { $0.date < $1.date }
            .prefix(maxPendingNotifications)
            .map { $0 }
    }

    private func request(for event: ScheduledPrayerNotification) -> UNNotificationRequest {
        switch event.kind {
        case .adhan:
            return adhanRequest(for: event.prayer, date: event.date)
        case .adhkar:
            return adhkarRequest(for: event.prayer, date: event.date)
        }
    }

    private func adhanRequest(for prayer: PrayerTime, date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "حان وقت صلاة \(prayer.title)"
        content.body = "أذان تل السبع • \(prayer.time)"
        content.sound = notificationSound

        var components = PrayerEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.timeZone = PrayerEngine.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = notificationPrefix + PrayerEngine.calendarIdentifier(for: date) + "-adhan-" + prayer.key.rawValue
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func adhkarRequest(for prayer: PrayerTime, date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "أذكار بعد صلاة \(prayer.title)"
        content.body = selectedAdhkarStyle.notificationBody
        content.sound = .default

        var components = PrayerEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.timeZone = PrayerEngine.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = notificationPrefix + PrayerEngine.calendarIdentifier(for: date) + "-adhkar-" + prayer.key.rawValue
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func schedulePreviewNotification() {
        let content = UNMutableNotificationContent()
        content.title = "معاينة صوت الأذان"
        content.body = "هذا الصوت سيعمل مع الصلوات التي تختارها"
        content.sound = notificationSound

        center.removePendingNotificationRequests(withIdentifiers: [previewNotificationIdentifier])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: previewNotificationIdentifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusText = error == nil ? "ستسمع معاينة الصوت بعد ثانيتين" : "تعذر إرسال معاينة الصوت"
            }
        }
    }

    private var notificationSound: UNNotificationSound {
        switch selectedSound {
        case .system:
            return .default
        case .bundledAdhan:
            for fileName in ["adhan.caf", "adhan.wav", "adhan.aiff"] {
                let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
                guard parts.count == 2 else { continue }

                if Bundle.main.url(forResource: parts[0], withExtension: parts[1]) != nil {
                    return UNNotificationSound(named: UNNotificationSoundName(fileName))
                }
            }

            return .default
        }
    }

    private func removeScheduledPrayerNotifications(completion: (() -> Void)? = nil) {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else {
                completion?()
                return
            }

            let identifiers = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(self.notificationPrefix) }
            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
            completion?()
        }
    }

    private func refreshStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self else { return }
                if self.isEnabled && (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional) {
                    let hasAdhkarSelection = self.isAdhkarReminderEnabled && !self.enabledAdhkarPrayerIDs.isEmpty
                    self.statusText = self.enabledPrayerIDs.isEmpty && !hasAdhkarSelection ? "اختر صلاة واحدة على الأقل للتنبيه" : "التنبيهات مفعلة"
                } else if settings.authorizationStatus == .denied {
                    self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                } else {
                    self.statusText = "التنبيهات غير مفعلة"
                }
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run {
            NotificationCenter.default.post(name: Self.openSettingsNotification, object: nil)
        }
    }
}

private struct ScheduledPrayerNotification {
    enum Kind {
        case adhan
        case adhkar
    }

    let kind: Kind
    let prayer: PrayerTime
    let date: Date
}

extension PrayerEngine {
    static func calendarIdentifier(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Self.timeZone
        formatter.dateFormat = "yyyyMMddHHmm"
        return formatter.string(from: date)
    }
}
