import SwiftUI

struct ConnectionLogsView: View {
    @ObservedObject var store: ConnectionLogStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Connection Log", systemImage: "text.alignleft")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    store.clear()
                }
                .buttonStyle(.borderless)
                .disabled(store.entries.isEmpty)
            }

            if store.entries.isEmpty {
                Text("Connection activity will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .center)
            } else {
                LazyVStack(spacing: 7) {
                    ForEach(store.entries.prefix(40)) { entry in
                        HStack(spacing: 9) {
                            Circle()
                                .fill(color(for: entry.level))
                                .frame(width: 6, height: 6)
                            Text(entry.date, format: .dateTime.hour().minute().second())
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.tertiary)
                            Text(entry.message)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }
            }
        }
        .pointerCard()
    }

    private func color(for level: LogLevel) -> Color {
        switch level {
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}
