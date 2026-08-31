import Foundation

enum PrayerRegion: String, CaseIterable, Identifiable {
    case negev
    case center
    case westBank
    case north

    var id: String { rawValue }

    var title: String {
        switch self {
        case .negev: return "النقب والجنوب"
        case .center: return "الوسط والساحل"
        case .westBank: return "الضفة والقدس"
        case .north: return "الشمال والجليل"
        }
    }
}

struct PrayerCity: Identifiable, Hashable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let offsetSeconds: Int
    let region: PrayerRegion
}

/// Shared, privacy-preserving prayer location storage.
/// Exact coordinates never leave the device; all app surfaces consume only
/// the closest supported city's published calendar offset.
enum PrayerLocationStore {
    static let appGroup = "group.com.omaralasam.telshevaazan"
    static let changedNotification = Notification.Name("PrayerLocationStore.changed")

    private static let automaticKey = "prayerLocation.automatic.v1"
    private static let cityKey = "prayerLocation.city.v1"
    private static let latitudeKey = "prayerLocation.latitude.v1"
    private static let longitudeKey = "prayerLocation.longitude.v1"
    private static let updatedAtKey = "prayerLocation.updatedAt.v1"
    private static let recentInterval: TimeInterval = 10 * 60
    private static let defaultCityID = "tel-sheva"

    static let defaults: UserDefaults = {
        #if os(watchOS)
        return .standard
        #else
        return UserDefaults(suiteName: appGroup) ?? .standard
        #endif
    }()

    static var defaultCity: PrayerCity {
        cities.first(where: { $0.id == defaultCityID })!
    }

    static var currentCity: PrayerCity {
        guard let savedID = defaults.string(forKey: cityKey),
              let city = city(withID: savedID) else {
            return defaultCity
        }
        return city
    }

    static var isAutomatic: Bool {
        guard defaults.object(forKey: automaticKey) != nil else { return true }
        return defaults.bool(forKey: automaticKey)
    }

    static var cachedLocationIsRecent: Bool {
        guard let updatedAt = defaults.object(forKey: updatedAtKey) as? Date else { return false }
        return Date().timeIntervalSince(updatedAt) < recentInterval
    }

    static var savedCoordinate: (latitude: Double, longitude: Double)? {
        guard defaults.object(forKey: latitudeKey) != nil,
              defaults.object(forKey: longitudeKey) != nil else { return nil }
        return (defaults.double(forKey: latitudeKey), defaults.double(forKey: longitudeKey))
    }

    static func city(withID id: String) -> PrayerCity? {
        cities.first(where: { $0.id == id })
    }

    static func cities(in region: PrayerRegion) -> [PrayerCity] {
        cities
            .filter { $0.region == region }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    static func setManualCity(_ city: PrayerCity) {
        defaults.set(false, forKey: automaticKey)
        defaults.set(city.id, forKey: cityKey)
        notifyChange()
    }

    static func setAutomaticEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: automaticKey)
        notifyChange()
    }

    /// Applies the city selected by the paired phone without exposing or
    /// transferring the phone's exact coordinates to the watch.
    static func applySyncedCity(id: String) {
        guard city(withID: id) != nil else { return }
        defaults.set(id, forKey: cityKey)
        notifyChange()
    }

    static func saveAutomaticLocation(latitude: Double, longitude: Double, at date: Date = Date()) -> PrayerCity {
        let city = nearestCity(toLatitude: latitude, longitude: longitude)
        defaults.set(true, forKey: automaticKey)
        defaults.set(city.id, forKey: cityKey)
        defaults.set(latitude, forKey: latitudeKey)
        defaults.set(longitude, forKey: longitudeKey)
        defaults.set(date, forKey: updatedAtKey)
        notifyChange()
        return city
    }

    static func nearestCity(toLatitude latitude: Double, longitude: Double) -> PrayerCity {
        cities.min {
            distance(latitude, longitude, $0.latitude, $0.longitude)
                < distance(latitude, longitude, $1.latitude, $1.longitude)
        } ?? defaultCity
    }

    static let cities: [PrayerCity] = {
        let references: [PrayerCity] = [
            .init(id: "tel-sheva", name: "تل السبع", latitude: 31.24864, longitude: 34.86007, offsetSeconds: 120, region: .negev),
            .init(id: "jerusalem", name: "القدس", latitude: 31.778, longitude: 35.235, offsetSeconds: 0, region: .westBank),
            .init(id: "ramallah", name: "رام الله", latitude: 31.904, longitude: 35.204, offsetSeconds: 0, region: .westBank),
            .init(id: "bethlehem", name: "بيت لحم", latitude: 31.705, longitude: 35.202, offsetSeconds: 0, region: .westBank),
            .init(id: "jenin", name: "جنين", latitude: 32.461, longitude: 35.300, offsetSeconds: 0, region: .westBank),
            .init(id: "nablus", name: "نابلس", latitude: 32.222, longitude: 35.262, offsetSeconds: 0, region: .westBank),
            .init(id: "nazareth", name: "الناصرة", latitude: 32.699, longitude: 35.304, offsetSeconds: 0, region: .north),
            .init(id: "umm-al-fahm", name: "أم الفحم", latitude: 32.519, longitude: 35.154, offsetSeconds: 0, region: .north),
            .init(id: "jericho", name: "أريحا", latitude: 31.857, longitude: 35.444, offsetSeconds: -60, region: .westBank),
            .init(id: "tiberias", name: "طبريا", latitude: 32.794, longitude: 35.532, offsetSeconds: -60, region: .north),
            .init(id: "safed", name: "صفد", latitude: 32.965, longitude: 35.498, offsetSeconds: -60, region: .north),
            .init(id: "beisan", name: "بيسان", latitude: 32.497, longitude: 35.498, offsetSeconds: -60, region: .north),
            .init(id: "hebron", name: "الخليل", latitude: 31.532, longitude: 35.099, offsetSeconds: 60, region: .westBank),
            .init(id: "idhna", name: "إذنا", latitude: 31.558, longitude: 34.975, offsetSeconds: 60, region: .westBank),
            .init(id: "dura", name: "دورا", latitude: 31.507, longitude: 35.028, offsetSeconds: 60, region: .westBank),
            .init(id: "beit-awwa", name: "بيت عوا", latitude: 31.510, longitude: 34.949, offsetSeconds: 60, region: .westBank),
            .init(id: "haifa", name: "حيفا", latitude: 32.794, longitude: 34.990, offsetSeconds: 60, region: .north),
            .init(id: "acre", name: "عكا", latitude: 32.928, longitude: 35.083, offsetSeconds: 60, region: .north),
            .init(id: "tulkarm", name: "طولكرم", latitude: 32.312, longitude: 35.028, offsetSeconds: 60, region: .westBank),
            .init(id: "kafr-qasim", name: "كفر قاسم", latitude: 32.115, longitude: 34.975, offsetSeconds: 60, region: .center),
            .init(id: "tayibe", name: "الطيبة", latitude: 32.267, longitude: 35.009, offsetSeconds: 60, region: .center),
            .init(id: "lod", name: "اللد", latitude: 31.951, longitude: 34.895, offsetSeconds: 90, region: .center),
            .init(id: "ramla", name: "الرملة", latitude: 31.929, longitude: 34.866, offsetSeconds: 90, region: .center),
            .init(id: "qalqilya", name: "قلقيلية", latitude: 32.189, longitude: 34.970, offsetSeconds: 90, region: .westBank),
            .init(id: "beersheba", name: "بئر السبع", latitude: 31.252, longitude: 34.791, offsetSeconds: 120, region: .negev),
            .init(id: "jaffa", name: "يافا", latitude: 32.050, longitude: 34.750, offsetSeconds: 120, region: .center),
            .init(id: "gaza", name: "غزة", latitude: 31.501, longitude: 34.466, offsetSeconds: 180, region: .negev),
            .init(id: "rafah", name: "رفح", latitude: 31.296, longitude: 34.244, offsetSeconds: 240, region: .negev),
            .init(id: "khan-yunis", name: "خان يونس", latitude: 31.346, longitude: 34.303, offsetSeconds: 240, region: .negev),
            .init(id: "deir-al-balah", name: "دير البلح", latitude: 31.418, longitude: 34.351, offsetSeconds: 240, region: .negev)
        ]

        var result = references
        func add(_ id: String, _ name: String, _ latitude: Double, _ longitude: Double, _ region: PrayerRegion) {
            let reference = references.min {
                distance(latitude, longitude, $0.latitude, $0.longitude)
                    < distance(latitude, longitude, $1.latitude, $1.longitude)
            } ?? references[0]
            result.append(.init(
                id: id,
                name: name,
                latitude: latitude,
                longitude: longitude,
                offsetSeconds: reference.offsetSeconds,
                region: region
            ))
        }

        // النقب والجنوب
        add("rahat", "رهط", 31.393, 34.755, .negev)
        add("hura", "حورة", 31.300, 34.936, .negev)
        add("laqiya", "اللقية", 31.324, 34.866, .negev)
        add("kuseife", "كسيفة", 31.245, 35.094, .negev)
        add("arara-negev", "عرعرة النقب", 31.159, 35.023, .negev)
        add("segev-shalom", "شقيب السلام", 31.200, 34.840, .negev)
        add("abu-qrenat", "أبو قرينات", 31.139, 34.957, .negev)
        add("abu-tlul", "أبو تلول", 31.079, 34.919, .negev)
        add("qasr-al-sir", "قصر السر", 31.083, 34.984, .negev)
        add("umm-batin", "أم بطين", 31.276, 34.882, .negev)
        add("dimona", "ديمونا", 31.069, 35.033, .negev)
        add("arad", "عراد", 31.258, 35.213, .negev)

        // القدس وبيت لحم ورام الله
        add("abu-dis", "أبو ديس", 31.763, 35.261, .westBank)
        add("al-eizariya", "العيزرية", 31.771, 35.269, .westBank)
        add("al-ram", "الرام", 31.850, 35.232, .westBank)
        add("anata", "عناتا", 31.809, 35.259, .westBank)
        add("hizma", "حزما", 31.834, 35.264, .westBank)
        add("bir-nabala", "بير نبالا", 31.850, 35.205, .westBank)
        add("beit-hanina", "بيت حنينا", 31.829, 35.216, .westBank)
        add("shuafat", "شعفاط", 31.813, 35.228, .westBank)
        add("al-bireh", "البيرة", 31.910, 35.216, .westBank)
        add("beitunia", "بيتونيا", 31.897, 35.168, .westBank)
        add("birzeit", "بيرزيت", 31.969, 35.196, .westBank)
        add("rawabi", "روابي", 32.010, 35.187, .westBank)
        add("silwad", "سلواد", 31.976, 35.261, .westBank)
        add("turmus-ayya", "ترمسعيا", 32.036, 35.285, .westBank)
        add("beit-sahour", "بيت ساحور", 31.700, 35.226, .westBank)
        add("beit-jala", "بيت جالا", 31.715, 35.187, .westBank)
        add("al-khader", "الخضر", 31.694, 35.167, .westBank)
        add("tuqu", "تقوع", 31.635, 35.214, .westBank)
        add("battir", "بتير", 31.727, 35.135, .westBank)

        // الخليل وريفها
        add("yatta", "يطا", 31.446, 35.090, .westBank)
        add("as-samu", "السموع", 31.397, 35.066, .westBank)
        add("ad-dhahiriya", "الظاهرية", 31.408, 34.973, .westBank)
        add("halhul", "حلحول", 31.579, 35.101, .westBank)
        add("bani-naim", "بني نعيم", 31.515, 35.164, .westBank)
        add("sair", "سعير", 31.579, 35.141, .westBank)
        add("tarqumiya", "ترقوميا", 31.576, 34.989, .westBank)
        add("beit-ummar", "بيت أمر", 31.623, 35.105, .westBank)
        add("surif", "صوريف", 31.651, 35.064, .westBank)

        // شمال الضفة والأغوار
        add("tubas", "طوباس", 32.321, 35.369, .westBank)
        add("qabatiya", "قباطية", 32.411, 35.280, .westBank)
        add("arraba-jenin", "عرابة جنين", 32.405, 35.202, .westBank)
        add("yabad", "يعبد", 32.445, 35.168, .westBank)
        add("burqin", "برقين", 32.455, 35.260, .westBank)
        add("salfit", "سلفيت", 32.084, 35.181, .westBank)
        add("huwara", "حوارة", 32.152, 35.256, .westBank)
        add("beita", "بيتا", 32.141, 35.287, .westBank)
        add("aqraba", "عقربا", 32.125, 35.342, .westBank)
        add("sebastia", "سبسطية", 32.276, 35.199, .westBank)
        add("anabta", "عنبتا", 32.308, 35.117, .westBank)
        add("attil", "عتيل", 32.369, 35.071, .westBank)
        add("bala", "بلعا", 32.333, 35.111, .westBank)
        add("azzun", "عزون", 32.175, 35.057, .westBank)
        add("jayus", "جيوس", 32.202, 35.034, .westBank)

        // المثلث والساحل
        add("baqa-al-gharbiya", "باقة الغربية", 32.418, 35.042, .north)
        add("jatt", "جت", 32.400, 35.036, .north)
        add("qalansuwa", "قلنسوة", 32.285, 34.983, .center)
        add("tira", "الطيرة", 32.234, 34.950, .center)
        add("jaljulia", "جلجولية", 32.155, 34.953, .center)
        add("kafr-qara", "كفر قرع", 32.506, 35.053, .north)
        add("arara-triangle", "عرعرة", 32.496, 35.091, .north)
        add("kafr-bara", "كفر برا", 32.130, 34.971, .center)
        add("hadera", "الخضيرة", 32.434, 34.919, .north)
        add("netanya", "نتانيا", 32.321, 34.853, .center)
        add("tel-aviv", "تل أبيب", 32.085, 34.782, .center)
        add("ashdod", "أسدود", 31.801, 34.643, .center)
        add("ashkelon", "عسقلان", 31.668, 34.574, .center)

        // الجليل وحيفا وعكا
        add("shefa-amr", "شفاعمرو", 32.805, 35.169, .north)
        add("tamra", "طمرة", 32.853, 35.199, .north)
        add("sakhnin", "سخنين", 32.864, 35.297, .north)
        add("arraba-galilee", "عرابة البطوف", 32.851, 35.338, .north)
        add("deir-hanna", "دير حنا", 32.861, 35.364, .north)
        add("kafr-kanna", "كفر كنا", 32.747, 35.341, .north)
        add("kafr-manda", "كفر مندا", 32.809, 35.260, .north)
        add("iksal", "إكسال", 32.682, 35.323, .north)
        add("reineh", "الرينة", 32.722, 35.316, .north)
        add("mashhad", "المشهد", 32.738, 35.322, .north)
        add("daburiyya", "دبورية", 32.693, 35.371, .north)
        add("kafr-yasif", "كفر ياسيف", 32.954, 35.165, .north)
        add("jadeidi-makr", "الجديدة المكر", 32.930, 35.141, .north)
        add("majd-al-krum", "مجد الكروم", 32.920, 35.252, .north)
        add("nahf", "نحف", 32.934, 35.317, .north)
        add("deir-al-asad", "دير الأسد", 32.936, 35.269, .north)
        add("baena", "البعنة", 32.929, 35.273, .north)
        add("tarshiha", "ترشيحا", 33.018, 35.270, .north)
        add("maghar", "المغار", 32.889, 35.407, .north)

        // قطاع غزة
        add("jabalia", "جباليا", 31.528, 34.483, .negev)
        add("beit-lahia", "بيت لاهيا", 31.547, 34.496, .negev)
        add("beit-hanoun", "بيت حانون", 31.539, 34.536, .negev)
        add("nuseirat", "النصيرات", 31.448, 34.392, .negev)
        add("bureij", "البريج", 31.439, 34.403, .negev)
        add("maghazi", "المغازي", 31.422, 34.386, .negev)
        add("zawayda", "الزوايدة", 31.429, 34.371, .negev)
        add("abasan", "عبسان الكبيرة", 31.323, 34.347, .negev)

        return result
    }()

    private static func notifyChange() {
        NotificationCenter.default.post(name: changedNotification, object: nil)
    }

    private static func distance(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
        let earthRadius = 6_371.0088
        let latitudeDelta = (lat2 - lat1) * .pi / 180
        let longitudeDelta = (lon2 - lon1) * .pi / 180
        let a = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}
