import XCTest
import CoreLocation
@testable import NearbyKit

final class PermissionStatusMapperTests: XCTestCase {

    func test_notDetermined_mapsToNotDetermined() {
        XCTAssertEqual(PermissionStatusMapper.state(from: .notDetermined), .notDetermined)
    }

    func test_restricted_mapsToRestricted() {
        XCTAssertEqual(PermissionStatusMapper.state(from: .restricted), .restricted)
    }

    func test_denied_mapsToDeniedByUser() {
        XCTAssertEqual(PermissionStatusMapper.state(from: .denied), .deniedByUser)
    }

    func test_authorizedWhenInUse_mapsCorrectly() {
        XCTAssertEqual(PermissionStatusMapper.state(from: .authorizedWhenInUse), .authorizedWhenInUse)
    }

    func test_authorizedAlways_mapsCorrectly() {
        XCTAssertEqual(PermissionStatusMapper.state(from: .authorizedAlways), .authorizedAlways)
    }

    func test_canRequestLocation_onlyTrueWhenAuthorized() {
        XCTAssertFalse(LocationPermissionState.notDetermined.canRequestLocation)
        XCTAssertFalse(LocationPermissionState.restricted.canRequestLocation)
        XCTAssertFalse(LocationPermissionState.deniedByUser.canRequestLocation)
        XCTAssertTrue(LocationPermissionState.authorizedWhenInUse.canRequestLocation)
        XCTAssertTrue(LocationPermissionState.authorizedAlways.canRequestLocation)
    }

    func test_userMessage_isNonEmptyForEveryState() {
        let states: [LocationPermissionState] = [
            .notDetermined, .restricted, .deniedByUser, .authorizedWhenInUse, .authorizedAlways
        ]
        for state in states {
            XCTAssertFalse(state.userMessage.isEmpty, "expected a message for \(state)")
        }
    }
}
