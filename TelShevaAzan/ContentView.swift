import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppThemeStorage.nightThemeKey, store: AppThemeStorage.defaults) private var selectedNightThemeID = PrayerVisualTheme.defaultNight.rawValue
    @AppStorage(AppThemeStorage.dayThemeKey, store: AppThemeStorage.defaults) private var selectedDayThemeID = PrayerVisualTheme.defaultDay.rawValue
    @AppStorage("welcomeActivationPromptCompleted") private var welcomeActivationPromptCompleted = false
    @AppStorage(
        IqamaPreviewStorage.expirationKey,
        store: IqamaPreviewStorage.defaults
    ) private var iqamaPreviewExpiration: Double = 0
    @State private var now = Date()
    @State private var selectedDateKey = PrayerEngine.automaticScheduleDateKey()
    @State private var followsToday = true
    @State private var selectedTab: HomeDockItem = .schedule
    @State private var showWelcomeActivationPrompt = false
    @State private var selectedPrayerDetails: PrayerTime?
    @State private var showLocationPicker = false
    @Namespace private var dockSelectionNamespace
    @StateObject private var notifications = PrayerNotificationManager.shared
    @StateObject private var prayerLocation = PrayerLocationManager()

    private static let nabawiDayImage = Self.loadNabawiImage(named: "nabawi-day")
    private static let nabawiNightImage = Self.loadNabawiImage(named: "nabawi-night")

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let visualRefreshKey = "v0_6_48_khatmah_theme_polish"

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720
            let sectionSpacing: CGFloat = compactHeight ? 5 : 6
            let rowSpacing: CGFloat = compactHeight ? 4 : 5
            let dockBottomPadding = max(proxy.safeAreaInsets.bottom * 0.22, CGFloat(6))
            let dockReservedHeight = CGFloat(60) + dockBottomPadding + (compactHeight ? 6 : 8)
            let rowHeight = min(CGFloat(50), max(CGFloat(43), (proxy.size.height - dockReservedHeight - (compactHeight ? 252 : 292)) / 6))

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
                        AdhkarView(
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

                bottomDock
                    .padding(.horizontal, 10)
                    .padding(.bottom, dockBottomPadding)
                    .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                    .zIndex(6)

                if showWelcomeActivationPrompt {
                    welcomeActivationOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        .zIndex(20)
                }
            }
        }
        .onReceive(timer) { value in
            if selectedTab == .schedule {
                updateScheduleClock(value)
            }
        }
        .onChange(of: selectedNightThemeID) { _ in
            WidgetRefreshCenter.refreshAll(force: true)
        }
        .onChange(of: selectedDayThemeID) { _ in
            WidgetRefreshCenter.refreshAll(force: true)
        }
        .onChange(of: prayerLocation.revision) { _ in
            refreshAfterLocationChange()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                prayerLocation.startAutomaticIfNeeded()
                refreshPrayerCalendarIfNeeded()
                notifications.refreshIfEnabled()
                WidgetRefreshCenter.refreshAll()
            }
        }
        .onAppear {
            applyVisualRefreshThemeOnce()
            prayerLocation.startAutomaticIfNeeded()
            refreshPrayerCalendarIfNeeded()
            notifications.refreshIfEnabled()
            WidgetRefreshCenter.refreshAll()
            presentWelcomeActivationPromptIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: PrayerNotificationManager.openSettingsNotification)) { _ in
            selectedTab = .notifications
        }
        .onReceive(NotificationCenter.default.publisher(for: PrayerNotificationManager.openScheduleNotification)) { _ in
            followsToday = true
            updateScheduleClock(Date())
            selectedTab = .schedule
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .sheet(item: $selectedPrayerDetails) { prayer in
            PrayerDetailsSheet(
                prayer: prayer,
                now: now,
                theme: activeTheme,
                iqamaTime: iqamaTime(for: prayer),
                iqamaLocationName: prayerLocation.city.name,
                statusText: prayerDetailStatus(for: prayer)
            )
            .presentationDetents([.height(360), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showLocationPicker) {
            PrayerLocationPickerView(location: prayerLocation, theme: activeTheme)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var welcomeActivationOverlay: some View {
        ZStack {
            Color.black
                .opacity(activeTheme.isNightTheme ? 0.62 : 0.38)
                .ignoresSafeArea()

            VStack(alignment: .trailing, spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("خلّي الأذان حاضر معك")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(activeTheme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.76)

                        Text("فعّل الإشعارات والأذكار لتظهر لك الصلاة القادمة في وقتها.")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(activeTheme.secondaryText.opacity(0.90))
                            .lineLimit(2)
                            .minimumScaleFactor(0.74)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(activeTheme.accent)
                        .frame(width: 48, height: 48)
                        .background(Circle().fill(activeTheme.countdownBackground.opacity(activeTheme.isNightTheme ? 0.92 : 0.16)))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(activeTheme.isNightTheme ? 0.18 : 0.74), lineWidth: 1)
                        )
                }
                .environment(\.layoutDirection, .leftToRight)

                VStack(spacing: 9) {
                    welcomeFeatureRow(symbol: "speaker.wave.2.fill", title: "تنبيهات الأذان", detail: "لكل الصلوات المختارة")
                    welcomeFeatureRow(symbol: "sparkles", title: "الأذكار والنفحات", detail: "تذكير هادئ بعد الصلاة وبين الأوقات")
                }

                HStack(spacing: 10) {
                    Button {
                        completeWelcomeActivationPrompt(activate: false)
                    } label: {
                        Text("لاحقًا")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(activeTheme.secondaryText)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(activeTheme.controlBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(activeTheme.controlBorder, lineWidth: 1)
                    )

                    Button {
                        completeWelcomeActivationPrompt(activate: true)
                    } label: {
                        HStack(spacing: 8) {
                            Text("تفعيل الآن")
                            Image(systemName: "checkmark.circle.fill")
                        }
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [activeTheme.accent, activeTheme.accent.opacity(0.72)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: activeTheme.accent.opacity(0.28), radius: 10, y: 5)
                }
                .environment(\.layoutDirection, .leftToRight)
            }
            .padding(18)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(welcomeActivationCardBackground)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(activeTheme.isNightTheme ? 0.18 : 0.76), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(activeTheme.isNightTheme ? 0.32 : 0.16), radius: 22, y: 12)
            .padding(.horizontal, 20)
            .environment(\.layoutDirection, .rightToLeft)
            .multilineTextAlignment(.trailing)
        }
    }

    private var welcomeActivationCardBackground: Color {
        if activeTheme.isNightTheme {
            return Color(red: 0.03, green: 0.06, blue: 0.07).opacity(0.96)
        }

        return Color(red: 0.88, green: 0.94, blue: 1.00).opacity(0.97)
    }

    private func welcomeFeatureRow(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(activeTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(detail)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(activeTheme.secondaryText.opacity(0.84))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Image(systemName: symbol)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(activeTheme.accent)
                .frame(width: 34, height: 34)
                .background(Circle().fill(activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.14 : 0.10)))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .environment(\.layoutDirection, .leftToRight)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(activeTheme.controlBackground.opacity(activeTheme.isNightTheme ? 0.82 : 0.62))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(activeTheme.controlBorder.opacity(0.9), lineWidth: 1)
        )
    }

    private func presentWelcomeActivationPromptIfNeeded() {
        guard !welcomeActivationPromptCompleted, !showWelcomeActivationPrompt else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard !welcomeActivationPromptCompleted, !showWelcomeActivationPrompt else { return }
            withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                showWelcomeActivationPrompt = true
            }
        }
    }

    private func completeWelcomeActivationPrompt(activate: Bool) {
        welcomeActivationPromptCompleted = true
        withAnimation(.easeInOut(duration: 0.20)) {
            showWelcomeActivationPrompt = false
        }

        if activate {
            notifications.enableWelcomeDefaults()
            WidgetRefreshCenter.refreshAll()
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "telshevaazan" else { return }

        let destination = url.host ?? url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let targetTab: HomeDockItem

        switch destination {
        case "schedule":
            followsToday = true
            updateScheduleClock(Date())
            targetTab = .schedule
        case "qibla":
            targetTab = .qibla
        default:
            return
        }

        if selectedTab != targetTab {
            selectedTab = targetTab
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
        let activeIqama = followsToday ? activeIqamaEvent(at: now) : nil

        return prayerScheduleContent(
            schedule: schedule,
            next: next,
            previous: previous,
            activeIqama: activeIqama,
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
        activeIqama: IqamaEvent?,
        compactHeight: Bool,
        sectionSpacing: CGFloat,
        rowSpacing: CGFloat,
        rowHeight: CGFloat,
        dockReservedHeight: CGFloat,
        size: CGSize
    ) -> some View {
        VStack(alignment: .trailing, spacing: sectionSpacing) {
            header

            nextPrayerPanel(next: next, previous: previous, activeIqama: activeIqama, compact: compactHeight)

            smartPrayerStatusStrip(next: next, activeIqama: activeIqama, compact: compactHeight)

            prayerRows(
                schedule: schedule,
                next: next,
                previous: previous,
                activeIqama: activeIqama,
                rowSpacing: rowSpacing,
                rowHeight: rowHeight
            )
        }
        .padding(.horizontal, 18)
        .padding(.top, compactHeight ? 8 : 10)
        .padding(.bottom, dockReservedHeight)
        .frame(width: size.width, height: size.height, alignment: .topTrailing)
        .foregroundStyle(activeTheme.primaryText)
        .environment(\.layoutDirection, .leftToRight)
        .multilineTextAlignment(.trailing)
    }

    private var quranVerse: some View {
        Text("فَأَقِيمُوا الصَّلَاةَ إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا")
            .font(.custom("NotoNaskhArabic-Regular", size: 35))
            .foregroundStyle(activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.94 : 0.88))
            .lineLimit(1)
            .minimumScaleFactor(0.48)
            .allowsTightening(true)
            .multilineTextAlignment(.trailing)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(
                Capsule(style: .continuous)
                    .fill(activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.14 : 0.085))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.24 : 0.16), lineWidth: 1)
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(glassSurface(activeTheme.panelBackground.opacity(activeTheme.isNightTheme ? 0.66 : 0.72), radius: 14, prominence: .quiet))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(activeTheme.rowBorder.opacity(activeTheme.isNightTheme ? 0.42 : 0.56), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .environment(\.layoutDirection, .leftToRight)
    }

    private var header: some View {
        let selectedDateSummary = "\(PrayerEngine.longDateLabel(for: selectedDateKey)) · \(PrayerEngine.hijriDateLabel(for: selectedDateKey))"
        let dateSummary = isShowingTomorrowSchedule ? "مواقيت الغد · \(selectedDateSummary)" : selectedDateSummary
        let timeSummary = Self.timeWithSecondsFormatter.string(from: now)

        return VStack(alignment: .center, spacing: 5) {
            Text(timeSummary)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.98 : 0.94))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(dateSummary)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.96 : 0.92))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity, alignment: .center)

            ZStack {
                Capsule(style: .continuous)
                    .fill(activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.10 : 0.08))
                    .frame(width: 74, height: 3)

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                activeTheme.accent.opacity(0.22),
                                activeTheme.accent.opacity(0.82),
                                activeTheme.accent.opacity(0.22)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 42, height: 3)
            }
            .padding(.top, 1)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            ZStack {
                glassSurface(activeTheme.panelBackground.opacity(activeTheme.isNightTheme ? 0.36 : 0.58), radius: 20, prominence: .quiet)

                LinearGradient(
                    colors: [
                        Color.white.opacity(activeTheme.isNightTheme ? 0.03 : 0.22),
                        activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.05 : 0.035),
                        Color.clear
                    ],
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(activeTheme.isNightTheme ? 0.10 : 0.70),
                            activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.18 : 0.16),
                            activeTheme.rowBorder.opacity(activeTheme.isNightTheme ? 0.36 : 0.42)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.08 : 0.06), radius: 12, y: 5)
        .padding(.horizontal, 32)
    }

    private static let timeWithSecondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    private func prayerRows(
        schedule: DaySchedule,
        next: PrayerTime?,
        previous: PrayerTime?,
        activeIqama: IqamaEvent?,
        rowSpacing: CGFloat,
        rowHeight: CGFloat
    ) -> some View {
        VStack(spacing: rowSpacing) {
            ForEach(schedule.displayTimes) { item in
                prayerRow(
                    item,
                    next: next,
                    previous: previous,
                    activeIqama: activeIqama,
                    rowHeight: rowHeight
                )
            }
        }
        .padding(6)
        .background(glassSurface(activeTheme.panelBackground.opacity(activeTheme.isNightTheme ? 0.54 : 0.66), radius: 14, prominence: .quiet))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            activeTheme.rowBorder.opacity(activeTheme.isNightTheme ? 0.72 : 0.80),
                            activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.28 : 0.22),
                            activeTheme.rowBorder.opacity(activeTheme.isNightTheme ? 0.40 : 0.52)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    ),
                    lineWidth: 1.1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.10 : 0.08), radius: 12, y: 5)
    }

    private var bottomDock: some View {
        let dockWidth: CGFloat = 286
        let slotWidth = dockWidth / CGFloat(dockItems.count)

        return ZStack(alignment: .bottom) {
            dockLiquidGlassBase
                .frame(width: dockWidth, height: 40)

            HStack(alignment: .bottom, spacing: 0) {
                ForEach(dockItems) { item in
                    dockSlotButton(item, slotWidth: slotWidth)
                }
            }
            .frame(width: dockWidth, height: 60, alignment: .bottom)
        }
        .frame(width: dockWidth)
        .frame(height: 60, alignment: .bottom)
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
                    selectedDockBubble(width: 72, height: 47)
                        .matchedGeometryEffect(id: "dockSelection", in: dockSelectionNamespace)

                    VStack(spacing: 3) {
                        Image(systemName: dockSymbol(for: item))
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(activeTheme.accent)
                            .frame(width: 32, height: 32)
                            .background(selectedDockIconFill)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(activeTheme.isNightTheme ? 0.38 : 0.82), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(activeTheme.isNightTheme ? 0.16 : 0.07), radius: 4, y: 1)
                            .offset(y: -5)

                        Text(item.title)
                            .font(.system(size: 9.5, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.66)
                            .offset(y: -3)
                    }
                    .frame(width: 72, height: 47)
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: dockSymbol(for: item))
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(activeTheme.secondaryText.opacity(0.86))
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 28, height: 20)

                        Text(item.title)
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(activeTheme.secondaryText.opacity(0.88))
                            .lineLimit(1)
                            .minimumScaleFactor(0.58)
                    }
                    .frame(width: slotWidth, height: 36)
                }
            }
            .frame(width: slotWidth, height: selected ? 53 : 39, alignment: .bottom)
            .offset(y: selected ? -5 : 0)
            .contentShape(Rectangle())
        }
        .buttonStyle(DockButtonPressStyle())
        .accessibilityLabel(item.title)
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
        Group {
            if activeTheme.usesNativeMaterialGlass {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(activeTheme.isNightTheme ? Material.thin : Material.ultraThin)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(dockGlassTint.opacity(activeTheme.isNightTheme ? 0.72 : 0.46))
                    )
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(activeTheme.isNightTheme ? 0.20 : 0.72),
                                Color.white.opacity(activeTheme.isNightTheme ? 0.05 : 0.20),
                                activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.08 : 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(activeTheme.isNightTheme ? 0.42 : 0.96),
                                        activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.20 : 0.12),
                                        Color.white.opacity(activeTheme.isNightTheme ? 0.12 : 0.52)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.9
                            )
                    )
            } else if activeTheme.isGlassTheme {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(dockGlassTint)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(activeTheme.isNightTheme ? 0.10 : 0.32),
                                Color.white.opacity(activeTheme.isNightTheme ? 0.03 : 0.12),
                                activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.035 : 0.045)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(activeTheme.isNightTheme ? 0.16 : 0.44), lineWidth: 0.8)
                    )
            } else {
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
        }
        .compositingGroup()
    }

    private var dockGlassTint: Color {
        if activeTheme.isNightTheme {
            return Color.black.opacity(activeTheme.isGlassTheme ? 0.38 : 0.32)
        }

        return Color.white.opacity(activeTheme.isGlassTheme ? 0.72 : 0.58)
    }

    private var selectedDockItem: HomeDockItem? {
        selectedTab
    }

    private func handleDockTap(_ item: HomeDockItem) {
        guard selectedTab != item else {
            return
        }

        if item == .schedule {
            updateScheduleClock(Date())
        }

        selectedTab = item
    }

    private func updateScheduleClock(_ value: Date) {
        now = value
        if followsToday {
            selectedDateKey = PrayerEngine.automaticScheduleDateKey(for: value)
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
        case .adhkar:
            return "sparkles"
        case .notifications:
            return notifications.isEnabled ? "bell.badge.fill" : "bell.fill"
        }
    }

    private func dockRotation(for item: HomeDockItem) -> Double {
        0
    }

    @ViewBuilder
    private func nextPrayerPanel(
        next: PrayerTime?,
        previous: PrayerTime?,
        activeIqama: IqamaEvent?,
        compact: Bool
    ) -> some View {
        if usesNabawiPrayerCard {
            nabawiNextPrayerPanel(
                next: next,
                previous: previous,
                activeIqama: activeIqama,
                compact: compact
            )
        } else {
            defaultNextPrayerPanel(
                next: next,
                previous: previous,
                activeIqama: activeIqama,
                compact: compact
            )
        }
    }

    private func defaultNextPrayerPanel(
        next: PrayerTime?,
        previous: PrayerTime?,
        activeIqama: IqamaEvent?,
        compact: Bool
    ) -> some View {
        let presentation = prayerPanelPresentation(next: next, activeIqama: activeIqama)

        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                prayerLocationChip(compact: compact, onImage: false)

                VStack(alignment: .leading, spacing: 2) {
                    Text(presentation.countdownTitle)
                        .font(.caption2.weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    Text(countdownText(until: presentation.countdownTarget))
                        .font(.subheadline.monospacedDigit().weight(.bold))
                        .lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(activeTheme.countdownBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text(presentation.title)
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundStyle(activeTheme.accent)
                    .lineLimit(1)

                Text(presentation.prayer?.title ?? "--")
                    .font(.system(size: compact ? 29 : 32, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(presentation.time)
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

    private func prayerPanelPresentation(
        next: PrayerTime?,
        activeIqama: IqamaEvent?
    ) -> (
        prayer: PrayerTime?,
        time: String,
        title: String,
        countdownTitle: String,
        countdownTarget: Date?
    ) {
        guard let activeIqama else {
            return (
                prayer: next,
                time: next?.time ?? "--:--",
                title: "الصلاة القادمة",
                countdownTitle: "باقي على الصلاة",
                countdownTarget: next?.date
            )
        }

        return (
            prayer: activeIqama.prayer,
            time: timeText(for: activeIqama.date),
            title: "الإقامة القادمة",
            countdownTitle: "متبقي للإقامة",
            countdownTarget: activeIqama.date
        )
    }

    private func smartPrayerStatusStrip(
        next: PrayerTime?,
        activeIqama: IqamaEvent?,
        compact: Bool
    ) -> some View {
        let presentation = prayerPanelPresentation(next: next, activeIqama: activeIqama)
        let prayerTitle = presentation.prayer?.title ?? "الصلاة"
        let statusTitle = activeIqama == nil
            ? "متبقي لأذان \(prayerTitle)"
            : "متبقي لإقامة \(prayerTitle)"
        let statusDetail = activeIqama == nil
            ? "\(IqamaSchedule.telSheva.locationName) · الأذان \(presentation.time)"
            : "مسجد \(IqamaSchedule.telSheva.locationName) · الإقامة \(presentation.time)"

        return HStack(spacing: compact ? 8 : 10) {
            Text(countdownText(until: presentation.countdownTarget))
                .font(.system(size: compact ? 13 : 15, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(activeTheme.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text(statusTitle)
                    .font(.system(size: compact ? 11 : 12, weight: .black, design: .rounded))
                    .foregroundStyle(activeTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(statusDetail)
                    .font(.system(size: compact ? 8.5 : 9.5, weight: .bold, design: .rounded))
                    .foregroundStyle(activeTheme.secondaryText.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Image(systemName: activeIqama == nil ? "clock.fill" : "person.2.fill")
                .font(.system(size: compact ? 13 : 14, weight: .black))
                .foregroundStyle(activeTheme.accent)
                .symbolRenderingMode(.hierarchical)
                .frame(width: compact ? 22 : 24, height: compact ? 22 : 24)
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, compact ? 11 : 13)
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 38 : 42)
        .background(
            glassSurface(
                activeTheme.panelBackground.opacity(activeTheme.isNightTheme ? 0.72 : 0.78),
                radius: 12,
                prominence: .quiet
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.28 : 0.22), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(statusTitle)، \(countdownText(until: presentation.countdownTarget))")
    }

    private func nabawiNextPrayerPanel(
        next: PrayerTime?,
        previous: PrayerTime?,
        activeIqama: IqamaEvent?,
        compact: Bool
    ) -> some View {
        let cornerRadius: CGFloat = compact ? 18 : 20
        let cardHeight: CGFloat = compact ? 180 : 202
        let isNightCard = activeTheme.isNightTheme
        let presentation = prayerPanelPresentation(next: next, activeIqama: activeIqama)

        return ZStack {
            nabawiCardBackground(height: cardHeight, isNight: isNightCard)

            VStack(alignment: .trailing, spacing: compact ? 5 : 6) {
                HStack(alignment: .top, spacing: 0) {
                    prayerLocationChip(compact: compact, onImage: true)
                    .padding(.top, compact ? 6 : 8)

                    Spacer(minLength: compact ? 12 : 16)

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(presentation.title)
                            .font(.system(size: compact ? 10 : 10.5, weight: .black, design: .rounded))
                            .foregroundStyle(activeTheme.accent)
                            .lineLimit(1)

                        Text(presentation.prayer?.title ?? "--")
                            .font(.system(size: compact ? 22 : 26, weight: .black, design: .rounded))
                            .foregroundStyle(nabawiPrimaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text(presentation.time)
                            .font(.system(size: compact ? 34 : 40, weight: .black, design: .rounded))
                            .foregroundStyle(activeTheme.accent)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .frame(maxWidth: compact ? 180 : 210, alignment: .trailing)
                }

                Spacer(minLength: compact ? 1 : 2)
            }
            .padding(.horizontal, compact ? 13 : 14)
            .padding(.top, compact ? 9 : 10)
            .padding(.bottom, compact ? 8 : 9)
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(nabawiCardBorder, lineWidth: 1)
        )
        .shadow(color: .black.opacity(isNightCard ? 0.16 : 0.06), radius: 8, y: 4)
    }

    private func prayerLocationChip(compact: Bool, onImage: Bool) -> some View {
        Button {
            showLocationPicker = true
        } label: {
            HStack(spacing: compact ? 5 : 6) {
                Circle()
                    .fill(locationIndicatorColor)
                    .frame(width: compact ? 7 : 8, height: compact ? 7 : 8)

                Text(prayerLocation.city.name)
                    .font(.system(size: compact ? 10.5 : 11.5, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Image(systemName: "location.fill")
                    .font(.system(size: compact ? 10 : 11, weight: .black))
            }
            .foregroundStyle(onImage ? nabawiPrimaryText : activeTheme.primaryText)
            .padding(.horizontal, compact ? 9 : 10)
            .frame(height: compact ? 30 : 34)
            .background(
                RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous)
                    .fill(onImage
                          ? (activeTheme.isNightTheme ? Color.black.opacity(0.52) : Color.white.opacity(0.80))
                          : activeTheme.palette.controlBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous)
                    .stroke(onImage ? Color.white.opacity(activeTheme.isNightTheme ? 0.18 : 0.65) : activeTheme.palette.controlBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("المنطقة الحالية \(prayerLocation.city.name)")
        .accessibilityHint("اضغط لتغيير المنطقة أو استخدام موقع الهاتف")
    }

    private var locationIndicatorColor: Color {
        switch prayerLocation.status {
        case .connected:
            return Color(red: 0.16, green: 0.80, blue: 0.48)
        case .resolving:
            return .orange
        case .manual:
            return activeTheme.accent
        case .permissionRequired, .unavailable:
            return activeTheme.mutedText.opacity(0.72)
        }
    }
    private func rtlPrayerProgressBar(progress: Double) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .trailing) {
                Capsule()
                    .fill(nabawiProgressTrack)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.70 : 0.64),
                                activeTheme.accent.opacity(0.92)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(progress))
            }
        }
        .clipShape(Capsule())
    }

    private var dateControls: some View {
        HStack(spacing: 8) {
            datePickerButton

            Button("اليوم التالي") {
                moveDay(1)
            }
            .buttonStyle(CompactButtonStyle(theme: activeTheme))
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: 1))

            Button("الآن") {
                selectedDateKey = PrayerEngine.automaticScheduleDateKey(for: now)
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

    private func prayerRow(
        _ item: PrayerTime,
        next: PrayerTime?,
        previous: PrayerTime?,
        activeIqama: IqamaEvent?,
        rowHeight: CGFloat
    ) -> some View {
        let isIqamaActive = isActiveIqamaRow(item, activeIqama: activeIqama)
        let isActive = isIqamaActive || (activeIqama == nil && item.key == next?.key)
        let isPrevious = !isIqamaActive && isPreviousPrayerRow(item, previous: previous, next: next)
        let effectiveRowHeight = max(rowHeight, (isActive || isPrevious) ? 49 : 45)

        return Button {
            selectedPrayerDetails = item
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.time)
                        .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(isActive ? activeTheme.accent : activeTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    if let iqamaTime = iqamaTime(for: item) {
                        Text("الإقامة \(iqamaTime)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(activeTheme.secondaryText.opacity(isActive ? 0.92 : 0.68))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(isActive ? activeTheme.accent : activeTheme.secondaryText.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)

                    if isPrevious {
                        Text(elapsedPrayerText(for: previous))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(activeTheme.secondaryText.opacity(0.82))
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                    }
                }

                Image(systemName: prayerSymbol(for: item.key))
                    .font(.system(size: isActive ? 18 : 17, weight: .bold, design: .rounded))
                    .foregroundStyle(isActive ? activeTheme.accent : activeTheme.secondaryText.opacity(0.62))
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 24, height: 24)

                Image(systemName: "chevron.left")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(activeTheme.secondaryText.opacity(0.38))
                    .frame(width: 10)
            }
            .padding(.horizontal, 9)
            .frame(height: effectiveRowHeight)
            .background(glassSurface(rowBackground(isActive: isActive), radius: 8, prominence: isActive ? .regular : .quiet))
            .overlay(alignment: .trailing) {
                if isActive {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(activeTheme.accent)
                        .frame(width: 4)
                        .padding(.vertical, 11)
                        .padding(.trailing, 1)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(rowBorder(isActive: isActive))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: isActive ? activeTheme.accent.opacity(activeTheme.isNightTheme ? 0.18 : 0.14) : .clear, radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var isNight: Bool {
        colorScheme == .dark
    }

    private var activeTheme: PrayerVisualTheme {
        PrayerVisualTheme.selected(isNight: isNight, nightID: selectedNightThemeID, dayID: selectedDayThemeID)
    }

    private var isShowingTomorrowSchedule: Bool {
        followsToday && selectedDateKey != PrayerEngine.defaultDateKey(for: now)
    }

    private var selectedDateBinding: Binding<Date> {
        Binding<Date>(
            get: {
                PrayerEngine.date(from: selectedDateKey, time: "12:00") ?? now
            },
            set: { date in
                let dateKey = PrayerEngine.defaultDateKey(for: date)
                selectedDateKey = dateKey
                followsToday = dateKey == PrayerEngine.automaticScheduleDateKey(for: now)
            }
        )
    }

    private var datePickerRange: ClosedRange<Date> {
        PrayerEngine.supportedDateRange(around: now)
    }

    private func prayerSymbol(for key: PrayerKey) -> String {
        switch key {
        case .fajr:
            return "sunrise.fill"
        case .sunrise:
            return "sun.max"
        case .dhuhr:
            return "sun.max.fill"
        case .asr:
            return "cloud.sun.fill"
        case .maghrib:
            return "sunset.fill"
        case .isha:
            return "moon.stars.fill"
        }
    }

    private func rowBackground(isActive: Bool) -> Color {
        isActive ? activeTheme.activeRowBackground : activeTheme.rowBackground
    }

    private func rowBorder(isActive: Bool) -> Color {
        isActive ? activeTheme.activeRowBorder : activeTheme.rowBorder
    }

    private var usesNabawiPrayerCard: Bool {
        activeTheme == .dayAppleGlass || activeTheme == .dayOasisGlass || activeTheme == .nightAppleGlass || activeTheme == .nightSakinaGlass || activeTheme == .daySalatiGlass || activeTheme == .nightSalatiGlass || activeTheme == .dayCrystalGlass || activeTheme == .nightCrystalGlass
    }

    private var nabawiPrimaryText: Color {
        activeTheme.isNightTheme ? .white : Color(red: 0.02, green: 0.06, blue: 0.12)
    }

    private var nabawiSecondaryText: Color {
        activeTheme.isNightTheme ? Color.white.opacity(0.82) : Color(red: 0.25, green: 0.30, blue: 0.39).opacity(0.88)
    }

    private var nabawiCardBorder: Color {
        activeTheme.isNightTheme ? Color.white.opacity(0.14) : Color.white.opacity(0.72)
    }

    private var nabawiProgressTrack: Color {
        activeTheme.isNightTheme ? Color.white.opacity(0.20) : Color(red: 0.70, green: 0.82, blue: 0.94).opacity(0.72)
    }

    @ViewBuilder
    private func nabawiCardBackground(height: CGFloat, isNight: Bool) -> some View {
        if isNight {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Color(red: 0.01, green: 0.03, blue: 0.05)

                    nabawiImage(isNight: true)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: height)
                        .scaleEffect(1.04, anchor: .bottomLeading)
                        .brightness(0.22)
                        .saturation(1.20)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.00),
                                    Color.black.opacity(0.05),
                                    Color.black.opacity(0.34)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.00),
                            Color.black.opacity(0.08),
                            Color.black.opacity(0.42)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )

                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.00),
                            Color.black.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            }
            .frame(height: height)
        } else {
            nabawiImage(isNight: false)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .brightness(0.05)
                .saturation(1.08)
                .overlay(nabawiCardOverlay(isNight: false))
        }
    }

    private func nabawiImage(isNight: Bool) -> Image {
        let image = isNight ? Self.nabawiNightImage : Self.nabawiDayImage
        if let image = image {
            return Image(uiImage: image)
        }

        return Image(systemName: "photo")
    }

    private static func loadNabawiImage(named name: String) -> UIImage? {
        let bundle = Bundle.main
        let urls = [
            bundle.url(forResource: name, withExtension: "jpg"),
            bundle.url(forResource: name, withExtension: "jpg", subdirectory: "Nabawi"),
            bundle.url(forResource: name, withExtension: "jpg", subdirectory: "Resources/Nabawi")
        ].compactMap { $0 }

        guard let url = urls.first else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    @ViewBuilder
    private func nabawiCardOverlay(isNight: Bool) -> some View {
        if isNight {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.00),
                        Color.black.opacity(0.22),
                        Color.black.opacity(0.72)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.00),
                        Color.black.opacity(0.34)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.12),
                        Color.white.opacity(0.48),
                        Color.white.opacity(0.78)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.04),
                        Color(red: 0.90, green: 0.96, blue: 1.0).opacity(0.42)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private func prayerProgress(previous: PrayerTime?, next: PrayerTime?) -> Double {
        guard let previous, let next else { return 0 }

        let total = next.date.timeIntervalSince(previous.date)
        guard total > 0 else { return 0 }

        let elapsed = now.timeIntervalSince(previous.date)
        return min(max(elapsed / total, 0), 1)
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
        countdownText(until: next?.date)
    }

    private func countdownText(until date: Date?) -> String {
        guard let date else { return "--:--:--" }
        let seconds = PrayerEngine.remainingSeconds(until: date, now: now)
        guard seconds > 0 else { return "--:--:--" }

        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    private func elapsedPrayerText(for previous: PrayerTime?) -> String {
        guard let previous else { return "مضى على الصلاة --:--:--" }
        return "مضى على \(previous.title) \(elapsedText(since: previous.date))"
    }

    private func iqamaTime(for prayer: PrayerTime) -> String? {
        guard let date = IqamaSchedule.telSheva.iqamaDate(for: prayer) else { return nil }
        return timeText(for: date)
    }

    private func prayerDetailStatus(for prayer: PrayerTime) -> String {
        let seconds = prayer.date.timeIntervalSince(now)

        if seconds > 0 {
            return "متبقي \(remainingPrayerTarget(for: prayer.key)) \(countdownText(for: prayer))"
        }

        return "مضى على \(prayer.title) \(elapsedText(since: prayer.date))"
    }

    private func timeText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = PrayerEngine.timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func elapsedText(since date: Date) -> String {
        let seconds = PrayerEngine.elapsedSeconds(since: date, now: now)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    private func isPreviousPrayerRow(_ item: PrayerTime, previous: PrayerTime?, next: PrayerTime?) -> Bool {
        guard let previous,
              item.key == previous.key,
              item.key != next?.key else {
            return false
        }

        return abs(item.date.timeIntervalSince(previous.date)) < 60
    }

    private func isActiveIqamaRow(_ item: PrayerTime, activeIqama: IqamaEvent?) -> Bool {
        guard let activeIqama,
              item.key == activeIqama.prayer.key else {
            return false
        }

        return abs(item.date.timeIntervalSince(activeIqama.prayer.date)) < 60
    }

    private func activeIqamaEvent(at date: Date) -> IqamaEvent? {
        if let realEvent = IqamaSchedule.telSheva.activeEvent(at: date) {
            return realEvent
        }

        guard iqamaPreviewExpiration > date.timeIntervalSince1970 else { return nil }
        return IqamaPreviewStorage.activeEvent(at: date, dateKey: selectedDateKey)
    }

    private func remainingPrayerTarget(for key: PrayerKey) -> String {
        switch key {
        case .fajr:
            return "للفجر"
        case .sunrise:
            return "للشروق"
        case .dhuhr:
            return "للظهر"
        case .asr:
            return "للعصر"
        case .maghrib:
            return "للمغرب"
        case .isha:
            return "للعشاء"
        }
    }

    private func moveDay(_ offset: Int) {
        guard let nextKey = PrayerEngine.dateKey(from: selectedDateKey, offset: offset) else { return }
        selectedDateKey = nextKey
        followsToday = false
    }

    private func applyVisualRefreshThemeOnce() {
        guard !AppThemeStorage.defaults.bool(forKey: visualRefreshKey) else { return }

        selectedNightThemeID = PrayerVisualTheme.nightSalatiGlass.rawValue
        selectedDayThemeID = PrayerVisualTheme.daySalatiGlass.rawValue
        AppThemeStorage.defaults.set(selectedNightThemeID, forKey: AppThemeStorage.nightThemeKey)
        AppThemeStorage.defaults.set(selectedDayThemeID, forKey: AppThemeStorage.dayThemeKey)
        AppThemeStorage.defaults.set(true, forKey: visualRefreshKey)
        AppThemeStorage.defaults.synchronize()
        WidgetRefreshCenter.refreshAll(force: true)
    }

    private func refreshAfterLocationChange() {
        let refreshDate = Date()
        now = refreshDate
        if followsToday {
            selectedDateKey = PrayerEngine.automaticScheduleDateKey(for: refreshDate)
        }
        notifications.refreshIfEnabled()
        WidgetRefreshCenter.refreshAll(force: true)
    }

    private func refreshPrayerCalendarIfNeeded() {
        PalestinePrayerCalendar.refreshRemoteIfNeeded { didUpdate in
            guard didUpdate else { return }
            now = Date()
            notifications.refreshIfEnabled()
            WidgetRefreshCenter.refreshAll(force: true)
        }
    }
}

private struct PrayerDetailsSheet: View {
    let prayer: PrayerTime
    let now: Date
    let theme: PrayerVisualTheme
    let iqamaTime: String?
    let iqamaLocationName: String
    let statusText: String

    var body: some View {
        ZStack {
            ThemeBackdrop(theme: theme)

            VStack(alignment: .trailing, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: symbol)
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(theme.accent)
                        .frame(width: 54, height: 54)
                        .background(Circle().fill(theme.accent.opacity(theme.isNightTheme ? 0.14 : 0.10)))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(prayer.key == .sunrise ? "تفاصيل الشروق" : "تفاصيل الصلاة")
                            .font(.caption.weight(.black))
                            .foregroundStyle(theme.accent)

                        Text(prayer.key == .sunrise ? "وقت الشروق" : "صلاة \(prayer.title)")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(theme.primaryText)
                            .lineLimit(1)
                    }
                }

                HStack(spacing: 10) {
                    if let iqamaTime {
                        detailTile(title: "إقامة \(iqamaLocationName)", value: iqamaTime, highlighted: true)
                        detailTile(title: "الأذان", value: prayer.time, highlighted: false)
                    } else {
                        detailTile(title: "وقت الشروق", value: prayer.time, highlighted: true)
                    }
                }

                VStack(alignment: .trailing, spacing: 8) {
                    Text(statusText)
                        .font(.headline.weight(.black))
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text(detailMessage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.secondaryText.opacity(0.84))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(14)
                .background(surface(theme.rowBackground, radius: 16, prominence: .quiet))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.rowBorder)
                )

                Spacer(minLength: 0)
            }
            .padding(20)
        }
        .environment(\.layoutDirection, .leftToRight)
        .multilineTextAlignment(.trailing)
    }

    private func detailTile(title: String, value: String, highlighted: Bool) -> some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.secondaryText.opacity(0.78))

            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded).monospacedDigit())
                .foregroundStyle(highlighted ? theme.accent : theme.primaryText)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(surface(highlighted ? theme.activeRowBackground : theme.controlBackground, radius: 18, prominence: highlighted ? .regular : .quiet))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(highlighted ? theme.activeRowBorder : theme.controlBorder)
        )
    }

    private var detailMessage: String {
        if prayer.key == .sunrise {
            if prayer.date > now {
                return "هذا وقت شروق الشمس، ولا توجد له إقامة أو أذان صلاة."
            }

            return "مضى وقت شروق الشمس، ويمكنك متابعة موعد الصلاة القادمة من جدول المواقيت."
        }

        if prayer.date > now {
            return "تقدر تتابع الوقت من الواجهة وتراجع صف المواقيت لمعرفة الصلاة القادمة."
        }

        return "بعد الصلاة خذ لحظة للأذكار، وتقدر ترجع لصف المواقيت لمتابعة الصلاة القادمة."
    }

    private var symbol: String {
        switch prayer.key {
        case .fajr:
            return "sunrise.fill"
        case .sunrise:
            return "sun.max"
        case .dhuhr:
            return "sun.max.fill"
        case .asr:
            return "cloud.sun.fill"
        case .maghrib:
            return "sunset.fill"
        case .isha:
            return "moon.stars.fill"
        }
    }

    private func surface(_ base: Color, radius: CGFloat, prominence: GlassProminence) -> some View {
        ThemeGlassSurface(
            theme: theme,
            base: base,
            cornerRadius: radius,
            prominence: prominence
        )
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
