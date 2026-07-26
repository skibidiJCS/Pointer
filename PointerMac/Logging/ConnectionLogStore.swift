import Foundation

enum LogLevel: String {
    case info
    case success
    case warning
    case error
}

struct ConnectionLogEntry: Identifiable {
    let id = UUID()
    let date: Date
    let message: String
    let level: LogLevel
}

@MainActor
final class ConnectionLogStore: ObservableObject {
    @Published private(set) var entries: [ConnectionLogEntry] = []

    func add(_ message: String, level: LogLevel) {
        entries.insert(
            ConnectionLogEntry(date: Date(), message: message, level: level),
            at: 0
        )
        if entries.count > 200 {
            entries.removeLast(entries.count - 200)
        }
    }

    func clear() {
        entries.removeAll()
    }
}
