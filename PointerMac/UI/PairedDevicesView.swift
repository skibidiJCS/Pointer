import SwiftUI

struct PairedDevicesView: View {
    @ObservedObject var store: PairedDeviceStore
    let forget: (PairedDevice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Paired Watches", systemImage: "applewatch")
                .font(.headline)

            if store.devices.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "applewatch.radiowaves.left.and.right")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    Text("No paired Watches")
                        .fontWeight(.medium)
                    Text("Open Pointer on Apple Watch to find this Mac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 128)
            } else {
                VStack(spacing: 0) {
                    ForEach(store.devices) { device in
                        deviceRow(device)
                        if device.id != store.devices.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .pointerCard()
    }

    private func deviceRow(_ device: PairedDevice) -> some View {
        HStack(spacing: 12) {
            StatusIndicator(color: device.isConnected ? .green : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .fontWeight(.medium)
                Text(device.isConnected ? "Connected" : device.lastSeen.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                forget(device)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .disabled(device.isConnected)
            .help(device.isConnected ? "Disconnect on Apple Watch first" : "Forget Watch")
        }
        .padding(.vertical, 10)
    }
}
