import CoreGraphics

struct MotionSettings: Equatable {
    let sensitivity: Double
    let acceleration: Double
    let smoothing: Double
}

struct MotionProcessor {
    private var filtered = CGPoint.zero

    mutating func process(
        deltaX: CGFloat,
        deltaY: CGFloat,
        settings: MotionSettings
    ) -> CGPoint {
        let magnitude = hypot(deltaX, deltaY)
        let normalizedSpeed = min(Double(magnitude) / 8, 3)
        let gain = settings.sensitivity
            * (1 + settings.acceleration * pow(normalizedSpeed, 1.25))
        let raw = CGPoint(
            x: deltaX * gain,
            y: deltaY * gain
        )
        let retained = settings.smoothing
        filtered = CGPoint(
            x: filtered.x * retained + raw.x * (1 - retained),
            y: filtered.y * retained + raw.y * (1 - retained)
        )
        return filtered
    }

    mutating func reset() {
        filtered = .zero
    }
}
