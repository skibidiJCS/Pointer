import Foundation

enum PointerMessage: Equatable, Sendable {
    case hello(PeerHello)
    case welcome(PeerHello)
    case motion(sequence: UInt32, deltaX: Float, deltaY: Float)
    case click(sequence: UInt32)
    case ping(sequence: UInt32)
    case pong(sequence: UInt32)
}

enum PointerMessageType: UInt8 {
    case hello = 1
    case welcome = 2
    case motion = 3
    case click = 4
    case ping = 5
    case pong = 6
}

enum PointerCodecError: Error, Equatable {
    case invalidMagic
    case unsupportedVersion
    case invalidLength
    case unknownMessage
    case malformedPayload
}
