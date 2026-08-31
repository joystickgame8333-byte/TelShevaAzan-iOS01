import CoreLocation
import Foundation

/// Gives WidgetKit a chance to resolve its own current region instead of
/// waiting for the containing app to open. WidgetKit controls when location
/// is available and how often the extension may refresh.
final class WidgetPrayerLocationResolver: NSObject, CLLocationManagerDelegate {
    static let shared = WidgetPrayerLocationResolver()

    private let manager = CLLocationManager()
    private var completions: [() -> Void] = []
    private var timeout: DispatchWorkItem?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func refreshIfAvailable(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            guard PrayerLocationStore.isAutomatic,
                  self.manager.isAuthorizedForWidgetUpdates else {
                completion()
                return
            }

            if let cached = self.manager.location,
               self.isUsable(cached, maximumAge: 20 * 60) {
                self.save(cached)
                completion()
                return
            }

            self.completions.append(completion)
            guard self.completions.count == 1 else { return }

            self.manager.requestLocation()
            let timeout = DispatchWorkItem { [weak self] in
                self?.finish()
            }
            self.timeout = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: timeout)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last(where: { isUsable($0, maximumAge: 60 * 60) }) {
            save(location)
        }
        finish()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish()
    }

    private func save(_ location: CLLocation) {
        _ = PrayerLocationStore.saveAutomaticLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            at: location.timestamp
        )
    }

    private func isUsable(_ location: CLLocation, maximumAge: TimeInterval) -> Bool {
        location.horizontalAccuracy >= 0
            && location.horizontalAccuracy <= 10_000
            && abs(location.timestamp.timeIntervalSinceNow) <= maximumAge
    }

    private func finish() {
        timeout?.cancel()
        timeout = nil
        let pending = completions
        completions.removeAll()
        pending.forEach { $0() }
    }
}
