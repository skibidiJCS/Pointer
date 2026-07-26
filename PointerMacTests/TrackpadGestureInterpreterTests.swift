import XCTest
@testable import PointerMac

final class TrackpadGestureInterpreterTests: XCTestCase {
    func testTapRegistersClick() {
        var interpreter = TrackpadGestureInterpreter()

        XCTAssertNil(
            interpreter.update(
                location: CGPoint(x: 20, y: 30),
                timestamp: 1
            )
        )

        XCTAssertTrue(interpreter.end(timestamp: 1.12))
    }

    func testDragProducesRelativeMovementWithoutClick() {
        var interpreter = TrackpadGestureInterpreter()
        _ = interpreter.update(location: CGPoint(x: 20, y: 30), timestamp: 1)

        let delta = interpreter.update(
            location: CGPoint(x: 32, y: 24),
            timestamp: 1.05
        )

        XCTAssertEqual(delta?.x, 12)
        XCTAssertEqual(delta?.y, -6)
        XCTAssertFalse(interpreter.end(timestamp: 1.1))
    }

    func testLongPressDoesNotClick() {
        var interpreter = TrackpadGestureInterpreter()
        _ = interpreter.update(location: CGPoint(x: 20, y: 30), timestamp: 1)

        XCTAssertFalse(interpreter.end(timestamp: 1.5))
    }

    func testStateResetsAfterGesture() {
        var interpreter = TrackpadGestureInterpreter()
        _ = interpreter.update(location: CGPoint(x: 10, y: 10), timestamp: 1)
        _ = interpreter.end(timestamp: 1.1)

        XCTAssertNil(
            interpreter.update(
                location: CGPoint(x: 50, y: 60),
                timestamp: 2
            )
        )
    }
}
