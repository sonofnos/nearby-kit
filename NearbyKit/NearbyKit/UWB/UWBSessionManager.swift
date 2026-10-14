import NearbyInteraction
import Combine
import Foundation

/// Wires up `NISession` for UWB precision finding between two devices,
/// following Apple's documented discovery-token-exchange pattern.
///
/// Honesty note: this class compiles against the real NearbyInteraction
/// API and the logic matches Apple's own sample structure, but it has not
/// been exercised end-to-end. Doing that needs two physical UWB-capable
/// iPhones (11 or later) held near each other; that hardware pair was not
/// available in the environment this was built in. See the README for what
/// was and wasn't verified.
final class UWBSessionManager: NSObject, ObservableObject {
    enum Status: Equatable {
        case unsupported
        case idle
        case waitingForPeer
        case ranging
        case peerLost
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var distanceMeters: Float?
    @Published private(set) var directionAvailable = false

    private var session: NISession?
    private let channel = MultipeerTokenChannel()
    private var peerDiscoveryToken: NIDiscoveryToken?

    /// `NISession.isSupported` works but is deprecated in favor of checking
    /// the specific capability this app needs (distance measurement), which
    /// is what `NISession.deviceCapabilities` reports per-device.
    private static var supportsDistanceRanging: Bool {
        NISession.deviceCapabilities.supportsPreciseDistanceMeasurement
    }

    override init() {
        super.init()
        guard Self.supportsDistanceRanging else {
            status = .unsupported
            return
        }
        channel.onDataReceived = { [weak self] data in
            self?.handleReceivedTokenData(data)
        }
    }

    func start() {
        guard Self.supportsDistanceRanging else {
            status = .unsupported
            return
        }
        session = NISession()
        session?.delegate = self
        channel.start()
        status = .waitingForPeer
        sendOwnTokenIfPossible()
    }

    func stop() {
        session?.invalidate()
        session = nil
        channel.stop()
        peerDiscoveryToken = nil
        distanceMeters = nil
        directionAvailable = false
        status = Self.supportsDistanceRanging ? .idle : .unsupported
    }

    private func sendOwnTokenIfPossible() {
        guard let session, let token = session.discoveryToken else { return }
        guard let encoded = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else { return }
        channel.send(encoded)
    }

    private func handleReceivedTokenData(_ data: Data) {
        guard let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else { return }
        peerDiscoveryToken = token
        let config = NINearbyPeerConfiguration(peerToken: token)
        session?.run(config)
        // The peer may not have our token yet if it connected after we
        // discovered it; resend now that a session is actually running.
        sendOwnTokenIfPossible()
    }
}

extension UWBSessionManager: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let object = nearbyObjects.first(where: { $0.discoveryToken == peerDiscoveryToken }) else { return }
        status = .ranging
        distanceMeters = object.distance
        directionAvailable = object.direction != nil
    }

    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        guard nearbyObjects.contains(where: { $0.discoveryToken == peerDiscoveryToken }) else { return }
        distanceMeters = nil
        directionAvailable = false
        status = .peerLost
    }

    func sessionWasSuspended(_ session: NISession) {
        status = .waitingForPeer
    }

    func sessionSuspensionEnded(_ session: NISession) {
        if let peerDiscoveryToken {
            session.run(NINearbyPeerConfiguration(peerToken: peerDiscoveryToken))
        }
    }

    func session(_ session: NISession, didInvalidateWith error: Error) {
        status = .idle
    }
}
