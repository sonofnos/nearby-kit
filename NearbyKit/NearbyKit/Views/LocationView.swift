import SwiftUI
import MapKit

struct LocationView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(position: $cameraPosition) {
                    if let coordinate = locationManager.currentLocation {
                        Annotation("You", coordinate: coordinate) {
                            Image(systemName: "location.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                        }
                    }
                    ForEach(PointOfInterest.samples) { poi in
                        Annotation(poi.name, coordinate: poi.coordinate) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .frame(height: 300)

                List {
                    Section {
                        permissionRow
                    }

                    if let origin = locationManager.currentLocation {
                        Section("Distance to points of interest") {
                            ForEach(PointOfInterest.samples) { poi in
                                HStack {
                                    Text(poi.name)
                                    Spacer()
                                    Text(DistanceCalculator.formatted(
                                        meters: DistanceCalculator.distanceMeters(from: origin, to: poi)
                                    ))
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Nearby")
            .onAppear {
                locationManager.requestPermission()
            }
        }
    }

    @ViewBuilder
    private var permissionRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(locationManager.permissionState.userMessage)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !locationManager.permissionState.canRequestLocation {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.footnote)
            }
        }
    }
}

#Preview {
    LocationView()
}
