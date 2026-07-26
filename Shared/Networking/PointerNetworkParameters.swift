import Network

enum PointerNetworkParameters {
    static func make() -> NWParameters {
        let tcp = NWProtocolTCP.Options()
        tcp.noDelay = true
        tcp.enableKeepalive = true
        tcp.keepaliveIdle = 2
        tcp.keepaliveInterval = 1
        tcp.keepaliveCount = 3

        let parameters = NWParameters(tls: nil, tcp: tcp)
        parameters.includePeerToPeer = true
        parameters.allowLocalEndpointReuse = true
        parameters.serviceClass = .responsiveData
        return parameters
    }
}
