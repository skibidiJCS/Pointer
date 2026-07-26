import Foundation

@MainActor
final class PairedDeviceStore: ObservableObject {
    @Published private(set) var devices: [PairedDevice] = []

    private let defaults: UserDefaults
    private let storageKey = "pairedDevices"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func markConnected(_ peer: PeerHello) {
        if let index = devices.firstIndex(where: { $0.id == peer.id }) {
            devices[index].name = peer.name
            devices[index].lastSeen = Date()
            devices[index].isConnected = true
        } else {
            devices.append(
                PairedDevice(
                    id: peer.id,
                    name: peer.name,
                    lastSeen: Date(),
                    isConnected: true
                )
            )
        }
        sort()
        save()
    }

    func markDisconnected(_ id: String) {
        guard let index = devices.firstIndex(where: { $0.id == id }) else {
            return
        }
        devices[index].isConnected = false
        devices[index].lastSeen = Date()
        sort()
        save()
    }

    func forget(_ id: String) {
        devices.removeAll { $0.id == id }
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([PairedDevice].self, from: data) else {
            return
        }
        devices = decoded.map {
            var device = $0
            device.isConnected = false
            return device
        }
        sort()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(devices) else {
            return
        }
        defaults.set(data, forKey: storageKey)
    }

    private func sort() {
        devices.sort {
            if $0.isConnected != $1.isConnected {
                return $0.isConnected
            }
            return $0.lastSeen > $1.lastSeen
        }
    }
}
