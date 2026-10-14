import CoreBluetooth
import UIKit

/// Advertises a custom service so other NearbyKit instances can discover
/// this device. Peripheral (advertising) role of the two CoreBluetooth
/// roles this app implements; see `BLECentralManager` for the scanning side.
final class BLEPeripheralManager: NSObject, ObservableObject, CBPeripheralManagerDelegate {
    @Published private(set) var state: CBManagerState = .unknown
    @Published private(set) var isAdvertising = false

    private var peripheral: CBPeripheralManager!
    private let localName: String

    init(localName: String = UIDevice.current.name) {
        self.localName = localName
        super.init()
        peripheral = CBPeripheralManager(delegate: self, queue: nil)
    }

    func startAdvertising() {
        guard peripheral.state == .poweredOn else { return }

        let characteristic = CBMutableCharacteristic(
            type: BluetoothIdentifiers.deviceNameCharacteristicUUID,
            properties: [.read],
            value: localName.data(using: .utf8),
            permissions: [.readable]
        )
        let service = CBMutableService(type: BluetoothIdentifiers.serviceUUID, primary: true)
        service.characteristics = [characteristic]
        peripheral.add(service)

        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [BluetoothIdentifiers.serviceUUID],
            CBAdvertisementDataLocalNameKey: localName
        ])
        isAdvertising = true
    }

    func stopAdvertising() {
        peripheral.stopAdvertising()
        isAdvertising = false
    }

    // MARK: - CBPeripheralManagerDelegate

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        state = peripheral.state
        if peripheral.state != .poweredOn {
            isAdvertising = false
        }
    }

    func peripheralManager(
        _ peripheral: CBPeripheralManager,
        didReceiveRead request: CBATTRequest
    ) {
        guard request.characteristic.uuid == BluetoothIdentifiers.deviceNameCharacteristicUUID else {
            peripheral.respond(to: request, withResult: .attributeNotFound)
            return
        }
        request.value = localName.data(using: .utf8)
        peripheral.respond(to: request, withResult: .success)
    }
}
