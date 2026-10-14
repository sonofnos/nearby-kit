import CoreBluetooth

enum BluetoothIdentifiers {
    /// Custom service UUID this app advertises and scans for. Generated once
    /// for this project; any two NearbyKit installs will discover each
    /// other, but it won't collide with other apps' services.
    static let serviceUUID = CBUUID(string: "7C9A9A9E-7F2B-4B7D-9C9E-2E6B3B6E5B40")

    /// Characteristic carrying a short device label, so a discovered
    /// peripheral can show something more useful than its UUID.
    static let deviceNameCharacteristicUUID = CBUUID(string: "7C9A9A9E-7F2B-4B7D-9C9E-2E6B3B6E5B41")
}
