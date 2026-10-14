import XCTest
@testable import NearbyKit

final class NearbyDeviceStoreTests: XCTestCase {

    func test_upsert_addsNewDevice() {
        let store = NearbyDeviceStore()
        let id = UUID()
        store.upsert(id: id, name: "Phone A", rssi: -50)
        XCTAssertEqual(store.devices.count, 1)
        XCTAssertEqual(store.devices[id]?.rssi, -50)
    }

    func test_upsert_updatesExistingDeviceInPlace() {
        let store = NearbyDeviceStore()
        let id = UUID()
        store.upsert(id: id, name: "Phone A", rssi: -50)
        store.upsert(id: id, name: "Phone A", rssi: -70)
        XCTAssertEqual(store.devices.count, 1)
        XCTAssertEqual(store.devices[id]?.rssi, -70)
    }

    func test_upsert_keepsPreviousName_whenNewNameIsEmpty() {
        let store = NearbyDeviceStore()
        let id = UUID()
        store.upsert(id: id, name: "Phone A", rssi: -50)
        store.upsert(id: id, name: "", rssi: -55)
        XCTAssertEqual(store.devices[id]?.name, "Phone A")
    }

    func test_sortedBySignalStrength_strongestFirst() {
        let store = NearbyDeviceStore()
        store.upsert(id: UUID(), name: "Far", rssi: -90)
        store.upsert(id: UUID(), name: "Near", rssi: -40)
        store.upsert(id: UUID(), name: "Mid", rssi: -65)

        let sorted = store.sortedBySignalStrength
        XCTAssertEqual(sorted.map(\.name), ["Near", "Mid", "Far"])
    }

    func test_pruneStale_removesOldEntries_keepsFreshOnes() {
        let store = NearbyDeviceStore()
        let staleId = UUID()
        let freshId = UUID()
        let now = Date()

        store.upsert(id: staleId, name: "Old", rssi: -60, now: now.addingTimeInterval(-20))
        store.upsert(id: freshId, name: "New", rssi: -60, now: now)

        store.pruneStale(now: now)

        XCTAssertNil(store.devices[staleId])
        XCTAssertNotNil(store.devices[freshId])
    }

    func test_reset_clearsAllDevices() {
        let store = NearbyDeviceStore()
        store.upsert(id: UUID(), name: "A", rssi: -50)
        store.upsert(id: UUID(), name: "B", rssi: -60)
        store.reset()
        XCTAssertTrue(store.devices.isEmpty)
    }

    func test_discoveredDevice_bucketLabel_matchesSharedKitBuckets() {
        let store = NearbyDeviceStore()
        let id = UUID()
        store.upsert(id: id, name: "Close", rssi: -40)
        XCTAssertEqual(store.devices[id]?.bucketLabel, "Immediate")
    }
}
