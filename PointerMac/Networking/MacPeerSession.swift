import Foundation
import Network

final class MacPeerSession {
    let id = UUID()
    let connection: NWConnection
    var peer: PeerHello?
    var onReady: (() -> Void)?
    var onMessage: ((PointerMessage) -> Void)?
    var onEnd: ((String?) -> Void)?

    private var parser = PointerFrameParser()
    private var ended = false

    init(connection: NWConnection) {
        self.connection = connection
    }

    func start(on queue: DispatchQueue) {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else {
                return
            }
            switch state {
            case .ready:
                self.onReady?()
                self.receive()
            case .failed(let error):
                self.finish(error.debugDescription)
            case .cancelled:
                self.finish(nil)
            default:
                break
            }
        }
        connection.start(queue: queue)
    }

    func send(_ message: PointerMessage) {
        connection.send(
            content: PointerCodec.encode(message),
            completion: .idempotent
        )
    }

    func cancel() {
        connection.cancel()
    }

    private func receive() {
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: PointerConstants.maximumFrameLength * 2
        ) { [weak self] data, _, isComplete, error in
            guard let self else {
                return
            }

            if let data, !data.isEmpty {
                do {
                    for message in try self.parser.append(data) {
                        self.onMessage?(message)
                    }
                } catch {
                    self.finish("Invalid packet")
                    self.connection.cancel()
                    return
                }
            }

            if let error {
                self.finish(error.debugDescription)
            } else if isComplete {
                self.finish(nil)
            } else {
                self.receive()
            }
        }
    }

    private func finish(_ reason: String?) {
        guard !ended else {
            return
        }
        ended = true
        onEnd?(reason)
    }
}
