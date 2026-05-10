import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppThemeStorage.nightThemeKey, store: AppThemeStorage.defaults) private var selectedNightThemeID = PrayerVisualTheme.defaultNight.rawValue
    @AppStorage(AppThemeStorage.dayThemeKey, store: AppThemeStorage.defaults) private var selectedDayThemeID = PrayerVisualTheme.defaultDay.rawValue
    @State private var now = Date()
    @State private var selectedDateKey = PrayerEngine.defaultDateKey()
    @State private var followsToday = true
    @State private var selectedTab: HomeDockItem = .schedule
    @State private var tabTransitionEdge: Edge = .leading
    @Namespace private var dockSelectionNamespace
    @StateObject private var notifications = PrayerNotificationManager.shared
    @StateObject private var liveActivityCenter = PrayerLiveActivityCenter.shared

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let visualRefreshKey = "v0_6_26_apple_glass_applied"

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720
            let sectionSpacing: CGFloat = compactHeight ? 6 : 8
            let rowSpacing: CGFloat = compactHeight ? 6 : 8
            let dockBottomPadding = max(proxy.safeAreaInsets.bottom * 0.22, CGFloat(6))
            let dockReservedHeight = proxy.safeAreaInsets.bottom + (compactHeight ? 62 : 70)
            let rowHeight = min(CGFloat(58), max(CGFloat(38), (proxy.size.height - dockReservedHeight - 430) / 6))

            ZStack {
                background

                Group {
                    switch selectedTab {
                    case .schedule:
                        prayerScheduleTabContent(
                            compactHeight: compactHeight,
                            sectionSpacing: sectionSpacing,
                            rowSpacing: rowSpacing,
                            rowHeight: rowHeight,
                            dockReservedHeight: dockReservedHeight,
                            size: proxy.size
                        )
                    case .notifications:
                        NotificationSettingsView(
                            theme: activeTheme,
                            isEmbedded: true,
                            bottomReservedHeight: dockReservedHeight
                        )
                    case .qibla:
                        QiblaView(
                            theme: activeTheme,
                            isEmbedded: true,
                            bottomReservedHeight: dockReservedHeight
                        )
                    case .adhkar:
                        NotificationSettingsView(
                            theme: activeTheme,
                            mode: .adhkarOnly,
                            isEmbedded: true,
                            bottomReservedHeight: dockReservedHeight
                        )
                    case .radio:
                        QuranRadioView(
                            theme: activeTheme,
                            isEmbedded: true,
                            bottomReservedHeight: dockReservedHeight
                        )
                    }
                }
                .id(selectedTab)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .move(edge: tabTransitionEdge)),
                        removal: .opacity.combined(with: .move(edge: oppositeTabTransitionEdge))
                    )
                )
                .animation(.easeInOut(duration: 0.30), value: selectedTab)

                bottomDock
                    .padding(.horizontal, 10)
                    .padding(.bottom, dockBottomPadding)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                    .zIndex(6)
            }
        }
        .onReceive(timer) { value in
            if selectedTab == .schedule {
                updateScheduleClock(value)
            }
            liveActivityCenter.syncWithPrayerWindow(now: value)
        }
        .onChange(of: selectedNightThemeID) { _ in
            WidgetRefreshCenter.refreshAll()
        }
        .onChange(of: selectedDayThemeID) { _ in
            WidgetRefreshCenter.refreshAll()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                WidgetRefreshCenter.refreshAll()
                WidgetRefreshCenter.refreshAgainSoon()
                liveActivityCenter.syncWithPrayerWindow(now: Date())
            }
        }
        .onAppear {
            applyVisualRefreshThemeOnce()
            notifications.refreshIfEnabled()
            WidgetRefreshCenter.refreshAll()
            WidgetRefreshCenter.refreshAgainSoon()
            liveActivityCenter.syncWithPrayerWindow(now: Date())
        }
        .onReceive(NotificationCenter.default.publisher(for: PrayerNotificationManager.openSettingsNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedTab = .notifications
            }
        }
    }

    private func prayerScheduleTabContent(
        compactHeight: Bool,
        sectionSpacing: CGFloat,
        rowSpacing: CGFloat,
        rowHeight: CGFloat,
        dockReservedHeight: CGFloat,
        size: CGSize
    ) -> some View {
        let schedule = PrayerEngine.schedule(for: selectedDateKey)
        let next = PrayerEngine.nextPrayer(for: selectedDateKey, now: now)
        let previous = PrayerEngine.previousPrayer(for: selectedDateKey, now: now)

        return prayerScheduleContent(
            schedule: schedule,
            next: next,
            previous: previous,
            compactHeight: compactHeight,
            sectionSpacing: sectionSpacing,
            rowSpacing: rowSpacing,
            rowHeight: rowHeight,
            dockReservedHeight: dockReservedHeight,
            size: size
        )
    }

    private func prayerScheduleContent(
        schedule: DaySchedule,
        next: PrayerTime?,
        previous: PrayerTime?,
        compactHeight: Bool,
        sectionSpacing: CGFloat,
        rowSpacing: CGFloat,
        rowHeight: CGFloat,
        dockReservedHeight: CGFloat,
        size: CGSize
    ) -> some View {
        VStack(alignment: .trailing, spacing: sectionSpacing) {
            quranVerse

            header

            nextPrayerPanel(next: next, previous: previous, compact: compactHeight)

            dateControls

            VStack(spacing: rowSpacing) {
                ForEach(schedule.displayTimes) { item in
                    prayerRow(item, activeKey: next?.key, rowHeight: rowHeight)
                }
            }

            footerNote
        }
        .padding(.horizontal, 16)
        .padding(.top, compactHeight ? 12 : 18)
        .padding(.bottom, dockReservedHeight)
        .frame(width: size.width, height: size.height, alignment: .topTrailing)
        .foregroundStyle(activeTheme.primaryText)
        .environment(\.layoutDirection, .leftToRight)
        .multilineTextAlignment(.trailing)
    }

    private var quranVerse: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text("إِنَّ ٱلصَّلَوٰةَ كَانَتْ عَلَى ٱلْمُؤْمِنِينَ كِتَـٰبًا مَّوْقُوتًا")
                .font(.custom("AmiriQuran-Regular", size: 25))
                .foregroundStyle(activeTheme.accent)
                .lineLimit(2)
                .minimumScaleFactor(0.64)

            Text("النساء ١٠٣")
                .font(.caption.weight(.bold))
                .foregroundStyle(activeTheme.secondaryText.opacity(0.74))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var header: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("أذان تل السبع")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(PrayerEngine.longDateLabel(for: selectedDateKey))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(activeTheme.secondaryText.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var bottomDock: some View {
        let dockWidth: CGFloat = 302
        let slotWidth = dockWidth / CGFloat(dockItems.count)

        return ZStack(alignment: .bottom) {
            dockLiquidGlassBase
                .frame(width: dockWidth, height: 44)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(dockItems) { item in
                    dockSlotButton(item, slotWidth: slotWidth)
                }
            }
            .frame(width: dockWidth, height: 66, alignment: .bottom)
        }
        .frame(width: dockWidth)
        .frame(height: 66, alignment: .bottom)
        .shadow(color: .black.opacity(activeTheme.isNightTheme ? 0.16 : 0.06), radius: 8, y: 2)
        .environment(\.layoutDirection, .leftToRight)
        .animation(.spring(response: 0.38, dampingFraction: 0.72), value: selectedTab)
    }

    private var dockItems: [HomeDockItem] {
        [.radio, .qibla, .schedule, .adhkar, .notifications]
    }

    private func dockSlotButton(_ item: HomeDockItem, slotWidth: CGFloat) -> some View {
        let selected = selectedDockItem == item

        return Button {
            handleDockTap(item)
        } label: {
            ZStack(alignment: .bottom) {
                if selected {
                    selectedDockBubble(width: 78, height: 52)
                        .matchedGeometryEffect(id: "dockSelection", in: dockSelectionNamespace)

                    VStack(spacing: 3) {
                        Image(systemName: dockSymbol(for: item))
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(activeTheme.accent)
                            .frame(width: 36, height: 36)
                            .background(selectedDockIconFill)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(activeTheme.isNightTheme ? 0.38 : 0.82), lineWidth: 1)
                            )
                            .overlay(alignment: .topTrailing) {
                                dockStatusBadge(for: item)
                                    .offset(x: 5, y: -4)
                            }
                            .shadow(color: .black.opacity(activeTheme.isNightTheme ? 0.16 : 0.07), radius: 4, y: 1)
                            .offset(y: -5)

                        Text(item.title)
                            .font(.system(size: 10.4, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.66)
                            .offset(y: -3)
                    }
                    .frame(width: 78, height: 52)
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: dockSymbol(for: item))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(activeTheme.secondaryText.opacity(0.86))
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 30, height: 22)
                            .overlay(alignment: .topTrailing) {
                                dockStatusBadge(for: item)
                                    .offset(x: 8, y: -6)
                            }

                        Text(item.title)
                            .font(.system(size: 8.2, weight: .bold, design: .rounded))
                            .foregroundStyle(activeTheme.secondaryText.opacity(0.88))
                            .lineLimit(1)
                            .minimumScaleFactor(0.58)
                    }
                    .frame(width: slotWidth, height: 38)
                }
            }
            .frame(width: slotWidth, height: selected ? 58 : 42, alignment: .bottom)
            .offset(y: selected ? -7 : 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(DockButtonPressStyle())
        .accessibilityLabel(item.title)
    }

    @ViewBuilder
    private func dockStatusBadge(for item: HomeDockItem) -> some View {
        if item == .adhkar && notifications.isNafahatEnabled {
            Image(systemName: "sparkle")
                .font(.system(size: 7, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(width: 14, height: 14)
                .background(Circle().fill(activeTheme.accent))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(activeTheme.isNightTheme ? 0.42 : 0.90), lineWidth: 1)
                )
                .shadow(color: activeTheme.accent.opacity(0.34), radius: 4, y: 1)
                .transition(.scale.combined(with: .opacity))
                .accessibilityHidden(true)
        }
    }

    private func selectedDockBubble(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: height * 0.42, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.95 : 0.90),
                        activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.72 : 0.78)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: height * 0.42, style: .continuous)
                    .stroke(Color.white.opacity(activeTheme.isNightTheme ? 0.22 : 0.46), lineWidth: 1)
            )
            .shadow(color: activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.22 : 0.24), radius: 9, y: 3)
            .frame(width: width, height: height)
    }

    private var selectedDockIconFill: some View {
        Circle()
            .fill(activeTheme.isNightTheme ? Color.white.opacity(0.94) : Color.white.opacity(0.98))
    }

    private var dockLiquidGlassBase: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(dockGlassTint)
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(activeTheme.isNightTheme ? 0.12 : 0.46),
                        Color.white.opacity(activeTheme.isNightTheme ? 0.04 : 0.16),
                        activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.04 : 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(activeTheme.isNightTheme ? 0.18 : 0.58), lineWidth: 0.9)
            )
    }

    private var dockGlassTint: Color {
        if activeTheme.isNightTheme {
            return Color.black.opacity(activeTheme.isGlassTheme ? 0.22 : 0.32)
        }

        return Color.white.opacity(activeTheme.isGlassTheme ? 0.34 : 0.58)
    }

    private var selectedDockItem: HomeDockItem? {
        selectedTab
    }

    private func handleDockTap(_ item: HomeDockItem) {
        guard selectedTab != item else {
            return
        }

        tabTransitionEdge = transitionEdge(from: selectedTab, to: item)
        if item == .schedule {
            updateScheduleClock(Date())
        }

        withAnimation(.easeInOut(duration: 0.30)) {
            selectedTab = item
        }
    }

    private func updateScheduleClock(_ value: Date) {
        now = value
        if followsToday {
            selectedDateKey = PrayerEngine.defaultDateKey(for: value)
        }
    }

    private var oppositeTabTransitionEdge: Edge {
        switch tabTransitionEdge {
        case .leading:
            return .trailing
        case .trailing:
            return .leading
        case .top:
            return .bottom
        case .bottom:
            return .top
        }
    }

    private func transitionEdge(from oldItem: HomeDockItem, to newItem: HomeDockItem) -> Edge {
        newItem.order > oldItem.order ? .leading : .trailing
    }

    private func dockSymbol(for item: HomeDockItem) -> String {
        switch item {
        case .schedule:
            return "clock.fill"
        case .radio:
            return "radio.fill"
        case .qibla:
            return "location.north.fill"
        case .adhkar:
            return "sparkles"
        case .notifications:
            return notifications.isEnabled ? "bell.badge.fill" : "bell.fill"
        }
    }

    private func dockRotation(for item: HomeDockItem) -> Double {
        0
    }

    private func nextPrayerPanel(next: PrayerTime?, previous: PrayerTime?, compact: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("باقي على الصلاة")
                        .font(.caption2.weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(countdownText(for: next))
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(activeTheme.countdownBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(elapsedText(for: previous))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(activeTheme.secondaryText.opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text("الصلاة القادمة")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(activeTheme.accent)
                    .lineLimit(1)

                Text(next?.title ?? "--")
                    .font(.system(size: compact ? 29 : 32, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(next?.time ?? "--:--")
                    .font(.system(size: compact ? 35 : 40, weight: .black, design: .rounded))
                    .foregroundStyle(activeTheme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(compact ? 12 : 14)
        .background(glassSurface(activeTheme.panelBackground, radius: 8, prominence: .strong))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(isNight ? 0.22 : 0.06), radius: 12, y: 6)
    }

    private var dateControls: some View {
        HStack(spacing: 8) {
            datePickerButton

            Button("اليوم التالي") {
                moveDay(1)
            }
            .buttonStyle(CompactButtonStyle(theme: activeTheme))
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: 1))

            Button("اليوم") {
                selectedDateKey = PrayerEngine.defaultDateKey(for: now)
                followsToday = true
            }
            .buttonStyle(CompactButtonStyle(theme: activeTheme))

            Button("اليوم السابق") {
                moveDay(-1)
            }
            .buttonStyle(CompactButtonStyle(theme: activeTheme))
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: -1))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var datePickerButton: some View {
        ZStack {
            HStack(spacing: 6) {
                Text("اختار تاريخ")
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Image(systemName: "calendar")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(activeTheme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(glassSurface(activeTheme.controlBackground, radius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(activeTheme.controlBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))

            DatePicker(
                "",
                selection: selectedDateBinding,
                in: datePickerRange,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .opacity(0.02)
        }
        .fixedSize()
    }

    private var footerNote: some View {
        Text("مواقيت محلية \(AppInfo.displayVersion) · تتحدث تلقائيًا")
            .font(.caption2.weight(.bold))
            .foregroundStyle(activeTheme.accent)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func prayerRow(_ item: PrayerTime, activeKey: PrayerKey?, rowHeight: CGFloat) -> some View {
        HStack {
            Text(item.time)
                .font(.headline.monospacedDigit().weight(.bold))
                .foregroundStyle(item.key == activeKey ? activeTheme.accent : activeTheme.primaryText)

            Spacer()

            Text(item.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(item.key == activeKey ? activeTheme.accent : activeTheme.secondaryText.opacity(0.78))
        }
        .lineLimit(1)
        .padding(.horizontal, 12)
        .frame(height: rowHeight)
        .background(glassSurface(rowBackground(isActive: item.key == activeKey), radius: 8, prominence: item.key == activeKey ? .regular : .quiet))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(rowBorder(isActive: item.key == activeKey))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var isNight: Bool {
        colorScheme == .dark
    }

    private var activeTheme: PrayerVisualTheme {
        PrayerVisualTheme.selected(isNight: isNight, nightID: selectedNightThemeID, dayID: selectedDayThemeID)
    }

    private var selectedDateBinding: Binding<Date> {
        Binding<Date>(
            get: {
                PrayerEngine.date(from: selectedDateKey, time: "12:00") ?? now
            },
            set: { date in
                let dateKey = PrayerEngine.defaultDateKey(for: date)
                selectedDateKey = dateKey
                followsToday = dateKey == PrayerEngine.defaultDateKey(for: now)
            }
        )
    }

    private var datePickerRange: ClosedRange<Date> {
        let firstKey = PrayerEngine.availableDateKeys.first ?? selectedDateKey
        let lastKey = PrayerEngine.availableDateKeys.last ?? selectedDateKey
        let start = PrayerEngine.date(from: firstKey, time: "00:00") ?? now
        let end = PrayerEngine.date(from: lastKey, time: "23:59") ?? now
        return start...end
    }

    private func rowBackground(isActive: Bool) -> Color {
        isActive ? activeTheme.activeRowBackground : activeTheme.rowBackground
    }

    private func rowBorder(isActive: Bool) -> Color {
        isActive ? activeTheme.activeRowBorder : activeTheme.rowBorder
    }

    private var dockBackgroundFill: Color {
        if activeTheme.isGlassTheme {
            if activeTheme.isNightTheme {
                return Color(red: 0.07, green: 0.09, blue: 0.09).opacity(0.88)
            }

            return Color.white.opacity(0.84)
        }

        return activeTheme.panelBackground.opacity(0.94)
    }

    private var background: some View {
        ThemeBackdrop(theme: activeTheme)
    }

    private func glassSurface(
        _ base: Color,
        radius: CGFloat,
        pressed: Bool = false,
        prominence: GlassProminence = .regular
    ) -> some View {
        ThemeGlassSurface(
            theme: activeTheme,
            base: base,
            cornerRadius: radius,
            pressed: pressed,
            prominence: prominence
        )
    }

    private func countdownText(for next: PrayerTime?) -> String {
        guard let next else { return "--:--:--" }
        let seconds = Int(next.date.timeIntervalSince(now))
        guard seconds > 0 else { return "--:--:--" }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    private func elapsedText(for previous: PrayerTime?) -> String {
        guard let previous else { return "مضى --:--" }
        let seconds = max(Int(now.timeIntervalSince(previous.date)), 0)
        return "مضى على صلاة \(previous.title) \(hourMinuteText(from: seconds))"
    }

    private func hourMinuteText(from seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        return String(format: "%02d:%02d", hours, minutes)
    }

    private func moveDay(_ offset: Int) {
        guard let nextKey = PrayerEngine.dateKey(from: selectedDateKey, offset: offset) else { return }
        selectedDateKey = nextKey
        followsToday = false
    }

    private func applyVisualRefreshThemeOnce() {
        guard !AppThemeStorage.defaults.bool(forKey: visualRefreshKey) else { return }

        selectedNightThemeID = PrayerVisualTheme.nightAppleGlass.rawValue
        selectedDayThemeID = PrayerVisualTheme.dayAppleGlass.rawValue
        AppThemeStorage.defaults.set(selectedNightThemeID, forKey: AppThemeStorage.nightThemeKey)
        AppThemeStorage.defaults.set(selectedDayThemeID, forKey: AppThemeStorage.dayThemeKey)
        AppThemeStorage.defaults.set(true, forKey: visualRefreshKey)
        AppThemeStorage.defaults.synchronize()
        WidgetRefreshCenter.refreshAll()
        WidgetRefreshCenter.refreshAgainSoon()
    }
}

private enum HomeDockItem: String, CaseIterable, Identifiable {
    case schedule
    case adhkar
    case notifications
    case qibla
    case radio

    var id: String { rawValue }

    var order: Int {
        switch self {
        case .radio:
            return 0
        case .qibla:
            return 1
        case .schedule:
            return 2
        case .adhkar:
            return 3
        case .notifications:
            return 4
        }
    }

    var title: String {
        switch self {
        case .schedule:
            return "مواقيت"
        case .adhkar:
            return "أذكار"
        case .radio:
            return "الراديو"
        case .qibla:
            return "القبلة"
        case .notifications:
            return "تنبيه"
        }
    }
}

private struct DockButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.66), value: configuration.isPressed)
    }
}

private struct CompactButtonStyle: ButtonStyle {
    let theme: PrayerVisualTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .foregroundStyle(theme.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                ThemeGlassSurface(
                    theme: theme,
                    base: configuration.isPressed ? theme.controlPressedBackground : theme.controlBackground,
                    cornerRadius: 8,
                    pressed: configuration.isPressed,
                    prominence: .regular
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.controlBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
        .environment(\.layoutDirection, .rightToLeft)
}
