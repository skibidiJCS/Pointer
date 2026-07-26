import SwiftUI

struct RootWatchView: View {
    @ObservedObject var model: WatchAppModel

    var body: some View {
        Group {
            if case .connected(let mac) = model.connectionState {
                TrackpadView(model: model, mac: mac)
            } else {
                ConnectionView(model: model)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.connectionState)
    }
}
