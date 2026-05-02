import SwiftUI
import WidgetKit

struct ContentView: View {
    @AppStorage("nightModeEnabled") private var nightModeEnabled = false
    @State private var now = Date()
    @State private var selectedDateKey = PrayerEngine.defaultDateKey()
    @State private var followsToday = true

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let schedule = PrayerEngine.schedule(for: selectedDateKey)
        let next = PrayerEngine.nextPrayer(for: selectedDateKey, now: now)

        ScrollView {
            VStack(alignment: .trailing, spacing: 16) {
                header

                nextPrayerPanel(next: next)

                dateControls

                VStack(spacing: 10) {
                    ForEach(schedule.displayTimes) { item in
                        prayerRow(item, activeKey: next?.key)
                    }
                }

                Text("النموذج الحالي يغطي مايو 2026. في التطبيق النهائي نضيف جدول السنة كاملًا.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 6)

                Text(AppInfo.displayVersion)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)

                widgetDiagnosticsPanel
            }
            .padding(18)
        }
        .background(background)
        .preferredColorScheme(nightModeEnabled ? .dark : .light)
        .onReceive(timer) { value in
            now = value
            if followsToday {
                selectedDateKey = PrayerEngine.defaultDateKey(for: value)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Button {
                    nightModeEnabled.toggle()
                } label: {
                    Label(nightModeEnabled ? "نهار" : "ليل", systemImage: nightModeEnabled ? "sun.max.fill" : "moon.stars.fill")
                }
                .buttonStyle(NightModeButtonStyle(isNight: nightModeEnabled))

                Spacer()

                Text("نموذج أولي \(AppInfo.displayVersion)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(accentColor)
            }

            Text("أذان تل السبع")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(PrayerEngine.longDateLabel(for: selectedDateKey))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var widgetDiagnosticsPanel: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack {
                Button {
                    WidgetCenter.shared.reloadAllTimelines()
                } label: {
                    Label("تحديث", systemImage: "arrow.clockwise")
                }
                .buttonStyle(CompactButtonStyle(isNight: nightModeEnabled))

                Spacer()

                Text("تشخيص الودجت")
                    .font(.caption.weight(.black))
                    .foregroundStyle(accentColor)
            }

            ForEach(widgetDiagnosticLines, id: \.self) { line in
                Text(line)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(12)
        .background(rowBackground(isActive: false))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(rowBorder(isActive: false))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var widgetDiagnosticLines: [String] {
        guard let pluginsURL = Bundle.main.builtInPlugInsURL else {
            return ["PlugIns: غير موجود"]
        }

        let pluginURLs = (try? FileManager.default.contentsOfDirectory(
            at: pluginsURL,
            includingPropertiesForKeys: nil
        ))?.filter { $0.pathExtension == "appex" } ?? []

        guard let widgetURL = pluginURLs.first(where: { $0.lastPathComponent.contains("Widget") }) ?? pluginURLs.first else {
            return ["PlugIns: 0", "Widget appex: غير موجود"]
        }

        let infoURL = widgetURL.appendingPathComponent("Info.plist")
        let info = NSDictionary(contentsOf: infoURL) as? [String: Any]
        let bundleID = info?["CFBundleIdentifier"] as? String ?? "--"
        let executable = info?["CFBundleExecutable"] as? String ?? "--"
        let extensionInfo = info?["NSExtension"] as? [String: Any]
        let point = extensionInfo?["NSExtensionPointIdentifier"] as? String ?? "--"
        let executableExists = FileManager.default.fileExists(atPath: widgetURL.appendingPathComponent(executable).path)

        return [
            "PlugIns: \(pluginURLs.count)",
            "Widget: \(widgetURL.lastPathComponent)",
            "ID: \(bundleID)",
            "Point: \(point)",
            "Exec: \(executableExists ? "OK" : "missing")"
        ]
    }

    private func nextPrayerPanel(next: PrayerTime?) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text("الصلاة القادمة")
                .font(.caption.weight(.bold))
                .foregroundStyle(accentColor)

            Text(next?.title ?? "--")
                .font(.system(size: 46, weight: .black, design: .rounded))

            Text(next?.time ?? "--:--")
                .font(.system(size: 58, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)

            Text(countdownText(for: next))
                .font(.title2.monospacedDigit().weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(countdownBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("القدس الدهري + دقيقتين لتل السبع + التوقيت الصيفي")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(18)
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(nightModeEnabled ? 0.28 : 0.08), radius: 18, y: 8)
    }

    private var dateControls: some View {
        HStack(spacing: 8) {
            Button("اليوم التالي") {
                moveDay(1)
            }
            .buttonStyle(CompactButtonStyle(isNight: nightModeEnabled))
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: 1))

            Button("اليوم") {
                selectedDateKey = PrayerEngine.defaultDateKey(for: now)
                followsToday = true
            }
            .buttonStyle(CompactButtonStyle(isNight: nightModeEnabled))

            Button("اليوم السابق") {
                moveDay(-1)
            }
            .buttonStyle(CompactButtonStyle(isNight: nightModeEnabled))
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: -1))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func prayerRow(_ item: PrayerTime, activeKey: PrayerKey?) -> some View {
        HStack {
            Text(item.time)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(item.key == activeKey ? accentColor : Color.primary)

            Spacer()

            Text(item.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(item.key == activeKey ? accentColor : Color.secondary)
        }
        .padding(14)
        .background(rowBackground(isActive: item.key == activeKey))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(rowBorder(isActive: item.key == activeKey))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var accentColor: Color {
        nightModeEnabled ? Color(red: 0.96, green: 0.78, blue: 0.38) : Color.teal
    }

    private var panelBackground: Color {
        nightModeEnabled ? Color(red: 0.07, green: 0.11, blue: 0.12).opacity(0.96) : Color.white.opacity(0.9)
    }

    private var countdownBackground: Color {
        nightModeEnabled ? Color(red: 0.45, green: 0.30, blue: 0.09) : Color(red: 0.04, green: 0.31, blue: 0.29)
    }

    private func rowBackground(isActive: Bool) -> Color {
        if nightModeEnabled {
            return isActive ? Color(red: 0.18, green: 0.15, blue: 0.08).opacity(0.92) : Color(red: 0.08, green: 0.13, blue: 0.14).opacity(0.92)
        }

        return isActive ? Color.teal.opacity(0.12) : Color.white.opacity(0.82)
    }

    private func rowBorder(isActive: Bool) -> Color {
        if nightModeEnabled {
            return isActive ? Color(red: 0.96, green: 0.78, blue: 0.38).opacity(0.55) : Color.white.opacity(0.09)
        }

        return isActive ? Color.teal.opacity(0.55) : Color.black.opacity(0.08)
    }

    private var background: some View {
        LinearGradient(
            colors: nightModeEnabled ? [
                Color(red: 0.02, green: 0.08, blue: 0.10),
                Color(red: 0.08, green: 0.16, blue: 0.14)
            ] : [
                Color(red: 0.95, green: 0.93, blue: 0.88),
                Color(red: 0.90, green: 0.96, blue: 0.94)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .ignoresSafeArea()
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

    private func moveDay(_ offset: Int) {
        guard let nextKey = PrayerEngine.dateKey(from: selectedDateKey, offset: offset) else { return }
        selectedDateKey = nextKey
        followsToday = false
    }
}

private struct CompactButtonStyle: ButtonStyle {
    let isNight: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isNight ? Color.white.opacity(configuration.isPressed ? 0.10 : 0.16) : Color.white.opacity(configuration.isPressed ? 0.65 : 0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isNight ? Color.white.opacity(0.12) : Color.black.opacity(0.1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct NightModeButtonStyle: ButtonStyle {
    let isNight: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.black))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(isNight ? Color(red: 0.96, green: 0.78, blue: 0.38) : Color(red: 0.04, green: 0.31, blue: 0.29))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(isNight ? Color.white.opacity(configuration.isPressed ? 0.10 : 0.16) : Color.white.opacity(configuration.isPressed ? 0.65 : 0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isNight ? Color.white.opacity(0.14) : Color.black.opacity(0.1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
        .environment(\.layoutDirection, .rightToLeft)
}
