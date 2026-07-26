import Network

struct DiscoveredMac: Identifiable {
    let id: String
    let name: String
    let endpoint: NWEndpoint

    static func == (lhs: DiscoveredMac, rhs: DiscoveredMac) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.endpoint == rhs.endpoint
    }
}

extension DiscoveredMac: Equatable {}
