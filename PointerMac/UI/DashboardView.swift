import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: MacAppModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.11),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .center
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    permissionBanner
                    HStack(alignment: .top, spacing: 18) {
                        PairedDevicesView(
                            store: model.devices,
                            forget: model.forget
                        )
                        .frame(maxWidth: .infinity)

                        SensitivitySettingsView(settings: model.settings)
                            .frame(width: 310)
                    }
                    ConnectionLogsView(store: model.logs)
                }
                .padding(24)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "cursorarrow.motionlines")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 52, height: 52)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 15))

            VStack(alignment: .leading, spacing: 3) {
                Text("Pointer")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                HStack(spacing: 7) {
                    StatusIndicator(color: statusColor)
                    Text(model.server.state.title)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("Local only")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial, in: Capsule())
        }
    }

    @ViewBuilder
    private var permissionBanner: some View {
        if model.accessibility.isTrusted {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundStyle(.green)
                Text("Cursor control is enabled")
                    .fontWeight(.medium)
                Spacer()
            }
            .pointerCard()
        } else {
            HStack(spacing: 12) {
                Image(systemName: "cursorarrow.click.2")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Accessibility permission needed")
                        .fontWeight(.semibold)
                    Text("Pointer asks only when you enable Mac cursor control.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Enable Cursor Control") {
                    model.requestAccessibility()
                }
                .buttonStyle(.borderedProminent)
            }
            .pointerCard()
        }
    }

    private var statusColor: Color {
        switch model.server.state {
        case .connected:
            return .green
        case .advertising:
            return .blue
        case .failed:
            return .red
        case .stopped:
            return .secondary
        }
    }
}
