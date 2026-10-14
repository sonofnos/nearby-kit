import CoreBluetooth
import Combine

/// Scans for other NearbyKit instances advertising `BluetoothIdentifiers.serviceUUID`.
/// Central (scanning) role of the two CoreBluetooth roles this app implements;
/// see `BLEPeripheralManager` for the advertising side.
final class BLECentralManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published private(set) var state: CBManagerState = .unknown
    @Published private(set) var isScanning = false
    @Published private(set) var devices: [DiscoveredDevice] = []

    private var central: CBCentralManager!
    private let store = NearbyDeviceStore()
    private var pruneTimer: Timer?

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard central.state == .poweredOn else { return }
        central.scanForPeripherals(
            withServices: [BluetoothIdentifiers.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
        schedulePruning()
    }

    func stopScanning() {
        central.stopScan()
        isScanning = false
        pruneTimer?.invalidate()
        pruneTimer = nil
    }

    private func schedulePruning() {
        pruneTimer?.invalidate()
        pruneTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.pruneAndPublish()
        }
    }

    private func pruneAndPublish() {
        store.pruneStale()
        devices = store.sortedBySignalStrength
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        state = central.state
        if central.state != .poweredOn {
            isScanning = false
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? ""
        store.upsert(id: peripheral.identifier, name: name, rssi: RSSI.intValue)
        devices = store.sortedBySignalStrength
    }
}
