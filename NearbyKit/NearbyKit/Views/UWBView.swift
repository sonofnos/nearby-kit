import SwiftUI

struct UWBView: View {
    @StateObject private var session = UWBSessionManager()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if session.status == .unsupported {
                    unsupportedNotice
                } else {
                    statusCard
                    controls
                }

                verificationNotice

                Spacer()
            }
            .padding()
            .navigationTitle("UWB Precision")
        }
    }

    private var unsupportedNotice: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text("This device does not support NearbyInteraction (U1/U2 chip required, iPhone 11 or later).")
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var statusCard: some View {
        VStack(spacing: 8) {
            Text(statusText)
                .font(.headline)

            if let distance = session.distanceMeters {
                Text(String(format: "%.2f m", distance))
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
            } else {
                Text("--")
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if session.directionAvailable {
                Text("Direction data available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var controls: some View {
        Button(session.status == .idle ? "Start session" : "Stop session") {
            if session.status == .idle {
                session.start()
            } else {
                session.stop()
            }
        }
        .buttonStyle(.borderedProminent)
    }

    private var verificationNotice: some View {
        Text("NISession wiring is real and follows Apple's discovery-token-exchange pattern, but full ranging has not been verified end-to-end. That needs two physical UWB-capable iPhones (11 or later) held near each other, which was not available when this was built.")
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    private var statusText: String {
        switch session.status {
        case .unsupported: return "Unsupported"
        case .idle: return "Idle"
        case .waitingForPeer: return "Waiting for a nearby peer"
        case .ranging: return "Ranging"
        case .peerLost: return "Peer lost"
        }
    }
}

#Preview {
    UWBView()
}
