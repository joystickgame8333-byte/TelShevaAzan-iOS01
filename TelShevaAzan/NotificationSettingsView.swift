import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notifications = PrayerNotificationManager.shared
    @State private var selectedPage: NotificationSettingsPage = .adhan

    let theme: PrayerVisualTheme

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 820

            ZStack {
                ThemeBackdrop(theme: theme)

                VStack(alignment: .trailing, spacing: compactHeight ? 9 : 11) {
                    header
                    pageSelector

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .trailing, spacing: compactHeight ? 10 : 13) {
                            if selectedPage == .adhan {
                                adhanSettings
                            } else {
                                nafahatSettings
                            }
                        }
                        .padding(.bottom, proxy.safeAreaInsets.bottom + 18)
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, proxy.safeAreaInsets.top + (compactHeight ? 8 : 14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .foregroundStyle(theme.primaryText)
        .environment(\.layoutDirection, .leftToRight)
        .multilineTextAlignment(.trailing)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
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

            Spacer(minLength: 16)

            VStack(alignment: .trailing, spacing: 4) {
                Text("تنبيهات الأذان")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("الأذان ونَفَحات الذكر في نافذة واحدة")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
    }

    private var pageSelector: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            notificationPageButton(.nafahat)
            notificationPageButton(.adhan)
        }
        .frame(maxWidth: .infinity, alignment: .topTrailing)
        .environment(\.layoutDirection, .leftToRight)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(glassSurface(selectedPage == page ? theme.countdownBackground : theme.controlBackground, radius: 8, prominence: selectedPage == page ? .strong : .regular))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedPage == page ? theme.activeRowBorder : theme.controlBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var adhanSettings: some View {
        VStack(alignment: .trailing, spacing: 12) {
            masterPanel
            soundPanel
            prayerPanel
        }
        .transition(.opacity)
    }

    private var nafahatSettings: some View {
        VStack(alignment: .trailing, spacing: 12) {
            nafahatMasterPanel
            nafahatPreviewPanel
            nafahatIntervalPanel
            nafahatTextPanel
            nafahatQuietPanel
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
            title: "تشغيل نَفَحات",
            subtitle: notifications.isNafahatEnabled ? "تذكير خفيف \(selectedNafahatIntervalTitle)" : "نَفَحات الذكر متوقفة",
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
                    Image(systemName: "bell.badge.fill")

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("جرّب نَفَحة الآن")
                            .font(.subheadline.weight(.black))
                            .lineLimit(1)

                        Text("يوصل تذكير تجريبي بعد ثانيتين")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(theme.secondaryText.opacity(0.82))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.vertical, 11)
                .padding(.horizontal, 12)
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

    private var prayerPanel: some View {
        panel(title: "الصلوات التي يصدر لها الأذان") {
            VStack(spacing: 0) {
                ForEach(Array(PrayerEngine.prayerOrder.enumerated()), id: \.element.id) { index, key in
                    prayerToggleRow(
                        key,
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
        }
    }

    private var nafahatIntervalPanel: some View {
        panel(title: "وقت النَفَحات") {
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
                .background(glassSurface(selected ? theme.countdownBackground : theme.rowBackground, radius: 8, prominence: selected ? .regular : .quiet))
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
        panel(title: "الصلوات التي يظهر بعدها التذكير") {
            VStack(spacing: 0) {
                ForEach(Array(PrayerEngine.prayerOrder.enumerated()), id: \.element.id) { index, key in
                    prayerToggleRow(
                        key,
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
        HStack(spacing: 12) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.accent)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.black))
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(glassSurface(theme.panelBackground, radius: 8, prominence: .strong))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func panel<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.accent)
                .frame(maxWidth: .infinity, alignment: .trailing)

            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(glassSurface(theme.controlBackground, radius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func optionRow(title: String, subtitle: String, symbol: String, selected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: selected ? "checkmark.circle.fill" : symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(selected ? theme.accent : theme.secondaryText.opacity(0.88))
                .frame(width: 28, alignment: .leading)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(selected ? theme.accent : theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.80))
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func prayerToggleRow(_ key: PrayerKey, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(theme.accent)

            Spacer(minLength: 12)

            HStack(spacing: 18) {
                Text(todayTime(for: key))
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
    }

    private func todayTime(for key: PrayerKey) -> String {
        let schedule = PrayerEngine.schedule(for: PrayerEngine.defaultDateKey())
        return schedule.times[key] ?? "--:--"
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

    private var selectedNafahatIntervalTitle: String {
        (NafahatReminderInterval(rawValue: notifications.nafahatIntervalMinutes) ?? .twoHours).title
    }
}

private enum NotificationSettingsPage: String, CaseIterable, Identifiable {
    case adhan
    case nafahat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .adhan:
            return "الأذان"
        case .nafahat:
            return "نَفَحات"
        }
    }

    var systemImage: String {
        switch self {
        case .adhan:
            return "bell.badge.fill"
        case .nafahat:
            return "sparkles"
        }
    }
}
