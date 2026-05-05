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

final class PrayerNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let openSettingsNotification = Notification.Name("PrayerNotificationManagerOpenSettings")

    private static let enabledKey = "prayer_notifications_enabled"
    private static let enabledPrayerIDsKey = "prayer_notifications_enabled_prayers"
    private static let selectedSoundIDKey = "prayer_notifications_selected_sound"

    static let shared = PrayerNotificationManager()

    @Published private(set) var isEnabled = UserDefaults.standard.bool(forKey: PrayerNotificationManager.enabledKey)
    @Published private(set) var statusText = "التنبيهات غير مفعلة"
    @Published private(set) var enabledPrayerIDs: Set<String>
    @Published private(set) var selectedSoundID: String

    private let center = UNUserNotificationCenter.current()
    private let notificationPrefix = "tel-sheva-prayer-"
    private let previewNotificationIdentifier = "tel-sheva-prayer-preview"
    private let maxPendingNotifications = 60
    private let defaults = UserDefaults.standard

    private var selectedSound: PrayerNotificationSound {
        PrayerNotificationSound(rawValue: selectedSoundID) ?? .bundledAdhan
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

    private func scheduleUpcomingPrayerNotifications() {
        let events = upcomingPrayerEvents()
        removeScheduledPrayerNotifications {
            for event in events {
                self.center.add(self.request(for: event))
            }

            DispatchQueue.main.async {
                if self.enabledPrayerIDs.isEmpty {
                    self.statusText = "اختر صلاة واحدة على الأقل للتنبيه"
                } else {
                    self.statusText = events.isEmpty ? "لا توجد صلوات قادمة في الجدول" : "التنبيهات مفعلة للصلوات المختارة"
                }
            }
        }
    }

    private func upcomingPrayerEvents() -> [PrayerTime] {
        let now = Date()
        return PrayerEngine.availableDateKeys
            .flatMap { dateKey in
                PrayerEngine.prayerOrder.compactMap { key -> PrayerTime? in
                    guard enabledPrayerIDs.contains(key.rawValue),
                          let time = PrayerEngine.schedule(for: dateKey).times[key],
                          let date = PrayerEngine.date(from: dateKey, time: time),
                          date > now else {
                        return nil
                    }

                    return PrayerTime(key: key, title: key.title, time: time, date: date)
                }
            }
            .sorted { $0.date < $1.date }
            .prefix(maxPendingNotifications)
            .map { $0 }
    }

    private func request(for prayer: PrayerTime) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "حان وقت صلاة \(prayer.title)"
        content.body = "أذان تل السبع • \(prayer.time)"
        content.sound = notificationSound

        var components = PrayerEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: prayer.date)
        components.timeZone = PrayerEngine.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = notificationPrefix + PrayerEngine.calendarIdentifier(for: prayer.date) + "-" + prayer.key.rawValue
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func schedulePreviewNotification() {
        let content = UNMutableNotificationContent()
        content.title = "معاينة صوت الأذان"
        content.body = "هذا الصوت سيعمل مع الصلوات التي تختارها"
        content.sound = notificationSound

        center.removePendingNotificationRequests(withIdentifiers: [previewNotificationIdentifier])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: previewNotificationIdentifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusText = error == nil ? "ستسمع معاينة الصوت بعد 5 ثواني" : "تعذر إرسال معاينة الصوت"
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
                    self.statusText = self.enabledPrayerIDs.isEmpty ? "اختر صلاة واحدة على الأقل للتنبيه" : "التنبيهات مفعلة"
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

extension PrayerEngine {
    static func calendarIdentifier(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = Self.timeZone
        formatter.dateFormat = "yyyyMMddHHmm"
        return formatter.string(from: date)
    }
}
