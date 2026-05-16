import SwiftUI

@main
struct TelShevaAzanApp: App {
    init() {
        _ = PrayerNotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, .rightToLeft)
                .onAppear {
                    WidgetRefreshCenter.refreshAll()
                }
        }
    }
}
