import ApplicationServices
import Foundation

@MainActor
final class AccessibilityAuthorizer: ObservableObject {
    @Published private(set) var isTrusted = false

    func refresh() {
        isTrusted = AXIsProcessTrusted()
    }

    func request() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        isTrusted = AXIsProcessTrustedWithOptions(options)
        scheduleRefresh(attemptsRemaining: 20)
    }

    private func scheduleRefresh(attemptsRemaining: Int) {
        guard attemptsRemaining > 0, !isTrusted else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refresh()
            self?.scheduleRefresh(attemptsRemaining: attemptsRemaining - 1)
        }
    }
}
