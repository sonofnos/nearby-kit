import CoreLocation
import Combine

/// Wraps `CLLocationManager`. Requests when-in-use authorization (the
/// correct default for a foreground-only feature like this one), reacts to
/// whatever the user actually decides, and never assumes authorization just
/// because a request was made.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var permissionState: LocationPermissionState
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    @Published private(set) var lastError: String?

    private let manager: CLLocationManager

    init(manager: CLLocationManager = CLLocationManager()) {
        self.manager = manager
        self.permissionState = PermissionStatusMapper.state(from: manager.authorizationStatus)
        super.init()
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        switch permissionState {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .deniedByUser, .restricted:
            // Can't re-prompt; caller should direct the user to Settings.
            break
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        }
    }

    func startUpdating() {
        guard permissionState.canRequestLocation else { return }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newState = PermissionStatusMapper.state(from: manager.authorizationStatus)
        permissionState = newState
        if newState.canRequestLocation {
            startUpdating()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        currentLocation = latest.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastError = error.localizedDescription
    }
}
