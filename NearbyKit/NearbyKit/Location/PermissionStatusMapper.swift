import CoreLocation

/// User-facing state derived from `CLAuthorizationStatus`. Kept separate from
/// `CLLocationManagerDelegate` so the mapping can be unit tested without a
/// real location manager.
enum LocationPermissionState: Equatable {
    case notDetermined
    case restricted
    case deniedByUser
    case authorizedWhenInUse
    case authorizedAlways

    var canRequestLocation: Bool {
        switch self {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        case .notDetermined, .restricted, .deniedByUser:
            return false
        }
    }

    var userMessage: String {
        switch self {
        case .notDetermined:
            return "Location access has not been requested yet."
        case .restricted:
            return "Location access is restricted on this device (parental controls or MDM)."
        case .deniedByUser:
            return "Location access was denied. Enable it in Settings to see nearby points of interest."
        case .authorizedWhenInUse:
            return "Location access granted while using the app."
        case .authorizedAlways:
            return "Location access granted at all times."
        }
    }
}

enum PermissionStatusMapper {
    static func state(from status: CLAuthorizationStatus) -> LocationPermissionState {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .deniedByUser
        case .authorizedWhenInUse:
            return .authorizedWhenInUse
        case .authorizedAlways:
            return .authorizedAlways
        @unknown default:
            return .deniedByUser
        }
    }
}
