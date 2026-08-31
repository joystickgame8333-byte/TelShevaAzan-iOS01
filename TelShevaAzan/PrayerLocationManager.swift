import CoreLocation
import Foundation

@MainActor
final class PrayerLocationManager: NSObject, ObservableObject {
    static let shared = PrayerLocationManager()

    enum Status: Equatable {
        case connected
        case manual
        case resolving
        case permissionRequired
        case unavailable

        var title: String {
            switch self {
            case .connected: return "الموقع متصل"
            case .manual: return "اختيار يدوي"
            case .resolving: return "جارٍ تحديد الموقع"
            case .permissionRequired: return "السماح بالموقع مطلوب"
            case .unavailable: return "تعذر تحديد الموقع"
            }
        }
    }

    @Published private(set) var city = PrayerLocationStore.currentCity
    @Published private(set) var isAutomatic = PrayerLocationStore.isAutomatic
    @Published private(set) var status: Status = PrayerLocationStore.isAutomatic ? .connected : .manual
    @Published private(set) var revision = 0

    private let manager = CLLocationManager()
    private var requestedAfterAuthorization = false
    private var requestedBackgroundUpgrade = false
    private var requestInFlight = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 500
        manager.activityType = .other
    }

    func startAutomaticIfNeeded(force: Bool = false) {
        city = PrayerLocationStore.currentCity
        isAutomatic = PrayerLocationStore.isAutomatic
        guard isAutomatic else {
            status = .manual
            return
        }
        guard force || !PrayerLocationStore.cachedLocationIsRecent else {
            status = .connected
            return
        }
        requestPhoneLocation()
    }

    func activateAutomaticLocation() {
        PrayerLocationStore.setAutomaticEnabled(true)
        isAutomatic = true
        requestedBackgroundUpgrade = true
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        }
        requestPhoneLocation()
    }

    func selectManualCity(_ selectedCity: PrayerCity) {
        manager.stopMonitoringSignificantLocationChanges()
        requestInFlight = false
        PrayerLocationStore.setManualCity(selectedCity)
        city = selectedCity
        isAutomatic = false
        status = .manual
        revision &+= 1
    }

    func requestPhoneLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            status = .unavailable
            return
        }

        switch manager.authorizationStatus {
        case .notDetermined:
            status = .resolving
            requestedAfterAuthorization = true
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            if let cached = manager.location,
               cached.horizontalAccuracy >= 0,
               cached.horizontalAccuracy <= 10_000,
               abs(cached.timestamp.timeIntervalSinceNow) <= 30 * 60 {
                accept(cached)
            }
            guard !requestInFlight else { return }
            status = .resolving
            requestInFlight = true
            manager.requestLocation()
        case .denied, .restricted:
            status = .permissionRequired
        @unknown default:
            status = .unavailable
        }
    }

    func resumeBackgroundMonitoring() {
        guard PrayerLocationStore.isAutomatic,
              CLLocationManager.significantLocationChangeMonitoringAvailable(),
              manager.authorizationStatus == .authorizedAlways else {
            return
        }
        manager.startMonitoringSignificantLocationChanges()
    }

    private func accept(_ location: CLLocation) {
        requestInFlight = false
        let previousCityID = PrayerLocationStore.currentCity.id
        let selected = PrayerLocationStore.saveAutomaticLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            at: location.timestamp
        )
        city = selected
        isAutomatic = true
        status = .connected
        if selected.id != previousCityID {
            revision &+= 1
            PrayerNotificationManager.shared.refreshIfEnabled()
            WidgetRefreshCenter.refreshAll(force: true)
        }
        resumeBackgroundMonitoring()
    }
}

extension PrayerLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if manager.authorizationStatus == .authorizedWhenInUse,
               requestedBackgroundUpgrade {
                requestedBackgroundUpgrade = false
                manager.requestAlwaysAuthorization()
            } else if manager.authorizationStatus == .authorizedAlways {
                requestedBackgroundUpgrade = false
            }
            if manager.authorizationStatus == .authorizedAlways {
                resumeBackgroundMonitoring()
            }
            if requestedAfterAuthorization || PrayerLocationStore.isAutomatic {
                requestedAfterAuthorization = false
                requestInFlight = true
                status = .resolving
                manager.requestLocation()
            }
        case .denied, .restricted:
            status = .permissionRequired
        case .notDetermined:
            break
        @unknown default:
            status = .unavailable
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard PrayerLocationStore.isAutomatic else { return }
        let usable = locations.filter { location in
            location.horizontalAccuracy >= 0
                && location.horizontalAccuracy <= 10_000
                && abs(location.timestamp.timeIntervalSinceNow) <= 60 * 60
        }
        guard let best = usable.min(by: { $0.horizontalAccuracy < $1.horizontalAccuracy }) ?? locations.last else {
            status = .unavailable
            return
        }
        accept(best)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        requestInFlight = false
        if let saved = PrayerLocationStore.savedCoordinate {
            let fallback = CLLocation(latitude: saved.latitude, longitude: saved.longitude)
            accept(fallback)
        } else {
            status = .unavailable
        }
    }
}
