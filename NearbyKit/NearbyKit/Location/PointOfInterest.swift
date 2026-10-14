import CoreLocation
import SharedKit

/// Sample fixed points of interest. In a real app these would come from a
/// backend; here they exist so the map and distance list have something to
/// show without a network dependency.
struct PointOfInterest: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

extension PointOfInterest {
    /// A handful of London landmarks, spread out enough that distances to
    /// them are visibly different from a user location anywhere in the city.
    static let samples: [PointOfInterest] = [
        PointOfInterest(name: "Big Ben", coordinate: CLLocationCoordinate2D(latitude: 51.5007, longitude: -0.1246)),
        PointOfInterest(name: "Tower Bridge", coordinate: CLLocationCoordinate2D(latitude: 51.5055, longitude: -0.0754)),
        PointOfInterest(name: "British Museum", coordinate: CLLocationCoordinate2D(latitude: 51.5194, longitude: -0.1270)),
        PointOfInterest(name: "King's Cross Station", coordinate: CLLocationCoordinate2D(latitude: 51.5308, longitude: -0.1238))
    ]
}

enum DistanceCalculator {
    /// Distance in meters from `origin` to `poi`, computed by the Kotlin
    /// Multiplatform shared module (`ProximityMath.haversineMeters`) rather
    /// than `CLLocation.distance(from:)`. This is the integration point
    /// that exercises the KMP-built `SharedKit` framework from Swift.
    static func distanceMeters(from origin: CLLocationCoordinate2D, to poi: PointOfInterest) -> Double {
        ProximityMath.shared.haversineMeters(
            lat1: origin.latitude,
            lon1: origin.longitude,
            lat2: poi.coordinate.latitude,
            lon2: poi.coordinate.longitude
        )
    }

    static func formatted(meters: Double) -> String {
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        }
        return String(format: "%.1f km", meters / 1000)
    }
}
