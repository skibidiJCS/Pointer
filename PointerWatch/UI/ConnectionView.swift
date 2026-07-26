import SwiftUI

struct ConnectionView: View {
    @ObservedObject var model: WatchAppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "cursorarrow.motionlines")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.tint)
                Text("Pointer")
                    .font(.headline)

                stateView

                if canShowMacs {
                    VStack(spacing: 7) {
                        ForEach(model.availableMacs) { mac in
                            Button {
                                model.connect(to: mac)
                            } label: {
                                HStack {
                                    Image(systemName: "desktopcomputer")
                                    Text(mac.name)
                                        .lineLimit(1)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
        }
    }

    @ViewBuilder
    private var stateView: some View {
        switch model.connectionState {
        case .connecting(let name), .handshaking(let name):
            VStack(spacing: 8) {
                ProgressView()
                Text("Connecting to \(name)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Cancel") {
                    model.disconnect()
                }
                .font(.caption)
            }
        case .failed(let message):
            VStack(spacing: 5) {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
                Text(macStatus)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .disconnected:
            Text(macStatus)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        case .connected:
            EmptyView()
        }
    }

    private var macStatus: String {
        model.availableMacs.isEmpty ? "Searching for nearby Macs…" : "Choose a Mac"
    }

    private var canShowMacs: Bool {
        switch model.connectionState {
        case .connecting, .handshaking:
            return false
        default:
            return true
        }
    }
}
