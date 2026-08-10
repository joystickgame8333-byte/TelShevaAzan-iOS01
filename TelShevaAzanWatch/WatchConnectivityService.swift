import Foundation
import Combine
import WatchConnectivity
import WidgetKit

final class WatchConnectivityService: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityService()

    @Published private(set) var lastUpdate = Date.distantPast

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated, error == nil else { return }
        apply(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    private func apply(_ context: [String: Any]) {
        guard !context.isEmpty else { return }
        DispatchQueue.main.async {
            guard WatchPrayerSharedState.apply(applicationContext: context) else { return }
            self.lastUpdate = Date()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
