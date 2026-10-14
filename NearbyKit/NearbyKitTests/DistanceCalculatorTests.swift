import XCTest
import CoreLocation
@testable import NearbyKit

final class DistanceCalculatorTests: XCTestCase {

    func test_distanceMeters_sameCoordinate_isZero() {
        let point = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        let poi = PointOfInterest(name: "Here", coordinate: point)
        let distance = DistanceCalculator.distanceMeters(from: point, to: poi)
        XCTAssertEqual(distance, 0, accuracy: 0.01)
    }

    func test_distanceMeters_usesSharedKitHaversine() {
        // Big Ben to Tower Bridge is roughly 3.3-3.6km; this exercises the
        // real call into the SharedKit framework, not a Swift re-implementation.
        let origin = CLLocationCoordinate2D(latitude: 51.5007, longitude: -0.1246)
        let poi = PointOfInterest(
            name: "Tower Bridge",
            coordinate: CLLocationCoordinate2D(latitude: 51.5055, longitude: -0.0754)
        )
        let distance = DistanceCalculator.distanceMeters(from: origin, to: poi)
        XCTAssertTrue((3000...4000).contains(distance), "expected ~3.3km, got \(distance)m")
    }

    func test_formatted_belowOneKm_showsMeters() {
        XCTAssertEqual(DistanceCalculator.formatted(meters: 350), "350 m")
    }

    func test_formatted_aboveOneKm_showsKilometers() {
        XCTAssertEqual(DistanceCalculator.formatted(meters: 2500), "2.5 km")
    }
}
