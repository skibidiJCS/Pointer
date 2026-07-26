import Foundation

enum PointerCodec {
    static let magic: UInt16 = 0x5054
    static let headerLength = 6

    static func encode(_ message: PointerMessage) -> Data {
        let type: PointerMessageType
        var payload = Data()

        switch message {
        case .hello(let hello):
            type = .hello
            payload = (try? JSONEncoder().encode(hello)) ?? Data()
        case .welcome(let hello):
            type = .welcome
            payload = (try? JSONEncoder().encode(hello)) ?? Data()
        case .motion(let sequence, let deltaX, let deltaY):
            type = .motion
            payload.appendUInt32(sequence)
            payload.appendFloat32(deltaX)
            payload.appendFloat32(deltaY)
        case .click(let sequence):
            type = .click
            payload.appendUInt32(sequence)
        case .ping(let sequence):
            type = .ping
            payload.appendUInt32(sequence)
        case .pong(let sequence):
            type = .pong
            payload.appendUInt32(sequence)
        }

        var frame = Data()
        frame.appendUInt16(magic)
        frame.append(PointerConstants.protocolVersion)
        frame.append(type.rawValue)
        frame.appendUInt16(UInt16(payload.count))
        frame.append(payload)
        return frame
    }

    static func decode(_ frame: Data) throws -> PointerMessage {
        guard frame.count >= headerLength else {
            throw PointerCodecError.invalidLength
        }
        guard frame.readUInt16(at: 0) == magic else {
            throw PointerCodecError.invalidMagic
        }
        guard frame[2] == PointerConstants.protocolVersion else {
            throw PointerCodecError.unsupportedVersion
        }
        guard let type = PointerMessageType(rawValue: frame[3]) else {
            throw PointerCodecError.unknownMessage
        }

        let payloadLength = Int(frame.readUInt16(at: 4))
        guard payloadLength <= PointerConstants.maximumFrameLength,
              frame.count == headerLength + payloadLength else {
            throw PointerCodecError.invalidLength
        }

        let payload = frame.subdata(in: headerLength..<frame.count)
        switch type {
        case .hello:
            return .hello(try decodeHello(payload))
        case .welcome:
            return .welcome(try decodeHello(payload))
        case .motion:
            guard payload.count == 12 else {
                throw PointerCodecError.malformedPayload
            }
            return .motion(
                sequence: payload.readUInt32(at: 0),
                deltaX: payload.readFloat32(at: 4),
                deltaY: payload.readFloat32(at: 8)
            )
        case .click:
            return .click(sequence: try decodeSequence(payload))
        case .ping:
            return .ping(sequence: try decodeSequence(payload))
        case .pong:
            return .pong(sequence: try decodeSequence(payload))
        }
    }

    private static func decodeHello(_ payload: Data) throws -> PeerHello {
        do {
            return try JSONDecoder().decode(PeerHello.self, from: payload)
        } catch {
            throw PointerCodecError.malformedPayload
        }
    }

    private static func decodeSequence(_ payload: Data) throws -> UInt32 {
        guard payload.count == 4 else {
            throw PointerCodecError.malformedPayload
        }
        return payload.readUInt32(at: 0)
    }
}

struct PointerFrameParser {
    private var buffer = Data()

    mutating func append(_ data: Data) throws -> [PointerMessage] {
        buffer.append(data)
        var messages: [PointerMessage] = []

        while buffer.count >= PointerCodec.headerLength {
            guard buffer.readUInt16(at: 0) == PointerCodec.magic else {
                buffer = Data(buffer.dropFirst())
                continue
            }

            let payloadLength = Int(buffer.readUInt16(at: 4))
            guard payloadLength <= PointerConstants.maximumFrameLength else {
                throw PointerCodecError.invalidLength
            }

            let frameLength = PointerCodec.headerLength + payloadLength
            guard buffer.count >= frameLength else {
                break
            }

            let frame = buffer.subdata(in: 0..<frameLength)
            buffer = Data(buffer.dropFirst(frameLength))
            messages.append(try PointerCodec.decode(frame))
        }

        return messages
    }
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        append(UInt8((value >> 8) & 0xff))
        append(UInt8(value & 0xff))
    }

    mutating func appendUInt32(_ value: UInt32) {
        append(UInt8((value >> 24) & 0xff))
        append(UInt8((value >> 16) & 0xff))
        append(UInt8((value >> 8) & 0xff))
        append(UInt8(value & 0xff))
    }

    mutating func appendFloat32(_ value: Float) {
        appendUInt32(value.bitPattern)
    }

    func readUInt16(at offset: Int) -> UInt16 {
        (UInt16(self[offset]) << 8) | UInt16(self[offset + 1])
    }

    func readUInt32(at offset: Int) -> UInt32 {
        (UInt32(self[offset]) << 24)
            | (UInt32(self[offset + 1]) << 16)
            | (UInt32(self[offset + 2]) << 8)
            | UInt32(self[offset + 3])
    }

    func readFloat32(at offset: Int) -> Float {
        Float(bitPattern: readUInt32(at: offset))
    }
}
