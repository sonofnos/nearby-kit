import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LocationView()
                .tabItem {
                    Label("Location", systemImage: "location.fill")
                }

            BluetoothView()
                .tabItem {
                    Label("Bluetooth", systemImage: "dot.radiowaves.left.and.right")
                }

            UWBView()
                .tabItem {
                    Label("Precision", systemImage: "scope")
                }
        }
    }
}

#Preview {
    ContentView()
}
