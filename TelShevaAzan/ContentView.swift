import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppThemeStorage.nightThemeKey, store: AppThemeStorage.defaults) private var selectedNightThemeID = PrayerVisualTheme.defaultNight.rawValue
    @AppStorage(AppThemeStorage.dayThemeKey, store: AppThemeStorage.defaults) private var selectedDayThemeID = PrayerVisualTheme.defaultDay.rawValue
    @State private var now = Date()
    @State private var selectedDateKey = PrayerEngine.defaultDateKey()
    @State private var followsToday = true
    @State private var isThemePickerPresented = false
    @State private var selectedTab: HomeDockItem = .schedule
    @Namespace private var dockSelectionNamespace
    @StateObject private var notifications = PrayerNotificationManager.shared

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let visualRefreshKey = "v0_6_26_apple_glass_applied"

    var body: some View {
        let schedule = PrayerEngine.schedule(for: selectedDateKey)
        let next = PrayerEngine.nextPrayer(for: selectedDateKey, now: now)
        let previous = PrayerEngine.previousPrayer(for: selectedDateKey, now: now)

        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720
            let sectionSpacing: CGFloat = compactHeight ? 6 : 8
            let rowSpacing: CGFloat = compactHeight ? 6 : 8
            let dockBottomPadding = max(proxy.safeAreaInsets.bottom, CGFloat(8))
            let dockReservedHeight = dockBottomPadding + (compactHeight ? 68 : 78)
            let rowHeight = min(CGFloat(58), max(CGFloat(38), (proxy.size.height - dockReservedHeight - 430) / 6))

            ZStack {
                background

                Group {
                    switch selectedTab {
                    case .schedule:
                        prayerScheduleContent(
                            schedule: schedule,
                            next: next,
                            previous: previous,
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
                    case .radio:
                        QuranRadioView(
                            theme: activeTheme,
                            isEmbedded: true,
                            bottomReservedHeight: dockReservedHeight
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .animation(.easeInOut(duration: 0.18), value: selectedTab)

                bottomDock(bottomInset: dockBottomPadding)
                    .padding(.horizontal, 22)
                    .padding(.bottom, dockBottomPadding)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                    .zIndex(6)

                if isThemePickerPresented {
                    themePickerOverlay(
                        width: min(proxy.size.width - 32, 330),
                        topOffset: compactHeight ? 116 : 132,
                        availableHeight: proxy.size.height
                    )
                }
            }
        }
        .onReceive(timer) { value in
            now = value
            if followsToday {
                selectedDateKey = PrayerEngine.defaultDateKey(for: value)
            }
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
            }
        }
        .onAppear {
            applyVisualRefreshThemeOnce()
            notifications.refreshIfEnabled()
            WidgetRefreshCenter.refreshAll()
            WidgetRefreshCenter.refreshAgainSoon()
        }
        .onReceive(NotificationCenter.default.publisher(for: PrayerNotificationManager.openSettingsNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedTab = .notifications
            }
        }
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
        .clipped()
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
        HStack(alignment: .bottom, spacing: 12) {
            themeMenu

            Spacer(minLength: 10)

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
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var themeMenu: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isThemePickerPresented.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Text(activeTheme.modeTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: activeTheme.symbol)
            }
            .font(.caption2.weight(.black))
            .foregroundStyle(activeTheme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 7)
            .background(glassSurface(activeTheme.controlBackground, radius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(activeTheme.controlBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func bottomDock(bottomInset: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(HomeDockItem.allCases) { item in
                dockButton(item)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .frame(height: 58)
        .background(glassSurface(dockBackgroundFill, radius: 23, prominence: .strong))
        .overlay(
            RoundedRectangle(cornerRadius: 23)
                .stroke(activeTheme.controlBorder.opacity(activeTheme.isGlassTheme ? 0.92 : 0.72))
        )
        .clipShape(RoundedRectangle(cornerRadius: 23))
        .shadow(color: .black.opacity(activeTheme.isNightTheme ? 0.24 : 0.08), radius: 11, y: 5)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func dockButton(_ item: HomeDockItem) -> some View {
        let selected = selectedDockItem == item

        return Button {
            handleDockTap(item)
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 2) {
                    Image(systemName: dockSymbol(for: item))
                        .font(.system(size: selected ? 20 : 18, weight: .black, design: .rounded))
                        .scaleEffect(selected ? 1.08 : 1.0)
                        .rotationEffect(.degrees(selected ? dockRotation(for: item) : 0))
                        .offset(y: selected ? -3 : 0)
                        .symbolRenderingMode(.hierarchical)

                    Text(item.title)
                        .font(.system(size: 8.5, weight: selected ? .black : .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(selected ? activeTheme.accent : activeTheme.secondaryText.opacity(0.84))
                .background(
                    Group {
                        if selected {
                            ZStack {
                                glassSurface(activeTheme.countdownBackground, radius: 20, prominence: .strong)

                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(activeTheme.isNightTheme ? 0.16 : 0.40),
                                                Color.white.opacity(0.02)
                                            ],
                                            startPoint: .topTrailing,
                                            endPoint: .bottomLeading
                                        )
                                    )
                                    .blendMode(.screen)
                            }
                            .matchedGeometryEffect(id: "dockSelection", in: dockSelectionNamespace)
                        } else {
                            Color.clear
                        }
                    }
                )
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                if item == .notifications && notifications.isEnabled {
                    Text("✓")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .frame(width: 15, height: 15)
                        .background(activeTheme.accent)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.84), lineWidth: 1))
                        .offset(x: -9, y: 4)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(DockButtonPressStyle())
        .animation(.spring(response: 0.34, dampingFraction: 0.70), value: selected)
        .accessibilityLabel(item.title)
    }

    private var selectedDockItem: HomeDockItem? {
        selectedTab
    }

    private func handleDockTap(_ item: HomeDockItem) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.70)) {
            selectedTab = item
            isThemePickerPresented = false
        }
    }

    private func dockSymbol(for item: HomeDockItem) -> String {
        switch item {
        case .schedule:
            return "clock.fill"
        case .radio:
            return "radio.fill"
        case .qibla:
            return "location.north.fill"
        case .notifications:
            return notifications.isEnabled ? "bell.badge.fill" : "bell.fill"
        }
    }

    private func dockRotation(for item: HomeDockItem) -> Double {
        switch item {
        case .schedule:
            return -5
        case .radio:
            return -4
        case .qibla:
            return 8
        case .notifications:
            return -7
        }
    }

    private func themePickerOverlay(width: CGFloat, topOffset: CGFloat, availableHeight: CGFloat) -> some View {
        ZStack(alignment: .topTrailing) {
            themePickerScrim
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isThemePickerPresented = false
                    }
                }

            themePickerPanel(width: width, maxHeight: max(360, availableHeight - topOffset - 28))
                .padding(.top, topOffset)
                .padding(.trailing, 16)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topTrailing)))
        }
        .zIndex(10)
    }

    private func themePickerPanel(width: CGFloat, maxHeight: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 0) {
                themeSection(
                    title: "أنماط الليل",
                    themes: PrayerVisualTheme.nightChoices,
                    selectedID: selectedNightThemeID
                ) { theme in
                    selectTheme(theme)
                }

                Divider()
                    .background(activeTheme.controlBorder)
                    .padding(.vertical, 4)

                themeSection(
                    title: "أنماط النهار",
                    themes: PrayerVisualTheme.dayChoices,
                    selectedID: selectedDayThemeID
                ) { theme in
                    selectTheme(theme)
                }

                Divider()
                    .background(activeTheme.controlBorder)
                    .padding(.vertical, 4)

                widgetRefreshButton
            }
            .padding(.vertical, 8)
        }
        .frame(width: width, alignment: .trailing)
        .frame(maxHeight: maxHeight)
        .background(glassSurface(themePickerPanelFill, radius: 12, prominence: .strong))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(activeTheme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(activeTheme.isNightTheme ? 0.30 : 0.10), radius: 10, y: 5)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func themeSection(
        title: String,
        themes: [PrayerVisualTheme],
        selectedID: String,
        select: @escaping (PrayerVisualTheme) -> Void
    ) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(activeTheme.secondaryText.opacity(0.74))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)

            ForEach(themes) { theme in
                Button {
                    select(theme)
                    WidgetRefreshCenter.refreshAll()
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isThemePickerPresented = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: selectedID == theme.rawValue ? "checkmark.circle.fill" : theme.symbol)
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 26, alignment: .leading)

                        Spacer(minLength: 16)

                        Text(theme.title)
                            .font(.headline.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.trailing)
                            .layoutPriority(1)
                            .environment(\.layoutDirection, .rightToLeft)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.layoutDirection, .leftToRight)
                    .foregroundStyle(selectedID == theme.rawValue ? activeTheme.accent : activeTheme.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(themeOptionBackground(isSelected: selectedID == theme.rawValue))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .multilineTextAlignment(.trailing)
    }

    private var widgetRefreshButton: some View {
        Button {
            WidgetRefreshCenter.refreshAll()
            WidgetRefreshCenter.refreshAgainSoon()
            withAnimation(.easeInOut(duration: 0.18)) {
                isThemePickerPresented = false
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 19, weight: .black))
                    .frame(width: 26, alignment: .leading)

                Spacer(minLength: 16)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("تحديث الويجت")
                        .font(.headline.weight(.black))
                        .lineLimit(1)

                    Text("بديل سريع عن إعادة تشغيل الهاتف")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(activeTheme.secondaryText.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.layoutDirection, .leftToRight)
            .foregroundStyle(activeTheme.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(themeOptionBackground(isSelected: false))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    private var themePickerScrim: Color {
        if activeTheme.isNightTheme {
            return Color.black.opacity(activeTheme.isGlassTheme ? 0.22 : 0.14)
        }

        return Color.white.opacity(activeTheme.isGlassTheme ? 0.34 : 0.18)
    }

    private var themePickerPanelFill: Color {
        if activeTheme.isGlassTheme {
            if activeTheme.isNightTheme {
                return Color(red: 0.06, green: 0.08, blue: 0.08).opacity(0.96)
            }

            return Color(red: 0.94, green: 0.98, blue: 0.98).opacity(0.96)
        }

        return activeTheme.panelBackground.opacity(0.98)
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

    private func themeOptionBackground(isSelected: Bool) -> Color {
        if isSelected {
            return activeTheme.activeRowBackground
        }

        if activeTheme.isGlassTheme {
            return activeTheme.rowBackground.opacity(activeTheme.isNightTheme ? 0.72 : 0.58)
        }

        return Color.clear
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

    private func selectTheme(_ theme: PrayerVisualTheme) {
        if theme.isNightTheme {
            selectedNightThemeID = theme.rawValue
            AppThemeStorage.defaults.set(theme.rawValue, forKey: AppThemeStorage.nightThemeKey)
        } else {
            selectedDayThemeID = theme.rawValue
            AppThemeStorage.defaults.set(theme.rawValue, forKey: AppThemeStorage.dayThemeKey)
        }

        AppThemeStorage.defaults.synchronize()
        WidgetRefreshCenter.refreshAll()
        WidgetRefreshCenter.refreshAgainSoon()
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
    case notifications
    case qibla
    case radio

    var id: String { rawValue }

    var title: String {
        switch self {
        case .schedule:
            return "مواقيت"
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
