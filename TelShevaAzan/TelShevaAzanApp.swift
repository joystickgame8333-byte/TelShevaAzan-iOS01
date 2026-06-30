import SwiftUI

@main
struct TelShevaAzanApp: App {
    @UIApplicationDelegateAdaptor(TelShevaAzanAppDelegate.self) private var appDelegate

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
