import SwiftUI
import WidgetKit

struct SalatiNextPrayerWidget: Widget {
    let kind = SalatiWidgetKind.nextPrayer

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiNextPrayerView(entry: entry)
        }
        .configurationDisplayName(SalatiText.nextPrayer)
        .description(SalatiText.nextPrayerDescription)
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

struct SalatiPrayerScheduleWidget: Widget {
    let kind = SalatiWidgetKind.dailySchedule

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiPrayerScheduleView(entry: entry)
        }
        .configurationDisplayName(SalatiText.todayTimes)
        .description(SalatiText.todayTimesDescription)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct SalatiNextTwoPrayersWidget: Widget {
    let kind = SalatiWidgetKind.nextTwoPrayers

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiNextTwoPrayersView(entry: entry)
        }
        .configurationDisplayName(SalatiText.nextAndFollowing)
        .description(SalatiText.nextAndFollowingDescription)
        .supportedFamilies([.systemMedium])
    }
}

struct SalatiDawnWidget: Widget {
    let kind = SalatiWidgetKind.dawn

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiDawnView(entry: entry)
        }
        .configurationDisplayName(SalatiText.dawnAndSunrise)
        .description(SalatiText.dawnAndSunriseDescription)
        .supportedFamilies([.systemSmall])
    }
}

struct SalatiPrayerPathWidget: Widget {
    let kind = SalatiWidgetKind.prayerPath

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiPrayerPathView(entry: entry)
        }
        .configurationDisplayName(SalatiText.prayerPath)
        .description(SalatiText.prayerPathDescription)
        .supportedFamilies([.systemMedium])
    }
}

struct SalatiTomorrowScheduleWidget: Widget {
    let kind = SalatiWidgetKind.tomorrowSchedule

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiTomorrowScheduleView(entry: entry)
        }
        .configurationDisplayName(SalatiText.tomorrowTimes)
        .description(SalatiText.tomorrowScheduleDescription)
        .supportedFamilies([.systemMedium])
    }
}

@main
struct TelShevaAzanWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalatiNextPrayerWidget()
        SalatiPrayerScheduleWidget()
        SalatiNextTwoPrayersWidget()
        SalatiDawnWidget()
        SalatiPrayerPathWidget()
        SalatiTomorrowScheduleWidget()
    }
}
