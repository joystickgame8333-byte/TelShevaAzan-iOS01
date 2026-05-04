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

    static func delta(from heading: Double, to bearing: Double) -> Double {
        var value = bearing - heading
        while value > 180 { value -= 360 }
        while value < -180 { value += 360 }
        return value
    }

    private static func bearing(fromLatitude lat1: Double, fromLongitude lon1: Double, toLatitude lat2: Double, toLongitude lon2: Double) -> Double {
        let phi1 = lat1.degreesToRadians
        let phi2 = lat2.degreesToRadians
        let deltaLambda = (lon2 - lon1).degreesToRadians
        let y = sin(deltaLambda) * cos(phi2)
        let x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(deltaLambda)
        return (atan2(y, x).radiansToDegrees + 360).truncatingRemainder(dividingBy: 360)
    }
}

final class QiblaCompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double?
    @Published var accuracy: Double = -1
    @Published var usesTrueNorth = false
    @Published var statusMessage = "شغّل البوصلة ووجّه أعلى الهاتف"

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = kCLHeadingFilterNone
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func start() {
        guard CLLocationManager.headingAvailable() else {
            statusMessage = "البوصلة غير متوفرة على هذا الجهاز"
            return
        }

        if CLLocationManager.locationServicesEnabled() {
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
            default:
                break
            }
        }

        manager.startUpdatingHeading()
    }

    func stop() {
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let trueHeading = newHeading.trueHeading
        let magneticHeading = newHeading.magneticHeading
        let nextHeading = trueHeading > 0 ? trueHeading : magneticHeading
        let nextAccuracy = newHeading.headingAccuracy

        DispatchQueue.main.async {
            self.heading = nextHeading
            self.accuracy = nextAccuracy
            self.usesTrueNorth = trueHeading > 0

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

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        true
    }
}

private extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
