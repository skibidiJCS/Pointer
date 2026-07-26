import Foundation
import Network

enum PointerServerState: Equatable {
    case stopped
    case advertising
    case connected(Int)
    case failed(String)

    var title: String {
        switch self {
        case .stopped:
            return "Offline"
        case .advertising:
            return "Ready for Apple Watch"
        case .connected(let count):
            return count == 1 ? "1 Watch connected" : "\(count) Watches connected"
        case .failed:
            return "Connection error"
        }
    }
}

@MainActor
final class PointerServer: ObservableObject {
    @Published private(set) var state: PointerServerState = .stopped

    var onPeerConnected: ((PeerHello) -> Void)?
    var onPeerDisconnected: ((PeerHello) -> Void)?
    var onMessage: ((PeerHello, PointerMessage) -> Void)?
    var onLog: ((String, LogLevel) -> Void)?

    private let queue = DispatchQueue(label: "com.pointer.mac.network", qos: .userInteractive)
    private var listener: NWListener?
    private var sessions: [UUID: MacPeerSession] = [:]
    private let identity: PeerHello

    init(defaults: UserDefaults = .standard) {
        let key = "macPeerID"
        let id = defaults.string(forKey: key) ?? UUID().uuidString
        defaults.set(id, forKey: key)
        identity = PeerHello(
            id: id,
            name: Host.current().localizedName ?? "Mac",
            protocolVersion: PointerConstants.protocolVersion
        )
    }

    func start() {
        guard listener == nil else {
            return
        }

        do {
            let listener = try NWListener(using: PointerNetworkParameters.make())
            let record = NWTXTRecord([
                "id": identity.id,
                "name": identity.name,
                "version": String(identity.protocolVersion)
            ])
            listener.service = NWListener.Service(
                name: identity.name,
                type: PointerConstants.serviceType,
                txtRecord: record
            )
            listener.stateUpdateHandler = { [weak self] newState in
                DispatchQueue.main.async {
                    self?.handleListenerState(newState)
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                DispatchQueue.main.async {
                    self?.accept(connection)
                }
            }
            self.listener = listener
            state = .advertising
            onLog?("Starting local discovery", .info)
            listener.start(queue: queue)
        } catch {
            state = .failed(error.localizedDescription)
            onLog?("Could not start: \(error.localizedDescription)", .error)
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        for session in sessions.values {
            session.cancel()
        }
        sessions.removeAll()
        state = .stopped
    }

    private func handleListenerState(_ newState: NWListener.State) {
        switch newState {
        case .ready:
            updateState()
            onLog?("Mac is discoverable on the local network", .success)
        case .waiting(let error):
            state = .failed(error.debugDescription)
            onLog?("Local network unavailable: \(error.debugDescription)", .warning)
        case .failed(let error):
            state = .failed(error.debugDescription)
            onLog?("Listener failed: \(error.debugDescription)", .error)
            listener = nil
        case .cancelled:
            if listener == nil {
                state = .stopped
            }
        default:
            break
        }
    }

    private func accept(_ connection: NWConnection) {
        let session = MacPeerSession(connection: connection)
        sessions[session.id] = session
        session.onMessage = { [weak self, weak session] message in
            DispatchQueue.main.async {
                guard let session else {
                    return
                }
                self?.handle(message, from: session)
            }
        }
        session.onEnd = { [weak self, weak session] reason in
            DispatchQueue.main.async {
                guard let session else {
                    return
                }
                self?.remove(session, reason: reason)
            }
        }
        session.start(on: queue)
    }

    private func handle(_ message: PointerMessage, from session: MacPeerSession) {
        if case .hello(let peer) = message {
            guard peer.protocolVersion == PointerConstants.protocolVersion else {
                onLog?("Rejected an incompatible Watch", .warning)
                session.cancel()
                return
            }

            let firstHandshake = session.peer == nil
            session.peer = peer
            session.send(.welcome(identity))
            if firstHandshake {
                onPeerConnected?(peer)
                updateState()
            }
            return
        }

        guard let peer = session.peer else {
            session.cancel()
            return
        }

        if case .ping(let sequence) = message {
            session.send(.pong(sequence: sequence))
            return
        }
        onMessage?(peer, message)
    }

    private func remove(_ session: MacPeerSession, reason: String?) {
        guard sessions.removeValue(forKey: session.id) != nil else {
            return
        }
        if let peer = session.peer {
            onPeerDisconnected?(peer)
        }
        if let reason {
            onLog?("Connection ended: \(reason)", .warning)
        }
        updateState()
    }

    private func updateState() {
        let connectedCount = sessions.values.filter { $0.peer != nil }.count
        state = connectedCount == 0 ? .advertising : .connected(connectedCount)
    }
}
