import SwiftUI

@main
struct PointerWatchApp: App {
    @StateObject private var model = WatchAppModel()

    var body: some Scene {
        WindowGroup {
            RootWatchView(model: model)
                .onAppear {
                    model.start()
                }
        }
    }
}
