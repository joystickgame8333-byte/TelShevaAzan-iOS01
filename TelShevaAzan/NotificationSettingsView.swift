import SwiftUI

enum NotificationSettingsMode {
    case full
    case adhkarOnly
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notifications = PrayerNotificationManager.shared
    @ObservedObject private var liveActivityCenter = PrayerLiveActivityCenter.shared
    @State private var selectedPage: NotificationSettingsPage = .adhan
    @State private var isPrayerListExpanded = false
    @AppStorage(AppThemeStorage.nightThemeKey, store: AppThemeStorage.defaults) private var selectedNightThemeID = PrayerVisualTheme.defaultNight.rawValue
    @AppStorage(AppThemeStorage.dayThemeKey, store: AppThemeStorage.defaults) private var selectedDayThemeID = PrayerVisualTheme.defaultDay.rawValue

    let theme: PrayerVisualTheme
    var mode: NotificationSettingsMode = .full
    var isEmbedded = false
    var bottomReservedHeight: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720

            ZStack {
                if !isEmbedded {
                    ThemeBackdrop(theme: theme)
                }

                VStack(alignment: .trailing, spacing: compactHeight ? 14 : 18) {
                    header
                    settingsContent(compact: compactHeight, bottomInset: proxy.safeAreaInsets.bottom)
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 18)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topTrailing)
            }
        }
        .foregroundStyle(theme.primaryText)
        .environment(\.layoutDirection, .leftToRight)
        .multilineTextAlignment(.trailing)
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
                Image(systemName: mode == .adhkarOnly ? "sparkles" : "bell.badge.fill")
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
                Text(mode == .adhkarOnly ? "أذكار" : "التنبيه")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text(mode == .adhkarOnly ? "تذكير روحي خفيف خلال اليوم" : "الأذان والأنماط")
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
        VStack(alignment: .trailing, spacing: compact ? 12 : 14) {
            if mode == .full {
                pageSelector
            }

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .trailing, spacing: compact ? 14 : 18) {
                    if mode == .adhkarOnly {
                        nafahatSettings
                    } else if selectedPage == .adhan {
                        adhanSettings
                    } else {
                        appearanceSettings
                    }
                }
                .padding(.bottom, bottomReservedHeight + max(bottomInset, CGFloat(18)))
                .frame(maxWidth: .infinity, alignment: .topTrailing)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }

    private var pageSelector: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            notificationPageButton(.appearance)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Group {
                    if selectedPage == page {
                        glassSurface(theme.countdownBackground, radius: 8, prominence: .strong)
                    } else {
                        lightRowSurface(theme.controlBackground, radius: 8)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedPage == page ? theme.activeRowBorder : theme.controlBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var adhanSettings: some View {
        VStack(alignment: .trailing, spacing: 16) {
            masterPanel
            liveActivityTestPanel
            soundPanel
            prayerPanel
        }
        .transition(.opacity)
    }

    private var nafahatSettings: some View {
        VStack(alignment: .trailing, spacing: 16) {
            nafahatMasterPanel
            adhkarSoundPanel
            nafahatPreviewPanel
            nafahatIntervalPanel
            nafahatTextPanel
            nafahatQuietPanel
        }
        .transition(.opacity)
    }

    private var appearanceSettings: some View {
        VStack(alignment: .trailing, spacing: 16) {
            themePalettePanel(
                title: "أنماط الليل",
                themes: PrayerVisualTheme.nightChoices,
                selectedID: selectedNightThemeID
            )

            themePalettePanel(
                title: "أنماط النهار",
                themes: PrayerVisualTheme.dayChoices,
                selectedID: selectedDayThemeID
            )

            widgetRefreshPanel
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

    private var liveActivityTestPanel: some View {
        panel(title: "اختبار الجزيرة") {
            VStack(alignment: .trailing, spacing: 12) {
                Button {
                    liveActivityCenter.startPreview(themeID: theme.rawValue)
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: liveActivityCenter.isPreviewActive ? "checkmark.circle.fill" : "timer.circle.fill")
                            .font(.system(size: 24, weight: .black))
                            .foregroundStyle(theme.accent)
                            .frame(width: 34, alignment: .leading)

                        Spacer(minLength: 10)

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(liveActivityCenter.isPreviewActive ? "الاختبار شغال الآن" : "تشغيل اختبار الجزيرة")
                                .font(.subheadline.weight(.black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Text("اختبار سريع ٣٠ ثانية للجزيرة")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.secondaryText.opacity(0.82))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 10)
                    .background(glassSurface(theme.countdownBackground, radius: 8, prominence: .strong))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.activeRowBorder)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                liveActivityPrayerTestGrid

                VStack(alignment: .trailing, spacing: 5) {
                    Text(liveActivityCenter.statusText)
                        .font(.caption.weight(.black))
                        .foregroundStyle(theme.accent)
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(liveActivityCenter.detailText)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(theme.secondaryText.opacity(0.80))
                        .lineLimit(4)
                        .minimumScaleFactor(0.72)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(liveActivityCenter.debugText)
                        .font(.caption2.monospaced().weight(.semibold))
                        .foregroundStyle(theme.secondaryText.opacity(0.72))
                        .lineLimit(8)
                        .minimumScaleFactor(0.68)
                        .multilineTextAlignment(.leading)
                        .environment(\.layoutDirection, .leftToRight)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 8)
            }
        }
    }

    private var liveActivityPrayerTestGrid: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("فحص كل الصلوات")
                .font(.caption.weight(.black))
                .foregroundStyle(theme.secondaryText.opacity(0.88))
                .frame(maxWidth: .infinity, alignment: .trailing)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 3),
                alignment: .trailing,
                spacing: 7
            ) {
                ForEach(PrayerEngine.prayerOrder, id: \.self) { prayerKey in
                    Button {
                        liveActivityCenter.startPreview(prayerKey: prayerKey, themeID: theme.rawValue)
                    } label: {
                        HStack(spacing: 5) {
                            Text(prayerKey.title)
                                .font(.caption.weight(.black))
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Image(systemName: testIconName(for: prayerKey))
                                .font(.caption.weight(.black))
                                .foregroundStyle(theme.accent)
                        }
                        .environment(\.layoutDirection, .rightToLeft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 6)
                        .background(lightRowSurface(theme.controlBackground, radius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(theme.controlBorder)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func testIconName(for key: PrayerKey) -> String {
        switch key {
        case .fajr:
            return "moon.stars.fill"
        case .dhuhr:
            return "sun.max.fill"
        case .asr:
            return "cloud.sun.fill"
        case .maghrib:
            return "sunset.fill"
        case .isha:
            return "moon.fill"
        case .sunrise:
            return "sunrise.fill"
        }
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
            title: "تشغيل الأذكار",
            subtitle: notifications.isNafahatEnabled ? "تذكير روحي خفيف \(selectedNafahatIntervalTitle)" : "تذكير الأذكار متوقف",
            isOn: Binding(
                get: { notifications.isNafahatEnabled },
                set: { notifications.setNafahatEnabled($0) }
            )
        )
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

                        Text("يوصل تذكير روحي تجريبي بعد ثانيتين")
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
                ForEach(Array(PrayerNotificationSound.allCases.enumerated()), id: \.element.id) { index, sound in
                    Button {
                        notifications.selectSound(sound)
                        notifications.sendPreviewNotification()
                    } label: {
                        optionRow(
                            title: sound.title,
                            subtitle: sound.subtitle,
                            symbol: sound.systemImage,
                            selected: notifications.selectedSoundID == sound.rawValue
                        )
                    }
                    .buttonStyle(.plain)

                    if index < PrayerNotificationSound.allCases.count - 1 {
                        Divider()
                            .background(theme.controlBorder)
                    }
                }

                Divider()
                    .background(theme.controlBorder)
                    .padding(.top, 2)

                previewButton
                    .padding(.top, 10)
            }
        }
    }

    private var adhkarSoundPanel: some View {
        panel(title: "صوت الأذكار") {
            VStack(spacing: 0) {
                ForEach(Array(AdhkarNotificationSound.allCases.enumerated()), id: \.element.id) { index, sound in
                    Button {
                        notifications.selectAdhkarSound(sound)
                        notifications.sendNafahatPreviewNotification()
                    } label: {
                        optionRow(
                            title: sound.title,
                            subtitle: sound.subtitle,
                            symbol: sound.systemImage,
                            selected: notifications.selectedAdhkarSoundID == sound.rawValue
                        )
                    }
                    .buttonStyle(.plain)

                    if index < AdhkarNotificationSound.allCases.count - 1 {
                        Divider()
                            .background(theme.controlBorder)
                    }
                }
            }
        }
    }

    private var prayerPanel: some View {
        let todayTimes = PrayerEngine.schedule(for: PrayerEngine.defaultDateKey()).times

        return panel(title: "الصلوات التي يصدر لها الأذان") {
            VStack(alignment: .trailing, spacing: 0) {
                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                        isPrayerListExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .black))
                            .rotationEffect(.degrees(isPrayerListExpanded ? 0 : 90))
                            .foregroundStyle(theme.accent)
                            .frame(width: 32, height: 32)
                            .background(lightRowSurface(theme.controlBackground, radius: 8))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Spacer(minLength: 8)

                        VStack(alignment: .trailing, spacing: 3) {
                            Text(isPrayerListExpanded ? "إخفاء الصلوات" : "عرض الصلوات")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(theme.primaryText)

                            Text("\(enabledPrayerCount) من \(PrayerEngine.prayerOrder.count) مفعّلة")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(theme.secondaryText.opacity(0.82))
                        }

                        Image(systemName: "bell.and.waves.left.and.right.fill")
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(theme.accent)
                            .frame(width: 34, height: 34)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)

                if isPrayerListExpanded {
                    Divider()
                        .background(theme.controlBorder)
                        .padding(.vertical, 8)

                    LazyVStack(spacing: 0) {
                        ForEach(Array(PrayerEngine.prayerOrder.enumerated()), id: \.element.id) { index, key in
                            prayerToggleRow(
                                key,
                                time: todayTimes[key] ?? "--:--",
                                isOn: Binding(
                                    get: { notifications.isPrayerEnabled(key) },
                                    set: { notifications.setPrayer(key, enabled: $0) }
                                )
                            )

                            if index < PrayerEngine.prayerOrder.count - 1 {
                                Divider()
                                    .background(theme.controlBorder)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
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

    private var previewButton: some View {
        Button {
            notifications.sendPreviewNotification()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2.fill")

                Text("معاينة الصوت")
                    .lineLimit(1)
            }
            .font(.subheadline.weight(.black))
            .foregroundStyle(theme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(glassSurface(theme.countdownBackground, radius: 8, prominence: .strong))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.activeRowBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
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
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(glassSurface(settingsPanelFill, radius: 8, prominence: .strong))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func panel<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .trailing, spacing: 12) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.accent)
                .frame(maxWidth: .infinity, alignment: .trailing)

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(glassSurface(settingsPanelFill, radius: 8, prominence: .regular))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func optionRow(title: String, subtitle: String, symbol: String, selected: Bool) -> some View {
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

                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.80))
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 8)
        .frame(minHeight: 64, alignment: .center)
        .background(lightRowSurface(selected ? theme.activeRowBackground : settingsRowFill, radius: 8, selected: selected))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
            .padding(.vertical, 10)
            .padding(.horizontal, 8)
            .background(lightRowSurface(isOn.wrappedValue ? theme.activeRowBackground : settingsRowFill, radius: 8, selected: isOn.wrappedValue))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
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

    private var widgetRefreshPanel: some View {
        panel(title: "الويجت") {
            Button {
                WidgetRefreshCenter.refreshAll()
                WidgetRefreshCenter.refreshAgainSoon()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(theme.accent)
                        .frame(width: 28, alignment: .leading)

                    Spacer(minLength: 12)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("تحديث الويجت")
                            .font(.subheadline.weight(.black))
                            .lineLimit(1)

                        Text("ينعش الودجت بدون إعادة تشغيل الهاتف")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.secondaryText.opacity(0.80))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(lightRowSurface(settingsRowFill, radius: 8))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
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
        WidgetRefreshCenter.refreshAll()
        WidgetRefreshCenter.refreshAgainSoon()
    }

    private func visualThemeSubtitle(for visualTheme: PrayerVisualTheme) -> String {
        if visualTheme == .dayAppleGlass || visualTheme == .nightAppleGlass {
            return "زجاج هادئ بروح iOS"
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

private enum NotificationSettingsPage: String, CaseIterable, Identifiable {
    case adhan
    case appearance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .adhan:
            return "الأذان"
        case .appearance:
            return "الأنماط"
        }
    }

    var systemImage: String {
        switch self {
        case .adhan:
            return "bell.badge.fill"
        case .appearance:
            return "paintpalette.fill"
        }
    }
}
