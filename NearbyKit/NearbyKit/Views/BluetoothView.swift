import SwiftUI
import CoreBluetooth

struct BluetoothView: View {
    @StateObject private var central = BLECentralManager()
    @StateObject private var peripheral = BLEPeripheralManager()

    var body: some View {
        NavigationStack {
            List {
                Section("This device") {
                    Toggle("Advertise as discoverable", isOn: Binding(
                        get: { peripheral.isAdvertising },
                        set: { shouldAdvertise in
                            if shouldAdvertise {
                                peripheral.startAdvertising()
                            } else {
                                peripheral.stopAdvertising()
                            }
                        }
                    ))
                    .disabled(peripheral.state != .poweredOn)

                    Text(statusText(for: peripheral.state))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Scan for nearby devices") {
                    Toggle("Scanning", isOn: Binding(
                        get: { central.isScanning },
                        set: { shouldScan in
                            if shouldScan {
                                central.startScanning()
                            } else {
                                central.stopScanning()
                            }
                        }
                    ))
                    .disabled(central.state != .poweredOn)

                    Text(statusText(for: central.state))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Discovered devices") {
                    if central.devices.isEmpty {
                        Text("No devices found yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(central.devices) { device in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(device.name)
                                    Text("\(device.rssi) dBm")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(device.bucketLabel)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.thinMaterial, in: Capsule())
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bluetooth")
        }
    }

    private func statusText(for state: CBManagerState) -> String {
        switch state {
        case .poweredOn: return "Bluetooth is on."
        case .poweredOff: return "Bluetooth is off. Turn it on in Settings."
        case .unauthorized: return "Bluetooth access denied. Enable it in Settings."
        case .unsupported: return "This device does not support Bluetooth LE."
        case .resetting: return "Bluetooth is resetting."
        case .unknown: return "Checking Bluetooth state."
        @unknown default: return "Unknown Bluetooth state."
        }
    }
}

#Preview {
    BluetoothView()
}
