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

enum NafahatReminderInterval: Int, CaseIterable, Identifiable {
    case thirtyMinutes = 30
    case oneHour = 60
    case twoHours = 120
    case threeHours = 180

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .thirtyMinutes:
            return "كل نصف ساعة"
        case .oneHour:
            return "كل ساعة"
        case .twoHours:
            return "كل ساعتين"
        case .threeHours:
            return "كل 3 ساعات"
        }
    }

    var subtitle: String {
        switch self {
        case .thirtyMinutes:
            return "تذكير قريب وخفيف"
        case .oneHour:
            return "توازن جميل خلال اليوم"
        case .twoHours:
            return "هادئ ومناسب للبداية"
        case .threeHours:
            return "تنبيهات قليلة جدًا"
        }
    }
}

struct NafahatReminderMessage {
    let title: String
    let body: String
}

enum NafahatReminderText: String, CaseIterable, Identifiable {
    case salawat
    case istighfar
    case tasbih
    case dua
    case protection
    case gratitude
    case quran
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .salawat:
            return "الصلاة على النبي"
        case .istighfar:
            return "استغفار"
        case .tasbih:
            return "تسبيح"
        case .dua:
            return "أدعية قصيرة"
        case .protection:
            return "تحصين"
        case .gratitude:
            return "شكر"
        case .quran:
            return "آيات وتذكير"
        case .mixed:
            return "منوّع"
        }
    }

    var subtitle: String {
        switch self {
        case .salawat:
            return "اللهم صل وسلم على نبينا محمد"
        case .istighfar:
            return "أستغفر الله وأتوب إليه"
        case .tasbih:
            return "سبحان الله وبحمده"
        case .dua:
            return "أدعية خفيفة كل فترة"
        case .protection:
            return "أذكار تحفظ القلب وتطمئنه"
        case .gratitude:
            return "تذكير بالحمد والرضا"
        case .quran:
            return "آيات قصيرة ومعانٍ لطيفة"
        case .mixed:
            return "يتغير بين صلاة واستغفار وتسبيح ودعاء"
        }
    }

    var systemImage: String {
        switch self {
        case .salawat:
            return "heart.fill"
        case .istighfar:
            return "leaf.fill"
        case .tasbih:
            return "sparkles"
        case .dua:
            return "hands.sparkles.fill"
        case .protection:
            return "shield.lefthalf.filled"
        case .gratitude:
            return "sun.max.fill"
        case .quran:
            return "book.closed.fill"
        case .mixed:
            return "shuffle"
        }
    }

    var messages: [NafahatReminderMessage] {
        switch self {
        case .salawat:
            return [
                NafahatReminderMessage(title: "صلِّ على النبي", body: "اللهم صل وسلم وبارك على نبينا محمد"),
                NafahatReminderMessage(title: "صلاة وسلام", body: "اللهم صل على محمد وعلى آل محمد"),
                NafahatReminderMessage(title: "نَفَحة صلاة", body: "صلِّ على النبي بقلب حاضر"),
                NafahatReminderMessage(title: "محبة النبي", body: "اللهم اجعل صلاتنا عليه نورًا وطمأنينة")
            ]
        case .istighfar:
            return [
                NafahatReminderMessage(title: "استغفار", body: "أستغفر الله العظيم وأتوب إليه"),
                NafahatReminderMessage(title: "باب التوبة", body: "رب اغفر لي وتب علي إنك أنت التواب الرحيم"),
                NafahatReminderMessage(title: "رجوع إلى الله", body: "اللهم اغفر لي ذنبي كله دقه وجله"),
                NafahatReminderMessage(title: "استغفار خفيف", body: "أستغفر الله الذي لا إله إلا هو الحي القيوم وأتوب إليه")
            ]
        case .tasbih:
            return [
                NafahatReminderMessage(title: "تسبيح", body: "سبحان الله وبحمده، سبحان الله العظيم"),
                NafahatReminderMessage(title: "ذكر خفيف", body: "سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر"),
                NafahatReminderMessage(title: "حمد وتسبيح", body: "الحمد لله رب العالمين"),
                NafahatReminderMessage(title: "ذكر طيب", body: "لا حول ولا قوة إلا بالله")
            ]
        case .dua:
            return [
                NafahatReminderMessage(title: "دعاء خفيف", body: "اللهم أعني على ذكرك وشكرك وحسن عبادتك"),
                NafahatReminderMessage(title: "يا رب", body: "اللهم آت نفسي تقواها وزكها أنت خير من زكاها"),
                NafahatReminderMessage(title: "راحة القلب", body: "اللهم اجعل لي من كل هم فرجًا ومن كل ضيق مخرجًا"),
                NafahatReminderMessage(title: "ثبات", body: "يا مقلب القلوب ثبت قلبي على دينك"),
                NafahatReminderMessage(title: "نور", body: "اللهم اجعل في قلبي نورًا وفي سمعي نورًا وفي بصري نورًا")
            ]
        case .protection:
            return [
                NafahatReminderMessage(title: "تحصين", body: "بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء"),
                NafahatReminderMessage(title: "كفاية", body: "حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم"),
                NafahatReminderMessage(title: "طمأنينة", body: "أعوذ بكلمات الله التامات من شر ما خلق"),
                NafahatReminderMessage(title: "حفظ", body: "اللهم احفظني من بين يدي ومن خلفي وعن يميني وعن شمالي")
            ]
        case .gratitude:
            return [
                NafahatReminderMessage(title: "شكر", body: "الحمد لله حمدًا كثيرًا طيبًا مباركًا فيه"),
                NafahatReminderMessage(title: "نعمة", body: "اللهم لك الحمد كما ينبغي لجلال وجهك وعظيم سلطانك"),
                NafahatReminderMessage(title: "رضا", body: "رضيت بالله ربًا وبالإسلام دينًا وبمحمد صلى الله عليه وسلم نبيًا")
            ]
        case .quran:
            return [
                NafahatReminderMessage(title: "تذكير قرآني", body: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ"),
                NafahatReminderMessage(title: "واذكر ربك", body: "وَاذْكُر رَّبَّكَ إِذَا نَسِيتَ"),
                NafahatReminderMessage(title: "نور", body: "اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ"),
                NafahatReminderMessage(title: "سعة", body: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا")
            ]
        case .mixed:
            return NafahatReminderText.salawat.messages
                + NafahatReminderText.istighfar.messages
                + NafahatReminderText.tasbih.messages
                + NafahatReminderText.dua.messages
                + NafahatReminderText.protection.messages
                + NafahatReminderText.gratitude.messages
                + NafahatReminderText.quran.messages
        }
    }
}

enum NafahatQuietWindow: String, CaseIterable, Identifiable {
    case none
    case lateNight
    case midnight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            return "بدون هدوء"
        case .lateNight:
            return "راحة الليل"
        case .midnight:
            return "هدوء عميق"
        }
    }

    var subtitle: String {
        switch self {
        case .none:
            return "تعمل النفحات طوال اليوم"
        case .lateNight:
            return "تتوقف من 11 ليلًا إلى 6 صباحًا"
        case .midnight:
            return "تتوقف من 12 ليلًا إلى 7 صباحًا"
        }
    }

    var systemImage: String {
        switch self {
        case .none:
            return "bell.fill"
        case .lateNight:
            return "moon.stars.fill"
        case .midnight:
            return "moon.zzz.fill"
        }
    }

    var hours: (start: Int, end: Int)? {
        switch self {
        case .none:
            return nil
        case .lateNight:
            return (23, 6)
        case .midnight:
            return (0, 7)
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
    private static let nafahatEnabledKey = "prayer_notifications_nafahat_enabled"
    private static let nafahatIntervalMinutesKey = "prayer_notifications_nafahat_interval_minutes"
    private static let selectedNafahatTextIDKey = "prayer_notifications_nafahat_text"
    private static let selectedNafahatQuietWindowIDKey = "prayer_notifications_nafahat_quiet_window"

    static let shared = PrayerNotificationManager()

    @Published private(set) var isEnabled = UserDefaults.standard.bool(forKey: PrayerNotificationManager.enabledKey)
    @Published private(set) var statusText = "التنبيهات غير مفعلة"
    @Published private(set) var enabledPrayerIDs: Set<String>
    @Published private(set) var selectedSoundID: String
    @Published private(set) var isAdhkarReminderEnabled: Bool
    @Published private(set) var adhkarDelayMinutes: Int
    @Published private(set) var enabledAdhkarPrayerIDs: Set<String>
    @Published private(set) var selectedAdhkarStyleID: String
    @Published private(set) var isNafahatEnabled: Bool
    @Published private(set) var nafahatIntervalMinutes: Int
    @Published private(set) var selectedNafahatTextID: String
    @Published private(set) var selectedNafahatQuietWindowID: String

    private let center = UNUserNotificationCenter.current()
    private let notificationPrefix = "tel-sheva-prayer-"
    private let previewNotificationIdentifier = "tel-sheva-prayer-preview"
    private let maxPendingNotifications = 60
    private let defaults = UserDefaults.standard
    private var pendingRescheduleWork: DispatchWorkItem?

    private var selectedSound: PrayerNotificationSound {
        PrayerNotificationSound(rawValue: selectedSoundID) ?? .bundledAdhan
    }

    private var selectedAdhkarStyle: AdhkarReminderStyle {
        AdhkarReminderStyle(rawValue: selectedAdhkarStyleID) ?? .tasbih
    }

    private var selectedNafahatInterval: NafahatReminderInterval {
        NafahatReminderInterval(rawValue: nafahatIntervalMinutes) ?? .twoHours
    }

    private var selectedNafahatText: NafahatReminderText {
        NafahatReminderText(rawValue: selectedNafahatTextID) ?? .mixed
    }

    private var selectedNafahatQuietWindow: NafahatQuietWindow {
        NafahatQuietWindow(rawValue: selectedNafahatQuietWindowID) ?? .lateNight
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
        isNafahatEnabled = UserDefaults.standard.bool(forKey: Self.nafahatEnabledKey)
        let savedNafahatInterval = UserDefaults.standard.integer(forKey: Self.nafahatIntervalMinutesKey)
        nafahatIntervalMinutes = savedNafahatInterval == 0 ? NafahatReminderInterval.twoHours.rawValue : savedNafahatInterval
        let savedNafahatTextID = UserDefaults.standard.string(forKey: Self.selectedNafahatTextIDKey)
        selectedNafahatTextID = savedNafahatTextID ?? NafahatReminderText.mixed.rawValue
        let savedNafahatQuietID = UserDefaults.standard.string(forKey: Self.selectedNafahatQuietWindowIDKey)
        selectedNafahatQuietWindowID = savedNafahatQuietID ?? NafahatQuietWindow.lateNight.rawValue

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

    func setNafahatEnabled(_ enabled: Bool) {
        isNafahatEnabled = enabled
        defaults.set(enabled, forKey: Self.nafahatEnabledKey)

        if enabled && !isEnabled {
            enable()
        } else {
            rescheduleIfEnabled()
        }
    }

    func setNafahatInterval(_ interval: NafahatReminderInterval) {
        nafahatIntervalMinutes = interval.rawValue
        defaults.set(interval.rawValue, forKey: Self.nafahatIntervalMinutesKey)
        rescheduleIfEnabled()
    }

    func selectNafahatText(_ text: NafahatReminderText) {
        selectedNafahatTextID = text.rawValue
        defaults.set(text.rawValue, forKey: Self.selectedNafahatTextIDKey)
        rescheduleIfEnabled()
    }

    func selectNafahatQuietWindow(_ window: NafahatQuietWindow) {
        selectedNafahatQuietWindowID = window.rawValue
        defaults.set(window.rawValue, forKey: Self.selectedNafahatQuietWindowIDKey)
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

    func sendNafahatPreviewNotification() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.scheduleNafahatPreviewNotification()
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
                        self.scheduleNafahatPreviewNotification()
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

    private func rescheduleIfEnabled() {
        guard isEnabled else {
            refreshStatus()
            return
        }

        pendingRescheduleWork?.cancel()
        statusText = "جاري تحديث التنبيهات..."

        let work = DispatchWorkItem { [weak self] in
            self?.scheduleUpcomingPrayerNotifications()
        }
        pendingRescheduleWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
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
                if self.enabledPrayerIDs.isEmpty && (!self.isAdhkarReminderEnabled || self.enabledAdhkarPrayerIDs.isEmpty) && !self.isNafahatEnabled {
                    self.statusText = "اختر صلاة واحدة على الأقل للتنبيه"
                } else {
                    self.statusText = events.isEmpty ? "لا توجد صلوات قادمة في الجدول" : "التنبيهات مفعلة للصلوات المختارة"
                }
            }
        }
    }

    private func upcomingNotificationEvents() -> [ScheduledPrayerNotification] {
        let now = Date()
        var events = PrayerEngine.availableDateKeys.flatMap { dateKey in
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

        events.append(contentsOf: upcomingNafahatEvents(now: now))

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
        case .nafahat:
            return nafahatRequest(for: event.nafahatMessage ?? nafahatMessage(for: 0, date: event.date), date: event.date)
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

    private func nafahatRequest(for message: NafahatReminderMessage, date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = nafahatNotificationSound

        var components = PrayerEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.timeZone = PrayerEngine.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = notificationPrefix + PrayerEngine.calendarIdentifier(for: date) + "-nafahat"
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func upcomingNafahatEvents(now: Date) -> [ScheduledPrayerNotification] {
        guard isNafahatEnabled else { return [] }

        var events: [ScheduledPrayerNotification] = []
        var date = now.addingTimeInterval(TimeInterval(selectedNafahatInterval.rawValue * 60))
        let end = now.addingTimeInterval(3 * 24 * 60 * 60)
        var index = 0

        while date < end && events.count < 24 {
            if !isWithinQuietWindow(date) && !isNearPrayerTime(date) {
                events.append(
                    ScheduledPrayerNotification(
                        kind: .nafahat,
                        prayer: PrayerTime(key: .fajr, title: "", time: "", date: date),
                        date: date,
                        nafahatMessage: nafahatMessage(for: index, date: date)
                    )
                )
                index += 1
            }

            date = date.addingTimeInterval(TimeInterval(selectedNafahatInterval.rawValue * 60))
        }

        return events
    }

    private func nafahatMessage(for index: Int, date: Date = Date()) -> NafahatReminderMessage {
        let messages = selectedNafahatText.messages
        guard !messages.isEmpty else {
            return NafahatReminderMessage(title: "نَفَحة ذكر", body: "اذكر الله ذكرًا خفيفًا")
        }

        if selectedNafahatText == .mixed {
            let seed = Int(date.timeIntervalSince1970 / 60)
            return messages[abs(seed + (index * 13)) % messages.count]
        }

        return messages[index % messages.count]
    }

    private func isWithinQuietWindow(_ date: Date) -> Bool {
        guard let hours = selectedNafahatQuietWindow.hours else { return false }
        let hour = PrayerEngine.calendar.component(.hour, from: date)

        if hours.start < hours.end {
            return hour >= hours.start && hour < hours.end
        }

        return hour >= hours.start || hour < hours.end
    }

    private func isNearPrayerTime(_ date: Date) -> Bool {
        let dateKey = PrayerEngine.defaultDateKey(for: date)
        let schedule = PrayerEngine.schedule(for: dateKey)

        return PrayerEngine.prayerOrder.contains { key in
            guard let time = schedule.times[key],
                  let prayerDate = PrayerEngine.date(from: dateKey, time: time) else {
                return false
            }

            return abs(date.timeIntervalSince(prayerDate)) <= 10 * 60
        }
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

    private func scheduleNafahatPreviewNotification() {
        let previewDate = Date()
        let message = nafahatMessage(for: Int(previewDate.timeIntervalSince1970), date: previewDate)
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = nafahatNotificationSound

        let identifier = previewNotificationIdentifier + "-nafahat"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusText = error == nil ? "ستصلك نَفَحة تجريبية بعد ثانيتين" : "تعذر إرسال اختبار النَفَحة"
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

    private var nafahatNotificationSound: UNNotificationSound {
        for fileName in ["nafahat.wav", "nafahat.caf", "nafahat.aiff"] {
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
                    let hasAdhkarSelection = self.isAdhkarReminderEnabled && !self.enabledAdhkarPrayerIDs.isEmpty
                    self.statusText = self.enabledPrayerIDs.isEmpty && !hasAdhkarSelection && !self.isNafahatEnabled ? "اختر صلاة واحدة على الأقل للتنبيه" : "التنبيهات مفعلة"
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
        case nafahat
    }

    let kind: Kind
    let prayer: PrayerTime
    let date: Date
    var nafahatMessage: NafahatReminderMessage? = nil
}

extension PrayerEngine {
    static func calendarIdentifier(for date: Date) -> String {
        let components = Self.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return String(
            format: "%04d%02d%02d%02d%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0,
            components.hour ?? 0,
            components.minute ?? 0
        )
    }
}
