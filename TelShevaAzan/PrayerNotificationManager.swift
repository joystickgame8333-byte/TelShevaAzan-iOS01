import Combine
import Foundation
import UserNotifications

enum PrayerNotificationSound: String, CaseIterable, Identifiable {
    case originalAdhan
    case bundledAdhan
    case softDhikr
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .originalAdhan:
            return "الأذان الأول"
        case .bundledAdhan:
            return "الأذان الثاني"
        case .softDhikr:
            return "رسالة إشعار"
        case .system:
            return "صوت الآيفون"
        }
    }

    var subtitle: String {
        switch self {
        case .originalAdhan:
            return "الصوت الأساسي للأذان"
        case .bundledAdhan:
            return "الأذان الثاني بصوت مختلف"
        case .softDhikr:
            return "صوت هادئ لمن يريد تنبيهًا أخف"
        case .system:
            return "تنبيه قصير من النظام بدون أذان"
        }
    }

    var systemImage: String {
        switch self {
        case .originalAdhan:
            return "speaker.wave.2.circle.fill"
        case .bundledAdhan:
            return "waveform.circle.fill"
        case .softDhikr:
            return "sparkles"
        case .system:
            return "iphone.gen3.radiowaves.left.and.right"
        }
    }
}

enum AdhkarNotificationSound: String, CaseIterable, Identifiable {
    case sakinah
    case noor
    case nada
    case tumanina
    case nasim

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sakinah:
            return "سكينة"
        case .noor:
            return "نور"
        case .nada:
            return "ندى"
        case .tumanina:
            return "طمأنينة"
        case .nasim:
            return "نسيم"
        }
    }

    var subtitle: String {
        switch self {
        case .sakinah:
            return "نغمة دافئة وهادئة من درجتين"
        case .noor:
            return "رنين صافي ومشرق قصير"
        case .nada:
            return "جرس رقيق وخفيف"
        case .tumanina:
            return "نغمة دافئة متدرجة بهدوء"
        case .nasim:
            return "تنبيه ناعم وسريع"
        }
    }

    var systemImage: String {
        switch self {
        case .sakinah:
            return "moon.stars.fill"
        case .noor:
            return "sun.max.fill"
        case .nada:
            return "drop.fill"
        case .tumanina:
            return "heart.fill"
        case .nasim:
            return "wind"
        }
    }
}

enum FajrAlarmIntensity: String, CaseIterable, Identifiable {
    case gentle
    case strong
    case wakeUp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle:
            return "هادئ"
        case .strong:
            return "قوي"
        case .wakeUp:
            return "إيقاظ"
        }
    }

    var subtitle: String {
        switch self {
        case .gentle:
            return "تنبيه واحد عند الفجر"
        case .strong:
            return "الفجر ثم تذكيران بعده"
        case .wakeUp:
            return "تكرار قريب مثل المنبه حتى تنتبه"
        }
    }

    var systemImage: String {
        switch self {
        case .gentle:
            return "bell.fill"
        case .strong:
            return "bell.and.waves.left.and.right.fill"
        case .wakeUp:
            return "alarm.fill"
        }
    }

    var repeatOffsetsMinutes: [Int] {
        switch self {
        case .gentle:
            return [0]
        case .strong:
            return [0, 2, 5]
        case .wakeUp:
            return [0, 1, 3, 5, 8]
        }
    }
}

enum FajrAlarmSound: String, CaseIterable, Identifiable {
    case classicAlarm
    case morningClock
    case clockBeep
    case digitalBuzzer
    case vintageWarning
    case alert
    case emergencyAlert
    case warningBuzzer
    case facilityAlarm
    case hallAlert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicAlarm:
            return "منبه كلاسيكي"
        case .morningClock:
            return "منبه صباحي"
        case .clockBeep:
            return "بيب الساعة"
        case .digitalBuzzer:
            return "جرس رقمي"
        case .vintageWarning:
            return "تحذير قديم"
        case .alert:
            return "تنبيه حاد"
        case .emergencyAlert:
            return "إيقاظ قوي"
        case .warningBuzzer:
            return "جرس مزعج"
        case .facilityAlarm:
            return "تنبيه طويل"
        case .hallAlert:
            return "صدى القاعة"
        }
    }

    var subtitle: String {
        switch self {
        case .classicAlarm:
            return "صوت ساعة منبه واضح وقصير"
        case .morningClock:
            return "أقرب إحساس لمنبه صباح حقيقي"
        case .clockBeep:
            return "بيب ثابت ومباشر"
        case .digitalBuzzer:
            return "نغمة رقمية تشبه منبه الآيفون"
        case .vintageWarning:
            return "قوي بطابع قديم"
        case .alert:
            return "حاد ومختصر لمن يريد تنبيه سريع"
        case .emergencyAlert:
            return "أقوى خيار للإيقاظ"
        case .warningBuzzer:
            return "مزعج كفاية للغفلة الثقيلة"
        case .facilityAlarm:
            return "طويل وواضح بدون تجاوز حد iOS"
        case .hallAlert:
            return "نظيف وفيه صدى واضح"
        }
    }

    var systemImage: String {
        switch self {
        case .classicAlarm, .morningClock:
            return "alarm.fill"
        case .clockBeep, .digitalBuzzer:
            return "waveform.circle.fill"
        case .vintageWarning, .warningBuzzer:
            return "bell.and.waves.left.and.right.fill"
        case .alert, .emergencyAlert:
            return "speaker.wave.3.fill"
        case .facilityAlarm, .hallAlert:
            return "dot.radiowaves.left.and.right"
        }
    }

    var fileNames: [String] {
        switch self {
        case .classicAlarm:
            return ["fajr-alarm-01-classic-alarm.wav"]
        case .morningClock:
            return ["fajr-alarm-02-morning-clock.wav"]
        case .clockBeep:
            return ["fajr-alarm-03-clock-beep.wav"]
        case .digitalBuzzer:
            return ["fajr-alarm-04-digital-buzzer.wav"]
        case .vintageWarning:
            return ["fajr-alarm-05-vintage-warning.wav"]
        case .alert:
            return ["fajr-alarm-06-alert.wav"]
        case .emergencyAlert:
            return ["fajr-alarm-07-emergency-alert.wav"]
        case .warningBuzzer:
            return ["fajr-alarm-08-warning-buzzer.wav"]
        case .facilityAlarm:
            return ["fajr-alarm-09-facility-alarm.wav"]
        case .hallAlert:
            return ["fajr-alarm-10-hall-alert.wav"]
        }
    }
}

struct FajrAlarmPresentation: Identifiable, Equatable {
    let id = UUID()
    let dateKey: String?
    let title: String
    let body: String
    let soundFileNames: [String]
    let snoozeMinutes: Int
}

struct PrayerNotificationDiagnostics: Equatable {
    var permissionText = "جاري فحص الإذن..."
    var isAuthorized = false
    var alertsEnabled = false
    var soundsEnabled = false
    var lockScreenEnabled = false
    var timeSensitiveEnabled = false
    var selectedSoundAvailable = false
    var scheduledPrayerCount = 0
    var scheduledNafahatCount = 0
    var firstPrayerDate: Date?
    var lastPrayerDate: Date?
    var checkedAt = Date()
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
    case lightReminders
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
        case .lightReminders:
            return "إشعارات خفيفة"
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
        case .lightReminders:
            return "عبارات إيمانية قصيرة تصل بهدوء"
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
        case .lightReminders:
            return "bell.and.waves.left.and.right.fill"
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
                NafahatReminderMessage(title: "ذكر الصلاة", body: "صلِّ على النبي بقلب حاضر"),
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
        case .lightReminders:
            return [
                NafahatReminderMessage(title: "ذكر خفيف", body: "سبحان الله وبحمده"),
                NafahatReminderMessage(title: "استغفار", body: "أستغفر الله وأتوب إليه"),
                NafahatReminderMessage(title: "دعاء قصير", body: "اللهم أعني على ذكرك وشكرك وحسن عبادتك"),
                NafahatReminderMessage(title: "طمأنينة", body: "لا حول ولا قوة إلا بالله"),
                NafahatReminderMessage(title: "دعوة جامعة", body: "ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة")
            ]
        case .mixed:
            return NafahatReminderText.salawat.messages
                + NafahatReminderText.istighfar.messages
                + NafahatReminderText.tasbih.messages
                + NafahatReminderText.dua.messages
                + NafahatReminderText.protection.messages
                + NafahatReminderText.gratitude.messages
                + NafahatReminderText.quran.messages
                + NafahatReminderText.lightReminders.messages
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
            return "تعمل الأذكار طوال اليوم"
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
    static let openScheduleNotification = Notification.Name("PrayerNotificationManagerOpenSchedule")
    static let presentFajrAlarmNotification = Notification.Name("PrayerNotificationManagerPresentFajrAlarm")

    private static let enabledKey = "prayer_notifications_enabled"
    private static let enabledPrayerIDsKey = "prayer_notifications_enabled_prayers"
    private static let selectedSoundIDKey = "prayer_notifications_selected_sound"
    private static let iqamaEnabledKey = "prayer_notifications_iqama_enabled"
    private static let adhkarEnabledKey = "prayer_notifications_adhkar_enabled"
    private static let adhkarDelayMinutesKey = "prayer_notifications_adhkar_delay_minutes"
    private static let adhkarPrayerIDsKey = "prayer_notifications_adhkar_prayers"
    private static let selectedAdhkarStyleIDKey = "prayer_notifications_adhkar_style"
    private static let selectedAdhkarSoundIDKey = "prayer_notifications_adhkar_sound"
    private static let nafahatEnabledKey = "prayer_notifications_nafahat_enabled"
    private static let nafahatIntervalMinutesKey = "prayer_notifications_nafahat_interval_minutes"
    private static let selectedNafahatTextIDKey = "prayer_notifications_nafahat_text"
    private static let selectedNafahatQuietWindowIDKey = "prayer_notifications_nafahat_quiet_window"
    private static let fajrAlarmEnabledKey = "prayer_notifications_fajr_alarm_enabled"
    private static let selectedFajrAlarmIntensityIDKey = "prayer_notifications_fajr_alarm_intensity"
    private static let selectedFajrAlarmSoundIDKey = "prayer_notifications_fajr_alarm_sound"
    private static let fajrAlarmWakeBeforeMinutesKey = "prayer_notifications_fajr_alarm_wake_before"
    private static let fajrAlarmSnoozeMinutesKey = "prayer_notifications_fajr_alarm_snooze"
    private static let fajrAlarmCategoryID = "tel-sheva-fajr-alarm-category"
    private static let fajrAlarmAwakeActionID = "tel-sheva-fajr-alarm-awake"
    private static let fajrAlarmSnoozeActionID = "tel-sheva-fajr-alarm-snooze"

    static let shared = PrayerNotificationManager()

    @Published private(set) var isEnabled = UserDefaults.standard.bool(forKey: PrayerNotificationManager.enabledKey)
    @Published private(set) var statusText = "التنبيهات غير مفعلة"
    @Published private(set) var enabledPrayerIDs: Set<String>
    @Published private(set) var selectedSoundID: String
    @Published private(set) var isIqamaNotificationEnabled: Bool
    @Published private(set) var isAdhkarReminderEnabled: Bool
    @Published private(set) var adhkarDelayMinutes: Int
    @Published private(set) var enabledAdhkarPrayerIDs: Set<String>
    @Published private(set) var selectedAdhkarStyleID: String
    @Published private(set) var selectedAdhkarSoundID: String
    @Published private(set) var isNafahatEnabled: Bool
    @Published private(set) var nafahatIntervalMinutes: Int
    @Published private(set) var selectedNafahatTextID: String
    @Published private(set) var selectedNafahatQuietWindowID: String
    @Published private(set) var isFajrAlarmEnabled: Bool
    @Published private(set) var selectedFajrAlarmIntensityID: String
    @Published private(set) var selectedFajrAlarmSoundID: String
    @Published private(set) var fajrAlarmWakeBeforeMinutes: Int
    @Published private(set) var fajrAlarmSnoozeMinutes: Int
    @Published private(set) var pendingFajrAlarmPresentation: FajrAlarmPresentation?
    @Published private(set) var diagnostics = PrayerNotificationDiagnostics()

    private let center = UNUserNotificationCenter.current()
    private let legacyNotificationPrefix = "tel-sheva-prayer-"
    private let scheduledNotificationPrefix = "tel-sheva-prayer-scheduled-"
    private let previewNotificationPrefix = "tel-sheva-prayer-preview"
    private let previewNotificationIdentifier = "tel-sheva-prayer-preview"
    private let maxPendingNotifications = 60
    private let prayerSlotsWhenNafahatEnabled = 50
    private let defaults = UserDefaults.standard
    private var pendingRescheduleWork: DispatchWorkItem?
    private var schedulingGeneration = 0

    private var selectedSound: PrayerNotificationSound {
        PrayerNotificationSound(rawValue: selectedSoundID) ?? .originalAdhan
    }

    private var selectedAdhkarStyle: AdhkarReminderStyle {
        AdhkarReminderStyle(rawValue: selectedAdhkarStyleID) ?? .tasbih
    }

    private var selectedAdhkarSound: AdhkarNotificationSound {
        AdhkarNotificationSound(rawValue: selectedAdhkarSoundID) ?? .sakinah
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

    private var selectedFajrAlarmIntensity: FajrAlarmIntensity {
        FajrAlarmIntensity(rawValue: selectedFajrAlarmIntensityID) ?? .wakeUp
    }

    private var selectedFajrAlarmSound: FajrAlarmSound {
        FajrAlarmSound(rawValue: selectedFajrAlarmSoundID) ?? .morningClock
    }

    private override init() {
        let savedPrayerIDs = UserDefaults.standard.stringArray(forKey: Self.enabledPrayerIDsKey)
        if let savedPrayerIDs {
            enabledPrayerIDs = Set(savedPrayerIDs)
        } else {
            enabledPrayerIDs = Set(PrayerEngine.prayerOrder.map(\.rawValue))
        }

        let savedSoundID = UserDefaults.standard.string(forKey: Self.selectedSoundIDKey)
        selectedSoundID = savedSoundID ?? PrayerNotificationSound.originalAdhan.rawValue
        isIqamaNotificationEnabled = UserDefaults.standard.bool(forKey: Self.iqamaEnabledKey)
        isAdhkarReminderEnabled = UserDefaults.standard.bool(forKey: Self.adhkarEnabledKey)
        let savedDelay = UserDefaults.standard.integer(forKey: Self.adhkarDelayMinutesKey)
        adhkarDelayMinutes = savedDelay == 0 ? 5 : savedDelay

        let savedAdhkarPrayerIDs = UserDefaults.standard.stringArray(forKey: Self.adhkarPrayerIDsKey)
        enabledAdhkarPrayerIDs = Set(savedAdhkarPrayerIDs ?? [])

        let savedAdhkarStyleID = UserDefaults.standard.string(forKey: Self.selectedAdhkarStyleIDKey)
        selectedAdhkarStyleID = savedAdhkarStyleID ?? AdhkarReminderStyle.tasbih.rawValue
        let savedAdhkarSoundID = UserDefaults.standard.string(forKey: Self.selectedAdhkarSoundIDKey)
        selectedAdhkarSoundID = AdhkarNotificationSound(rawValue: savedAdhkarSoundID ?? "")?.rawValue
            ?? AdhkarNotificationSound.sakinah.rawValue
        isNafahatEnabled = UserDefaults.standard.bool(forKey: Self.nafahatEnabledKey)
        let savedNafahatInterval = UserDefaults.standard.integer(forKey: Self.nafahatIntervalMinutesKey)
        nafahatIntervalMinutes = savedNafahatInterval == 0 ? NafahatReminderInterval.twoHours.rawValue : savedNafahatInterval
        let savedNafahatTextID = UserDefaults.standard.string(forKey: Self.selectedNafahatTextIDKey)
        selectedNafahatTextID = savedNafahatTextID ?? NafahatReminderText.mixed.rawValue
        let savedNafahatQuietID = UserDefaults.standard.string(forKey: Self.selectedNafahatQuietWindowIDKey)
        selectedNafahatQuietWindowID = savedNafahatQuietID ?? NafahatQuietWindow.lateNight.rawValue
        isFajrAlarmEnabled = false
        UserDefaults.standard.set(false, forKey: Self.fajrAlarmEnabledKey)
        let savedFajrIntensityID = UserDefaults.standard.string(forKey: Self.selectedFajrAlarmIntensityIDKey)
        selectedFajrAlarmIntensityID = savedFajrIntensityID ?? FajrAlarmIntensity.wakeUp.rawValue
        let savedFajrSoundID = UserDefaults.standard.string(forKey: Self.selectedFajrAlarmSoundIDKey)
        selectedFajrAlarmSoundID = FajrAlarmSound(rawValue: savedFajrSoundID ?? "")?.rawValue ?? FajrAlarmSound.morningClock.rawValue
        let savedWakeBefore = UserDefaults.standard.object(forKey: Self.fajrAlarmWakeBeforeMinutesKey) as? Int
        fajrAlarmWakeBeforeMinutes = savedWakeBefore ?? 0
        let savedSnooze = UserDefaults.standard.object(forKey: Self.fajrAlarmSnoozeMinutesKey) as? Int
        fajrAlarmSnoozeMinutes = savedSnooze ?? 5

        super.init()
        center.delegate = self
        registerNotificationCategories()
        removePendingFajrAlarmNotifications(for: nil)
        refreshStatus()
        refreshDiagnostics()
    }

    private func registerNotificationCategories() {
        center.setNotificationCategories([])
    }

    func enable() {
        center.requestAuthorization(options: [.alert, .sound, .timeSensitive]) { [weak self] granted, error in
            DispatchQueue.main.async {
                guard let self else { return }

                if error != nil {
                    self.isEnabled = false
                    self.defaults.set(false, forKey: Self.enabledKey)
                    self.statusText = "تعذر طلب إذن التنبيهات"
                    self.refreshDiagnostics()
                    return
                }

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

    func enableWelcomeDefaults() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional:
                DispatchQueue.main.async {
                    self.applyWelcomeDefaults()
                    self.isEnabled = true
                    self.defaults.set(true, forKey: Self.enabledKey)
                    self.scheduleUpcomingPrayerNotifications()
                }
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .timeSensitive]) { [weak self] granted, error in
                    DispatchQueue.main.async {
                        guard let self else { return }

                        guard error == nil, granted else {
                            self.statusText = error == nil
                                ? "اسمح بالإشعارات من إعدادات الآيفون"
                                : "تعذر طلب إذن التنبيهات"
                            self.refreshDiagnostics()
                            return
                        }

                        self.applyWelcomeDefaults()
                        self.isEnabled = true
                        self.defaults.set(true, forKey: Self.enabledKey)
                        self.scheduleUpcomingPrayerNotifications()
                    }
                }
            default:
                DispatchQueue.main.async {
                    self.applyWelcomeDefaults()
                    self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                }
            }
        }
    }

    func disable() {
        pendingRescheduleWork?.cancel()
        pendingRescheduleWork = nil
        schedulingGeneration &+= 1
        isEnabled = false
        defaults.set(false, forKey: Self.enabledKey)
        removeScheduledPrayerNotifications { [weak self] in
            self?.refreshDiagnostics()
        }
        statusText = "التنبيهات غير مفعلة"
    }

    func refreshIfEnabled() {
        guard isEnabled else {
            refreshStatus()
            refreshDiagnostics()
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
                    self.removeScheduledPrayerNotifications { [weak self] in
                        self?.refreshDiagnostics()
                    }
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

    func setIqamaNotificationEnabled(_ enabled: Bool) {
        isIqamaNotificationEnabled = enabled
        defaults.set(enabled, forKey: Self.iqamaEnabledKey)

        if enabled && !isEnabled {
            enable()
        } else {
            rescheduleIfEnabled()
        }
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

    func selectAdhkarSound(_ sound: AdhkarNotificationSound) {
        selectedAdhkarSoundID = sound.rawValue
        defaults.set(sound.rawValue, forKey: Self.selectedAdhkarSoundIDKey)
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

    func setFajrAlarmEnabled(_ enabled: Bool) {
        isFajrAlarmEnabled = false
        defaults.set(false, forKey: Self.fajrAlarmEnabledKey)
        removePendingFajrAlarmNotifications(for: nil)
        rescheduleIfEnabled()
    }

    func selectFajrAlarmIntensity(_ intensity: FajrAlarmIntensity) {
        selectedFajrAlarmIntensityID = intensity.rawValue
        defaults.set(intensity.rawValue, forKey: Self.selectedFajrAlarmIntensityIDKey)
        rescheduleIfEnabled()
    }

    func selectFajrAlarmSound(_ sound: FajrAlarmSound) {
        selectedFajrAlarmSoundID = sound.rawValue
        defaults.set(sound.rawValue, forKey: Self.selectedFajrAlarmSoundIDKey)
        rescheduleIfEnabled()
    }

    func setFajrAlarmWakeBeforeMinutes(_ minutes: Int) {
        fajrAlarmWakeBeforeMinutes = minutes
        defaults.set(minutes, forKey: Self.fajrAlarmWakeBeforeMinutesKey)
        rescheduleIfEnabled()
    }

    func setFajrAlarmSnoozeMinutes(_ minutes: Int) {
        fajrAlarmSnoozeMinutes = minutes
        defaults.set(minutes, forKey: Self.fajrAlarmSnoozeMinutesKey)
        registerNotificationCategories()
        rescheduleIfEnabled()
    }

    func stopFajrAlarm(dateKey: String?) {
        removePendingFajrAlarmNotifications(for: dateKey)
        DispatchQueue.main.async {
            self.statusText = "تم إيقاف منبه الفجر"
        }
    }

    func snoozeFajrAlarm(dateKey: String?) {
        scheduleFajrAlarmSnoozeNotification(dateKey: dateKey)
    }

    func consumePendingFajrAlarmPresentation() -> FajrAlarmPresentation? {
        let presentation = pendingFajrAlarmPresentation
        pendingFajrAlarmPresentation = nil
        return presentation
    }

    func sendPreviewNotification() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.schedulePreviewNotification()
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .timeSensitive]) { [weak self] granted, error in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        guard error == nil, granted else {
                            self.statusText = error == nil
                                ? "اسمح بالإشعارات من إعدادات الآيفون"
                                : "تعذر طلب إذن التنبيهات"
                            self.refreshDiagnostics()
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

    func sendIqamaPreviewNotification() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.scheduleIqamaPreviewNotification()
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .timeSensitive]) { [weak self] granted, error in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        guard error == nil, granted else {
                            self.statusText = error == nil
                                ? "اسمح بالإشعارات من إعدادات الآيفون"
                                : "تعذر طلب إذن التنبيهات"
                            self.refreshDiagnostics()
                            return
                        }

                        self.isEnabled = true
                        self.defaults.set(true, forKey: Self.enabledKey)
                        self.scheduleIqamaPreviewNotification()
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

    func sendNafahatPreviewNotification() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.scheduleNafahatPreviewNotification()
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .timeSensitive]) { [weak self] granted, error in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        guard error == nil, granted else {
                            self.statusText = error == nil
                                ? "اسمح بالإشعارات من إعدادات الآيفون"
                                : "تعذر طلب إذن التنبيهات"
                            self.refreshDiagnostics()
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

    func sendFajrAlarmTestNotification() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.scheduleFajrAlarmPreviewNotification()
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound, .timeSensitive, .criticalAlert]) { [weak self] granted, _ in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        guard granted else {
                            self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                            return
                        }

                        self.isEnabled = true
                        self.defaults.set(true, forKey: Self.enabledKey)
                        self.scheduleFajrAlarmPreviewNotification()
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

    private func applyWelcomeDefaults() {
        enabledPrayerIDs = Set(PrayerEngine.prayerOrder.map(\.rawValue))
        persistPrayerSelection()

        isAdhkarReminderEnabled = false
        defaults.set(false, forKey: Self.adhkarEnabledKey)
        enabledAdhkarPrayerIDs = []
        persistAdhkarPrayerSelection()

        isNafahatEnabled = false
        defaults.set(false, forKey: Self.nafahatEnabledKey)

        isIqamaNotificationEnabled = false
        defaults.set(false, forKey: Self.iqamaEnabledKey)
    }

    private func scheduleUpcomingPrayerNotifications() {
        schedulingGeneration &+= 1
        let generation = schedulingGeneration
        let events = upcomingNotificationEvents()

        removeScheduledPrayerNotifications {
            DispatchQueue.main.async {
                guard self.isEnabled, self.schedulingGeneration == generation else { return }
                self.addScheduledEvents(events, generation: generation)
            }
        }
    }

    private func addScheduledEvents(_ events: [ScheduledPrayerNotification], generation: Int) {
        guard !events.isEmpty else {
            statusText = enabledPrayerIDs.isEmpty && !isNafahatEnabled
                ? "اختر صلاة واحدة على الأقل للتنبيه"
                : "لا توجد صلوات قادمة في الجدول"
            refreshDiagnostics()
            return
        }

        let group = DispatchGroup()
        let failureLock = NSLock()
        var failureCount = 0

        for event in events {
            group.enter()
            center.add(request(for: event)) { error in
                if error != nil {
                    failureLock.lock()
                    failureCount += 1
                    failureLock.unlock()
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            guard self.isEnabled, self.schedulingGeneration == generation else { return }
            if failureCount == 0 {
                self.refreshStatus()
            } else {
                self.statusText = "تعذر جدولة \(failureCount) من أصل \(events.count) تنبيهًا"
            }
            self.refreshDiagnostics()
        }
    }

    private func upcomingNotificationEvents() -> [ScheduledPrayerNotification] {
        let now = Date()
        let prayerEvents = PrayerEngine.upcomingDateKeys(from: now, count: 60).flatMap { dateKey in
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

                if isIqamaNotificationEnabled,
                   enabledPrayerIDs.contains(key.rawValue),
                   let iqamaDate = IqamaSchedule.telSheva.iqamaDate(for: prayer),
                   iqamaDate > now {
                    result.append(ScheduledPrayerNotification(kind: .iqama, prayer: prayer, date: iqamaDate))
                }

                return result
            }
        }

        let sortedPrayerEvents = prayerEvents.sorted { $0.date < $1.date }
        guard isNafahatEnabled else {
            return Array(sortedPrayerEvents.prefix(maxPendingNotifications))
        }

        let protectedPrayerEvents = Array(sortedPrayerEvents.prefix(prayerSlotsWhenNafahatEnabled))
        let availableNafahatSlots = max(0, maxPendingNotifications - protectedPrayerEvents.count)
        let nafahatEvents = Array(upcomingNafahatEvents(now: now)
            .sorted { $0.date < $1.date }
            .prefix(availableNafahatSlots))

        return (protectedPrayerEvents + nafahatEvents).sorted { $0.date < $1.date }
    }

    private func request(for event: ScheduledPrayerNotification) -> UNNotificationRequest {
        switch event.kind {
        case .adhan:
            return adhanRequest(for: event.prayer, date: event.date)
        case .iqama:
            return iqamaRequest(for: event.prayer, date: event.date)
        case .adhkar:
            return adhkarRequest(for: event.prayer, date: event.date)
        case .nafahat:
            return nafahatRequest(for: event.nafahatMessage ?? nafahatMessage(for: 0, date: event.date), date: event.date)
        case .fajrAlarm:
            return fajrAlarmRequest(for: event.prayer, date: event.date, isWakeBefore: event.isWakeBefore)
        }
    }

    private func adhanRequest(for prayer: PrayerTime, date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "حان وقت صلاة \(prayer.title)"
        content.body = "صلاتي • \(prayer.time)"
        content.sound = notificationSound
        content.interruptionLevel = .timeSensitive
        content.threadIdentifier = "tel-sheva-adhan"
        content.userInfo = [
            "notificationKind": "adhan",
            "prayerKey": prayer.key.rawValue,
            "dateKey": PrayerEngine.defaultDateKey(for: prayer.date)
        ]

        var components = PrayerEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.timeZone = PrayerEngine.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = scheduledNotificationPrefix + PrayerEngine.calendarIdentifier(for: date) + "-adhan-" + prayer.key.rawValue
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func iqamaRequest(for prayer: PrayerTime, date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "الآن تقام صلاة \(prayer.title)"
        content.body = "إقامة مسجد \(IqamaSchedule.telSheva.locationName) • \(clockText(for: date))"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.threadIdentifier = "tel-sheva-iqama"
        content.userInfo = [
            "notificationKind": "iqama",
            "prayerKey": prayer.key.rawValue,
            "dateKey": PrayerEngine.defaultDateKey(for: prayer.date)
        ]

        var components = PrayerEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.timeZone = PrayerEngine.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = scheduledNotificationPrefix + PrayerEngine.calendarIdentifier(for: date) + "-iqama-" + prayer.key.rawValue
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func fajrAlarmRequest(for prayer: PrayerTime, date: Date, isWakeBefore: Bool) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = isWakeBefore ? "اقترب وقت الفجر" : "منبه الفجر"
        content.body = isWakeBefore
            ? "باقي \(fajrAlarmWakeBeforeMinutes) دقيقة على صلاة الفجر"
            : "حان وقت صلاة الفجر • اضغط صحيت أو غفوة"
        content.sound = fajrAlarmNotificationSound
        content.categoryIdentifier = Self.fajrAlarmCategoryID
        content.threadIdentifier = "tel-sheva-fajr-alarm"
        content.interruptionLevel = .critical
        content.userInfo = ["fajrDateKey": PrayerEngine.defaultDateKey(for: prayer.date)]

        var components = PrayerEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.timeZone = PrayerEngine.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = scheduledNotificationPrefix + PrayerEngine.calendarIdentifier(for: date) + "-fajr-alarm-" + (isWakeBefore ? "before" : prayer.key.rawValue)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func adhkarRequest(for prayer: PrayerTime, date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "أذكار بعد صلاة \(prayer.title)"
        content.body = selectedAdhkarStyle.notificationBody
        content.sound = adhkarNotificationSound

        var components = PrayerEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.timeZone = PrayerEngine.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = scheduledNotificationPrefix + PrayerEngine.calendarIdentifier(for: date) + "-adhkar-" + prayer.key.rawValue
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }

    private func nafahatRequest(for message: NafahatReminderMessage, date: Date) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = adhkarNotificationSound

        var components = PrayerEngine.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.timeZone = PrayerEngine.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let identifier = scheduledNotificationPrefix + PrayerEngine.calendarIdentifier(for: date) + "-nafahat"
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

    private func upcomingFajrAlarmEvents(now: Date) -> [ScheduledPrayerNotification] {
        guard isFajrAlarmEnabled else { return [] }

        return PrayerEngine.upcomingDateKeys(from: now, count: 60).flatMap { dateKey -> [ScheduledPrayerNotification] in
            guard let time = PrayerEngine.schedule(for: dateKey).times[.fajr],
                  let fajrDate = PrayerEngine.date(from: dateKey, time: time) else {
                return []
            }

            let prayer = PrayerTime(key: .fajr, title: PrayerKey.fajr.title, time: time, date: fajrDate)
            var result: [ScheduledPrayerNotification] = []

            if fajrAlarmWakeBeforeMinutes > 0 {
                let beforeDate = fajrDate.addingTimeInterval(TimeInterval(-fajrAlarmWakeBeforeMinutes * 60))
                if beforeDate > now {
                    result.append(
                        ScheduledPrayerNotification(
                            kind: .fajrAlarm,
                            prayer: prayer,
                            date: beforeDate,
                            isWakeBefore: true
                        )
                    )
                }
            }

            for offset in selectedFajrAlarmIntensity.repeatOffsetsMinutes {
                let alarmDate = fajrDate.addingTimeInterval(TimeInterval(offset * 60))
                if alarmDate > now {
                    result.append(
                        ScheduledPrayerNotification(
                            kind: .fajrAlarm,
                            prayer: prayer,
                            date: alarmDate,
                            isWakeBefore: false
                        )
                    )
                }
            }

            return result
        }
    }

    private func nafahatMessage(for index: Int, date: Date = Date()) -> NafahatReminderMessage {
        let messages = selectedNafahatText.messages
        guard !messages.isEmpty else {
            return NafahatReminderMessage(title: "ذكر خفيف", body: "اذكر الله ذكرًا خفيفًا")
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
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: previewNotificationIdentifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusText = error == nil ? "ستسمع معاينة الأذان بعد 5 ثواني" : "تعذر إرسال معاينة الصوت"
            }
        }
    }

    private func scheduleNafahatPreviewNotification() {
        let previewDate = Date()
        let message = nafahatMessage(for: Int(previewDate.timeIntervalSince1970), date: previewDate)
        let content = UNMutableNotificationContent()
        content.title = message.title
        content.body = message.body
        content.sound = adhkarNotificationSound

        let identifier = previewNotificationIdentifier + "-adhkar"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusText = error == nil ? "ستصلك أذكار تجريبية بعد ثانيتين" : "تعذر إرسال اختبار الأذكار"
            }
        }
    }

    private func scheduleFajrAlarmPreviewNotification() {
        let content = UNMutableNotificationContent()
        content.title = "اختبار منبه الفجر"
        content.body = "هذا نفس صوت وإجراءات منبه الفجر • صحيت أو غفوة"
        content.sound = fajrAlarmNotificationSound
        content.categoryIdentifier = Self.fajrAlarmCategoryID
        content.threadIdentifier = "tel-sheva-fajr-alarm"
        content.interruptionLevel = .critical

        let identifier = previewNotificationIdentifier + "-fajr-alarm"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusText = error == nil ? "منبه الفجر التجريبي بعد 5 ثواني" : "تعذر إرسال اختبار منبه الفجر"
            }
        }
    }

    private func scheduleFajrAlarmSnoozeNotification(dateKey: String?) {
        let content = UNMutableNotificationContent()
        content.title = "غفوة منبه الفجر"
        content.body = "عاد التنبيه بعد \(fajrAlarmSnoozeMinutes) دقائق"
        content.sound = fajrAlarmNotificationSound
        content.categoryIdentifier = Self.fajrAlarmCategoryID
        content.threadIdentifier = "tel-sheva-fajr-alarm"
        content.interruptionLevel = .critical
        if let dateKey {
            content.userInfo = ["fajrDateKey": dateKey]
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(fajrAlarmSnoozeMinutes, 1) * 60), repeats: false)
        let identifier = legacyNotificationPrefix + "fajr-alarm-snooze-" + PrayerEngine.calendarIdentifier(for: Date())
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusText = error == nil ? "تم ضبط غفوة الفجر \(self.fajrAlarmSnoozeMinutes) دقائق" : "تعذر ضبط الغفوة"
            }
        }
    }

    private var notificationSound: UNNotificationSound {
        switch selectedSound {
        case .system:
            return .default
        case .bundledAdhan:
            return bundledNotificationSound(["adhan-mohamed-jazi.caf", "adhan-mohamed-jazi.wav", "adhan-mohamed-jazi.aiff"])
        case .originalAdhan:
            return bundledNotificationSound(["adhan.caf", "adhan.wav", "adhan.aiff"])
        case .softDhikr:
            return bundledNotificationSound(["notification-soft-01.wav", "nafahat.wav", "nafahat.caf"])
        }
    }

    private var fajrAlarmNotificationSound: UNNotificationSound {
        bundledCriticalNotificationSound(selectedFajrAlarmSound.fileNames)
    }

    private var adhkarNotificationSound: UNNotificationSound {
        switch selectedAdhkarSound {
        case .sakinah:
            return bundledNotificationSound(["adhkar-sakinah.wav", "nafahat.wav"])
        case .noor:
            return bundledNotificationSound(["adhkar-noor.wav", "nafahat.wav"])
        case .nada:
            return bundledNotificationSound(["adhkar-nada.wav", "nafahat.wav"])
        case .tumanina:
            return bundledNotificationSound(["adhkar-tumanina.wav", "nafahat.wav"])
        case .nasim:
            return bundledNotificationSound(["adhkar-nasim.wav", "nafahat.wav"])
        }
    }

    private func bundledNotificationSound(_ fileNames: [String]) -> UNNotificationSound {
        for fileName in fileNames {
            let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            if Bundle.main.url(forResource: parts[0], withExtension: parts[1]) != nil {
                return UNNotificationSound(named: UNNotificationSoundName(fileName))
            }
        }

        return .default
    }

    private func bundledCriticalNotificationSound(_ fileNames: [String]) -> UNNotificationSound {
        for fileName in fileNames {
            let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }

            if Bundle.main.url(forResource: parts[0], withExtension: parts[1]) != nil {
                return UNNotificationSound.criticalSoundNamed(
                    UNNotificationSoundName(fileName),
                    withAudioVolume: 1.0
                )
            }
        }

        return UNNotificationSound.defaultCriticalSound(withAudioVolume: 1.0)
    }

    private func removeScheduledPrayerNotifications(completion: (() -> Void)? = nil) {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else {
                completion?()
                return
            }

            let identifiers = requests
                .map(\.identifier)
                .filter { self.isManagedScheduledIdentifier($0) }
            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
            completion?()
        }
    }

    private func scheduleIqamaPreviewNotification() {
        let content = UNMutableNotificationContent()
        content.title = "الآن تقام صلاة الظهر"
        content.body = "اختبار تنبيه الإقامة • مسجد \(IqamaSchedule.telSheva.locationName)"
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.threadIdentifier = "tel-sheva-iqama"
        content.userInfo = ["notificationKind": "iqama"]

        let identifier = previewNotificationIdentifier + "-iqama"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.statusText = error == nil
                    ? "سيصلك اختبار الإقامة بعد 5 ثواني"
                    : "تعذر إرسال اختبار الإقامة"
            }
        }
    }

    private func clockText(for date: Date) -> String {
        let components = PrayerEngine.calendar.dateComponents([.hour, .minute], from: date)
        return String(
            format: "%02d:%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            components.hour ?? 0,
            components.minute ?? 0
        )
    }

    private var selectedPrayerSoundIsAvailable: Bool {
        let fileNames: [String]
        switch selectedSound {
        case .system:
            return true
        case .bundledAdhan:
            fileNames = ["adhan-mohamed-jazi.caf", "adhan-mohamed-jazi.wav", "adhan-mohamed-jazi.aiff"]
        case .originalAdhan:
            fileNames = ["adhan.caf", "adhan.wav", "adhan.aiff"]
        case .softDhikr:
            fileNames = ["notification-soft-01.wav", "nafahat.wav", "nafahat.caf"]
        }

        return fileNames.contains { fileName in
            let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return false }
            return Bundle.main.url(forResource: parts[0], withExtension: parts[1]) != nil
        }
    }

    private func isManagedScheduledIdentifier(_ identifier: String) -> Bool {
        if identifier.hasPrefix(scheduledNotificationPrefix) {
            return true
        }

        guard identifier.hasPrefix(legacyNotificationPrefix),
              !identifier.hasPrefix(previewNotificationPrefix),
              !identifier.contains("-snooze-") else {
            return false
        }
        return true
    }

    private func removePendingFajrAlarmNotifications(for dateKey: String?) {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }

            let identifiers = requests
                .filter { request in
                    guard request.identifier.hasPrefix(self.legacyNotificationPrefix),
                          request.identifier.contains("fajr-alarm") else {
                        return false
                    }

                    if let dateKey {
                        return (request.content.userInfo["fajrDateKey"] as? String) == dateKey
                            || request.identifier.contains("snooze")
                    }

                    return request.identifier.contains("snooze") || request.identifier.contains("preview")
                }
                .map(\.identifier)
            self.center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }

    private func refreshStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self else { return }
                if self.isEnabled && (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional) {
                    if self.enabledPrayerIDs.isEmpty && !self.isNafahatEnabled {
                        self.statusText = "اختر صلاة واحدة على الأقل للتنبيه"
                    } else if settings.alertSetting != .enabled {
                        self.statusText = "التنبيهات مفعلة لكن ظهورها مغلق من إعدادات الآيفون"
                    } else if settings.soundSetting != .enabled {
                        self.statusText = "التنبيهات مفعلة لكن الصوت مغلق من إعدادات الآيفون"
                    } else if settings.lockScreenSetting != .enabled {
                        self.statusText = "التنبيهات مفعلة لكن ظهور شاشة القفل مغلق"
                    } else if settings.timeSensitiveSetting != .enabled {
                        self.statusText = "فعّل الإشعارات الحساسة للوقت لضمان وصول الأذان"
                    } else {
                        self.statusText = "التنبيهات مفعلة"
                    }
                } else if settings.authorizationStatus == .denied {
                    self.statusText = "اسمح بالإشعارات من إعدادات الآيفون"
                } else {
                    self.statusText = "التنبيهات غير مفعلة"
                }
            }
        }
    }

    func refreshDiagnostics() {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            self.center.getPendingNotificationRequests { [weak self] requests in
                guard let self else { return }

                let prayerRequests = requests.filter {
                    $0.identifier.hasPrefix(self.scheduledNotificationPrefix)
                        && $0.identifier.contains("-adhan-")
                }
                let nafahatRequests = requests.filter {
                    $0.identifier.hasPrefix(self.scheduledNotificationPrefix)
                        && $0.identifier.hasSuffix("-nafahat")
                }
                let prayerDates = prayerRequests
                    .compactMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
                    .sorted()

                let permissionText: String
                switch settings.authorizationStatus {
                case .authorized:
                    permissionText = "مسموح"
                case .provisional:
                    permissionText = "مسموح بهدوء"
                case .denied:
                    permissionText = "مرفوض"
                case .notDetermined:
                    permissionText = "لم يُطلب بعد"
                case .ephemeral:
                    permissionText = "مؤقت"
                @unknown default:
                    permissionText = "غير معروف"
                }

                let isAuthorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional

                DispatchQueue.main.async {
                    self.diagnostics = PrayerNotificationDiagnostics(
                        permissionText: permissionText,
                        isAuthorized: isAuthorized,
                        alertsEnabled: settings.alertSetting == .enabled,
                        soundsEnabled: settings.soundSetting == .enabled,
                        lockScreenEnabled: settings.lockScreenSetting == .enabled,
                        timeSensitiveEnabled: settings.timeSensitiveSetting == .enabled,
                        selectedSoundAvailable: self.selectedPrayerSoundIsAvailable,
                        scheduledPrayerCount: prayerRequests.count,
                        scheduledNafahatCount: nafahatRequests.count,
                        firstPrayerDate: prayerDates.first,
                        lastPrayerDate: prayerDates.last,
                        checkedAt: Date()
                    )
                }
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let notificationKind = response.notification.request.content.userInfo["notificationKind"] as? String
        await MainActor.run {
            let notificationName = notificationKind == "adhan" || notificationKind == "iqama"
                ? Self.openScheduleNotification
                : Self.openSettingsNotification
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }

    private func presentFajrAlarm(from notification: UNNotification) {
        let dateKey = notification.request.content.userInfo["fajrDateKey"] as? String
        let presentation = FajrAlarmPresentation(
            dateKey: dateKey,
            title: notification.request.content.title.isEmpty ? "منبه الفجر" : notification.request.content.title,
            body: notification.request.content.body.isEmpty ? "حان وقت صلاة الفجر" : notification.request.content.body,
            soundFileNames: selectedFajrAlarmSound.fileNames,
            snoozeMinutes: fajrAlarmSnoozeMinutes
        )

        DispatchQueue.main.async {
            self.pendingFajrAlarmPresentation = presentation
            NotificationCenter.default.post(
                name: Self.presentFajrAlarmNotification,
                object: presentation
            )
        }
    }
}

private struct ScheduledPrayerNotification {
    enum Kind {
        case adhan
        case iqama
        case adhkar
        case nafahat
        case fajrAlarm
    }

    let kind: Kind
    let prayer: PrayerTime
    let date: Date
    var nafahatMessage: NafahatReminderMessage? = nil
    var isWakeBefore = false
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
