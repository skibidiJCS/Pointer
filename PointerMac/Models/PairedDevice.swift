import Foundation

struct PairedDevice: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var lastSeen: Date
    var isConnected: Bool
}
