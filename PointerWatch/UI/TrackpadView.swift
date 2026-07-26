import SwiftUI

struct TrackpadView: View {
    @ObservedObject var model: WatchAppModel
    let mac: PeerHello

    @State private var lastLocation: CGPoint?
    @State private var gestureStart: Date?
    @State private var traveledDistance = 0.0

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.34),
                        Color.black.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                        Text(mac.name)
                            .font(.caption2.weight(.medium))
                            .lineLimit(1)
                        Spacer()
                        Button {
                            model.disconnect()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2.bold())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 7)

                    Spacer()

                    Image(systemName: "hand.draw")
                        .font(.system(size: 27, weight: .light))
                        .foregroundStyle(.secondary)
                    Text("Drag to move · Tap to click")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(Rectangle())
            .gesture(trackpadGesture, including: .gesture)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
    }

    private var trackpadGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if gestureStart == nil {
                    gestureStart = Date()
                    lastLocation = value.location
                    traveledDistance = 0
                    return
                }

                guard let lastLocation else {
                    self.lastLocation = value.location
                    return
                }

                let deltaX = value.location.x - lastLocation.x
                let deltaY = value.location.y - lastLocation.y
                traveledDistance += hypot(deltaX, deltaY)
                self.lastLocation = value.location

                if deltaX != 0 || deltaY != 0 {
                    model.sendMotion(deltaX: deltaX, deltaY: deltaY)
                }
            }
            .onEnded { _ in
                let duration = Date().timeIntervalSince(gestureStart ?? Date())
                if duration < 0.35 && traveledDistance < 10 {
                    model.click()
                }
                resetGesture()
            }
    }

    private func resetGesture() {
        lastLocation = nil
        gestureStart = nil
        traveledDistance = 0
    }
}
