import Foundation

enum WatchConnectionState: Equatable {
    case disconnected
    case connecting(String)
    case handshaking(String)
    case connected(PeerHello)
    case failed(String)
}

@MainActor
final class PointerClient {
    var onStateChange: ((WatchConnectionState) -> Void)?

    private(set) var state: WatchConnectionState = .disconnected {
        didSet {
            onStateChange?(state)
        }
    }

    private let identity: PeerHello
    private let queue = DispatchQueue(label: "com.pointer.watch.connection", qos: .userInteractive)
    private var session: WatchPeerSession?
    private var expectedMacID: String?
    private var sequence: UInt32 = 0
    private var heartbeatTimer: Timer?
    private var lastPong = Date()

    init(identity: PeerHello) {
        self.identity = identity
    }

    func connect(to mac: DiscoveredMac) {
        disconnectSession()
        expectedMacID = mac.id
        state = .connecting(mac.name)

        let session = WatchPeerSession(endpoint: mac.endpoint)
        self.session = session
        session.onReady = { [weak self, weak session] in
            DispatchQueue.main.async {
                guard let self, let session, self.session?.id == session.id else {
                    return
                }
                self.state = .handshaking(mac.name)
                session.send(.hello(self.identity))
            }
        }
        session.onMessage = { [weak self, weak session] message in
            DispatchQueue.main.async {
                guard let self, let session, self.session?.id == session.id else {
                    return
                }
                self.handle(message)
            }
        }
        session.onEnd = { [weak self, weak session] reason in
            DispatchQueue.main.async {
                guard let self, let session, self.session?.id == session.id else {
                    return
                }
                self.session = nil
                self.stopHeartbeat()
                self.state = reason.map(WatchConnectionState.failed) ?? .disconnected
            }
        }
        session.start(on: queue)
    }

    func disconnect() {
        disconnectSession()
        state = .disconnected
    }

    func sendMotion(deltaX: Float, deltaY: Float) {
        guard case .connected = state else {
            return
        }
        sequence &+= 1
        session?.send(
            .motion(sequence: sequence, deltaX: deltaX, deltaY: deltaY)
        )
    }

    func sendClick() -> Bool {
        guard case .connected = state else {
            return false
        }
        sequence &+= 1
        session?.send(.click(sequence: sequence))
        return true
    }

    private func handle(_ message: PointerMessage) {
        switch message {
        case .welcome(let mac):
            guard mac.id == expectedMacID,
                  mac.protocolVersion == PointerConstants.protocolVersion else {
                state = .failed("The Mac identity could not be verified")
                disconnectSession()
                return
            }
            state = .connected(mac)
            startHeartbeat()
        case .pong:
            lastPong = Date()
        default:
            break
        }
    }

    private func startHeartbeat() {
        stopHeartbeat()
        lastPong = Date()
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else {
                    return
                }
                if Date().timeIntervalSince(self.lastPong) > 6 {
                    self.state = .failed("Connection lost")
                    self.disconnectSession()
                    return
                }
                self.sequence &+= 1
                self.session?.send(.ping(sequence: self.sequence))
            }
        }
        heartbeatTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }

    private func disconnectSession() {
        stopHeartbeat()
        let activeSession = session
        session = nil
        activeSession?.cancel()
    }
}
