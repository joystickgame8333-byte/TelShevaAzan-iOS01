import SwiftUI
import WidgetKit

@main
struct TelShevaAzanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.layoutDirection, .rightToLeft)
                .onAppear {
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}
