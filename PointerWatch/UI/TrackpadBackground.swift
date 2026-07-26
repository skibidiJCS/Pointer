import SwiftUI

struct TrackpadBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.26, blue: 0.27),
                    Color(red: 0.12, green: 0.13, blue: 0.14),
                    Color(red: 0.07, green: 0.075, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    .white.opacity(0.09),
                    .clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 230
            )

            Canvas { context, size in
                let spacing: CGFloat = 7
                let diameter: CGFloat = 0.7
                var row = 0
                var y: CGFloat = 3.5

                while y < size.height {
                    var column = 0
                    var x = 3.5 + (row.isMultiple(of: 2) ? 0 : spacing / 2)

                    while x < size.width {
                        let tone = (row * 17 + column * 31) % 7
                        let color = tone < 3
                            ? Color.white.opacity(0.055)
                            : Color.black.opacity(0.07)
                        context.fill(
                            Path(
                                ellipseIn: CGRect(
                                    x: x,
                                    y: y,
                                    width: diameter,
                                    height: diameter
                                )
                            ),
                            with: .color(color)
                        )
                        x += spacing
                        column += 1
                    }

                    y += spacing
                    row += 1
                }
            }

            LinearGradient(
                colors: [
                    .white.opacity(0.035),
                    .clear,
                    .black.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
