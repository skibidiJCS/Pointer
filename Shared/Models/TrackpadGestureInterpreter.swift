import CoreGraphics
import Foundation

struct TrackpadGestureInterpreter {
    private let maximumTapDuration: TimeInterval
    private let maximumTapDistance: CGFloat
    private var previousLocation: CGPoint?
    private var startedAt: TimeInterval?
    private var traveledDistance: CGFloat = 0

    init(
        maximumTapDuration: TimeInterval = 0.35,
        maximumTapDistance: CGFloat = 10
    ) {
        self.maximumTapDuration = maximumTapDuration
        self.maximumTapDistance = maximumTapDistance
    }

    mutating func update(
        location: CGPoint,
        timestamp: TimeInterval
    ) -> CGPoint? {
        guard let previousLocation else {
            startedAt = timestamp
            self.previousLocation = location
            return nil
        }

        let delta = CGPoint(
            x: location.x - previousLocation.x,
            y: location.y - previousLocation.y
        )
        traveledDistance += hypot(delta.x, delta.y)
        self.previousLocation = location
        return delta == .zero ? nil : delta
    }

    mutating func end(timestamp: TimeInterval) -> Bool {
        defer {
            reset()
        }
        guard let startedAt else {
            return true
        }
        return timestamp - startedAt <= maximumTapDuration
            && traveledDistance <= maximumTapDistance
    }

    mutating func reset() {
        previousLocation = nil
        startedAt = nil
        traveledDistance = 0
    }
}
