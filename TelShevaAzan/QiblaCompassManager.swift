import Combine
import CoreLocation
import Foundation

enum QiblaCalculator {
    static let telShevaLatitude = 31.24864
    static let telShevaLongitude = 34.86007
    static let kaabaLatitude = 21.422487
    static let kaabaLongitude = 39.826206

    static var telShevaBearing: Double {
        bearing(
            fromLatitude: telShevaLatitude,
            fromLongitude: telShevaLongitude,
            toLatitude: kaabaLatitude,
            toLongitude: kaabaLongitude
        )
    }

    static func bearing(from location: CLLocation) -> Double {
        bearing(
            fromLatitude: location.coordinate.latitude,
            fromLongitude: location.coordinate.longitude,
            toLatitude: kaabaLatitude,
            toLongitude: kaabaLongitude
        )
    }

    static func delta(from heading: Double, to bearing: Double) -> Double {
        var value = bearing - heading
        while value > 180 { value -= 360 }
        while value < -180 { value += 360 }
        return value
    }

    static func normalized(_ degrees: Double) -> Double {
        (degrees.truncatingRemainder(dividingBy: 360) + 360)
            .truncatingRemainder(dividingBy: 360)
    }

    private static func bearing(
        fromLatitude lat1: Double,
        fromLongitude lon1: Double,
        toLatitude lat2: Double,
        toLongitude lon2: Double
    ) -> Double {
        let phi1 = lat1.degreesToRadians
        let phi2 = lat2.degreesToRadians
        let deltaLambda = (lon2 - lon1).degreesToRadians
        let y = sin(deltaLambda) * cos(phi2)
        let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda)
        return normalized(atan2(y, x).radiansToDegrees)
    }
}

final class QiblaCompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double?
    @Published var accuracy: Double = -1
    @Published var usesTrueNorth = false
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isHeadingAvailable = CLLocationManager.headingAvailable()
    @Published var statusMessage = "شغّل البوصلة ووجّه أعلى الهاتف"

    private let manager = CLLocationManager()
    private var smoothedHeading: Double?

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 1
        manager.headingOrientation = .portrait
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 25
        authorizationStatus = manager.authorizationStatus
    }

    func start() {
        isHeadingAvailable = CLLocationManager.headingAvailable()

        guard isHeadingAvailable else {
            statusMessage = "البوصلة غير متوفرة على هذا الجهاز"
            return
        }

        if CLLocationManager.locationServicesEnabled() {
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                statusMessage = "فعّل الموقع لاستخدام الشمال الحقيقي"
            @unknown default:
                statusMessage = "تعذر التحقق من إذن الموقع"
            }
        }

        manager.startUpdatingHeading()
    }

    func stop() {
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            statusMessage = "فعّل الموقع لاستخدام الشمال الحقيقي"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else {
            DispatchQueue.main.async {
                self.accuracy = newHeading.headingAccuracy
                self.statusMessage = "حرّك الهاتف على شكل 8 لمعايرة البوصلة"
            }
            return
        }

        let trueHeading = newHeading.trueHeading
        let magneticHeading = newHeading.magneticHeading
        let hasTrueHeading = trueHeading >= 0
        let nextHeading = hasTrueHeading ? trueHeading : magneticHeading
        let nextAccuracy = newHeading.headingAccuracy
        let filteredHeading = smooth(nextHeading)

        DispatchQueue.main.async {
            self.heading = filteredHeading
            self.accuracy = nextAccuracy
            self.usesTrueNorth = hasTrueHeading

            if nextAccuracy < 0 {
                self.statusMessage = "حرّك الهاتف على شكل 8 لمعايرة البوصلة"
            } else if nextAccuracy <= 10 {
                self.statusMessage = "دقة ممتازة"
            } else if nextAccuracy <= 25 {
                self.statusMessage = "دقة جيدة، أبعد الهاتف عن المعادن"
            } else {
                self.statusMessage = "الدقة ضعيفة، حرّك الهاتف على شكل 8"
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= 1_000,
              abs(location.timestamp.timeIntervalSinceNow) <= 120
        else {
            return
        }

        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard (error as? CLError)?.code != .locationUnknown else { return }

        DispatchQueue.main.async {
            self.statusMessage = "تعذر تحديث الموقع، ما زالت البوصلة تعمل"
        }
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }

    private func smooth(_ newHeading: Double) -> Double {
        guard let previous = smoothedHeading else {
            smoothedHeading = newHeading
            return newHeading
        }

        let shortestChange = QiblaCalculator.delta(from: previous, to: newHeading)
        let smoothingFactor = abs(shortestChange) > 20 ? 0.46 : 0.24
        let result = QiblaCalculator.normalized(previous + shortestChange * smoothingFactor)
        smoothedHeading = result
        return result
    }
}

private extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
