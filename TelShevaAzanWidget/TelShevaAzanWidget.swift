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
            .systemMedium
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

struct SalatiLockInlineWidget: Widget {
    let kind = SalatiWidgetKind.lockInline

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiLockScreenView(entry: entry, style: .inline)
        }
        .configurationDisplayName(SalatiText.lockInlineTitle)
        .description(SalatiText.lockInlineDescription)
        .supportedFamilies([.accessoryInline])
    }
}

struct SalatiLockPrayerTimeWidget: Widget {
    let kind = SalatiWidgetKind.lockPrayerTime

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiLockScreenView(entry: entry, style: .prayerTime)
        }
        .configurationDisplayName(SalatiText.lockPrayerTimeTitle)
        .description(SalatiText.lockPrayerTimeDescription)
        .supportedFamilies([.accessoryCircular])
    }
}

struct SalatiLockCountdownWidget: Widget {
    let kind = SalatiWidgetKind.lockCountdown

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiLockScreenView(entry: entry, style: .countdown)
        }
        .configurationDisplayName(SalatiText.lockCountdownTitle)
        .description(SalatiText.lockCountdownDescription)
        .supportedFamilies([.accessoryCircular])
    }
}

struct SalatiLockNextPrayerWidget: Widget {
    let kind = SalatiWidgetKind.lockNextPrayer

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiLockScreenView(entry: entry, style: .nextPrayer)
        }
        .configurationDisplayName(SalatiText.lockNextPrayerTitle)
        .description(SalatiText.lockNextPrayerDescription)
        .supportedFamilies([.accessoryRectangular])
    }
}

struct SalatiLockFollowingPrayersWidget: Widget {
    let kind = SalatiWidgetKind.lockFollowingPrayers

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiLockScreenView(entry: entry, style: .followingPrayers)
        }
        .configurationDisplayName(SalatiText.lockFollowingPrayersTitle)
        .description(SalatiText.lockFollowingPrayersDescription)
        .supportedFamilies([.accessoryRectangular])
    }
}

struct SalatiLockScheduleWidget: Widget {
    let kind = SalatiWidgetKind.lockDailySchedule

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalatiWidgetProvider()) { entry in
            SalatiLockScreenView(entry: entry, style: .dailySchedule)
        }
        .configurationDisplayName(SalatiText.lockScheduleTitle)
        .description(SalatiText.lockScheduleDescription)
        .supportedFamilies([.accessoryRectangular])
    }
}

@main
struct TelShevaAzanWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalatiNextPrayerWidget()
        SalatiPrayerScheduleWidget()
        SalatiPrayerPathWidget()
        SalatiLockInlineWidget()
        SalatiLockPrayerTimeWidget()
        SalatiLockCountdownWidget()
        SalatiLockNextPrayerWidget()
        SalatiLockFollowingPrayersWidget()
        SalatiLockScheduleWidget()
    }
}
