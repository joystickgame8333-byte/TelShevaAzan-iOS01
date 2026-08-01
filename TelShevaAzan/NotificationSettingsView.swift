import SwiftUI
import UIKit

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notifications = PrayerNotificationManager.shared
    @State private var selectedPage: NotificationSettingsPage = .adhan
    @State private var showsAdvancedDiagnostics = false
    @State private var showsSoundChoices = false
    @AppStorage(AppThemeStorage.nightThemeKey, store: AppThemeStorage.defaults) private var selectedNightThemeID = PrayerVisualTheme.defaultNight.rawValue
    @AppStorage(AppThemeStorage.dayThemeKey, store: AppThemeStorage.defaults) private var selectedDayThemeID = PrayerVisualTheme.defaultDay.rawValue
    @AppStorage("adhkar.miniKhatmah.enabled") private var isMiniKhatmahEnabled = false
    @AppStorage("adhkar.miniKhatmah.dailyPortion") private var miniKhatmahDailyPortion = MiniKhatmahPortion.halfPage.rawValue
    @AppStorage("adhkar.miniKhatmah.startDate") private var miniKhatmahStartDate: Double = 0
    @AppStorage(
        IqamaPreviewStorage.expirationKey,
        store: IqamaPreviewStorage.defaults
    ) private var iqamaPreviewExpiration: Double = 0

    private static let notificationCoverageDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ar")
        formatter.calendar = PrayerEngine.calendar
        formatter.timeZone = PrayerEngine.timeZone
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return formatter
    }()

    let theme: PrayerVisualTheme
    var isEmbedded = false
    var bottomReservedHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720

            ZStack {
                if !isEmbedded {
                    ThemeBackdrop(theme: theme)
                }

                VStack(alignment: .trailing, spacing: compactHeight ? 10 : 13) {
                    header
                    settingsContent(compact: compactHeight, bottomInset: proxy.safeAreaInsets.bottom)
                }
                .padding(.horizontal, compactHeight ? 16 : 18)
                .padding(.top, compactHeight ? 9 : 11)
                .padding(.bottom, 10 + bottomReservedHeight)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topTrailing)
            }
        }
        .foregroundStyle(theme.primaryText)
        .environment(\.layoutDirection, .leftToRight)
        .multilineTextAlignment(.trailing)
        .onAppear {
            notifications.refreshDiagnostics()
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            if !isEmbedded {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .black))
                        .frame(width: 38, height: 38)
                        .background(glassSurface(theme.controlBackground, radius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.controlBorder)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(theme.accent)
                    .frame(width: 38, height: 38)
                    .background(glassSurface(theme.controlBackground, radius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.controlBorder)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer(minLength: 16)

            VStack(alignment: .trailing, spacing: 4) {
                Text("التنبيه")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("الأذان والإقامة والتذكيرات")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
    }

    private func settingsContent(compact: Bool, bottomInset: CGFloat) -> some View {
        VStack(alignment: .trailing, spacing: compact ? 9 : 11) {
            pageSelector

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .trailing, spacing: compact ? 11 : 14) {
                        Color.clear
                            .frame(height: 1)
                            .id("notification-settings-top")

                        if selectedPage == .adhan {
                            adhanSettings
                        } else if selectedPage == .adhkar {
                            nafahatSettings
                        } else {
                            appearanceSettings
                        }
                    }
                    .padding(.bottom, max(bottomInset, CGFloat(24)) + 24)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: selectedPage) { _ in
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo("notification-settings-top", anchor: .top)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private var pageSelector: some View {
        HStack(spacing: 8) {
            notificationPageButton(.appearance)
            notificationPageButton(.adhkar)
            notificationPageButton(.adhan)
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
        .environment(\.layoutDirection, .leftToRight)
        .padding(.top, 2)
    }

    private func notificationPageButton(_ page: NotificationSettingsPage) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedPage = page
            }
        } label: {
            HStack(spacing: 6) {
                Text(page.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Image(systemName: page.systemImage)
            }
            .environment(\.layoutDirection, .rightToLeft)
            .font(.caption.weight(.black))
            .foregroundStyle(selectedPage == page ? theme.primaryText : theme.secondaryText.opacity(0.82))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                Group {
                    if selectedPage == page {
                        glassSurface(theme.activeRowBackground, radius: 12, prominence: .regular)
                    } else {
                        lightRowSurface(theme.controlBackground, radius: 12)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedPage == page ? theme.activeRowBorder : theme.controlBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var adhanSettings: some View {
        VStack(alignment: .trailing, spacing: 13) {
            masterPanel
            prayerPanel
            iqamaNotificationPanel
            soundPanel
            notificationDiagnosticsPanel
        }
        .transition(.opacity)
    }

    private var fajrAlarmSettings: some View {
        VStack(alignment: .trailing, spacing: 16) {
            fajrAlarmMasterPanel
            fajrAlarmIntensityPanel
            fajrAlarmTimingPanel
            fajrAlarmSnoozePanel
            fajrAlarmSoundPanel
            fajrAlarmTestPanel
        }
        .transition(.opacity)
    }

    private var nafahatSettings: some View {
        VStack(alignment: .trailing, spacing: 13) {
            nafahatMasterPanel
            nafahatIntervalPanel
            nafahatQuietPanel
            nafahatTextPanel
            nafahatPreviewPanel
        }
        .transition(.opacity)
    }

    private var appearanceSettings: some View {
        VStack(alignment: .trailing, spacing: 16) {
            themeSplitPalettePanel
        }
        .transition(.opacity)
    }

    private var masterPanel: some View {
        toggleSummaryPanel(
            title: "تشغيل تنبيهات الأذان",
            subtitle: notifications.statusText,
            isOn: Binding(
                get: { notifications.isEnabled },
                set: { enabled in
                    if enabled {
                        notifications.enable()
                    } else {
                        notifications.disable()
                    }
                }
            )
        )
    }

    private var notificationDiagnosticsPanel: some View {
        let diagnostics = notifications.diagnostics
        let essentialsHealthy = diagnostics.isAuthorized
            && diagnostics.alertsEnabled
            && diagnostics.lockScreenEnabled
            && diagnostics.scheduledPrayerCount > 0

        return panel(title: "حالة التنبيهات") {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showsAdvancedDiagnostics.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: showsAdvancedDiagnostics ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.black))
                            .foregroundStyle(theme.accent)

                        Spacer(minLength: 10)

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(essentialsHealthy ? "التنبيهات جاهزة" : "تحتاج مراجعة الإعدادات")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(essentialsHealthy ? theme.primaryText : Color.orange)

                            Text(notificationCoverageText)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.secondaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }

                        Image(systemName: essentialsHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(essentialsHealthy ? theme.accent : Color.orange)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(lightRowSurface(settingsRowFill, radius: 12))
                }
                .buttonStyle(.plain)

                if showsAdvancedDiagnostics {
                    Group {
                        diagnosticDivider
                        diagnosticStatusRow(
                            title: "إذن التنبيهات",
                            value: diagnostics.permissionText,
                            symbol: "bell.badge.fill",
                            isHealthy: diagnostics.isAuthorized
                        )
                        diagnosticDivider
                        diagnosticStatusRow(
                            title: "ظهور التنبيه",
                            value: diagnostics.alertsEnabled ? "مسموح" : "مغلق",
                            symbol: "bell.fill",
                            isHealthy: diagnostics.alertsEnabled
                        )
                        diagnosticDivider
                        diagnosticStatusRow(
                            title: "شاشة القفل",
                            value: diagnostics.lockScreenEnabled ? "مسموح" : "مغلق",
                            symbol: "lock.fill",
                            isHealthy: diagnostics.lockScreenEnabled
                        )
                        diagnosticDivider
                        diagnosticStatusRow(
                            title: "حساس للوقت",
                            value: diagnostics.timeSensitiveEnabled ? "مسموح" : "مغلق",
                            symbol: "clock.fill",
                            isHealthy: diagnostics.timeSensitiveEnabled
                        )
                        diagnosticDivider
                        diagnosticStatusRow(
                            title: "جدول الأذان",
                            value: notificationCoverageText,
                            symbol: "calendar",
                            isHealthy: diagnostics.scheduledPrayerCount > 0
                        )

                        HStack(spacing: 10) {
                            Button {
                                openNotificationSettings()
                            } label: {
                                diagnosticActionLabel(title: "إعدادات الآيفون", symbol: "gearshape.fill")
                            }

                            Button {
                                notifications.refreshDiagnostics()
                            } label: {
                                diagnosticActionLabel(title: "تحديث الفحص", symbol: "arrow.clockwise")
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    private var notificationCoverageText: String {
        let diagnostics = notifications.diagnostics
        guard diagnostics.scheduledPrayerCount > 0,
              let firstDate = diagnostics.firstPrayerDate,
              let lastDate = diagnostics.lastPrayerDate else {
            return "لا توجد مواعيد"
        }

        let firstText = notificationLatinDigits(Self.notificationCoverageDateFormatter.string(from: firstDate))
        let lastText = notificationLatinDigits(Self.notificationCoverageDateFormatter.string(from: lastDate))
        return "\(diagnostics.scheduledPrayerCount) تنبيه • من \(firstText) حتى \(lastText)"
    }

    private func notificationLatinDigits(_ text: String) -> String {
        let replacements: [Character: Character] = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"
        ]
        return String(text.map { replacements[$0] ?? $0 })
    }

    private var diagnosticDivider: some View {
        Divider()
            .background(theme.controlBorder)
            .padding(.vertical, 2)
    }

    private func diagnosticStatusRow(title: String, value: String, symbol: String, isHealthy: Bool) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: isHealthy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(isHealthy ? theme.accent : Color.orange)

                Text(value)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(isHealthy ? theme.secondaryText : Color.orange)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 10)

            HStack(spacing: 7) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .multilineTextAlignment(.trailing)

                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.accent)
                    .frame(width: 20)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
    }

    private func diagnosticActionLabel(title: String, symbol: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.76)

            Image(systemName: symbol)
                .font(.caption.weight(.black))
        }
        .environment(\.layoutDirection, .rightToLeft)
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, minHeight: 40)
        .background(lightRowSurface(settingsRowFill, radius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var adhkarMasterPanel: some View {
        toggleSummaryPanel(
            title: "تذكير الأذكار",
            subtitle: notifications.isAdhkarReminderEnabled ? "يظهر تذكير خفيف بعد الصلوات المختارة" : "التذكير بالأذكار متوقف",
            isOn: Binding(
                get: { notifications.isAdhkarReminderEnabled },
                set: { notifications.setAdhkarReminderEnabled($0) }
            )
        )
    }

    private var nafahatMasterPanel: some View {
        toggleSummaryPanel(
            title: "تذكيرات الأذكار",
            subtitle: notifications.isNafahatEnabled ? "ذكر خفيف \(selectedNafahatIntervalTitle)" : "تذكيرات الأذكار متوقفة",
            isOn: Binding(
                get: { notifications.isNafahatEnabled },
                set: { notifications.setNafahatEnabled($0) }
            )
        )
    }

    private var miniKhatmahPanel: some View {
        let portion = MiniKhatmahPortion(rawValue: miniKhatmahDailyPortion) ?? .halfPage
        let progress = miniKhatmahProgress(for: portion)

        return panel(title: "ختمة مصغرة") {
            VStack(alignment: .trailing, spacing: 12) {
                Button {
                    if !isMiniKhatmahEnabled {
                        miniKhatmahStartDate = Date().timeIntervalSince1970
                    }
                    isMiniKhatmahEnabled.toggle()
                } label: {
                    HStack(spacing: 12) {
                        lightSwitch(isOn: isMiniKhatmahEnabled)

                        Spacer(minLength: 12)

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(isMiniKhatmahEnabled ? "الختمة تعمل بهدوء" : "تشغيل الختمة المصغرة")
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(isMiniKhatmahEnabled ? theme.accent : theme.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)

                            Text(portion.subtitle)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.secondaryText.opacity(0.82))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 18, weight: .black))
                            .foregroundStyle(theme.accent)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 12)
                    .background(lightRowSurface(isMiniKhatmahEnabled ? theme.activeRowBackground : settingsRowFill, radius: 8, selected: isMiniKhatmahEnabled))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    ForEach(MiniKhatmahPortion.allCases) { item in
                        miniKhatmahPortionButton(item)
                    }
                }
                .environment(\.layoutDirection, .leftToRight)

                HStack(alignment: .center, spacing: 10) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(progress.title)
                            .font(.headline.weight(.black))
                            .foregroundStyle(theme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.74)

                        Text(progress.detail)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(theme.secondaryText.opacity(0.86))
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    ZStack {
                        Circle()
                            .stroke(theme.accent.opacity(theme.isNightTheme ? 0.20 : 0.16), lineWidth: 6)

                        Circle()
                            .trim(from: 0, to: progress.ratio)
                            .stroke(theme.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))

                        Text("\(progress.percent)%")
                            .font(.caption2.monospacedDigit().weight(.black))
                            .foregroundStyle(theme.accent)
                    }
                    .frame(width: 54, height: 54)
                }
                .padding(12)
                .background(lightRowSurface(theme.countdownBackground.opacity(theme.isNightTheme ? 0.34 : 0.16), radius: 8, selected: false))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func miniKhatmahPortionButton(_ portion: MiniKhatmahPortion) -> some View {
        let selected = miniKhatmahDailyPortion == portion.rawValue

        return Button {
            miniKhatmahDailyPortion = portion.rawValue
            if miniKhatmahStartDate == 0 {
                miniKhatmahStartDate = Date().timeIntervalSince1970
            }
        } label: {
            Text(portion.title)
                .font(.caption.weight(.black))
                .foregroundStyle(selected ? .white : theme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected ? theme.accent : theme.controlBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(selected ? Color.white.opacity(0.28) : theme.controlBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func miniKhatmahProgress(for portion: MiniKhatmahPortion) -> (title: String, detail: String, ratio: CGFloat, percent: Int) {
        let start = miniKhatmahStartDate > 0 ? Date(timeIntervalSince1970: miniKhatmahStartDate) : Date()
        let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: start), to: Calendar.current.startOfDay(for: Date())).day ?? 0)
        let currentStep = min(portion.totalSteps, days + 1)
        let currentPage = min(604, Int(ceil(Double(currentStep) * portion.pagesPerStep)))
        let ratio = min(1, max(0, CGFloat(currentStep) / CGFloat(portion.totalSteps)))
        let percent = Int((ratio * 100).rounded())
        let title = isMiniKhatmahEnabled ? "ورد اليوم: \(portion.title)" : "ابدأ بخطة خفيفة"
        let detail = isMiniKhatmahEnabled
            ? "صفحة \(currentPage) • اليوم \(currentStep) من \(portion.totalSteps)"
            : "اختر نصف صفحة أو صفحة يوميًا، والتطبيق يرتب لك المسار."

        return (title, detail, ratio, percent)
    }

    private var nafahatPreviewPanel: some View {
        panel(title: "اختبار التذكير") {
            Button {
                notifications.sendNafahatPreviewNotification()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .black))
                        .frame(width: 34, alignment: .leading)

                    Spacer(minLength: 8)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("جرّب تذكير أذكار الآن")
                            .font(.subheadline.weight(.black))
                            .lineLimit(2)
                            .minimumScaleFactor(0.84)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("يوصل تذكير صامت تجريبي بعد ثانيتين")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.secondaryText.opacity(0.82))
                            .lineLimit(2)
                            .minimumScaleFactor(0.78)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .frame(minHeight: 78, alignment: .center)
                .background(glassSurface(theme.activeRowBackground, radius: 12, prominence: .regular))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.activeRowBorder.opacity(0.72))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    private var fajrAlarmMasterPanel: some View {
        toggleSummaryPanel(
            title: "منبه الفجر",
            subtitle: notifications.isFajrAlarmEnabled ? "يعمل عند صلاة الفجر بإعدادات مستقلة" : "منبه الفجر متوقف",
            isOn: Binding(
                get: { notifications.isFajrAlarmEnabled },
                set: { notifications.setFajrAlarmEnabled($0) }
            )
        )
    }

    private var fajrAlarmIntensityPanel: some View {
        panel(title: "قوة المنبه") {
            VStack(spacing: 0) {
                ForEach(Array(FajrAlarmIntensity.allCases.enumerated()), id: \.element.id) { index, intensity in
                    Button {
                        notifications.selectFajrAlarmIntensity(intensity)
                    } label: {
                        optionRow(
                            title: intensity.title,
                            subtitle: intensity.subtitle,
                            symbol: intensity.systemImage,
                            selected: notifications.selectedFajrAlarmIntensityID == intensity.rawValue
                        )
                    }
                    .buttonStyle(.plain)

                    if index < FajrAlarmIntensity.allCases.count - 1 {
                        Divider()
                            .background(theme.controlBorder)
                    }
                }
            }
        }
    }

    private var fajrAlarmTimingPanel: some View {
        panel(title: "موعد التنبيه") {
            VStack(alignment: .trailing, spacing: 10) {
                Text("اختار هل يبدأ مع الأذان أو قبله")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                HStack(spacing: 8) {
                    fajrChoiceButton(
                        title: "قبل 15 د",
                        selected: notifications.fajrAlarmWakeBeforeMinutes == 15
                    ) {
                        notifications.setFajrAlarmWakeBeforeMinutes(15)
                    }

                    fajrChoiceButton(
                        title: "قبل 10 د",
                        selected: notifications.fajrAlarmWakeBeforeMinutes == 10
                    ) {
                        notifications.setFajrAlarmWakeBeforeMinutes(10)
                    }

                    fajrChoiceButton(
                        title: "قبل 5 د",
                        selected: notifications.fajrAlarmWakeBeforeMinutes == 5
                    ) {
                        notifications.setFajrAlarmWakeBeforeMinutes(5)
                    }

                    fajrChoiceButton(
                        title: "مع الأذان",
                        selected: notifications.fajrAlarmWakeBeforeMinutes == 0
                    ) {
                        notifications.setFajrAlarmWakeBeforeMinutes(0)
                    }
                }
            }
        }
    }

    private var fajrAlarmSnoozePanel: some View {
        panel(title: "الغفوة") {
            HStack(spacing: 8) {
                ForEach([10, 5, 3], id: \.self) { minutes in
                    fajrChoiceButton(
                        title: "\(minutes) دقائق",
                        selected: notifications.fajrAlarmSnoozeMinutes == minutes
                    ) {
                        notifications.setFajrAlarmSnoozeMinutes(minutes)
                    }
                }
            }
        }
    }

    private var fajrAlarmSoundPanel: some View {
        panel(title: "صوت منبه الفجر") {
            VStack(spacing: 0) {
                ForEach(Array(FajrAlarmSound.allCases.enumerated()), id: \.element.id) { index, sound in
                    Button {
                        notifications.selectFajrAlarmSound(sound)
                        notifications.sendFajrAlarmTestNotification()
                    } label: {
                        optionRow(
                            title: sound.title,
                            subtitle: sound.subtitle,
                            symbol: sound.systemImage,
                            selected: notifications.selectedFajrAlarmSoundID == sound.rawValue
                        )
                    }
                    .buttonStyle(.plain)

                    if index < FajrAlarmSound.allCases.count - 1 {
                        Divider()
                            .background(theme.controlBorder)
                    }
                }
            }
        }
    }

    private var fajrAlarmTestPanel: some View {
        panel(title: "اختبار منبه الفجر") {
            Button {
                notifications.sendFajrAlarmTestNotification()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "alarm.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(theme.accent)
                        .frame(width: 34, alignment: .leading)

                    Spacer(minLength: 10)

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("جرّب منبه الفجر الآن")
                            .font(.subheadline.weight(.black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.80)

                        Text("يصلك اختبار بعد 5 ثواني مع صحيت وغفوة")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.secondaryText.opacity(0.82))
                            .lineLimit(2)
                            .minimumScaleFactor(0.76)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .frame(minHeight: 78, alignment: .center)
                .background(glassSurface(theme.countdownBackground, radius: 8, prominence: .strong))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.activeRowBorder)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private var soundPanel: some View {
        panel(title: "صوت الأذان") {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showsSoundChoices.toggle()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: showsSoundChoices ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.black))
                            .foregroundStyle(theme.accent)

                        Spacer(minLength: 10)

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(selectedPrayerSound.title)
                                .font(.subheadline.weight(.black))
                                .lineLimit(1)

                            Text("اضغط لتغيير الصوت أو تجربته")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.secondaryText)
                        }

                        Image(systemName: selectedPrayerSound.systemImage)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(theme.accent)
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(lightRowSurface(settingsRowFill, radius: 12))
                }
                .buttonStyle(.plain)

                if showsSoundChoices {
                    Divider()
                        .background(theme.controlBorder)
                        .padding(.vertical, 6)

                    ForEach(Array(PrayerNotificationSound.allCases.enumerated()), id: \.element.id) { index, sound in
                        Button {
                            notifications.selectSound(sound)
                        } label: {
                            optionRow(
                                title: sound.title,
                                subtitle: sound.subtitle,
                                symbol: sound.systemImage,
                                selected: notifications.selectedSoundID == sound.rawValue,
                                showsSubtitle: false
                            )
                        }
                        .buttonStyle(.plain)

                        if index < PrayerNotificationSound.allCases.count - 1 {
                            Divider()
                                .background(theme.controlBorder)
                        }
                    }

                    Button {
                        notifications.sendPreviewNotification()
                    } label: {
                        diagnosticActionLabel(title: "جرّب الصوت بعد 5 ثوانٍ", symbol: "play.fill")
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                }
            }
        }
    }

    private var selectedPrayerSound: PrayerNotificationSound {
        PrayerNotificationSound(rawValue: notifications.selectedSoundID) ?? .originalAdhan
    }

    private var prayerPanel: some View {
        let todayTimes = PrayerEngine.schedule(for: PrayerEngine.defaultDateKey()).times

        return panel(title: "الصلوات التي يصدر لها الأذان") {
            VStack(alignment: .trailing, spacing: 12) {
                HStack(spacing: 8) {
                    Text("\(enabledPrayerCount) من \(PrayerEngine.prayerOrder.count) مفعّلة")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.secondaryText.opacity(0.82))

                    Spacer(minLength: 8)

                    Image(systemName: "bell.and.waves.left.and.right.fill")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(theme.accent)
                        .frame(width: 30, height: 30)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                LazyVStack(spacing: 10) {
                    ForEach(PrayerEngine.prayerOrder, id: \.id) { key in
                        prayerToggleRow(
                            key,
                            time: todayTimes[key] ?? "--:--",
                            isOn: Binding(
                                get: { notifications.isPrayerEnabled(key) },
                                set: { notifications.setPrayer(key, enabled: $0) }
                            )
                        )
                        .background(lightRowSurface(settingsRowFill, radius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.controlBorder)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }

    private var iqamaNotificationPanel: some View {
        VStack(alignment: .trailing, spacing: 10) {
            toggleSummaryPanel(
                title: "تنبيهات الإقامة",
                subtitle: notifications.isIqamaNotificationEnabled
                    ? "يظهر تنبيه عند إقامة الصلوات المفعّلة أعلاه"
                    : "تنبيهات الإقامة متوقفة",
                isOn: Binding(
                    get: { notifications.isIqamaNotificationEnabled },
                    set: { notifications.setIqamaNotificationEnabled($0) }
                )
            )

            Button {
                let expiration = IqamaPreviewStorage.start(prayer: .dhuhr)
                iqamaPreviewExpiration = expiration.timeIntervalSince1970
                WidgetRefreshCenter.refreshAll(force: true)
                NotificationCenter.default.post(
                    name: PrayerNotificationManager.openScheduleNotification,
                    object: nil
                )
            } label: {
                iqamaTestButtonLabel(
                    title: "معاينة عدّاد الإقامة",
                    subtitle: iqamaPreviewExpiration > Date().timeIntervalSince1970
                        ? "المعاينة تعمل الآن في التطبيق والويجت"
                        : "تظهر في التطبيق والويجت لمدة دقيقتين",
                    symbol: "timer"
                )
            }
            .buttonStyle(.plain)

            if notifications.isIqamaNotificationEnabled {
                Button {
                    notifications.sendIqamaPreviewNotification()
                } label: {
                    iqamaTestButtonLabel(
                        title: "اختبار تنبيه الإقامة",
                        subtitle: "يصلك تنبيه تجريبي بعد 5 ثواني",
                        symbol: "person.2.fill"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func iqamaTestButtonLabel(
        title: String,
        subtitle: String,
        symbol: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 19, weight: .black))
                .foregroundStyle(theme.accent)
                .frame(width: 34, alignment: .leading)

            Spacer(minLength: 10)

            VStack(alignment: .trailing, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.82))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(glassSurface(theme.activeRowBackground, radius: 8, prominence: .regular))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.activeRowBorder.opacity(0.72))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var enabledPrayerCount: Int {
        PrayerEngine.prayerOrder.filter { notifications.isPrayerEnabled($0) }.count
    }

    private var nafahatIntervalPanel: some View {
        panel(title: "وقت الأذكار") {
            VStack(alignment: .trailing, spacing: 10) {
                Text("اختر كل كم وقت يصلك ذكر خفيف")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                VStack(spacing: 0) {
                    ForEach(Array(NafahatReminderInterval.allCases.enumerated()), id: \.element.id) { index, interval in
                        Button {
                            notifications.setNafahatInterval(interval)
                        } label: {
                            optionRow(
                                title: interval.title,
                                subtitle: interval.subtitle,
                                symbol: "clock.fill",
                                selected: notifications.nafahatIntervalMinutes == interval.rawValue
                            )
                        }
                        .buttonStyle(.plain)

                        if index < NafahatReminderInterval.allCases.count - 1 {
                            Divider()
                                .background(theme.controlBorder)
                        }
                    }
                }
            }
        }
    }

    private var nafahatTextPanel: some View {
        panel(title: "نوع الذكر") {
            VStack(spacing: 0) {
                ForEach(Array(NafahatReminderText.allCases.enumerated()), id: \.element.id) { index, text in
                    Button {
                        notifications.selectNafahatText(text)
                    } label: {
                        optionRow(
                            title: text.title,
                            subtitle: text.subtitle,
                            symbol: text.systemImage,
                            selected: notifications.selectedNafahatTextID == text.rawValue
                        )
                    }
                    .buttonStyle(.plain)

                    if index < NafahatReminderText.allCases.count - 1 {
                        Divider()
                            .background(theme.controlBorder)
                    }
                }
            }
        }
    }

    private var nafahatQuietPanel: some View {
        panel(title: "وقت الهدوء") {
            VStack(spacing: 0) {
                ForEach(Array(NafahatQuietWindow.allCases.enumerated()), id: \.element.id) { index, window in
                    Button {
                        notifications.selectNafahatQuietWindow(window)
                    } label: {
                        optionRow(
                            title: window.title,
                            subtitle: window.subtitle,
                            symbol: window.systemImage,
                            selected: notifications.selectedNafahatQuietWindowID == window.rawValue
                        )
                    }
                    .buttonStyle(.plain)

                    if index < NafahatQuietWindow.allCases.count - 1 {
                        Divider()
                            .background(theme.controlBorder)
                    }
                }
            }
        }
    }

    private var adhkarDelayPanel: some View {
        panel(title: "وقت تذكير الأذكار") {
            VStack(alignment: .trailing, spacing: 10) {
                Text("بعد صلاة كل صلاة تختارها")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.82))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                HStack(spacing: 8) {
                    ForEach([15, 10, 5, 2], id: \.self) { minutes in
                        delayButton(minutes)
                    }
                }
            }
        }
    }

    private func fajrChoiceButton(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(selected ? theme.primaryText : theme.secondaryText.opacity(0.84))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(lightRowSurface(selected ? theme.countdownBackground : theme.rowBackground, radius: 8, selected: selected))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected ? theme.activeRowBorder : theme.rowBorder)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func delayButton(_ minutes: Int) -> some View {
        let selected = notifications.adhkarDelayMinutes == minutes
        return Button {
            notifications.setAdhkarDelayMinutes(minutes)
        } label: {
            Text("بعد \(minutes) د")
                .font(.caption.weight(.black))
                .foregroundStyle(selected ? theme.primaryText : theme.secondaryText.opacity(0.84))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(lightRowSurface(selected ? theme.countdownBackground : theme.rowBackground, radius: 8, selected: selected))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(selected ? theme.activeRowBorder : theme.rowBorder)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var adhkarStylePanel: some View {
        panel(title: "نوع الذكر") {
            VStack(spacing: 0) {
                ForEach(Array(AdhkarReminderStyle.allCases.enumerated()), id: \.element.id) { index, style in
                    Button {
                        notifications.selectAdhkarStyle(style)
                    } label: {
                        optionRow(
                            title: style.title,
                            subtitle: style.subtitle,
                            symbol: style.systemImage,
                            selected: notifications.selectedAdhkarStyleID == style.rawValue
                        )
                    }
                    .buttonStyle(.plain)

                    if index < AdhkarReminderStyle.allCases.count - 1 {
                        Divider()
                            .background(theme.controlBorder)
                    }
                }
            }
        }
    }

    private var adhkarPrayerPanel: some View {
        let todayTimes = PrayerEngine.schedule(for: PrayerEngine.defaultDateKey()).times

        return panel(title: "الصلوات التي يظهر بعدها التذكير") {
            VStack(spacing: 0) {
                ForEach(Array(PrayerEngine.prayerOrder.enumerated()), id: \.element.id) { index, key in
                    prayerToggleRow(
                        key,
                        time: todayTimes[key] ?? "--:--",
                        isOn: Binding(
                            get: { notifications.isAdhkarPrayerEnabled(key) },
                            set: { notifications.setAdhkarPrayer(key, enabled: $0) }
                        )
                    )

                    if index < PrayerEngine.prayerOrder.count - 1 {
                        Divider()
                            .background(theme.controlBorder)
                    }
                }
            }
        }
    }

    private func toggleSummaryPanel(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.accent)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.82))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(glassSurface(settingsPanelFill, radius: 16, prominence: .regular))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func panel<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.accent)
                .frame(maxWidth: .infinity, alignment: .trailing)

            content()
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(glassSurface(settingsPanelFill, radius: 16, prominence: .regular))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func optionRow(title: String, subtitle: String, symbol: String, selected: Bool, showsSubtitle: Bool = true) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: selected ? "checkmark.circle.fill" : symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(selected ? theme.accent : theme.secondaryText.opacity(0.88))
                .frame(width: 28, alignment: .leading)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(selected ? theme.accent : theme.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                if showsSubtitle {
                    Text(subtitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.secondaryText.opacity(0.80))
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, showsSubtitle ? 9 : 8)
        .padding(.horizontal, 8)
        .frame(minHeight: showsSubtitle ? 58 : 48, alignment: .center)
        .background(lightRowSurface(selected ? theme.activeRowBackground : settingsRowFill, radius: 12, selected: selected))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }

    private func prayerToggleRow(_ key: PrayerKey, time: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            HStack(spacing: 12) {
                lightSwitch(isOn: isOn.wrappedValue)

                Spacer(minLength: 12)

                HStack(spacing: 18) {
                    Text(time)
                        .font(.headline.monospacedDigit().weight(.black))
                        .foregroundStyle(theme.secondaryText.opacity(0.82))
                        .lineLimit(1)

                    Text(key.title)
                        .font(.headline.weight(.bold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(lightRowSurface(isOn.wrappedValue ? theme.activeRowBackground : settingsRowFill, radius: 12, selected: isOn.wrappedValue))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func lightSwitch(isOn: Bool) -> some View {
        Capsule()
            .fill(isOn ? theme.accent : theme.secondaryText.opacity(theme.isNightTheme ? 0.24 : 0.18))
            .frame(width: 48, height: 28)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                    .padding(2)
            }
            .overlay(
                Capsule()
                    .stroke(isOn ? Color.white.opacity(0.30) : theme.controlBorder, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.16), value: isOn)
            .accessibilityHidden(true)
    }

    private var themeSplitPalettePanel: some View {
        panel(title: "أنماط التطبيق") {
            VStack(alignment: .trailing, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    themeColumn(title: "نهاري", themes: PrayerVisualTheme.dayChoices, selectedID: selectedDayThemeID)
                    themeColumn(title: "ليلي", themes: PrayerVisualTheme.nightChoices, selectedID: selectedNightThemeID)
                }
                .environment(\.layoutDirection, .leftToRight)

                Text("اختار نمطًا نهاريًا ونمطًا ليليًا، والتطبيق يبدل بينهم تلقائيًا حسب الوقت.")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.78))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private func themeEssentialCard(title: String, subtitle: String, visualTheme: PrayerVisualTheme, selected: Bool) -> some View {
        Button {
            selectTheme(visualTheme)
        } label: {
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: selected ? "checkmark.circle.fill" : visualTheme.symbol)
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(selected ? theme.accent : theme.secondaryText.opacity(0.76))

                    Spacer()

                    Text(title)
                        .font(.caption.weight(.black))
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                }
                .environment(\.layoutDirection, .leftToRight)

                Text(subtitle)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.secondaryText.opacity(0.78))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: visualTheme.widgetBackground,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 8)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(theme.isNightTheme ? 0.18 : 0.54), lineWidth: 0.8)
                    )
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topTrailing)
            .background(lightRowSurface(selected ? theme.activeRowBackground : settingsRowFill, radius: 8, selected: selected))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selected ? theme.activeRowBorder : theme.controlBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func themeColumn(title: String, themes: [PrayerVisualTheme], selectedID: String) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(theme.accent)
                .frame(maxWidth: .infinity, alignment: .trailing)

            ForEach(themes) { visualTheme in
                themePreviewOption(visualTheme, selected: selectedID == visualTheme.rawValue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
    }

    private func themePreviewOption(_ visualTheme: PrayerVisualTheme, selected: Bool) -> some View {
        Button {
            selectTheme(visualTheme)
        } label: {
            VStack(alignment: .trailing, spacing: 7) {
                ZStack(alignment: .bottomTrailing) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: visualTheme.widgetBackground,
                                startPoint: .topTrailing,
                                endPoint: .bottomLeading
                            )
                        )

                    LinearGradient(
                        colors: [
                            Color.white.opacity(visualTheme.isNightTheme ? 0.06 : 0.34),
                            visualTheme.accent.opacity(visualTheme.isNightTheme ? 0.22 : 0.14),
                            Color.black.opacity(visualTheme.isNightTheme ? 0.28 : 0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    HStack(alignment: .bottom, spacing: 6) {
                        Text("04:08")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(visualTheme.accent)

                        Spacer(minLength: 4)

                        Image(systemName: visualTheme.symbol)
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(visualTheme.isNightTheme ? .white.opacity(0.90) : visualTheme.accent)
                    }
                    .padding(8)
                }
                .frame(height: 54)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selected ? visualTheme.accent.opacity(0.78) : Color.white.opacity(theme.isNightTheme ? 0.16 : 0.70), lineWidth: selected ? 1.4 : 0.8)
                )

                HStack(spacing: 6) {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(selected ? theme.accent : theme.secondaryText.opacity(0.58))

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(visualTheme.title)
                            .font(.caption2.weight(.black))
                            .foregroundStyle(selected ? theme.accent : theme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)

                        Text(visualThemeSubtitle(for: visualTheme))
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.secondaryText.opacity(0.72))
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                    }
                }
                .environment(\.layoutDirection, .leftToRight)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(lightRowSurface(selected ? theme.activeRowBackground : settingsRowFill, radius: 10, selected: selected))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func themePalettePanel(title: String, themes: [PrayerVisualTheme], selectedID: String) -> some View {
        panel(title: title) {
            LazyVStack(spacing: 0) {
                ForEach(Array(themes.enumerated()), id: \.element.id) { index, visualTheme in
                    Button {
                        selectTheme(visualTheme)
                    } label: {
                        optionRow(
                            title: visualTheme.title,
                            subtitle: visualThemeSubtitle(for: visualTheme),
                            symbol: visualTheme.symbol,
                            selected: selectedID == visualTheme.rawValue
                        )
                    }
                    .buttonStyle(.plain)

                    if index < themes.count - 1 {
                        Divider()
                            .background(theme.controlBorder)
                    }
                }
            }
        }
    }

    private func selectTheme(_ visualTheme: PrayerVisualTheme) {
        if visualTheme.isNightTheme {
            selectedNightThemeID = visualTheme.rawValue
            AppThemeStorage.defaults.set(visualTheme.rawValue, forKey: AppThemeStorage.nightThemeKey)
        } else {
            selectedDayThemeID = visualTheme.rawValue
            AppThemeStorage.defaults.set(visualTheme.rawValue, forKey: AppThemeStorage.dayThemeKey)
        }

        AppThemeStorage.defaults.synchronize()
        WidgetRefreshCenter.refreshAll(force: true)
    }

    private func visualThemeSubtitle(for visualTheme: PrayerVisualTheme) -> String {
        switch visualTheme {
        case .daySalatiGlass, .nightSalatiGlass:
            return "النمط الأساسي الحالي"
        case .dayCrystalGlass:
            return "بلّور مضيء وضبابية حقيقية"
        case .nightCrystalGlass:
            return "بلّور داكن وعمق هادئ"
        case .dayAppleGlass:
            return "زجاج أبيض مع صورة أوضح"
        case .dayOasisGlass:
            return "زجاج سماوي مع هدوء أكثر"
        case .nightAppleGlass:
            return "ليل أزرق مع صورة المسجد"
        case .nightSakinaGlass:
            return "ليل دافئ وناعم"
        default:
            break
        }

        return visualTheme.isGlassTheme ? "زجاج خفيف ومتناسق" : "نمط كلاسيكي"
    }

    private func glassSurface(
        _ base: Color,
        radius: CGFloat,
        prominence: GlassProminence = .regular
    ) -> some View {
        ThemeGlassSurface(
            theme: theme,
            base: base,
            cornerRadius: radius,
            prominence: prominence
        )
    }

    private func lightRowSurface(_ base: Color, radius: CGFloat, selected: Bool = false) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(base)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(
                        selected ? theme.activeRowBorder.opacity(theme.isGlassTheme ? 0.72 : 1.0) : theme.rowBorder.opacity(theme.isGlassTheme ? 0.82 : 1.0),
                        lineWidth: 0.8
                    )
            )
    }

    private var selectedNafahatIntervalTitle: String {
        (NafahatReminderInterval(rawValue: notifications.nafahatIntervalMinutes) ?? .twoHours).title
    }

    private var settingsPanelFill: Color {
        theme.isGlassTheme ? theme.panelBackground.opacity(theme.isNightTheme ? 0.92 : 0.86) : theme.panelBackground
    }

    private var settingsRowFill: Color {
        theme.isGlassTheme ? theme.rowBackground.opacity(theme.isNightTheme ? 0.70 : 0.58) : Color.clear
    }
}

private enum MiniKhatmahPortion: String, CaseIterable, Identifiable {
    case halfPage
    case fullPage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .halfPage:
            return "نصف صفحة"
        case .fullPage:
            return "صفحة يوميًا"
        }
    }

    var subtitle: String {
        switch self {
        case .halfPage:
            return "نصف صفحة يوميًا لمن يريد مسارًا هادئًا"
        case .fullPage:
            return "صفحة يوميًا لختمة ثابتة وواضحة"
        }
    }

    var totalSteps: Int {
        switch self {
        case .halfPage:
            return 1208
        case .fullPage:
            return 604
        }
    }

    var pagesPerStep: Double {
        switch self {
        case .halfPage:
            return 0.5
        case .fullPage:
            return 1
        }
    }
}

private enum NotificationSettingsPage: String, CaseIterable, Identifiable {
    case adhan
    case adhkar
    case appearance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .adhan:
            return "الأذان"
        case .adhkar:
            return "الأذكار"
        case .appearance:
            return "المظهر"
        }
    }

    var systemImage: String {
        switch self {
        case .adhan:
            return "bell.badge.fill"
        case .adhkar:
            return "sparkles"
        case .appearance:
            return "paintpalette.fill"
        }
    }
}
