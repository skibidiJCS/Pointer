import Foundation

@MainActor
final class PointerSettings: ObservableObject {
    @Published var sensitivity: Double {
        didSet {
            defaults.set(sensitivity, forKey: Keys.sensitivity)
        }
    }

    @Published var acceleration: Double {
        didSet {
            defaults.set(acceleration, forKey: Keys.acceleration)
        }
    }

    @Published var smoothing: Double {
        didSet {
            defaults.set(smoothing, forKey: Keys.smoothing)
        }
    }

    var snapshot: MotionSettings {
        MotionSettings(
            sensitivity: sensitivity,
            acceleration: acceleration,
            smoothing: smoothing
        )
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sensitivity = defaults.object(forKey: Keys.sensitivity) as? Double ?? 1.1
        acceleration = defaults.object(forKey: Keys.acceleration) as? Double ?? 0.45
        smoothing = defaults.object(forKey: Keys.smoothing) as? Double ?? 0.08
    }

    func restoreDefaults() {
        sensitivity = 1.1
        acceleration = 0.45
        smoothing = 0.08
    }

    private enum Keys {
        static let sensitivity = "pointerSensitivity"
        static let acceleration = "pointerAcceleration"
        static let smoothing = "pointerSmoothing"
    }
}
