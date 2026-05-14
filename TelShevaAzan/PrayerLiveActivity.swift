import Foundation

#if canImport(ActivityKit)
import ActivityKit

struct PrayerLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: PrayerLiveActivityPhase
        var prayerDate: Date
        var updatedAt: Date
    }

    let prayerID: String
    let prayerName: String
    let prayerTime: String
    let prayerDate: Date
    let previousPrayerName: String
    let previousPrayerDate: Date?
    let cityName: String
    let themeID: String
    let isPreview: Bool
}

enum PrayerLiveActivityPhase: String, Codable, Hashable {
    case almostTime
    case now
    case adhkar

    var title: String {
        switch self {
        case .almostTime:
            return "اقترب الأذان"
        case .now:
            return "حان الأذان"
        case .adhkar:
            return "أذكار بعد الصلاة"
        }
    }

    var shortTitle: String {
        switch self {
        case .almostTime:
            return "قريب"
        case .now:
            return "الآن"
        case .adhkar:
            return "أذكار"
        }
    }

    var systemImage: String {
        switch self {
        case .almostTime:
            return "bell.and.waves.left.and.right.fill"
        case .now:
            return "bell.badge.fill"
        case .adhkar:
            return "sparkles"
        }
    }
}
#endif
