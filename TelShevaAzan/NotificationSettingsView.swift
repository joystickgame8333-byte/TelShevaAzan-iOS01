import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var notifications = PrayerNotificationManager.shared

    let theme: PrayerVisualTheme

    var body: some View {
        GeometryReader { proxy in
            let compactHeight = proxy.size.height < 720
            let safeTopPadding = max(proxy.safeAreaInsets.top, 44) + (compactHeight ? 12 : 18)

            ZStack {
                LinearGradient(
                    colors: theme.appBackground,
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .trailing, spacing: compactHeight ? 12 : 14) {
                        header
                        masterPanel
                        soundPanel
                        prayerPanel
                        previewButton
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, safeTopPadding)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .topTrailing)
                }
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
                    .background(theme.controlBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(theme.controlBorder)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text("تنبيهات الأذان")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Text("اختر الصوت والصلوات التي تريدها")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private var masterPanel: some View {
        HStack(spacing: 14) {
            Toggle("", isOn: Binding(
                get: { notifications.isEnabled },
                set: { enabled in
                    if enabled {
                        notifications.enable()
                    } else {
                        notifications.disable()
                    }
                }
            ))
            .labelsHidden()
            .tint(theme.accent)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 5) {
                Text("تشغيل التنبيهات")
                    .font(.headline.weight(.black))
                    .lineLimit(1)

                Text(notifications.statusText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.82))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(theme.panelBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
            }
        }
    }

    private var prayerPanel: some View {
        panel(title: "الصلوات التي يصدر لها الأذان") {
            VStack(spacing: 0) {
                ForEach(Array(PrayerEngine.prayerOrder.enumerated()), id: \.element.id) { index, key in
                    prayerToggleRow(key)

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
            .font(.headline.weight(.black))
            .foregroundStyle(theme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(theme.countdownBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.activeRowBorder)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
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
        .background(theme.controlBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.controlBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func optionRow(title: String, subtitle: String, symbol: String, selected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: selected ? "checkmark.circle.fill" : symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(selected ? theme.accent : theme.secondaryText.opacity(0.88))
                .frame(width: 28, alignment: .leading)

            Spacer(minLength: 14)

            VStack(alignment: .trailing, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(selected ? theme.accent : theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.80))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func prayerToggleRow(_ key: PrayerKey) -> some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { notifications.isPrayerEnabled(key) },
                set: { notifications.setPrayer(key, enabled: $0) }
            ))
            .labelsHidden()
            .tint(theme.accent)

            Spacer(minLength: 14)

            VStack(alignment: .trailing, spacing: 4) {
                Text(key.title)
                    .font(.headline.weight(.bold))
                    .lineLimit(1)

                Text(todayTime(for: key))
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(theme.secondaryText.opacity(0.82))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 9)
    }

    private func todayTime(for key: PrayerKey) -> String {
        let schedule = PrayerEngine.schedule(for: PrayerEngine.defaultDateKey())
        return schedule.times[key] ?? "--:--"
    }
}
