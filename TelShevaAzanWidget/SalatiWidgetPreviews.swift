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

#Preview("مواقيت اليوم — كبير", as: .systemLarge) {
    SalatiPrayerScheduleWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("مواقيت اليوم — متوسط", as: .systemMedium) {
    SalatiPrayerScheduleWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("شاشة القفل — مستطيل", as: .accessoryRectangular) {
    SalatiNextPrayerWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("الإقامة — صغير", as: .systemSmall) {
    SalatiIqamaWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("شاشة القفل — دائري", as: .accessoryCircular) {
    SalatiNextPrayerWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("شاشة القفل — سطر", as: .accessoryInline) {
    SalatiNextPrayerWidget()
} timeline: {
    SalatiWidgetEntry.preview
}

#Preview("الإقامة — مستطيل", as: .accessoryRectangular) {
    SalatiIqamaWidget()
} timeline: {
    SalatiWidgetEntry.preview
}
#endif
