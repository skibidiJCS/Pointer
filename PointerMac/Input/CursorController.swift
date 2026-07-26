import CoreGraphics
import Foundation

@MainActor
final class CursorController {
    private var processor = MotionProcessor()
    private let eventSource = CGEventSource(stateID: .hidSystemState)
    private var lastMovementDate: Date?

    func move(deltaX: CGFloat, deltaY: CGFloat, settings: MotionSettings) {
        guard let location = CGEvent(source: nil)?.location else {
            return
        }

        let now = Date()
        if let lastMovementDate,
           now.timeIntervalSince(lastMovementDate) > 0.1 {
            processor.reset()
        }
        self.lastMovementDate = now

        let delta = processor.process(deltaX: deltaX, deltaY: deltaY, settings: settings)
        let destination = CGPoint(x: location.x + delta.x, y: location.y + delta.y)
        let event = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .mouseMoved,
            mouseCursorPosition: destination,
            mouseButton: .left
        )
        event?.post(tap: .cghidEventTap)
    }

    func leftClick() {
        guard let location = CGEvent(source: nil)?.location else {
            return
        }

        let down = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .leftMouseDown,
            mouseCursorPosition: location,
            mouseButton: .left
        )
        let up = CGEvent(
            mouseEventSource: eventSource,
            mouseType: .leftMouseUp,
            mouseCursorPosition: location,
            mouseButton: .left
        )
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    func reset() {
        processor.reset()
        lastMovementDate = nil
    }
}
