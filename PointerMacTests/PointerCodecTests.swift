import XCTest
@testable import PointerMac

final class PointerCodecTests: XCTestCase {
    func testMotionRoundTrip() throws {
        let message = PointerMessage.motion(
            sequence: 42,
            deltaX: 3.25,
            deltaY: -8.5
        )
        let decoded = try PointerCodec.decode(PointerCodec.encode(message))
        XCTAssertEqual(decoded, message)
    }

    func testInputPacketsStayCompact() {
        let motion = PointerCodec.encode(
            .motion(sequence: 1, deltaX: 2, deltaY: 3)
        )
        let click = PointerCodec.encode(.click(sequence: 2))

        XCTAssertEqual(motion.count, 18)
        XCTAssertEqual(click.count, 10)
    }

    func testChunkedFrames() throws {
        let first = PointerCodec.encode(.click(sequence: 4))
        let second = PointerCodec.encode(.ping(sequence: 5))
        let stream = first + second
        var parser = PointerFrameParser()

        XCTAssertTrue(try parser.append(stream.prefix(3)).isEmpty)
        let messages = try parser.append(stream.dropFirst(3))

        XCTAssertEqual(messages, [.click(sequence: 4), .ping(sequence: 5)])
    }

    func testHelloRoundTrip() throws {
        let hello = PeerHello(
            id: UUID().uuidString,
            name: "Test Watch",
            protocolVersion: PointerConstants.protocolVersion
        )
        let decoded = try PointerCodec.decode(
            PointerCodec.encode(.hello(hello))
        )
        XCTAssertEqual(decoded, .hello(hello))
    }
}
