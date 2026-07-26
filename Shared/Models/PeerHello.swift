import Foundation

struct PeerHello: Codable, Equatable, Sendable {
    let id: String
    let name: String
    let protocolVersion: UInt8
}

enum PointerConstants {
    static let serviceType = "_pointer._tcp"
    static let protocolVersion: UInt8 = 1
    static let maximumFrameLength = 4096
}
