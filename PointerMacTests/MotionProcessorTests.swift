import XCTest
@testable import PointerMac

final class MotionProcessorTests: XCTestCase {
    func testSensitivityScalesMovement() {
        var processor = MotionProcessor()
        let settings = MotionSettings(
            sensitivity: 2,
            acceleration: 0,
            smoothing: 0
        )

        let output = processor.process(
            deltaX: 3,
            deltaY: -2,
            settings: settings
        )

        XCTAssertEqual(output.x, 6, accuracy: 0.001)
        XCTAssertEqual(output.y, -4, accuracy: 0.001)
    }

    func testAccelerationIncreasesFastMovementGain() {
        var slowProcessor = MotionProcessor()
        var fastProcessor = MotionProcessor()
        let settings = MotionSettings(
            sensitivity: 1,
            acceleration: 0.8,
            smoothing: 0
        )

        let slow = slowProcessor.process(
            deltaX: 1,
            deltaY: 0,
            settings: settings
        )
        let fast = fastProcessor.process(
            deltaX: 10,
            deltaY: 0,
            settings: settings
        )

        XCTAssertGreaterThan(fast.x / 10, slow.x)
    }
}
