import Foundation
import SharedKit

/// A discovered BLE peripheral, with its proximity bucket computed by the
/// Kotlin Multiplatform `ProximityMath` shared module (same code the
/// Kotlin unit tests exercise).
struct DiscoveredDevice: Identifiable, Equatable {
    let id: UUID
    var name: String
    var rssi: Int
    var lastSeen: Date

    var bucket: ProximityBucket {
        ProximityMath.shared.bucketForRssi(rssi: Int32(rssi))
    }

    var bucketLabel: String {
        ProximityMath.shared.labelForBucket(bucket: bucket)
    }

    static func == (lhs: DiscoveredDevice, rhs: DiscoveredDevice) -> Bool {
        lhs.id == rhs.id
    }
}

/// Pure logic for tracking discovered peripherals: de-duplicates by
/// identifier, keeps the freshest RSSI, drops stale entries, and sorts by
/// signal strength. Kept free of `CoreBluetooth` types so it can be unit
/// tested without a real radio or simulator Bluetooth stack.
final class NearbyDeviceStore {
    private(set) var devices: [UUID: DiscoveredDevice] = [:]

    /// How long a device is kept after its last advertisement before
    /// `pruneStale` drops it.
    static let staleAfter: TimeInterval = 10

    func upsert(id: UUID, name: String, rssi: Int, now: Date = Date()) {
        if var existing = devices[id] {
            existing.rssi = rssi
            existing.lastSeen = now
            if !name.isEmpty {
                existing.name = name
            }
            devices[id] = existing
        } else {
            devices[id] = DiscoveredDevice(id: id, name: name.isEmpty ? "Unknown device" : name, rssi: rssi, lastSeen: now)
        }
    }

    func pruneStale(now: Date = Date()) {
        devices = devices.filter { now.timeIntervalSince($0.value.lastSeen) < Self.staleAfter }
    }

    /// Nearest (strongest RSSI) first.
    var sortedBySignalStrength: [DiscoveredDevice] {
        devices.values.sorted { $0.rssi > $1.rssi }
    }

    func reset() {
        devices.removeAll()
    }
}
