import Combine
import Foundation
import UserNotifications

final class PrayerNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    private static let enabledKey = "prayer_notifications_enabled"

    static let shared = PrayerNotificationManager()

    @Published private(set) var isEnabled = UserDefaults.standard.bool(forKey: PrayerNotificationManager.enabledKey)
    @Published private(set) var statusText = "التنبيهات غير مفعلة"

    private let center = UNUserNotificationCenter.current()
    private let notificationPrefix = "tel-sheva-prayer-"
    private let testNotificationIdentifier = "tel-sheva-prayer-test"
    private let maxPendingNotifications = 60

    private override init() {
        super.init()
        center.delegate = self
        refreshStatus()
    }

    func enable() {
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self else { return }

                self.isEnabled = granted
                UserDefaults.standard.set(granted, forKey: Self.enabledKey)

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
        UserDefaults.standard.set(false, forKey: Self.enabledKey)
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
                    UserDefaults.standard.set(false, forKey: Self.enabledKey)
                    self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                }
            }
        }
    }

    func toggle() {
        isEnabled ? disable() : enable()
    }

    func sendTestNotification() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.scheduleTestNotification()
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        guard granted else {
                            self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                            return
                        }

                        self.scheduleTestNotification()
                    }
                }
            default:
                DispatchQueue.main.async {
                    self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                }
            }
        }
    }

    private func scheduleUpcomingPrayerNotifications() {
        let events = upcomingPrayerEvents()
        removeScheduledPrayerNotifications {
            for event in events {
                self.center.add(self.request(for: event))
            }

            DispatchQueue.main.async {
                self.statusText = events.isEmpty ? "لا توجد صلوات قادمة في الجدول" : "التنبيهات مفعلة للصلوات القادمة"
            }
        }
    }

    private func upcomingPrayerEvents() -> [PrayerTime] {
        let now = Date()
        return PrayerEngine.availableDateKeys
            .flatMap { dateKey in
                PrayerEngine.prayerOrder.compactMap { key -> PrayerTime? in
                    let schedule = PrayerEngine.schedule(for: dateKey)
                    guard let time = schedule.times[key],
                          let date = PrayerEngine.date(from: schedule.dateKey, time: time),
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

    private func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "تجربة إشعار الأذان"
        content.body = "هذا شكل إشعار أذان تل السبع"
        content.sound = notificationSound

        center.removePendingNotificationRequests(withIdentifiers: [testNotificationIdentifier])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: testNotificationIdentifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusText = error == nil ? "سيظهر إشعار تجربة بعد 5 ثواني" : "تعذر إرسال إشعار التجربة"
            }
        }
    }

    private var notificationSound: UNNotificationSound {
        for fileName in ["adhan.caf", "adhan.wav", "adhan.aiff"] {
            let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            if Bundle.main.url(forResource: parts[0], withExtension: parts[1]) != nil {
                return UNNotificationSound(named: UNNotificationSoundName(fileName))
            }
        }

        return .default
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
                    self.statusText = "التنبيهات مفعلة"
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
