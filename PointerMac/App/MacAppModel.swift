import AppKit
import Foundation

@MainActor
final class MacAppModel: ObservableObject {
    let accessibility: AccessibilityAuthorizer
    let devices: PairedDeviceStore
    let logs: ConnectionLogStore
    let settings: PointerSettings
    let server: PointerServer

    private let cursor = CursorController()
    private var hasLoggedMissingPermission = false
    private var started = false

    init() {
        accessibility = AccessibilityAuthorizer()
        devices = PairedDeviceStore()
        logs = ConnectionLogStore()
        settings = PointerSettings()
        server = PointerServer()

        server.onPeerConnected = { [weak self] peer in
            self?.cursor.reset()
            self?.devices.markConnected(peer)
            self?.logs.add("\(peer.name) connected", level: .success)
        }
        server.onPeerDisconnected = { [weak self] peer in
            self?.cursor.reset()
            self?.devices.markDisconnected(peer.id)
            self?.logs.add("\(peer.name) disconnected", level: .info)
        }
        server.onMessage = { [weak self] peer, message in
            self?.handle(message, from: peer)
        }
        server.onLog = { [weak self] message, level in
            self?.logs.add(message, level: level)
        }
    }

    func start() {
        guard !started else {
            return
        }
        started = true
        refreshPermission()
        server.start()
    }

    func refreshPermission() {
        accessibility.refresh()
        if accessibility.isTrusted {
            hasLoggedMissingPermission = false
        }
    }

    func requestAccessibility() {
        accessibility.request()
        logs.add("Accessibility permission requested", level: .info)
    }

    func forget(_ device: PairedDevice) {
        devices.forget(device.id)
        logs.add("Forgot \(device.name)", level: .info)
    }

    private func handle(_ message: PointerMessage, from peer: PeerHello) {
        switch message {
        case .motion(_, let deltaX, let deltaY):
            guard accessibility.isTrusted else {
                logMissingPermissionIfNeeded()
                return
            }
            cursor.move(
                deltaX: CGFloat(deltaX),
                deltaY: CGFloat(deltaY),
                settings: settings.snapshot
            )
        case .click:
            guard accessibility.isTrusted else {
                logMissingPermissionIfNeeded()
                return
            }
            cursor.leftClick()
        default:
            break
        }
    }

    private func logMissingPermissionIfNeeded() {
        guard !hasLoggedMissingPermission else {
            return
        }
        hasLoggedMissingPermission = true
        logs.add("Cursor input blocked until Accessibility is enabled", level: .warning)
    }
}
