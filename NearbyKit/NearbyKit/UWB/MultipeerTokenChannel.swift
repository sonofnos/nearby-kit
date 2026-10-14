import MultipeerConnectivity
import Combine
import UIKit

/// Exchanges opaque payloads between two nearby devices over
/// MultipeerConnectivity. `NISession` itself has no transport: Apple's own
/// NearbyInteraction samples use MultipeerConnectivity (or a custom
/// Bluetooth/network channel) purely to hand each side the other's
/// `NIDiscoveryToken` before ranging can start. This class is that
/// transport, nothing more.
final class MultipeerTokenChannel: NSObject, ObservableObject {
    @Published private(set) var connectedPeer: MCPeerID?
    var onDataReceived: ((Data) -> Void)?

    private let serviceType = "nearbykit-ni"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)

    private lazy var session: MCSession = {
        let session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()

    private lazy var advertiser = MCNearbyServiceAdvertiser(
        peer: myPeerId,
        discoveryInfo: nil,
        serviceType: serviceType
    )

    private lazy var browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)

    func start() {
        advertiser.delegate = self
        browser.delegate = self
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func stop() {
        advertiser.stopAdvertisingPeer()
        browser.stopBrowsingForPeers()
        session.disconnect()
    }

    func send(_ data: Data) {
        guard let peer = connectedPeer else { return }
        try? session.send(data, toPeers: [peer], with: .reliable)
    }
}

extension MultipeerTokenChannel: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            connectedPeer = peerID
        case .notConnected:
            if connectedPeer == peerID {
                connectedPeer = nil
            }
        case .connecting:
            break
        @unknown default:
            break
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        onDataReceived?(data)
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerTokenChannel: MCNearbyServiceAdvertiserDelegate {
    func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        invitationHandler(true, session)
    }
}

extension MultipeerTokenChannel: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if connectedPeer == peerID {
            connectedPeer = nil
        }
    }
}
