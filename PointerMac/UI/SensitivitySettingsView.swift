import SwiftUI

struct SensitivitySettingsView: View {
    @ObservedObject var settings: PointerSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Pointer Feel", systemImage: "slider.horizontal.3")
                    .font(.headline)
                Spacer()
                Button("Reset") {
                    settings.restoreDefaults()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }

            setting(
                title: "Sensitivity",
                value: $settings.sensitivity,
                range: 0.4...3,
                valueText: settings.sensitivity.formatted(.number.precision(.fractionLength(2)))
            )
            setting(
                title: "Acceleration",
                value: $settings.acceleration,
                range: 0...1.5,
                valueText: settings.acceleration.formatted(.number.precision(.fractionLength(2)))
            )
            setting(
                title: "Smoothing",
                value: $settings.smoothing,
                range: 0...0.5,
                valueText: settings.smoothing.formatted(.percent.precision(.fractionLength(0)))
            )
        }
        .pointerCard()
    }

    private func setting(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        valueText: String
    ) -> some View {
        VStack(spacing: 7) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(valueText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}
