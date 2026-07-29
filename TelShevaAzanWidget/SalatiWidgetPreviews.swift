#if DEBUG
import SwiftUI
import WidgetKit

#Preview("الصلاة القادمة — صغير", as: .systemSmall) {
    SalatiNextPrayerWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("الصلاة القادمة — متوسط", as: .systemMedium) {
    SalatiNextPrayerWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("مواقيت اليوم — متوسط", as: .systemMedium) {
    SalatiPrayerScheduleWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("مواقيت اليوم — صغير", as: .systemSmall) {
    SalatiPrayerScheduleWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("مواقيت اليوم — كبير", as: .systemLarge) {
    SalatiPrayerScheduleWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("شاشة القفل — السطر الذكي", as: .accessoryInline) {
    SalatiLockInlineWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("شاشة القفل — موعد الصلاة", as: .accessoryCircular) {
    SalatiLockPrayerTimeWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("شاشة القفل — العد التنازلي", as: .accessoryCircular) {
    SalatiLockCountdownWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("شاشة القفل — الصلاة القادمة", as: .accessoryRectangular) {
    SalatiLockNextPrayerWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("شاشة القفل — القادمة وبعدها", as: .accessoryRectangular) {
    SalatiLockFollowingPrayersWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("شاشة القفل — كل المواقيت", as: .accessoryRectangular) {
    SalatiLockScheduleWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("مسار الصلوات", as: .systemMedium) {
    SalatiPrayerPathWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("الصلاة القادمة — الحالات الذكية", as: .systemMedium) {
    SalatiNextPrayerWidget()
} timeline: {
    SalatiWidgetEntry.previewApproaching
    SalatiWidgetEntry.previewAdhan
    SalatiWidgetEntry.previewIqama
    SalatiWidgetEntry.previewTomorrow
}

#Preview("شاشة القفل — الحالات الذكية", as: .accessoryRectangular) {
    SalatiLockNextPrayerWidget()
} timeline: {
    SalatiWidgetEntry.previewApproaching
    SalatiWidgetEntry.previewAdhan
    SalatiWidgetEntry.previewIqama
    SalatiWidgetEntry.previewTomorrow
}
#endif
