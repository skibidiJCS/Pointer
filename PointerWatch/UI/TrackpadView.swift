import SwiftUI

struct TrackpadView: View {
    @ObservedObject var model: WatchAppModel
    let mac: PeerHello

    @State private var gestureInterpreter = TrackpadGestureInterpreter()

    var body: some View {
        ZStack {
            TrackpadBackground()
                .ignoresSafeArea()

            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .gesture(trackpadGesture)

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text(mac.name)
                            .font(.caption2.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .allowsHitTesting(false)

                    Spacer(minLength: 6)

                    Button {
                        model.disconnect()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2.bold())
                            .frame(width: 28, height: 28)
                            .background(.black.opacity(0.32), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Disconnect")
                }
                .padding(.horizontal, 9)
                .padding(.top, 2)

                Spacer()

                VStack(spacing: 5) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 25, weight: .light))
                    Text("drag to move")
                        .font(.caption2.weight(.semibold))
                    Text("tap to click")
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.68))
                .allowsHitTesting(false)

                Spacer()
            }
        }
    }

    private var trackpadGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if let delta = gestureInterpreter.update(
                    location: value.location,
                    timestamp: ProcessInfo.processInfo.systemUptime
                ) {
                    model.sendMotion(deltaX: delta.x, deltaY: delta.y)
                }
            }
            .onEnded { _ in
                if gestureInterpreter.end(
                    timestamp: ProcessInfo.processInfo.systemUptime
                ) {
                    model.click()
                }
            }
    }
}
