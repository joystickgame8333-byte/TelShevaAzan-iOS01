import SwiftUI

@main
struct TelShevaAzanWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchPrayerView()
                .environment(\.layoutDirection, .rightToLeft)
        }
    }
}

struct WatchPrayerView: View {
    @State private var now = Date()

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var dateKey: String {
        PrayerEngine.defaultDateKey(for: now)
    }

    private var nextPrayer: PrayerTime? {
        PrayerEngine.nextPrayer(for: dateKey, now: now)
    }

    private var schedule: [PrayerTime] {
        PrayerEngine.schedule(for: dateKey).displayTimes
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 10) {
                header
                nextPrayerCard
                prayerList
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .background(Color.black)
        .foregroundStyle(.white)
        .onReceive(timer) { now = $0 }
    }

    private var header: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("صلاتي")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("مواقيت محلية \(AppInfo.displayVersion)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.96, green: 0.75, blue: 0.32))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var nextPrayerCard: some View {
        VStack(alignment: .trailing, spacing: 5) {
            Text("الصلاة القادمة")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Color(red: 0.96, green: 0.75, blue: 0.32))

            Text(nextPrayer?.title ?? "الصلاة")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(nextPrayer?.time ?? "--:--")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color(red: 0.96, green: 0.75, blue: 0.32))

            Text(remainingText)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .monospacedDigit()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(12)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.12, blue: 0.12),
                    Color(red: 0.03, green: 0.05, blue: 0.05)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var prayerList: some View {
        VStack(spacing: 5) {
            ForEach(schedule) { item in
                HStack {
                    Text(item.time)
                        .font(.system(size: 14, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundStyle(item.key == nextPrayer?.key ? Color(red: 0.96, green: 0.75, blue: 0.32) : .white)

                    Spacer(minLength: 6)

                    Text(item.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(item.key == nextPrayer?.key ? 1.0 : 0.72))
                }
                .padding(.horizontal, 9)
                .frame(height: 28)
                .background(item.key == nextPrayer?.key ? Color(red: 0.22, green: 0.16, blue: 0.06) : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var remainingText: String {
        guard let nextDate = nextPrayer?.date else { return "باقي --:--" }
        let seconds = max(Int(nextDate.timeIntervalSince(now)), 0)
        return "باقي \(formatDuration(seconds))"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = max((seconds + 59) / 60, 1)
        return String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}
