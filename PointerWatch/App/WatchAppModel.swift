import Foundation
import WatchKit

@MainActor
final class WatchAppModel: ObservableObject {
    @Published private(set) var availableMacs: [DiscoveredMac] = []
    @Published private(set) var connectionState: WatchConnectionState = .disconnected

    private let browser = PointerBrowser()
    private let client: PointerClient
    private let defaults: UserDefaults
    private var reconnectWorkItem: DispatchWorkItem?
    private var manuallyDisconnected = false
    private var started = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let key = "watchPeerID"
        let id = defaults.string(forKey: key) ?? UUID().uuidString
        defaults.set(id, forKey: key)
        client = PointerClient(
            identity: PeerHello(
                id: id,
                name: WKInterfaceDevice.current().name,
                protocolVersion: PointerConstants.protocolVersion
            )
        )

        browser.onUpdate = { [weak self] macs in
            self?.availableMacs = macs
            self?.attemptAutomaticReconnect()
        }
        browser.onError = { [weak self] error in
            guard let self, case .disconnected = self.connectionState else {
                return
            }
            self.connectionState = .failed(error)
            self.scheduleReconnect()
        }
        client.onStateChange = { [weak self] state in
            self?.connectionState = state
            self?.handleConnectionState(state)
        }
    }

    func start() {
        guard !started else {
            return
        }
        started = true
        browser.start()
    }

    func connect(to mac: DiscoveredMac) {
        reconnectWorkItem?.cancel()
        manuallyDisconnected = false
        client.connect(to: mac)
    }

    func disconnect() {
        manuallyDisconnected = true
        reconnectWorkItem?.cancel()
        client.disconnect()
    }

    func sendMotion(deltaX: Double, deltaY: Double) {
        client.sendMotion(deltaX: Float(deltaX), deltaY: Float(deltaY))
    }

    func click() {
        guard client.sendClick() else {
            return
        }
        WKInterfaceDevice.current().play(.click)
    }

    private func handleConnectionState(_ state: WatchConnectionState) {
        switch state {
        case .connected(let mac):
            defaults.set(mac.id, forKey: "lastMacID")
            defaults.set(mac.name, forKey: "lastMacName")
            browser.stop()
        case .failed, .disconnected:
            browser.start()
            scheduleReconnect()
        default:
            break
        }
    }

    private func attemptAutomaticReconnect() {
        guard !manuallyDisconnected,
              let lastMacID = defaults.string(forKey: "lastMacID"),
              let mac = availableMacs.first(where: { $0.id == lastMacID }) else {
            return
        }
        switch connectionState {
        case .disconnected, .failed:
            break
        default:
            return
        }
        client.connect(to: mac)
    }

    private func scheduleReconnect() {
        guard started, !manuallyDisconnected else {
            return
        }
        reconnectWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.attemptAutomaticReconnect()
        }
        reconnectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: workItem)
    }
}
