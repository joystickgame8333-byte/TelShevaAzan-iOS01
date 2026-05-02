import SwiftUI

struct ContentView: View {
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
            }
            .padding(18)
        }
        .background(background)
        .onReceive(timer) { value in
            now = value
            if followsToday {
                selectedDateKey = PrayerEngine.defaultDateKey(for: value)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text("نموذج أولي")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.teal)

            Text("أذان تل السبع")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .trailing)

            Text(PrayerEngine.longDateLabel(for: selectedDateKey))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private func nextPrayerPanel(next: PrayerTime?) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text("الصلاة القادمة")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.teal)

            Text(next?.title ?? "--")
                .font(.system(size: 46, weight: .black, design: .rounded))

            Text(next?.time ?? "--:--")
                .font(.system(size: 58, weight: .black, design: .rounded))
                .foregroundStyle(Color.teal)

            Text(countdownText(for: next))
                .font(.title2.monospacedDigit().weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(Color(red: 0.04, green: 0.31, blue: 0.29))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("القدس الدهري + دقيقتين لتل السبع + التوقيت الصيفي")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(18)
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }

    private var dateControls: some View {
        HStack(spacing: 8) {
            Button("اليوم التالي") {
                moveDay(1)
            }
            .buttonStyle(CompactButtonStyle())
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: 1))

            Button("اليوم") {
                selectedDateKey = PrayerEngine.defaultDateKey(for: now)
                followsToday = true
            }
            .buttonStyle(CompactButtonStyle())

            Button("اليوم السابق") {
                moveDay(-1)
            }
            .buttonStyle(CompactButtonStyle())
            .disabled(!PrayerEngine.canMove(from: selectedDateKey, by: -1))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func prayerRow(_ item: PrayerTime, activeKey: PrayerKey?) -> some View {
        HStack {
            Text(item.time)
                .font(.title3.monospacedDigit().weight(.bold))
                .foregroundStyle(item.key == activeKey ? Color.teal : Color.primary)

            Spacer()

            Text(item.title)
                .font(.headline.weight(.bold))
                .foregroundStyle(item.key == activeKey ? Color.teal : Color.secondary)
        }
        .padding(14)
        .background(item.key == activeKey ? Color.teal.opacity(0.12) : Color.white.opacity(0.82))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(item.key == activeKey ? Color.teal.opacity(0.55) : Color.black.opacity(0.08))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var background: some View {
        LinearGradient(
            colors: [
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
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.bold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.white.opacity(configuration.isPressed ? 0.65 : 0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
        .environment(\.layoutDirection, .rightToLeft)
}
