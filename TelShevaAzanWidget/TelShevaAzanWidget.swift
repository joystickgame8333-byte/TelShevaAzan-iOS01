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

@main
struct TelShevaAzanWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalatiNextPrayerWidget()
        SalatiPrayerScheduleWidget()
    }
}
